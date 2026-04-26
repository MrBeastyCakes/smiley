import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/data/datasources/session_remote_datasource.dart';
import 'package:openclaw_client/src/data/models/session_model.dart';
import 'package:openclaw_client/src/data/repositories/session_repository_impl.dart';
import 'package:openclaw_client/src/domain/entities/session.dart';

class MockSessionRemoteDataSource extends Mock implements SessionRemoteDataSource {}

void main() {
  late MockSessionRemoteDataSource mockDataSource;
  late SessionRepositoryImpl repository;

  final tSessionModel = SessionModel(
    id: 'session-1',
    title: 'Test Session',
    agentId: 'agent-1',
    createdAt: '2026-04-25T12:00:00.000',
    updatedAt: '2026-04-25T12:00:00.000',
    messageCount: 5,
    isPinned: false,
    isArchived: false,
    lastMessagePreview: 'Hello',
  );

  final tSession = tSessionModel.toEntity();
  final tSessionModels = [tSessionModel];
  final tSessions = [tSession];

  setUp(() {
    mockDataSource = MockSessionRemoteDataSource();
    repository = SessionRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('getSessions', () {
    test('should return Right(List<Session>) on success', () async {
      when(() => mockDataSource.listSessions()).thenAnswer((_) async => tSessionModels);

      final result = await repository.getSessions();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('should be Right'),
        (sessions) {
          expect(sessions.length, 1);
          expect(sessions.first.id, 'session-1');
        },
      );
      verify(() => mockDataSource.listSessions()).called(1);
    });

    test('should return Left(GatewayFailure) when datasource throws GatewayException', () async {
      when(() => mockDataSource.listSessions()).thenThrow(
        const GatewayException('Gateway error', code: 'GW_ERR'),
      );

      final result = await repository.getSessions();

      expect(
        result,
        equals(const Left<Failure, List<Session>>(GatewayFailure('Gateway error', code: 'GW_ERR'))),
      );
      verify(() => mockDataSource.listSessions()).called(1);
    });

    test('should return Left(NetworkFailure) on unexpected exception', () async {
      when(() => mockDataSource.listSessions()).thenThrow(Exception('boom'));

      final result = await repository.getSessions();

      expect(result, isA<Left<Failure, List<Session>>>());
      result.fold(
        (failure) => expect(failure.message, 'Failed to get sessions: Exception: boom'),
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.listSessions()).called(1);
    });
  });

  group('getSessionById', () {
    test('should return Right(Session) on success', () async {
      when(() => mockDataSource.getSessionById(any())).thenAnswer((_) async => tSessionModel);

      final result = await repository.getSessionById('session-1');

      expect(result, equals(Right<Failure, Session>(tSession)));
      verify(() => mockDataSource.getSessionById('session-1')).called(1);
    });

    test('should return Left(GatewayFailure) when datasource throws GatewayException', () async {
      when(() => mockDataSource.getSessionById(any())).thenThrow(
        const GatewayException('Not found', code: 'NOT_FOUND'),
      );

      final result = await repository.getSessionById('session-1');

      expect(
        result,
        equals(const Left<Failure, Session>(GatewayFailure('Not found', code: 'NOT_FOUND'))),
      );
      verify(() => mockDataSource.getSessionById('session-1')).called(1);
    });

    test('should return Left(NetworkFailure) on unexpected exception', () async {
      when(() => mockDataSource.getSessionById(any())).thenThrow(Exception('boom'));

      final result = await repository.getSessionById('session-1');

      expect(result, isA<Left<Failure, Session>>());
      result.fold(
        (failure) => expect(failure.message, 'Failed to get session: Exception: boom'),
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.getSessionById('session-1')).called(1);
    });
  });

  group('pinSession', () {
    test('should return Right(void) on success', () async {
      when(() => mockDataSource.pinSession(any(), any())).thenAnswer((_) async {});

      final result = await repository.pinSession('session-1', true);

      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => mockDataSource.pinSession('session-1', true)).called(1);
    });

    test('should return Left(GatewayFailure) when datasource throws GatewayException', () async {
      when(() => mockDataSource.pinSession(any(), any())).thenThrow(
        const GatewayException('Forbidden', code: 'FORBIDDEN'),
      );

      final result = await repository.pinSession('session-1', true);

      expect(
        result,
        equals(const Left<Failure, void>(GatewayFailure('Forbidden', code: 'FORBIDDEN'))),
      );
      verify(() => mockDataSource.pinSession('session-1', true)).called(1);
    });

    test('should return Left(NetworkFailure) on unexpected exception', () async {
      when(() => mockDataSource.pinSession(any(), any())).thenThrow(Exception('boom'));

      final result = await repository.pinSession('session-1', true);

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) => expect(failure.message, 'Failed to pin session: Exception: boom'),
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.pinSession('session-1', true)).called(1);
    });
  });

  group('archiveSession', () {
    test('should return Right(void) on success', () async {
      when(() => mockDataSource.archiveSession(any())).thenAnswer((_) async {});

      final result = await repository.archiveSession('session-1');

      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => mockDataSource.archiveSession('session-1')).called(1);
    });

    test('should return Left(GatewayFailure) when datasource throws GatewayException', () async {
      when(() => mockDataSource.archiveSession(any())).thenThrow(
        const GatewayException('Not found', code: 'NOT_FOUND'),
      );

      final result = await repository.archiveSession('session-1');

      expect(
        result,
        equals(const Left<Failure, void>(GatewayFailure('Not found', code: 'NOT_FOUND'))),
      );
      verify(() => mockDataSource.archiveSession('session-1')).called(1);
    });

    test('should return Left(NetworkFailure) on unexpected exception', () async {
      when(() => mockDataSource.archiveSession(any())).thenThrow(Exception('boom'));

      final result = await repository.archiveSession('session-1');

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) => expect(failure.message, 'Failed to archive session: Exception: boom'),
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.archiveSession('session-1')).called(1);
    });
  });

  group('watchSessions', () {
    test('should emit Right(List<Session>) on successful stream event', () async {
      when(() => mockDataSource.watchSessions()).thenAnswer(
        (_) => Stream.fromIterable([tSessionModels]),
      );

      final result = await repository.watchSessions().first;

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('should be Right'),
        (sessions) {
          expect(sessions.length, 1);
          expect(sessions.first.id, 'session-1');
        },
      );
      verify(() => mockDataSource.watchSessions()).called(1);
    });

    test('should emit Left(GatewayFailure) when stream throws GatewayException', () async {
      when(() => mockDataSource.watchSessions()).thenAnswer(
        (_) => Stream.error(
          const GatewayException('Stream error', code: 'STREAM_ERR'),
        ),
      );

      final result = await repository.watchSessions().first;

      expect(
        result,
        equals(const Left<Failure, List<Session>>(GatewayFailure('Stream error', code: 'STREAM_ERR'))),
      );
    });

    test('should emit Left(NetworkFailure) when stream throws unexpected error', () async {
      when(() => mockDataSource.watchSessions()).thenAnswer(
        (_) => Stream.error(Exception('boom')),
      );

      final result = await repository.watchSessions().first;

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Session stream error: Exception: boom'),
        (_) => fail('should be Left'),
      );
    });
  });
}
