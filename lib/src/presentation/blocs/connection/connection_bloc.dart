import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/gateway_ping_datasource.dart';
import '../../../data/sync/sync_coordinator.dart';
import '../../../domain/entities/gateway_settings.dart';
import '../../../services/gateway_websocket.dart';

part 'connection_event.dart';
part 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  final GatewayWebSocketClient? _client;
  final GatewayPingDataSource? _ping;
  final SyncCoordinator? _syncCoordinator;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _retrySubscription;
  GatewaySettings? _lastSettings;
  int _retryCount = 0;

  ConnectionBloc({
    GatewayWebSocketClient? client,
    GatewayPingDataSource? ping,
    SyncCoordinator? syncCoordinator,
  })  : _client = client ?? ServiceLocator.get<GatewayWebSocketClient>(),
        _ping = ping,
        _syncCoordinator = syncCoordinator,
        super(const ConnectionInitial()) {
    on<ConnectRequested>(_onConnectRequested);
    on<DisconnectRequested>(_onDisconnectRequested);
    on<ConnectionStatusChanged>(_onStatusChanged);
    on<RetryCountUpdated>(_onRetryCountUpdated);
    on<RetryNowRequested>(_onRetryNowRequested);
  }

  Future<void> _onConnectRequested(ConnectRequested event, Emitter<ConnectionState> emit) async {
    emit(const ConnectionLoading());
    _lastSettings = event.settings;

    // Step 1: Ping the gateway to give immediate feedback on common errors.
    final ping = _ping ?? GatewayPingDataSource();
    try {
      await ping.ping(event.settings.host, event.settings.port);
    } catch (e) {
      if (e is GatewayException) {
        emit(ConnectionError(message: e.message, code: ConnectionErrorCode.connectionRefused));
      } else {
        emit(ConnectionError(message: e.toString(), code: ConnectionErrorCode.unknown));
      }
      return;
    }

    // Step 2: WebSocket handshake
    try {
      await _client!.connect(event.settings);
      _retryCount = 0;
      _subscribeToClient();
      // If already connected, emit immediately (the connected event may have
      // fired before we subscribed to the status stream).
      if (_client!.isConnected) {
        emit(ConnectionConnected(settings: event.settings));
        // Start background sync
        await _syncCoordinator?.startSync(event.settings);
      }
    } on SocketException catch (e) {
      final code = _mapSocketError(e);
      emit(ConnectionError(
        message: _errorMessageFor(code, event.settings),
        code: code,
      ));
    } on FormatException catch (_) {
      emit(const ConnectionError(
        message: 'Invalid host format. Check the IP address or hostname.',
        code: ConnectionErrorCode.invalidHost,
      ));
    } catch (e) {
      emit(ConnectionError(
        message: 'Connection failed: $e',
        code: ConnectionErrorCode.unknown,
      ));
    }
  }

  Future<void> _onDisconnectRequested(DisconnectRequested event, Emitter<ConnectionState> emit) async {
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    await _retrySubscription?.cancel();
    _retrySubscription = null;
    await _syncCoordinator?.stopSync();
    await _client?.disconnect();
    emit(const ConnectionInitial());
  }

  Future<void> _onRetryNowRequested(RetryNowRequested event, Emitter<ConnectionState> emit) async {
    if (_lastSettings == null) return;
    emit(ConnectionReconnecting(settings: _lastSettings!, retryCount: 0));
    await _client?.retryNow();
  }

  Future<void> _onRetryCountUpdated(RetryCountUpdated event, Emitter<ConnectionState> emit) async {
    _retryCount = event.retryCount;
    if (state is ConnectionReconnecting) {
      final s = state as ConnectionReconnecting;
      emit(ConnectionReconnecting(settings: s.settings, retryCount: _retryCount));
    }
  }

  Future<void> _onStatusChanged(ConnectionStatusChanged event, Emitter<ConnectionState> emit) async {
    switch (event.status) {
      case ConnectionStatus.connected:
        _retryCount = 0;
        // Always emit Connected when we get a connected status —
        // covers both initial connect and auto-reconnect.
        if (state is! ConnectionConnected) {
          emit(ConnectionConnected(settings: _lastSettings ?? const GatewaySettings(host: '', port: 0, token: '')));
        }
        // Start background sync when fully connected
        if (_lastSettings != null) {
          await _syncCoordinator?.startSync(_lastSettings!);
        }
        break;
      case ConnectionStatus.disconnected:
        await _syncCoordinator?.stopSync();
        // Don't kick user out to initial — show reconnecting banner instead.
        if (_lastSettings != null && state is! ConnectionOffline && state is! ConnectionReconnecting) {
          emit(ConnectionReconnecting(
            settings: _lastSettings!,
            retryCount: _retryCount,
          ));
        }
        break;
      case ConnectionStatus.error:
        // If we've hit max retries, show offline.
        if (_retryCount >= GatewayWebSocketClient.maxRetryAttempts && _lastSettings != null) {
          emit(ConnectionOffline(settings: _lastSettings!));
          return;
        }
        // Only show error if we're not already showing one and not connected
        if (state is! ConnectionError && state is! ConnectionConnected) {
          emit(const ConnectionError(
            message: 'Connection lost. Retrying...',
            code: ConnectionErrorCode.unknown,
          ));
        }
        break;
      case ConnectionStatus.reconnecting:
        if (_lastSettings != null && state is! ConnectionReconnecting) {
          emit(ConnectionReconnecting(
            settings: _lastSettings!,
            retryCount: _retryCount,
          ));
        }
        break;
      default:
        break;
    }
  }

  @override
  Future<void> close() async {
    await _statusSubscription?.cancel();
    await _retrySubscription?.cancel();
    return super.close();
  }

  void _subscribeToClient() {
    _statusSubscription?.cancel();
    _retrySubscription?.cancel();
    _statusSubscription = _client!.statusStream.listen(
      (status) => add(ConnectionStatusChanged(status)),
    );
    _retrySubscription = _client!.retryCountStream.listen(
      (count) => add(RetryCountUpdated(count)),
    );
  }

  ConnectionErrorCode _mapSocketError(SocketException e) {
    final osError = e.osError;
    if (osError == null) return ConnectionErrorCode.unknown;
    switch (osError.errorCode) {
      case 10061:
      case 111:
        return ConnectionErrorCode.connectionRefused;
      case 10051:
      case 101:
        return ConnectionErrorCode.networkUnreachable;
      case 10060:
      case 110:
        return ConnectionErrorCode.timeout;
      default:
        return ConnectionErrorCode.unknown;
    }
  }

  String _errorMessageFor(ConnectionErrorCode code, GatewaySettings settings) {
    switch (code) {
      case ConnectionErrorCode.connectionRefused:
        return 'Connection refused at ${settings.host}:${settings.port}.\n\n'
            '• Is the gateway running?\n'
            '• Did you use the correct port?\n'
            '• Is a firewall blocking port ${settings.port}?';
      case ConnectionErrorCode.networkUnreachable:
        return 'Network unreachable.\n\n'
            '• Are you on the same WiFi as the gateway?\n'
            '• Is the host address correct?';
      case ConnectionErrorCode.timeout:
        return 'Connection timed out.\n\n'
            '• The gateway may be behind a firewall.\n'
            '• Try checking the host and port.';
      case ConnectionErrorCode.invalidToken:
        return 'Invalid token. Generate a new one in the gateway dashboard.';
      default:
        return 'Connection failed. Check the host, port, and token.';
    }
  }
}
