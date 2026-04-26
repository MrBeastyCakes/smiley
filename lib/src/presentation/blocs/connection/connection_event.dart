part of 'connection_bloc.dart';

sealed class ConnectionEvent extends Equatable {
  const ConnectionEvent();
  @override List<Object?> get props => [];
}

class ConnectRequested extends ConnectionEvent {
  final GatewaySettings settings;
  const ConnectRequested(this.settings);
  @override List<Object?> get props => [settings];
}

class DisconnectRequested extends ConnectionEvent {
  const DisconnectRequested();
}

/// User tapped to retry connection after max retries exhausted.
class RetryNowRequested extends ConnectionEvent {
  const RetryNowRequested();
}

class ConnectionStatusChanged extends ConnectionEvent {
  final ConnectionStatus status;
  const ConnectionStatusChanged(this.status);
  @override List<Object?> get props => [status];
}

/// Emitted when the auto-retry attempt count changes.
class RetryCountUpdated extends ConnectionEvent {
  final int retryCount;
  const RetryCountUpdated(this.retryCount);
  @override List<Object?> get props => [retryCount];
}
