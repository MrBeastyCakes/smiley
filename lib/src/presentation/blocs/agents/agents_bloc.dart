import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/agent.dart';
import '../../../domain/repositories/agent_repository.dart';

part 'agents_event.dart';
part 'agents_state.dart';

class AgentsBloc extends Bloc<AgentsEvent, AgentsState> {
  final AgentRepository _repository;
  StreamSubscription<Either<Failure, List<Agent>>>? _subscription;

  AgentsBloc({AgentRepository? repository})
      : _repository = repository ?? ServiceLocator.get<AgentRepository>(),
        super(const AgentsLoading()) {
    on<LoadAgents>(_onLoad);
    on<RefreshAgents>(_onLoad);
    on<ToggleAgent>(_onToggle);
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _repository.watchAgents().listen(
      (either) => either.fold(
        (failure) {},
        (agents) => emit(AgentsLoaded(agents: agents)),
      ),
    );
  }

  Future<void> _onLoad(AgentsEvent event, Emitter<AgentsState> emit) async {
    emit(const AgentsLoading());
    final result = await _repository.getAgents();
    result.fold(
      (failure) => emit(AgentsError(message: failure.message)),
      (agents) => emit(AgentsLoaded(agents: agents)),
    );
  }

  Future<void> _onToggle(ToggleAgent event, Emitter<AgentsState> emit) async {
    final result = await _repository.toggleActive(event.id, event.active);
    result.fold(
      (failure) => emit(AgentsError(message: failure.message)),
      (_) => add(const RefreshAgents()),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
