import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/data/datasources/agent_remote_datasource.dart';
import 'package:openclaw_client/src/data/local/database_helper.dart';
import 'package:openclaw_client/src/data/local/agent_local_datasource.dart';
import 'package:openclaw_client/src/data/models/agent_model.dart';
import 'package:openclaw_client/src/data/repositories/agent_repository_impl.dart';
import 'package:openclaw_client/src/domain/entities/agent.dart';

import '../../helpers/sqflite_test_helper.dart';

class MockAgentRemoteDataSource extends Mock implements AgentRemoteDataSource {}

void main() {
  initSqfliteFfi();

  group('AgentRepositoryImpl (local-first)', () {
    late DatabaseHelper dbHelper;
    late AgentLocalDataSource localDataSource;
    late MockAgentRemoteDataSource mockRemote;
    late AgentRepositoryImpl repository;

    final tAgent = AgentModel(
      id: 'agent-1',
      name: 'Alpha',
      description: 'Test agent',
      capabilities: const ['chat'],
      defaultAutonomy: 'suggest',
      isActive: false,
    );

    setUp(() async {
      dbHelper = DatabaseHelper();
      await dbHelper.deleteDatabaseFile();
      localDataSource = AgentLocalDataSource(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    group('local-only (no remote)', () {
      setUp(() {
        repository = AgentRepositoryImpl(localDataSource: localDataSource);
      });

      test('getAgents returns empty when no local data', () async {
        final result = await repository.getAgents();
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (agents) => expect(agents, isEmpty),
        );
      });

      test('getAgents returns saved local agents', () async {
        await localDataSource.saveAgent(tAgent);
        final result = await repository.getAgents();
        result.fold(
          (_) => fail('should be Right'),
          (agents) {
            expect(agents.length, 1);
            expect(agents.first.name, 'Alpha');
          },
        );
      });

      test('getAgentById returns local agent', () async {
        await localDataSource.saveAgent(tAgent);
        final result = await repository.getAgentById('agent-1');
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (agent) => expect(agent.name, 'Alpha'),
        );
      });

      test('getAgentById returns StorageFailure when not found', () async {
        final result = await repository.getAgentById('nonexistent');
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<StorageFailure>()),
          (_) => fail('should be Left'),
        );
      });

      test('updateAutonomy updates local agent', () async {
        await localDataSource.saveAgent(tAgent);
        final result = await repository.updateAutonomy('agent-1', AutonomyLevel.autonomous);
        expect(result, equals(const Right<Failure, void>(null)));

        final updated = await localDataSource.getAgentById('agent-1');
        expect(updated.defaultAutonomy, 'autonomous');
      });

      test('toggleActive updates local agent', () async {
        await localDataSource.saveAgent(tAgent);
        final result = await repository.toggleActive('agent-1', true);
        expect(result, equals(const Right<Failure, void>(null)));

        final updated = await localDataSource.getAgentById('agent-1');
        expect(updated.isActive, true);
      });

      test('watchAgents emits local agents', () async {
        await localDataSource.saveAgent(tAgent);
        final result = await repository.watchAgents().first;
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (agents) => expect(agents.first.id, 'agent-1'),
        );
      });
    });

    group('with remote', () {
      setUp(() {
        mockRemote = MockAgentRemoteDataSource();
        repository = AgentRepositoryImpl(
          localDataSource: localDataSource,
          remoteDataSource: mockRemote,
        );
      });

      test('getAgents returns local and background syncs remote', () async {
        await localDataSource.saveAgent(tAgent);
        final remoteAgent = AgentModel(
          id: tAgent.id,
          name: 'Remote Alpha',
          description: tAgent.description,
          capabilities: tAgent.capabilities,
          defaultAutonomy: tAgent.defaultAutonomy,
          isActive: tAgent.isActive,
        );
        when(() => mockRemote.getAgents()).thenAnswer((_) async => [remoteAgent]);

        final result = await repository.getAgents();
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('should be Right'),
          (agents) => expect(agents.first.name, 'Alpha'),
        );

        await Future.delayed(const Duration(milliseconds: 200));
        final localAfter = await localDataSource.getAgentById('agent-1');
        expect(localAfter.name, 'Remote Alpha');
      });

      test('getAgents silently ignores remote failure', () async {
        await localDataSource.saveAgent(tAgent);
        when(() => mockRemote.getAgents()).thenThrow(
          const GatewayException('Remote error', code: 'REMOTE_ERR'),
        );

        final result = await repository.getAgents();
        expect(result.isRight(), true);
      });

      test('getAgentById returns local and background refreshes', () async {
        await localDataSource.saveAgent(tAgent);
        final remoteAgent = AgentModel(
          id: tAgent.id,
          name: tAgent.name,
          description: 'Remote desc',
          capabilities: tAgent.capabilities,
          defaultAutonomy: tAgent.defaultAutonomy,
          isActive: tAgent.isActive,
        );
        when(() => mockRemote.getAgentById(any())).thenAnswer((_) async => remoteAgent);

        final result = await repository.getAgentById('agent-1');
        expect(result.isRight(), true);

        await Future.delayed(const Duration(milliseconds: 200));
        final localAfter = await localDataSource.getAgentById('agent-1');
        expect(localAfter.description, 'Remote desc');
      });

      test('updateAutonomy local-first then syncs to remote', () async {
        await localDataSource.saveAgent(tAgent);
        when(() => mockRemote.updateAutonomy(any(), any())).thenAnswer((_) async {});

        final result = await repository.updateAutonomy('agent-1', AutonomyLevel.confirm);
        expect(result, equals(const Right<Failure, void>(null)));
        verify(() => mockRemote.updateAutonomy('agent-1', AutonomyLevel.confirm)).called(1);
      });

      test('updateAutonomy returns success even when remote fails', () async {
        await localDataSource.saveAgent(tAgent);
        when(() => mockRemote.updateAutonomy(any(), any())).thenThrow(Exception('boom'));

        final result = await repository.updateAutonomy('agent-1', AutonomyLevel.confirm);
        expect(result, equals(const Right<Failure, void>(null)));
      });

      test('toggleActive local-first then syncs to remote', () async {
        await localDataSource.saveAgent(tAgent);
        when(() => mockRemote.toggleActive(any(), any())).thenAnswer((_) async {});

        final result = await repository.toggleActive('agent-1', true);
        expect(result, equals(const Right<Failure, void>(null)));
        verify(() => mockRemote.toggleActive('agent-1', true)).called(1);
      });

      test('watchAgents merges local and remote streams', () async {
        await localDataSource.saveAgent(tAgent);
        when(() => mockRemote.watchAgents()).thenAnswer(
          (_) => Stream.fromIterable([
            [AgentModel(
              id: tAgent.id,
              name: 'Remote Stream',
              description: tAgent.description,
              capabilities: tAgent.capabilities,
              defaultAutonomy: tAgent.defaultAutonomy,
              isActive: tAgent.isActive,
            )],
          ]),
        );

        final results = await repository.watchAgents().take(2).toList();
        expect(results.length, 2);
        expect(results[0].isRight(), true);
        expect(results[1].isRight(), true);
      });

      test('watchAgents emits NetworkFailure on ConnectionTimeoutException', () async {
        when(() => mockRemote.watchAgents()).thenAnswer(
          (_) => Stream.error(const ConnectionTimeoutException()),
        );

        final result = await repository.watchAgents().first;
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('should be Left'),
        );
      });

      test('watchAgents emits GatewayFailure on GatewayException', () async {
        when(() => mockRemote.watchAgents()).thenAnswer(
          (_) => Stream.error(
            const GatewayException('GW err', code: 'GW'),
          ),
        );

        final result = await repository.watchAgents().first;
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<GatewayFailure>()),
          (_) => fail('should be Left'),
        );
      });
    });
  });
}
