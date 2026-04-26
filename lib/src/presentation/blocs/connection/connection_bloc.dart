import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/gateway_ping_datasource.dart';
import '../../../domain/entities/gateway_settings.dart';
import '../../../services/gateway_websocket.dart';

part 'connection_event.dart';
part 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  final GatewayWebSocketClient? _client;
  final GatewayPingDataSource? _ping;
  StreamSubscription? _statusSubscription;
  GatewaySettings? _lastSettings;

  ConnectionBloc({GatewayWebSocketClient? client, GatewayPingDataSource? ping})
      : _client = client ?? ServiceLocator.get<GatewayWebSocketClient>(),
        _ping = ping,
        super(const ConnectionInitial()) {
    on<ConnectRequested>(_onConnectRequested);
    on<DisconnectRequested>(_onDisconnectRequested);
    on<ConnectionStatusChanged>(_onStatusChanged);
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
      _statusSubscription?.cancel();
      _statusSubscription = _client!.statusStream.listen(
        (status) => add(ConnectionStatusChanged(status)),
      );
      // If already connected, emit immediately (the connected event may have
      // fired before we subscribed to the status stream).
      if (_client!.isConnected) {
        emit(ConnectionConnected(settings: event.settings));
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
    await _client?.disconnect();
    emit(const ConnectionInitial());
  }

  Future<void> _onStatusChanged(ConnectionStatusChanged event, Emitter<ConnectionState> emit) async {
    switch (event.status) {
      case ConnectionStatus.connected:
        if (state is ConnectionLoading || state is ConnectionError) {
          emit(ConnectionConnected(settings: _lastSettings ?? const GatewaySettings(host: '', port: 0, token: '')));
        }
        break;
      case ConnectionStatus.disconnected:
        emit(const ConnectionInitial());
        break;
      case ConnectionStatus.error:
        emit(const ConnectionError(
          message: 'Connection lost. Tap Connect to retry.',
          code: ConnectionErrorCode.unknown,
        ));
        break;
      case ConnectionStatus.reconnecting:
        break;
      default:
        break;
    }
  }

  @override
  Future<void> close() async {
    await _statusSubscription?.cancel();
    return super.close();
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
