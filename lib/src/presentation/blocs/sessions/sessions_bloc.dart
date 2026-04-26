import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/repositories/session_repository.dart';

part 'sessions_event.dart';
part 'sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final SessionRepository _repository;
  StreamSubscription<Either<Failure, List<Session>>>? _subscription;

  SessionsBloc({SessionRepository? repository})
      : _repository = repository ?? ServiceLocator.get<SessionRepository>(),
        super(const SessionsLoading()) {
    on<LoadSessions>(_onLoad);
    on<RefreshSessions>(_onLoad);
    on<CreateSession>(_onCreate);
    on<PinSession>(_onPin);
    on<ArchiveSession>(_onArchive);
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _repository.watchSessions().listen(
      (either) => either.fold(
        (failure) {},
        (sessions) => emit(SessionsLoaded(sessions: sessions)),
      ),
    );
  }

  Future<void> _onLoad(SessionsEvent event, Emitter<SessionsState> emit) async {
    emit(const SessionsLoading());
    final result = await _repository.getSessions();
    result.fold(
      (failure) => emit(SessionsError(message: failure.message)),
      (sessions) => emit(SessionsLoaded(sessions: sessions)),
    );
  }

  Future<void> _onPin(PinSession event, Emitter<SessionsState> emit) async {
    final result = await _repository.pinSession(event.id, event.pinned);
    result.fold(
      (failure) => emit(SessionsError(message: failure.message)),
      (_) => add(const RefreshSessions()),
    );
  }

  Future<void> _onArchive(ArchiveSession event, Emitter<SessionsState> emit) async {
    final result = await _repository.archiveSession(event.id);
    result.fold(
      (failure) => emit(SessionsError(message: failure.message)),
      (_) => add(const RefreshSessions()),
    );
  }

  Future<void> _onCreate(CreateSession event, Emitter<SessionsState> emit) async {
    emit(const SessionsLoading());
    final result = await _repository.createSession(
      title: event.title,
      agentId: event.agentId,
    );
    result.fold(
      (failure) => emit(SessionsError(message: failure.message)),
      (session) => emit(SessionCreated(session: session)),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
