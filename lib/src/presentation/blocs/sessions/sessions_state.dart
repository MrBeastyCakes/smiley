part of 'sessions_bloc.dart';

sealed class SessionsState extends Equatable {
  const SessionsState();
  @override List<Object?> get props => [];
}

class SessionsLoading extends SessionsState {
  const SessionsLoading();
}

class SessionsLoaded extends SessionsState {
  final List<Session> sessions;
  const SessionsLoaded({required this.sessions});
  @override List<Object?> get props => [sessions];
}

class SessionCreated extends SessionsState {
  final Session session;
  const SessionCreated({required this.session});
  @override List<Object?> get props => [session];
}

class SessionsError extends SessionsState {
  final String message;
  const SessionsError({required this.message});
  @override List<Object?> get props => [message];
}
