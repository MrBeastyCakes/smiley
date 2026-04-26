import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/data/models/chat_message_model.dart';
import 'package:openclaw_client/src/domain/entities/chat_message.dart';

void main() {
  group('ChatMessageModel', () {
    final now = DateTime(2026, 4, 25, 12, 0, 0);
    final nowIso = now.toIso8601String();

    final testJson = {
      'id': 'msg-1',
      'sessionId': 'session-1',
      'role': 'assistant',
      'text': 'Hello there',
      'timestamp': nowIso,
      'status': 'sent',
      'editedAt': nowIso,
      'agentId': 'agent-1',
      'thinking': {
        'content': 'Thinking...',
        'isExpanded': true,
        'startedAt': nowIso,
        'completedAt': nowIso,
      },
      'actionCards': [
        {
          'id': 'card-1',
          'title': 'Action',
          'description': 'Do something',
          'actionType': 'tool_call',
          'buttons': [
            {
              'id': 'btn-1',
              'label': 'Confirm',
              'action': 'confirm',
              'isPrimary': true,
            },
          ],
          'rationale': 'Because',
          'confidence': 0.95,
        },
      ],
      'attachments': [
        {
          'id': 'att-1',
          'type': 'image',
          'name': 'photo.png',
          'uri': 'file://photo.png',
          'sizeBytes': 1024,
          'mimeType': 'image/png',
        },
      ],
      'metadata': {
        'tokenCount': 42,
        'latencyMs': 150,
        'modelName': 'gpt-4',
        'citations': ['ref-1', 'ref-2'],
      },
    };

    final testModel = ChatMessageModel(
      id: 'msg-1',
      sessionId: 'session-1',
      role: 'assistant',
      text: 'Hello there',
      timestamp: nowIso,
      status: 'sent',
      editedAt: nowIso,
      agentId: 'agent-1',
      thinking: ThinkingBlockModel(
        content: 'Thinking...',
        isExpanded: true,
        startedAt: nowIso,
        completedAt: nowIso,
      ),
      actionCards: [
        ActionCardModel(
          id: 'card-1',
          title: 'Action',
          description: 'Do something',
          actionType: 'tool_call',
          buttons: [
            ActionButtonModel(
              id: 'btn-1',
              label: 'Confirm',
              action: 'confirm',
              isPrimary: true,
            ),
          ],
          rationale: 'Because',
          confidence: 0.95,
        ),
      ],
      attachments: [
        MessageAttachmentModel(
          id: 'att-1',
          type: 'image',
          name: 'photo.png',
          uri: 'file://photo.png',
          sizeBytes: 1024,
          mimeType: 'image/png',
        ),
      ],
      metadata: MessageMetadataModel(
        tokenCount: 42,
        latencyMs: 150,
        modelName: 'gpt-4',
        citations: ['ref-1', 'ref-2'],
      ),
    );

    test('fromJson parses all fields correctly', () {
      final model = ChatMessageModel.fromJson(testJson);
      expect(model.id, 'msg-1');
      expect(model.sessionId, 'session-1');
      expect(model.role, 'assistant');
      expect(model.text, 'Hello there');
      expect(model.timestamp, nowIso);
      expect(model.status, 'sent');
      expect(model.editedAt, nowIso);
      expect(model.agentId, 'agent-1');
      expect(model.thinking, isNotNull);
      expect(model.thinking!.content, 'Thinking...');
      expect(model.thinking!.isExpanded, true);
      expect(model.actionCards.length, 1);
      expect(model.actionCards[0].title, 'Action');
      expect(model.actionCards[0].buttons.length, 1);
      expect(model.actionCards[0].buttons[0].isPrimary, true);
      expect(model.attachments.length, 1);
      expect(model.attachments[0].name, 'photo.png');
      expect(model.metadata, isNotNull);
      expect(model.metadata!.tokenCount, 42);
      expect(model.metadata!.latencyMs, 150);
      expect(model.metadata!.citations, ['ref-1', 'ref-2']);
    });

    test('toJson serializes all fields correctly', () {
      final json = testModel.toJson();
      expect(json, testJson);
    });

    test('fromJson/toJson round-trip preserves data', () {
      final model = ChatMessageModel.fromJson(testJson);
      final json = model.toJson();
      expect(json, testJson);
    });

    test('toEntity/fromEntity round-trip preserves data', () {
      final entity = testModel.toEntity();
      final back = ChatMessageModel.fromEntity(entity);
      expect(back.id, testModel.id);
      expect(back.sessionId, testModel.sessionId);
      expect(back.role, testModel.role);
      expect(back.text, testModel.text);
      expect(back.timestamp, testModel.timestamp);
      expect(back.status, testModel.status);
      expect(back.editedAt, testModel.editedAt);
      expect(back.agentId, testModel.agentId);
      expect(back.thinking!.content, testModel.thinking!.content);
      expect(back.actionCards.length, testModel.actionCards.length);
      expect(back.attachments.length, testModel.attachments.length);
      expect(back.metadata!.tokenCount, testModel.metadata!.tokenCount);
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'msg-2',
        'sessionId': 'session-1',
        'role': 'user',
        'text': 'Hi',
        'timestamp': nowIso,
      };
      final model = ChatMessageModel.fromJson(json);
      expect(model.status, 'sent');
      expect(model.editedAt, isNull);
      expect(model.agentId, isNull);
      expect(model.thinking, isNull);
      expect(model.actionCards, isEmpty);
      expect(model.attachments, isEmpty);
      expect(model.metadata, isNull);
    });

    test('default values are correct', () {
      final model = ChatMessageModel(
        id: 'm',
        sessionId: 's',
        role: 'user',
        text: 't',
        timestamp: nowIso,
      );
      expect(model.status, 'sent');
      expect(model.actionCards, isEmpty);
      expect(model.attachments, isEmpty);
    });

    test('invalid status falls back to sent', () {
      final model = ChatMessageModel.fromJson({
        'id': 'm',
        'sessionId': 's',
        'role': 'user',
        'text': 't',
        'timestamp': nowIso,
        'status': 'nonexistent',
      });
      final entity = model.toEntity();
      expect(entity.status, MessageStatus.sent);
    });

    test('ThinkingBlockModel fromJson/toJson round-trip', () {
      final json = {
        'content': 'Thinking...',
        'isExpanded': true,
        'startedAt': nowIso,
        'completedAt': nowIso,
      };
      final model = ThinkingBlockModel.fromJson(json);
      expect(model.toJson(), json);
    });

    test('ActionCardModel fromJson/toJson round-trip', () {
      final json = {
        'id': 'card-1',
        'title': 'Action',
        'description': 'Do something',
        'actionType': 'tool_call',
        'buttons': [
          {
            'id': 'btn-1',
            'label': 'Confirm',
            'action': 'confirm',
            'isPrimary': true,
          },
        ],
        'rationale': 'Because',
        'confidence': 0.95,
      };
      final model = ActionCardModel.fromJson(json);
      expect(model.toJson(), json);
    });

    test('ActionButtonModel fromJson/toJson round-trip', () {
      final json = {
        'id': 'btn-1',
        'label': 'Confirm',
        'action': 'confirm',
        'isPrimary': true,
      };
      final model = ActionButtonModel.fromJson(json);
      expect(model.toJson(), json);
    });

    test('MessageAttachmentModel fromJson/toJson round-trip', () {
      final json = {
        'id': 'att-1',
        'type': 'image',
        'name': 'photo.png',
        'uri': 'file://photo.png',
        'sizeBytes': 1024,
        'mimeType': 'image/png',
      };
      final model = MessageAttachmentModel.fromJson(json);
      expect(model.toJson(), json);
    });

    test('MessageMetadataModel fromJson/toJson round-trip', () {
      final json = {
        'tokenCount': 42,
        'latencyMs': 150,
        'modelName': 'gpt-4',
        'citations': ['ref-1', 'ref-2'],
      };
      final model = MessageMetadataModel.fromJson(json);
      expect(model.toJson(), json);
    });

    test('MessageMetadataModel toEntity/fromEntity with latency', () {
      const model = MessageMetadataModel(
        tokenCount: 10,
        latencyMs: 500,
        modelName: 'test',
        citations: ['a'],
      );
      final entity = model.toEntity();
      expect(entity.tokenCount, 10);
      expect(entity.latency, const Duration(milliseconds: 500));
      expect(entity.modelName, 'test');
      expect(entity.citations, ['a']);
      final back = MessageMetadataModel.fromEntity(entity);
      expect(back.latencyMs, 500);
    });

    test('MessageMetadataModel handles null latency', () {
      const model = MessageMetadataModel();
      final entity = model.toEntity();
      expect(entity.latency, isNull);
      final back = MessageMetadataModel.fromEntity(entity);
      expect(back.latencyMs, isNull);
    });
  });
}
