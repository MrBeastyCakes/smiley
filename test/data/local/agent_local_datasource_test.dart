import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/data/local/database_helper.dart';
import 'package:openclaw_client/src/data/local/agent_local_datasource.dart';
import 'package:openclaw_client/src/data/models/agent_model.dart';
import 'package:openclaw_client/src/domain/entities/agent.dart';

import '../../helpers/sqflite_test_helper.dart';

void main() {
  initSqfliteFfi();

  group('AgentLocalDataSource', () {
    late DatabaseHelper dbHelper;
    late AgentLocalDataSource dataSource;

    final tAgent1 = AgentModel(
      id: 'agent-1',
      name: 'Alpha',
      avatarUrl: 'https://example.com/alpha.png',
      description: 'First agent',
      capabilities: const ['chat', 'voice'],
      defaultAutonomy: 'confirm',
      isActive: true,
      lastActiveAt: '2026-04-25T10:00:00.000',
    );

    final tAgent2 = AgentModel(
      id: 'agent-2',
      name: 'Beta',
      description: 'Second agent',
      capabilities: const ['chat'],
      defaultAutonomy: 'suggest',
      isActive: false,
    );

    setUp(() async {
      dbHelper = DatabaseHelper();
      await dbHelper.deleteDatabaseFile();
      dataSource = AgentLocalDataSource(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    group('saveAgent / getAgentById', () {
      test('should save and retrieve an agent', () async {
        await dataSource.saveAgent(tAgent1);
        final result = await dataSource.getAgentById('agent-1');
        expect(result.id, 'agent-1');
        expect(result.name, 'Alpha');
        expect(result.isActive, true);
        expect(result.capabilities, ['chat', 'voice']);
      });

      test('should update existing agent (upsert)', () async {
        await dataSource.saveAgent(tAgent1);
        final updated = AgentModel(
          id: tAgent1.id,
          name: 'Alpha Prime',
          avatarUrl: tAgent1.avatarUrl,
          description: tAgent1.description,
          capabilities: tAgent1.capabilities,
          defaultAutonomy: tAgent1.defaultAutonomy,
          isActive: tAgent1.isActive,
          lastActiveAt: tAgent1.lastActiveAt,
        );
        await dataSource.saveAgent(updated);
        final result = await dataSource.getAgentById('agent-1');
        expect(result.name, 'Alpha Prime');
      });

      test('should throw StorageException when agent not found', () async {
        expect(
          () => dataSource.getAgentById('nonexistent'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('saveAgents / getAgents', () {
      test('should save multiple agents and list them ordered by name', () async {
        await dataSource.saveAgents([tAgent1, tAgent2]);
        final result = await dataSource.getAgents();
        expect(result.length, 2);
        expect(result[0].name, 'Alpha');
        expect(result[1].name, 'Beta');
      });
    });

    group('updateAutonomy', () {
      test('should change autonomy level', () async {
        await dataSource.saveAgent(tAgent1);
        await dataSource.updateAutonomy('agent-1', AutonomyLevel.autonomous);
        final result = await dataSource.getAgentById('agent-1');
        expect(result.defaultAutonomy, 'autonomous');
      });

      test('should throw StorageException for nonexistent agent', () async {
        expect(
          () => dataSource.updateAutonomy('nonexistent', AutonomyLevel.observe),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('toggleActive', () {
      test('should toggle active state', () async {
        await dataSource.saveAgent(tAgent1);
        await dataSource.toggleActive('agent-1', false);
        final result = await dataSource.getAgentById('agent-1');
        expect(result.isActive, false);
      });

      test('should throw StorageException for nonexistent agent', () async {
        expect(
          () => dataSource.toggleActive('nonexistent', true),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('deleteAgent', () {
      test('should remove an agent', () async {
        await dataSource.saveAgent(tAgent1);
        await dataSource.deleteAgent('agent-1');
        expect(
          () => dataSource.getAgentById('agent-1'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('clearAll', () {
      test('should remove all agents', () async {
        await dataSource.saveAgents([tAgent1, tAgent2]);
        await dataSource.clearAll();
        final result = await dataSource.getAgents();
        expect(result, isEmpty);
      });
    });

    group('getUnsyncedAgents / markSynced', () {
      test('should track unsynced agents', () async {
        await dataSource.saveAgent(tAgent1);
        final unsynced = await dataSource.getUnsyncedAgents();
        expect(unsynced.length, 1);

        await dataSource.markSynced('agent-1');
        final afterSync = await dataSource.getUnsyncedAgents();
        expect(afterSync, isEmpty);
      });
    });
  });
}
