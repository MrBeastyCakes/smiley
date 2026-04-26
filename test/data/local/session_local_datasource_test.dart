import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/data/local/database_helper.dart';
import 'package:openclaw_client/src/data/local/session_local_datasource.dart';
import 'package:openclaw_client/src/data/models/session_model.dart';

import '../../helpers/sqflite_test_helper.dart';

void main() {
  initSqfliteFfi();

  group('SessionLocalDataSource', () {
    late DatabaseHelper dbHelper;
    late SessionLocalDataSource dataSource;

    final tSession1 = SessionModel(
      id: 'session-1',
      title: 'First Session',
      agentId: 'agent-1',
      createdAt: '2026-04-25T10:00:00.000',
      updatedAt: '2026-04-25T10:00:00.000',
      messageCount: 3,
      isPinned: true,
      isArchived: false,
      lastMessagePreview: 'Hello world',
    );

    final tSession2 = SessionModel(
      id: 'session-2',
      title: 'Second Session',
      agentId: 'agent-2',
      createdAt: '2026-04-25T09:00:00.000',
      updatedAt: '2026-04-25T09:00:00.000',
      messageCount: 0,
      isPinned: false,
      isArchived: true,
      lastMessagePreview: null,
    );

    setUp(() async {
      dbHelper = DatabaseHelper();
      await dbHelper.deleteDatabaseFile();
      dataSource = SessionLocalDataSource(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    group('saveSession / getSessionById', () {
      test('should save and retrieve a session', () async {
        await dataSource.saveSession(tSession1);
        final result = await dataSource.getSessionById('session-1');
        expect(result.id, 'session-1');
        expect(result.title, 'First Session');
        expect(result.isPinned, true);
        expect(result.isArchived, false);
      });

      test('should update an existing session (upsert)', () async {
        await dataSource.saveSession(tSession1);
        final updated = SessionModel(
          id: tSession1.id,
          title: 'Updated Title',
          agentId: tSession1.agentId,
          createdAt: tSession1.createdAt,
          updatedAt: tSession1.updatedAt,
          messageCount: tSession1.messageCount,
          isPinned: tSession1.isPinned,
          isArchived: tSession1.isArchived,
          lastMessagePreview: tSession1.lastMessagePreview,
        );
        await dataSource.saveSession(updated);
        final result = await dataSource.getSessionById('session-1');
        expect(result.title, 'Updated Title');
      });

      test('should throw StorageException when session not found', () async {
        expect(
          () => dataSource.getSessionById('nonexistent'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('saveSessions / listSessions', () {
      test('should save multiple sessions and list them ordered by updatedAt DESC', () async {
        await dataSource.saveSessions([tSession1, tSession2]);
        final result = await dataSource.listSessions();
        expect(result.length, 2);
        expect(result[0].id, 'session-1'); // more recent
        expect(result[1].id, 'session-2');
      });
    });

    group('pinSession', () {
      test('should toggle pin status', () async {
        await dataSource.saveSession(tSession1);
        await dataSource.pinSession('session-1', false);
        final result = await dataSource.getSessionById('session-1');
        expect(result.isPinned, false);
      });

      test('should throw StorageException when pinning nonexistent session', () async {
        expect(
          () => dataSource.pinSession('nonexistent', true),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('archiveSession', () {
      test('should archive a session', () async {
        await dataSource.saveSession(tSession1);
        await dataSource.archiveSession('session-1');
        final result = await dataSource.getSessionById('session-1');
        expect(result.isArchived, true);
      });

      test('should throw StorageException when archiving nonexistent session', () async {
        expect(
          () => dataSource.archiveSession('nonexistent'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('deleteSession', () {
      test('should delete a session', () async {
        await dataSource.saveSession(tSession1);
        await dataSource.deleteSession('session-1');
        expect(
          () => dataSource.getSessionById('session-1'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('clearAll', () {
      test('should remove all sessions', () async {
        await dataSource.saveSessions([tSession1, tSession2]);
        await dataSource.clearAll();
        final result = await dataSource.listSessions();
        expect(result, isEmpty);
      });
    });

    group('getUnsyncedSessions / markSynced', () {
      test('should return only unsynced sessions', () async {
        await dataSource.saveSession(tSession1);
        final unsynced = await dataSource.getUnsyncedSessions();
        expect(unsynced.length, 1);

        await dataSource.markSynced('session-1');
        final afterSync = await dataSource.getUnsyncedSessions();
        expect(afterSync, isEmpty);
      });
    });
  });
}
