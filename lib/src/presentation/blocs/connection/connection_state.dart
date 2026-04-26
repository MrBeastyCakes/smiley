part of 'connection_bloc.dart';

/// Typed error codes for connection failures.
enum ConnectionErrorCode {
  none,
  invalidHost,
  connectionRefused,
  networkUnreachable,
  invalidToken,
  timeout,
  serverError,
  unknown,
}

sealed class ConnectionState extends Equatable {
  const ConnectionState();
  @override List<Object?> get props => [];
}

class ConnectionInitial extends ConnectionState {
  const ConnectionInitial();
}

class ConnectionLoading extends ConnectionState {
  const ConnectionLoading();
}

class ConnectionConnected extends ConnectionState {
  final GatewaySettings settings;
  const ConnectionConnected({required this.settings});
  @override List<Object?> get props => [settings];
}

class ConnectionError extends ConnectionState {
  final String message;
  final ConnectionErrorCode code;
  const ConnectionError({
    required this.message,
    this.code = ConnectionErrorCode.unknown,
  });
  @override List<Object?> get props => [message, code];
}
