part of 'sessions_bloc.dart';

sealed class SessionsEvent extends Equatable {
  const SessionsEvent();
  @override List<Object?> get props => [];
}

class LoadSessions extends SessionsEvent {
  const LoadSessions();
}

class CreateSession extends SessionsEvent {
  final String? title;
  final String? agentId;
  const CreateSession({this.title, this.agentId});
  @override List<Object?> get props => [title, agentId];
}

class RefreshSessions extends SessionsEvent {
  const RefreshSessions();
}

class PinSession extends SessionsEvent {
  final String id;
  final bool pinned;
  const PinSession({required this.id, required this.pinned});
  @override List<Object?> get props => [id, pinned];
}

class ArchiveSession extends SessionsEvent {
  final String id;
  const ArchiveSession({required this.id});
  @override List<Object?> get props => [id];
}
