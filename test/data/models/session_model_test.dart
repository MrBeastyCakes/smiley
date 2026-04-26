import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/data/models/session_model.dart';
import 'package:openclaw_client/src/domain/entities/session.dart';

void main() {
  group('SessionModel', () {
    final now = DateTime(2026, 4, 25, 12, 0, 0);
    final nowIso = now.toIso8601String();

    final testJson = {
      'id': 'session-1',
      'title': 'Hello World',
      'agentId': 'agent-1',
      'createdAt': nowIso,
      'updatedAt': nowIso,
      'messageCount': 5,
      'isPinned': true,
      'isArchived': false,
      'lastMessagePreview': 'Last msg',
    };

    final testModel = SessionModel(
      id: 'session-1',
      title: 'Hello World',
      agentId: 'agent-1',
      createdAt: nowIso,
      updatedAt: nowIso,
      messageCount: 5,
      isPinned: true,
      isArchived: false,
      lastMessagePreview: 'Last msg',
    );

    test('fromJson parses all fields correctly', () {
      final model = SessionModel.fromJson(testJson);
      expect(model.id, 'session-1');
      expect(model.title, 'Hello World');
      expect(model.agentId, 'agent-1');
      expect(model.createdAt, nowIso);
      expect(model.updatedAt, nowIso);
      expect(model.messageCount, 5);
      expect(model.isPinned, true);
      expect(model.isArchived, false);
      expect(model.lastMessagePreview, 'Last msg');
    });

    test('toJson serializes all fields correctly', () {
      final json = testModel.toJson();
      expect(json, testJson);
    });

    test('fromJson/toJson round-trip preserves data', () {
      final model = SessionModel.fromJson(testJson);
      final json = model.toJson();
      expect(json, testJson);
    });

    test('toEntity/fromEntity round-trip preserves data', () {
      final entity = testModel.toEntity();
      final back = SessionModel.fromEntity(entity);
      expect(back.id, testModel.id);
      expect(back.title, testModel.title);
      expect(back.agentId, testModel.agentId);
      expect(back.createdAt, testModel.createdAt);
      expect(back.updatedAt, testModel.updatedAt);
      expect(back.messageCount, testModel.messageCount);
      expect(back.isPinned, testModel.isPinned);
      expect(back.isArchived, testModel.isArchived);
      expect(back.lastMessagePreview, testModel.lastMessagePreview);
    });

    test('toEntity converts ISO8601 strings to DateTime', () {
      final entity = testModel.toEntity();
      expect(entity.createdAt, now);
      expect(entity.updatedAt, now);
    });

    test('fromEntity converts DateTime to ISO8601 strings', () {
      final entity = Session(
        id: 's',
        title: 't',
        createdAt: now,
        updatedAt: now,
      );
      final model = SessionModel.fromEntity(entity);
      expect(model.createdAt, nowIso);
      expect(model.updatedAt, nowIso);
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'session-2',
        'title': 'Empty',
        'createdAt': nowIso,
        'updatedAt': nowIso,
      };
      final model = SessionModel.fromJson(json);
      expect(model.agentId, isNull);
      expect(model.messageCount, 0);
      expect(model.isPinned, false);
      expect(model.isArchived, false);
      expect(model.lastMessagePreview, isNull);
    });

    test('default values are correct', () {
      final model = SessionModel(
        id: 's',
        title: 't',
        createdAt: nowIso,
        updatedAt: nowIso,
      );
      expect(model.messageCount, 0);
      expect(model.isPinned, false);
      expect(model.isArchived, false);
    });
  });
}
