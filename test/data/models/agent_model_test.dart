import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/data/models/agent_model.dart';
import 'package:openclaw_client/src/domain/entities/agent.dart';

void main() {
  group('AgentModel', () {
    const testAgentModel = AgentModel(
      id: 'agent-1',
      name: 'Rosalina',
      avatarUrl: 'https://example.com/avatar.png',
      description: 'Queen of the Galaxy',
      capabilities: ['chat', 'voice'],
      defaultAutonomy: 'suggest',
      isActive: true,
      lastActiveAt: '2026-04-25T12:00:00.000',
    );

    final testJson = {
      'id': 'agent-1',
      'name': 'Rosalina',
      'avatarUrl': 'https://example.com/avatar.png',
      'description': 'Queen of the Galaxy',
      'capabilities': ['chat', 'voice'],
      'defaultAutonomy': 'suggest',
      'isActive': true,
      'lastActiveAt': '2026-04-25T12:00:00.000',
    };

    test('fromJson parses all fields correctly', () {
      final model = AgentModel.fromJson(testJson);
      expect(model.id, 'agent-1');
      expect(model.name, 'Rosalina');
      expect(model.avatarUrl, 'https://example.com/avatar.png');
      expect(model.description, 'Queen of the Galaxy');
      expect(model.capabilities, ['chat', 'voice']);
      expect(model.defaultAutonomy, 'suggest');
      expect(model.isActive, true);
      expect(model.lastActiveAt, '2026-04-25T12:00:00.000');
    });

    test('toJson serializes all fields correctly', () {
      final json = testAgentModel.toJson();
      expect(json, testJson);
    });

    test('fromJson/toJson round-trip preserves data', () {
      final model = AgentModel.fromJson(testJson);
      final json = model.toJson();
      expect(json, testJson);
    });

    test('toEntity/fromEntity round-trip preserves data', () {
      final entity = testAgentModel.toEntity();
      final back = AgentModel.fromEntity(entity);
      expect(back.id, testAgentModel.id);
      expect(back.name, testAgentModel.name);
      expect(back.avatarUrl, testAgentModel.avatarUrl);
      expect(back.description, testAgentModel.description);
      expect(back.capabilities, testAgentModel.capabilities);
      expect(back.defaultAutonomy, testAgentModel.defaultAutonomy);
      expect(back.isActive, testAgentModel.isActive);
      expect(back.lastActiveAt, testAgentModel.lastActiveAt);
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'agent-2',
        'name': 'Bare Agent',
      };
      final model = AgentModel.fromJson(json);
      expect(model.avatarUrl, isNull);
      expect(model.description, isNull);
      expect(model.capabilities, isEmpty);
      expect(model.defaultAutonomy, 'suggest');
      expect(model.isActive, false);
      expect(model.lastActiveAt, isNull);
    });

    test('toEntity converts lastActiveAt to DateTime', () {
      final entity = testAgentModel.toEntity();
      expect(entity.lastActiveAt, DateTime.parse('2026-04-25T12:00:00.000'));
    });

    test('toEntity with null lastActiveAt', () {
      const model = AgentModel(id: 'a', name: 'n');
      final entity = model.toEntity();
      expect(entity.lastActiveAt, isNull);
    });

    test('fromEntity with null lastActiveAt', () {
      final entity = Agent(
        id: 'a',
        name: 'n',
        lastActiveAt: null,
      );
      final model = AgentModel.fromEntity(entity);
      expect(model.lastActiveAt, isNull);
    });

    test('default values are correct', () {
      const model = AgentModel(id: 'a', name: 'n');
      expect(model.capabilities, isEmpty);
      expect(model.defaultAutonomy, 'suggest');
      expect(model.isActive, false);
    });

    test('invalid autonomy level falls back to suggest', () {
      final model = AgentModel.fromJson({
        'id': 'a',
        'name': 'n',
        'defaultAutonomy': 'nonexistent',
      });
      final entity = model.toEntity();
      expect(entity.defaultAutonomy, AutonomyLevel.suggest);
    });
  });
}
