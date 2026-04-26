import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/errors/exceptions.dart';
import '../domain/entities/gateway_settings.dart';

/// Connection status for the gateway WebSocket client.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Manages a persistent WebSocket connection to the OpenClaw gateway.
class GatewayWebSocketClient {
  static const _heartbeatInterval = Duration(seconds: 30);
  static const _heartbeatTimeout = Duration(seconds: 10);
  static const _maxReconnectDelay = Duration(seconds: 30);
  static const _initialReconnectDelay = Duration(seconds: 1);

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _requestController =
      StreamController<Map<String, dynamic>>.broadcast();

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _heartbeatTimeoutTimer;
  Timer? _reconnectTimer;

  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final _random = Random.secure();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  GatewaySettings? _settings;
  Duration _reconnectDelay = _initialReconnectDelay;
  bool _disposed = false;
  bool _pendingPing = false;

  /// The current connection status.
  ConnectionStatus get status => _status;

  /// Whether the client is currently connected.
  bool get isConnected => _status == ConnectionStatus.connected;

  /// Stream of incoming JSON messages from the gateway.
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Stream of incoming broadcast events (non-request-responses).
  Stream<Map<String, dynamic>> get eventStream => _messageController.stream;

  /// Stream of connection status changes.
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Connects to the gateway using the provided settings.
  /// Retries with exponential backoff on failure.
  Future<void> connect(GatewaySettings settings) async {
    if (_disposed) {
      throw const GatewayException('Client has been disposed');
    }
    if (_status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      return;
    }

    _settings = settings;
    await _connectWithRetry();
  }

  Future<void> _connectWithRetry() async {
    _setStatus(ConnectionStatus.connecting);

    while (!_disposed && _status != ConnectionStatus.connected) {
      try {
        await _attemptConnection();
        _reconnectDelay = _initialReconnectDelay;
        return;
      } catch (e) {
        if (_disposed) return;
        _setStatus(ConnectionStatus.error, reason: 'Connection failed: $e');
        await Future.delayed(_reconnectDelay);
        if (_disposed) return;
        _reconnectDelay = Duration(
          seconds: min(_reconnectDelay.inSeconds * 2, _maxReconnectDelay.inSeconds),
        );
        _setStatus(ConnectionStatus.reconnecting);
      }
    }
  }

  Future<void> _attemptConnection() async {
    final settings = _settings!;
    final protocol = settings.useTls ? 'wss' : 'ws';
    final uri = Uri.parse('$protocol://${settings.host}:${settings.port}/ws')
        .replace(queryParameters: {'token': settings.token});

    _channel = WebSocketChannel.connect(
      uri,
      protocols: ['openclaw-v1'],
    );

    // Wait for the connection to be ready
    await _channel!.ready;

    if (_disposed) {
      await _channel!.sink.close();
      _channel = null;
      return;
    }

    _setStatus(ConnectionStatus.connected);

    // Listen for incoming messages
    _channel!.stream.listen(
      _onMessage,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );

    _startHeartbeat();
  }

  /// Generates a unique request ID for correlated request/response.
  String _generateReqId() {
    final bytes = Uint8List(12);
    for (var i = 0; i < 12; i++) bytes[i] = _random.nextInt(256);
    return base64Url.encode(bytes);
  }

  /// Sends a request and waits for the matching response by `req_id`.
  /// Returns the response payload (with `req_id` stripped).
  Future<Map<String, dynamic>> sendRequest(Map<String, dynamic> payload) async {
    if (!isConnected || _channel == null) {
      throw const GatewayException('Not connected', code: 'NOT_CONNECTED');
    }

    final reqId = _generateReqId();
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[reqId] = completer;

    final message = Map<String, dynamic>.from(payload)..['req_id'] = reqId;

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      _pendingRequests.remove(reqId);
      throw GatewayException('Send failed: $e', code: 'SEND_ERROR');
    }

