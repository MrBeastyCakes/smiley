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
