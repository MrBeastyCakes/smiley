part of 'connection_bloc.dart';

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
  const ConnectionError({required this.message});
  @override List<Object?> get props => [message];
}
