import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/data/datasources/message_remote_datasource.dart';
import 'package:openclaw_client/src/data/local/database_helper.dart';
import 'package:openclaw_client/src/data/local/message_local_datasource.dart';
import 'package:openclaw_client/src/data/models/chat_message_model.dart';
import 'package:openclaw_client/src/data/repositories/message_repository_impl.dart';
import 'package:openclaw_client/src/domain/entities/chat_message.dart';

import '../../helpers/sqflite_test_helper.dart';

class MockMessageRemoteDataSource extends Mock implements MessageRemoteDataSource {}

void main() {
  initSqfliteFfi();

  group('MessageRepositoryImpl (local-first)', () {
    late DatabaseHelper dbHelper;
    late MessageLocalDataSource localDataSource;
    late MockMessageRemoteDataSource mockRemote;
    late MessageRepositoryImpl repository;

    final tMessage = ChatMessageModel(
      id: 'msg-1',
      sessionId: 'session-1',
      role: 'user',
      text: 'Hello',
      timestamp: '2026-04-25T12:00:00.000',
      status: 'sent',
    );

    setUp(() async {
      dbHelper = DatabaseHelper.test('message_repo_test');
      await dbHelper.deleteDatabaseFile();
      localDataSource = MessageLocalDataSource(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    group('local-only (no remote)', () {
      setUp(() {
        repository = MessageRepositoryImpl(localDataSource: localDataSource);
      });

      test('getMessages returns empty when no local data', () async {
        final result = await repository.getMessages('session-1');
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (messages) => expect(messages, isEmpty),
        );
      });

      test('getMessages returns saved local messages', () async {
        await localDataSource.saveMessage(tMessage);
        final result = await repository.getMessages('session-1');
        result.fold(
          (_) => fail('should be Right'),
          (messages) {
            expect(messages.length, 1);
            expect(messages.first.text, 'Hello');
          },
        );
      });

      test('sendMessage creates a pending message locally', () async {
        final result = await repository.sendMessage('session-1', 'New text');
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (msg) {
            expect(msg.text, 'New text');
            expect(msg.role, 'user');
          },
        );

        final local = await localDataSource.listMessages('session-1');
        expect(local.length, 1);
        expect(local.first.status, 'pending');
      });

      test('watchNewMessages emits local messages', () async {
        await localDataSource.saveMessage(tMessage);
        final result = await repository.watchNewMessages('session-1').first;
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (msg) => expect(msg.text, 'Hello'),
        );
      });

      test('watchMessageStream is empty when no remote', () async {
        final result = await repository.watchMessageStream('session-1').isEmpty;
        expect(result, true);
      });
    });

    group('with remote', () {
      setUp(() {
        mockRemote = MockMessageRemoteDataSource();
        repository = MessageRepositoryImpl(
          localDataSource: localDataSource,
          remoteDataSource: mockRemote,
        );
      });

      test('getMessages returns local and background syncs remote', () async {
        await localDataSource.saveMessage(tMessage);
        final remoteMsg = ChatMessageModel(
          id: tMessage.id,
          sessionId: tMessage.sessionId,
          role: tMessage.role,
          text: 'Remote text',
          timestamp: tMessage.timestamp,
          status: tMessage.status,
        );
        when(() => mockRemote.listMessages(any())).thenAnswer((_) async => [remoteMsg]);

        final result = await repository.getMessages('session-1');
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (messages) => expect(messages.first.text, 'Hello'),
        );

        await Future.delayed(const Duration(milliseconds: 200));
        final localAfter = await localDataSource.listMessages('session-1');
        expect(localAfter.first.text, 'Remote text');
      });

      test('getMessages silently ignores remote failure', () async {
        await localDataSource.saveMessage(tMessage);
        when(() => mockRemote.listMessages(any())).thenThrow(
          const GatewayException('Remote error', code: 'REMOTE_ERR'),
        );

        final result = await repository.getMessages('session-1');
        expect(result.isRight(), true);
      });

      test('sendMessage saves locally then sends remote and overwrites with confirmed', () async {
        final confirmed = ChatMessageModel(
          id: 'msg-confirmed',
          sessionId: tMessage.sessionId,
          role: tMessage.role,
          text: tMessage.text,
          timestamp: tMessage.timestamp,
          status: 'sent',
        );
        when(() => mockRemote.sendMessage(any(), any())).thenAnswer((_) async => confirmed);

        final result = await repository.sendMessage('session-1', 'Hello');
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (msg) => expect(msg.status, MessageStatus.sent),
        );

        final local = await localDataSource.listMessages('session-1');
        expect(local.any((m) => m.id == 'msg-confirmed'), true);
      });

      test('sendMessage marks local message failed when remote fails', () async {
        when(() => mockRemote.sendMessage(any(), any())).thenThrow(Exception('boom'));

        final result = await repository.sendMessage('session-1', 'Hello');
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (msg) => expect(msg.status, MessageStatus.failed),
        );

        final local = await localDataSource.listMessages('session-1');
        expect(local.length, 1);
        expect(local.first.status, 'failed');
      });

      test('watchNewMessages merges local and remote', () async {
        await localDataSource.saveMessage(tMessage);
        when(() => mockRemote.watchNewMessages(any())).thenAnswer(
          (_) => Stream.fromIterable([ChatMessageModel(
            id: tMessage.id,
            sessionId: tMessage.sessionId,
            role: tMessage.role,
            text: 'Remote',
            timestamp: tMessage.timestamp,
            status: tMessage.status,
          )]),
        );

        final results = await repository.watchNewMessages('session-1').take(2).toList();
        expect(results.length, 2);
        expect(results[0].isRight(), true);
        expect(results[1].isRight(), true);
      });

      test('watchMessageStream emits remote chunks', () async {
        when(() => mockRemote.watchMessageEvents()).thenAnswer(
          (_) => Stream.fromIterable([
            {'type': 'message_chunk', 'sessionId': 'session-1', 'chunk': 'chunk1'},
            {'type': 'message_chunk', 'sessionId': 'session-1', 'chunk': 'chunk2'},
          ]),
        );

        final results = await repository.watchMessageStream('session-1').take(2).toList();
        expect(results.length, 2);
        expect(results[0], equals(const Right<Failure, String>('chunk1')));
        expect(results[1], equals(const Right<Failure, String>('chunk2')));
      });

      test('watchMessageStream returns NetworkFailure on unexpected error', () async {
        when(() => mockRemote.watchMessageEvents()).thenAnswer(
          (_) => Stream.error(Exception('boom')),
        );

        final result = await repository.watchMessageStream('session-1').first;
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('should be Left'),
        );
      });
    });
  });
}
