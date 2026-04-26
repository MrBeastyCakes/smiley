import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/data/datasources/session_remote_datasource.dart';
import 'package:openclaw_client/src/data/local/database_helper.dart';
import 'package:openclaw_client/src/data/local/session_local_datasource.dart';
import 'package:openclaw_client/src/data/models/session_model.dart';
import 'package:openclaw_client/src/data/repositories/session_repository_impl.dart';
import 'package:openclaw_client/src/domain/entities/session.dart';

import '../../helpers/sqflite_test_helper.dart';

class MockSessionRemoteDataSource extends Mock implements SessionRemoteDataSource {}

void main() {
  initSqfliteFfi();

  group('SessionRepositoryImpl (local-first)', () {
    late DatabaseHelper dbHelper;
    late SessionLocalDataSource localDataSource;
    late MockSessionRemoteDataSource mockRemote;
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

    setUp(() async {
      dbHelper = DatabaseHelper.test('session_repo_test');
      await dbHelper.deleteDatabaseFile();
      localDataSource = SessionLocalDataSource(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    group('local-only (no remote)', () {
      setUp(() {
        repository = SessionRepositoryImpl(localDataSource: localDataSource);
      });

      test('getSessions returns local data even when empty', () async {
        final result = await repository.getSessions();
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (sessions) => expect(sessions, isEmpty),
        );
      });

      test('getSessions returns saved local sessions', () async {
        await localDataSource.saveSession(tSessionModel);
        final result = await repository.getSessions();
        result.fold(
          (_) => fail('should be Right'),
          (sessions) {
            expect(sessions.length, 1);
            expect(sessions.first.id, 'session-1');
          },
        );
      });

      test('getSessionById returns local session', () async {
        await localDataSource.saveSession(tSessionModel);
        final result = await repository.getSessionById('session-1');
        expect(result, equals(Right<Failure, Session>(tSession)));
      });

      test('getSessionById returns StorageFailure when not found', () async {
        final result = await repository.getSessionById('nonexistent');
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<StorageFailure>()),
          (_) => fail('should be Left'),
        );
      });

      test('pinSession updates local session', () async {
        await localDataSource.saveSession(tSessionModel);
        final result = await repository.pinSession('session-1', true);
        expect(result, equals(const Right<Failure, void>(null)));

        final updated = await localDataSource.getSessionById('session-1');
        expect(updated.isPinned, true);
      });

      test('archiveSession updates local session', () async {
        await localDataSource.saveSession(tSessionModel);
        final result = await repository.archiveSession('session-1');
        expect(result, equals(const Right<Failure, void>(null)));

        final updated = await localDataSource.getSessionById('session-1');
        expect(updated.isArchived, true);
      });

      test('watchSessions emits local sessions', () async {
        await localDataSource.saveSession(tSessionModel);
        final result = await repository.watchSessions().first
            .timeout(const Duration(seconds: 3));
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (sessions) => expect(sessions.first.id, 'session-1'),
        );
      });
    });

    group('with remote', () {
      setUp(() {
        mockRemote = MockSessionRemoteDataSource();
        repository = SessionRepositoryImpl(
          localDataSource: localDataSource,
          remoteDataSource: mockRemote,
        );
      });

      test('getSessions returns local immediately and background syncs remote', () async {
        await localDataSource.saveSession(tSessionModel);
        final remoteModel = SessionModel(
          id: tSessionModel.id,
          title: 'Remote Title',
          agentId: tSessionModel.agentId,
          createdAt: tSessionModel.createdAt,
          updatedAt: tSessionModel.updatedAt,
          messageCount: tSessionModel.messageCount,
          isPinned: tSessionModel.isPinned,
          isArchived: tSessionModel.isArchived,
          lastMessagePreview: tSessionModel.lastMessagePreview,
        );
        when(() => mockRemote.listSessions()).thenAnswer((_) async => [remoteModel]);

        final result = await repository.getSessions();
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (sessions) => expect(sessions.first.title, 'Test Session'),
        );

        // Background sync should eventually update local store.
        await Future.delayed(const Duration(milliseconds: 200));
        final localAfter = await localDataSource.getSessionById('session-1');
        expect(localAfter.title, 'Remote Title');
      });

      test('getSessions silently ignores remote failure', () async {
        await localDataSource.saveSession(tSessionModel);
        when(() => mockRemote.listSessions()).thenThrow(
          const GatewayException('Remote error', code: 'REMOTE_ERR'),
        );

        final result = await repository.getSessions();
        expect(result.isRight(), true);
      });

      test('getSessionById returns local and background refreshes remote', () async {
        await localDataSource.saveSession(tSessionModel);
        final remoteModel = SessionModel(
          id: tSessionModel.id,
          title: tSessionModel.title,
          agentId: tSessionModel.agentId,
          createdAt: tSessionModel.createdAt,
          updatedAt: tSessionModel.updatedAt,
          messageCount: 99,
          isPinned: tSessionModel.isPinned,
          isArchived: tSessionModel.isArchived,
          lastMessagePreview: tSessionModel.lastMessagePreview,
        );
        when(() => mockRemote.getSessionById(any())).thenAnswer((_) async => remoteModel);

        final result = await repository.getSessionById('session-1');
        expect(result, equals(Right<Failure, Session>(tSession)));

        await Future.delayed(const Duration(milliseconds: 200));
        final localAfter = await localDataSource.getSessionById('session-1');
        expect(localAfter.messageCount, 99);
      });

      test('pinSession local-first then syncs to remote', () async {
        await localDataSource.saveSession(tSessionModel);
        when(() => mockRemote.pinSession(any(), any())).thenAnswer((_) async {});

        final result = await repository.pinSession('session-1', true);
        expect(result, equals(const Right<Failure, void>(null)));
        await Future.delayed(Duration.zero);
        verify(() => mockRemote.pinSession('session-1', true)).called(1);
      });

      test('pinSession returns success even when remote fails', () async {
        await localDataSource.saveSession(tSessionModel);
        when(() => mockRemote.pinSession(any(), any())).thenThrow(Exception('boom'));

        final result = await repository.pinSession('session-1', true);
        expect(result, equals(const Right<Failure, void>(null)));
      });

      test('archiveSession local-first then syncs to remote', () async {
        await localDataSource.saveSession(tSessionModel);
        when(() => mockRemote.archiveSession(any())).thenAnswer((_) async {});

        final result = await repository.archiveSession('session-1');
        expect(result, equals(const Right<Failure, void>(null)));
        await Future.delayed(Duration.zero);
        verify(() => mockRemote.archiveSession('session-1')).called(1);
      });
    });
  });
}
