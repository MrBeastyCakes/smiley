import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/data/local/database_helper.dart';
import 'package:openclaw_client/src/data/local/message_local_datasource.dart';
import 'package:openclaw_client/src/data/models/chat_message_model.dart';

import '../../helpers/sqflite_test_helper.dart';

void main() {
  initSqfliteFfi();

  group('MessageLocalDataSource', () {
    late DatabaseHelper dbHelper;
    late MessageLocalDataSource dataSource;

    final tMessage = ChatMessageModel(
      id: 'msg-1',
      sessionId: 'session-1',
      role: 'user',
      text: 'Hello',
      timestamp: '2026-04-25T10:00:00.000',
      status: 'sent',
    );

    final tMessage2 = ChatMessageModel(
      id: 'msg-2',
      sessionId: 'session-1',
      role: 'assistant',
      text: 'Hi there',
      timestamp: '2026-04-25T10:01:00.000',
      status: 'sent',
    );

    final tMessageOther = ChatMessageModel(
      id: 'msg-3',
      sessionId: 'session-2',
      role: 'user',
      text: 'Other session',
      timestamp: '2026-04-25T10:02:00.000',
      status: 'sent',
    );

    setUp(() async {
      dbHelper = DatabaseHelper();
      await dbHelper.deleteDatabaseFile();
      dataSource = MessageLocalDataSource(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    group('saveMessage / listMessages', () {
      test('should save and retrieve messages for a session', () async {
        await dataSource.saveMessage(tMessage);
        await dataSource.saveMessage(tMessage2);
        final result = await dataSource.listMessages('session-1');
        expect(result.length, 2);
        expect(result[0].id, 'msg-1');
        expect(result[1].id, 'msg-2');
      });

      test('should return only messages for the requested session', () async {
        await dataSource.saveMessage(tMessage);
        await dataSource.saveMessage(tMessageOther);
        final result = await dataSource.listMessages('session-2');
        expect(result.length, 1);
        expect(result.first.text, 'Other session');
      });
    });

    group('sendMessage', () {
      test('should create a pending message locally', () async {
        final result = await dataSource.sendMessage('session-1', 'New message');
        expect(result.sessionId, 'session-1');
        expect(result.text, 'New message');
        expect(result.role, 'user');
        expect(result.status, 'pending');

        final list = await dataSource.listMessages('session-1');
        expect(list.length, 1);
        expect(list.first.status, 'pending');
      });
    });

    group('updateMessage', () {
      test('should update message text and status', () async {
        await dataSource.saveMessage(tMessage);
        final updated = ChatMessageModel(
          id: tMessage.id,
          sessionId: tMessage.sessionId,
          role: tMessage.role,
          text: 'Updated',
          timestamp: tMessage.timestamp,
          status: 'sent',
        );
        await dataSource.updateMessage(updated);
        final result = await dataSource.listMessages('session-1');
        expect(result.first.text, 'Updated');
        expect(result.first.status, 'sent');
      });
    });

    group('deleteMessage', () {
      test('should remove a message', () async {
        await dataSource.saveMessage(tMessage);
        await dataSource.deleteMessage('msg-1');
        final result = await dataSource.listMessages('session-1');
        expect(result, isEmpty);
      });
    });

    group('deleteMessagesForSession', () {
      test('should remove all messages for a session', () async {
        await dataSource.saveMessage(tMessage);
        await dataSource.saveMessage(tMessage2);
        await dataSource.deleteMessagesForSession('session-1');
        expect(await dataSource.listMessages('session-1'), isEmpty);
      });
    });

    group('clearAll', () {
      test('should remove all messages', () async {
        await dataSource.saveMessage(tMessage);
        await dataSource.saveMessage(tMessageOther);
        await dataSource.clearAll();
        expect(await dataSource.listMessages('session-1'), isEmpty);
        expect(await dataSource.listMessages('session-2'), isEmpty);
      });
    });

    group('saveMessages (batch)', () {
      test('should save multiple messages in a batch', () async {
        await dataSource.saveMessages([tMessage, tMessage2]);
        final result = await dataSource.listMessages('session-1');
        expect(result.length, 2);
      });
    });

    group('getUnsyncedMessages / markSynced', () {
      test('should track unsynced messages', () async {
        await dataSource.saveMessage(tMessage);
        final unsynced = await dataSource.getUnsyncedMessages();
        expect(unsynced.length, 1);

        await dataSource.markSynced('msg-1');
        final afterSync = await dataSource.getUnsyncedMessages();
        expect(afterSync, isEmpty);
      });
    });

    group('complex message with attachments / thinking / metadata', () {
      test('should round-trip all nested fields', () async {
        final complex = ChatMessageModel(
          id: 'msg-complex',
          sessionId: 'session-1',
          role: 'assistant',
          text: 'Here is my answer',
          timestamp: '2026-04-25T10:00:00.000',
          status: 'sent',
          thinking: const ThinkingBlockModel(
            content: 'Thinking...',
            isExpanded: true,
            startedAt: '2026-04-25T09:59:00.000',
            completedAt: '2026-04-25T10:00:00.000',
          ),
          actionCards: const [
            ActionCardModel(
              id: 'card-1',
              title: 'Card',
              actionType: 'navigate',
              buttons: [
                ActionButtonModel(id: 'btn-1', label: 'Go', action: 'go'),
              ],
            ),
          ],
          attachments: const [
            MessageAttachmentModel(
              id: 'att-1',
              type: 'image',
              name: 'pic.png',
              uri: 'file://pic.png',
              sizeBytes: 1024,
              mimeType: 'image/png',
            ),
          ],
          metadata: const MessageMetadataModel(
            tokenCount: 42,
            latencyMs: 250,
            modelName: 'gpt-4',
            citations: ['doc1'],
          ),
        );

        await dataSource.saveMessage(complex);
        final result = await dataSource.listMessages('session-1');
        expect(result.length, 1);
        final r = result.first;
        expect(r.thinking!.content, 'Thinking...');
        expect(r.actionCards.length, 1);
        expect(r.actionCards.first.title, 'Card');
        expect(r.attachments.length, 1);
        expect(r.attachments.first.name, 'pic.png');
        expect(r.metadata!.tokenCount, 42);
        expect(r.metadata!.modelName, 'gpt-4');
      });
    });
  });
}
