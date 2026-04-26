import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/domain/entities/agent.dart';

void main() {
  group('Agent', () {
    const agent = Agent(id: 'a1', name: 'DevBot', description: 'A coding assistant', capabilities: ['code', 'review'], defaultAutonomy: AutonomyLevel.suggest, isActive: true);

    test('properties are correct', () {
      expect(agent.id, 'a1');
      expect(agent.name, 'DevBot');
      expect(agent.description, 'A coding assistant');
      expect(agent.capabilities, ['code', 'review']);
      expect(agent.defaultAutonomy, AutonomyLevel.suggest);
      expect(agent.isActive, true);
    });

    test('copyWith updates specified fields', () {
      final updated = agent.copyWith(name: 'TestBot', isActive: false);
      expect(updated.name, 'TestBot');
      expect(updated.isActive, false);
      expect(updated.id, agent.id);
    });

    test('supports value equality', () {
      const a2 = Agent(id: 'a1', name: 'DevBot', description: 'A coding assistant', capabilities: ['code', 'review'], defaultAutonomy: AutonomyLevel.suggest, isActive: true);
      expect(agent, a2);
    });

    test('different ids are not equal', () {
      const a2 = Agent(id: 'a2', name: 'DevBot');
      expect(agent, isNot(a2));
    });
  });

  group('AutonomyLevel', () {
    test('labels', () {
      expect(AutonomyLevel.observe.label, 'Observe');
      expect(AutonomyLevel.suggest.label, 'Suggest');
      expect(AutonomyLevel.confirm.label, 'Confirm');
      expect(AutonomyLevel.autonomous.label, 'Autonomous');
    });

    test('canAct', () {
      expect(AutonomyLevel.observe.canAct, false);
      expect(AutonomyLevel.suggest.canAct, true);
      expect(AutonomyLevel.confirm.canAct, true);
      expect(AutonomyLevel.autonomous.canAct, true);
    });

    test('requiresConfirmation', () {
      expect(AutonomyLevel.observe.requiresConfirmation, false);
      expect(AutonomyLevel.suggest.requiresConfirmation, false);
      expect(AutonomyLevel.confirm.requiresConfirmation, true);
      expect(AutonomyLevel.autonomous.requiresConfirmation, false);
    });

    test('isFullyAutonomous', () {
      expect(AutonomyLevel.autonomous.isFullyAutonomous, true);
      expect(AutonomyLevel.confirm.isFullyAutonomous, false);
    });
  });
}