    try {
      final response = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _pendingRequests.remove(reqId);
          throw const GatewayException('Request timeout', code: 'TIMEOUT');
        },
      );
      return response;
    } on GatewayException {
      rethrow;
    } catch (e) {
      _pendingRequests.remove(reqId);
      throw GatewayException('Request failed: $e', code: 'REQUEST_FAILED');
    }
  }

  void _onMessage(dynamic data) {
    if (_disposed) return;

    Map<String, dynamic>? json;
    try {
      if (data is String) {
        json = jsonDecode(data) as Map<String, dynamic>?;
      }
    } catch (_) {
      return;
    }

    if (json == null) return;

    // Handle pong responses for heartbeat
    if (json['type'] == 'pong') {
      _pendingPing = false;
      _heartbeatTimeoutTimer?.cancel();
      _heartbeatTimeoutTimer = null;
      return;
    }

    // Route correlated responses to pending requests
    final reqId = json['req_id'] as String?;
    if (reqId != null && _pendingRequests.containsKey(reqId)) {
      final completer = _pendingRequests.remove(reqId)!;
      if (!completer.isCompleted) {
        completer.complete(Map<String, dynamic>.from(json)..remove('req_id'));
      }
      return;
    }

    if (!_messageController.isClosed) {
      _messageController.add(json);
    }
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (_disposed) return;
    _setStatus(ConnectionStatus.error, reason: error.toString());
    _scheduleReconnect();
  }

  void _onDone() {
    if (_disposed) return;
    if (_status == ConnectionStatus.disconnected) return;
    _setStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _cleanupConnection();
    if (_disposed || _settings == null) return;

    _setStatus(ConnectionStatus.reconnecting);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (_disposed) return;
      _reconnectDelay = Duration(
        seconds: min(_reconnectDelay.inSeconds * 2, _maxReconnectDelay.inSeconds),
      );
      await _connectWithRetry();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (!isConnected || _disposed) return;

      try {
        await send({'type': 'ping'});
        _pendingPing = true;

        _heartbeatTimeoutTimer?.cancel();
        _heartbeatTimeoutTimer = Timer(_heartbeatTimeout, () {
          if (_pendingPing && !_disposed) {
            _pendingPing = false;
            _setStatus(ConnectionStatus.error, reason: 'Heartbeat timeout');
            _channel?.sink.close(1001, 'Heartbeat timeout');
            _scheduleReconnect();
          }
        });
      } catch (_) {
        // Send failed; reconnect will be triggered by onError/onDone
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _heartbeatTimeoutTimer?.cancel();
    _heartbeatTimeoutTimer = null;
    _pendingPing = false;
  }

  /// Sends a JSON message to the gateway.
  /// Throws [GatewayException] if not connected.
  Future<void> send(Map<String, dynamic> message) async {
    if (!isConnected || _channel == null) {
      throw const GatewayException('Not connected', code: 'NOT_CONNECTED');
    }

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      throw GatewayException('Send failed: $e', code: 'SEND_ERROR');
    }
  }

  /// Disconnects from the gateway and stops reconnection attempts.
  Future<void> disconnect() async {
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          const GatewayException('Client disconnected', code: 'DISCONNECTED'),
        );
      }
    }
    _pendingRequests.clear();

    if (_disposed) return;
    _settings = null;
    _reconnectDelay = _initialReconnectDelay;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _setStatus(ConnectionStatus.disconnected);
    await _cleanupConnection();
  }

  Future<void> _cleanupConnection() async {
    _stopHeartbeat();
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _setStatus(ConnectionStatus newStatus, {String? reason}) {
    if (_statusController.isClosed) return;
    if (_status == newStatus) return;
    _status = newStatus;
    _statusController.add(newStatus);
  }

  /// Cleans up all resources. The client should not be used after disposal.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await disconnect();
    if (!_statusController.isClosed) {
      await _statusController.close();
    }
    if (!_messageController.isClosed) {
      await _messageController.close();
    }
  }
}
