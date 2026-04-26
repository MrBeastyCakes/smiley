part of 'agents_bloc.dart';

sealed class AgentsState extends Equatable {
  const AgentsState();
  @override List<Object?> get props => [];
}

class AgentsLoading extends AgentsState {
  const AgentsLoading();
}

class AgentsLoaded extends AgentsState {
  final List<Agent> agents;
  const AgentsLoaded({required this.agents});
  @override List<Object?> get props => [agents];
}

class AgentsError extends AgentsState {
  final String message;
  const AgentsError({required this.message});
  @override List<Object?> get props => [message];
}
