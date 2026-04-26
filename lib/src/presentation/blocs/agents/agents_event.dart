part of 'agents_bloc.dart';

sealed class AgentsEvent extends Equatable {
  const AgentsEvent();
  @override List<Object?> get props => [];
}

class LoadAgents extends AgentsEvent {
  const LoadAgents();
}

class RefreshAgents extends AgentsEvent {
  const RefreshAgents();
}

class ToggleAgent extends AgentsEvent {
  final String id;
  final bool active;
  const ToggleAgent({required this.id, required this.active});
  @override List<Object?> get props => [id, active];
}
