import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/domain/entities/session.dart';
import 'package:openclaw_client/src/domain/repositories/session_repository.dart';
import 'package:openclaw_client/src/presentation/blocs/sessions/sessions_bloc.dart';

class _MockSessionRepository implements SessionRepository {
  final List<Session> _sessions;
  final Failure? _failure;
  final Stream<List<Session>>? _watchStream;

  _MockSessionRepository({
    List<Session> sessions = const [],
    Failure? failure,
    Stream<List<Session>>? watchStream,
  })  : _sessions = sessions,
        _failure = failure,
        _watchStream = watchStream;

  @override
  Future<Either<Failure, List<Session>>> getSessions() async {
    if (_failure != null) return Left(_failure!);
    return Right(_sessions);
  }

  @override
  Future<Either<Failure, Session>> getSessionById(String id) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> pinSession(String id, bool pinned) async => const Right(null);

  @override
  Future<Either<Failure, void>> archiveSession(String id) async => const Right(null);

  @override
  Stream<Either<Failure, List<Session>>> watchSessions() {
    return (_watchStream ?? const Stream.empty()).map((list) => Right(list));
  }
}

void main() {
  group('SessionsBloc', () {
    final mockSessions = [
      Session(
        id: 's1', title: 'Test Session',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        messageCount: 3, lastMessagePreview: 'Hello',
      ),
    ];

    blocTest<SessionsBloc, SessionsState>(
      'emits [SessionsLoading, SessionsLoaded] on LoadSessions',
      build: () => SessionsBloc(
        repository: _MockSessionRepository(sessions: mockSessions),
      ),
      act: (bloc) => bloc.add(const LoadSessions()),
      expect: () => [
        isA<SessionsLoading>(),
        isA<SessionsLoaded>().having((s) => s.sessions.length, 'count', 1),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'emits [SessionsLoading, SessionsError] on failure',
      build: () => SessionsBloc(
        repository: _MockSessionRepository(failure: const NetworkFailure('oops')),
      ),
      act: (bloc) => bloc.add(const LoadSessions()),
      expect: () => [
        isA<SessionsLoading>(),
        isA<SessionsError>().having((s) => s.message, 'message', 'oops'),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'emits updated SessionsLoaded on watch stream',
      build: () {
        final updated = [
          Session(
            id: 's2', title: 'Updated',
            createdAt: DateTime.now(), updatedAt: DateTime.now(),
            messageCount: 1,
          ),
        ];
        return SessionsBloc(
          repository: _MockSessionRepository(
            sessions: mockSessions,
            watchStream: Stream.fromFuture(Future.delayed(Duration.zero, () => updated)),
          ),
        );
      },
      act: (bloc) => bloc.add(const LoadSessions()),
      expect: () => [
        isA<SessionsLoading>(),
        isA<SessionsLoaded>().having((s) => s.sessions.length, 'count', 1),
        isA<SessionsLoaded>().having((s) => s.sessions.first.id, 'id', 's2'),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'refreshes after PinSession',
      build: () => SessionsBloc(
        repository: _MockSessionRepository(sessions: mockSessions),
      ),
      act: (bloc) => bloc.add(const PinSession(id: 's1', pinned: true)),
      expect: () => [
        isA<SessionsLoading>(),
        isA<SessionsLoaded>().having((s) => s.sessions.length, 'count', 1),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'refreshes after ArchiveSession',
      build: () => SessionsBloc(
        repository: _MockSessionRepository(sessions: mockSessions),
      ),
      act: (bloc) => bloc.add(const ArchiveSession(id: 's1')),
      expect: () => [
        isA<SessionsLoading>(),
        isA<SessionsLoaded>().having((s) => s.sessions.length, 'count', 1),
      ],
    );
  });
}
