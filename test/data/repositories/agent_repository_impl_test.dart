import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/data/datasources/agent_remote_datasource.dart';
import 'package:openclaw_client/src/data/models/agent_model.dart';
import 'package:openclaw_client/src/data/repositories/agent_repository_impl.dart';
import 'package:openclaw_client/src/domain/entities/agent.dart';

class MockAgentRemoteDataSource extends Mock implements AgentRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(AutonomyLevel.suggest);
  });

  late MockAgentRemoteDataSource mockDataSource;
  late AgentRepositoryImpl repository;

  final tAgentModel = AgentModel(
    id: 'agent-1',
    name: 'Test Agent',
    defaultAutonomy: 'suggest',
    isActive: true,
  );

  final tAgent = Agent(
    id: 'agent-1',
    name: 'Test Agent',
    defaultAutonomy: AutonomyLevel.suggest,
    isActive: true,
  );

  setUp(() {
    mockDataSource = MockAgentRemoteDataSource();
    repository = AgentRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('getAgents', () {
    test('should return Right(List<Agent>) on success', () async {
      when(() => mockDataSource.getAgents()).thenAnswer((_) async => [tAgentModel]);

      final result = await repository.getAgents();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should be Right'),
        (agents) {
          expect(agents.length, 1);
          expect(agents.first, equals(tAgent));
        },
      );
      verify(() => mockDataSource.getAgents()).called(1);
    });

    test('should return Left(GatewayFailure) on GatewayException', () async {
      when(() => mockDataSource.getAgents()).thenThrow(
        const GatewayException('gateway error', code: 'ERR'),
      );

      final result = await repository.getAgents();

      expect(
        result,
        equals(const Left<Failure, List<Agent>>(GatewayFailure('gateway error', code: 'ERR'))),
      );
      verify(() => mockDataSource.getAgents()).called(1);
    });

    test('should return Left(NetworkFailure) on ConnectionTimeoutException', () async {
      when(() => mockDataSource.getAgents()).thenThrow(const ConnectionTimeoutException());

      final result = await repository.getAgents();

      expect(
        result,
        equals(const Left<Failure, List<Agent>>(NetworkFailure('Connection timed out', code: 'TIMEOUT'))),
      );
      verify(() => mockDataSource.getAgents()).called(1);
    });

    test('should return Left(UnexpectedFailure) on unexpected error', () async {
      when(() => mockDataSource.getAgents()).thenThrow(Exception('boom'));

      final result = await repository.getAgents();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'Unexpected error while getting agents'),
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.getAgents()).called(1);
    });
  });

  group('getAgentById', () {
    test('should return Right(Agent) on success', () async {
      when(() => mockDataSource.getAgentById(any())).thenAnswer((_) async => tAgentModel);

      final result = await repository.getAgentById('agent-1');

      expect(result, equals(Right<Failure, Agent>(tAgent)));
      verify(() => mockDataSource.getAgentById('agent-1')).called(1);
    });

    test('should return Left(GatewayFailure) on GatewayException', () async {
      when(() => mockDataSource.getAgentById(any())).thenThrow(
        const GatewayException('not found', code: 'NOT_FOUND'),
      );

      final result = await repository.getAgentById('agent-1');

      expect(
        result,
        equals(const Left<Failure, Agent>(GatewayFailure('not found', code: 'NOT_FOUND'))),
      );
      verify(() => mockDataSource.getAgentById('agent-1')).called(1);
    });

    test('should return Left(NetworkFailure) on ConnectionTimeoutException', () async {
      when(() => mockDataSource.getAgentById(any())).thenThrow(const ConnectionTimeoutException());

      final result = await repository.getAgentById('agent-1');

      expect(
        result,
        equals(const Left<Failure, Agent>(NetworkFailure('Connection timed out', code: 'TIMEOUT'))),
      );
      verify(() => mockDataSource.getAgentById('agent-1')).called(1);
    });

    test('should return Left(UnexpectedFailure) on unexpected error', () async {
      when(() => mockDataSource.getAgentById(any())).thenThrow(Exception('boom'));

      final result = await repository.getAgentById('agent-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'Unexpected error while getting agent'),
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.getAgentById('agent-1')).called(1);
    });
  });

  group('updateAutonomy', () {
    test('should return Right(null) on success', () async {
      when(() => mockDataSource.updateAutonomy(any(), any())).thenAnswer((_) async {});

      final result = await repository.updateAutonomy('agent-1', AutonomyLevel.autonomous);

      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => mockDataSource.updateAutonomy('agent-1', AutonomyLevel.autonomous)).called(1);
    });

    test('should return Left(GatewayFailure) on GatewayException', () async {
      when(() => mockDataSource.updateAutonomy(any(), any())).thenThrow(
        const GatewayException('rejected', code: 'REJECTED'),
      );

      final result = await repository.updateAutonomy('agent-1', AutonomyLevel.confirm);

      expect(
        result,
        equals(const Left<Failure, void>(GatewayFailure('rejected', code: 'REJECTED'))),
      );
      verify(() => mockDataSource.updateAutonomy('agent-1', AutonomyLevel.confirm)).called(1);
    });

    test('should return Left(NetworkFailure) on ConnectionTimeoutException', () async {
      when(() => mockDataSource.updateAutonomy(any(), any())).thenThrow(const ConnectionTimeoutException());

      final result = await repository.updateAutonomy('agent-1', AutonomyLevel.observe);

      expect(
        result,
        equals(const Left<Failure, void>(NetworkFailure('Connection timed out', code: 'TIMEOUT'))),
      );
      verify(() => mockDataSource.updateAutonomy('agent-1', AutonomyLevel.observe)).called(1);
    });

    test('should return Left(UnexpectedFailure) on unexpected error', () async {
      when(() => mockDataSource.updateAutonomy(any(), any())).thenThrow(Exception('boom'));

      final result = await repository.updateAutonomy('agent-1', AutonomyLevel.suggest);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'Unexpected error while updating autonomy'),
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.updateAutonomy('agent-1', AutonomyLevel.suggest)).called(1);
    });
  });

  group('toggleActive', () {
    test('should return Right(null) on success', () async {
      when(() => mockDataSource.toggleActive(any(), any())).thenAnswer((_) async {});

      final result = await repository.toggleActive('agent-1', false);

      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => mockDataSource.toggleActive('agent-1', false)).called(1);
    });

    test('should return Left(GatewayFailure) on GatewayException', () async {
      when(() => mockDataSource.toggleActive(any(), any())).thenThrow(
        const GatewayException('rejected', code: 'REJECTED'),
      );

      final result = await repository.toggleActive('agent-1', true);

      expect(
        result,
        equals(const Left<Failure, void>(GatewayFailure('rejected', code: 'REJECTED'))),
      );
      verify(() => mockDataSource.toggleActive('agent-1', true)).called(1);
    });

    test('should return Left(NetworkFailure) on ConnectionTimeoutException', () async {
      when(() => mockDataSource.toggleActive(any(), any())).thenThrow(const ConnectionTimeoutException());

      final result = await repository.toggleActive('agent-1', true);

      expect(
        result,
        equals(const Left<Failure, void>(NetworkFailure('Connection timed out', code: 'TIMEOUT'))),
      );
      verify(() => mockDataSource.toggleActive('agent-1', true)).called(1);
    });

    test('should return Left(UnexpectedFailure) on unexpected error', () async {
      when(() => mockDataSource.toggleActive(any(), any())).thenThrow(Exception('boom'));

      final result = await repository.toggleActive('agent-1', true);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'Unexpected error while toggling active state'),
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.toggleActive('agent-1', true)).called(1);
    });
  });

  group('watchAgents', () {
    test('should emit Right(List<Agent>) on successful updates', () async {
      when(() => mockDataSource.watchAgents()).thenAnswer(
        (_) => Stream.value([tAgentModel]),
      );

      final result = repository.watchAgents();

      final emitted = await result.first;
      expect(emitted.isRight(), isTrue);
      emitted.fold(
        (_) => fail('should be Right'),
        (agents) {
          expect(agents.length, 1);
          expect(agents.first, equals(tAgent));
        },
      );
      verify(() => mockDataSource.watchAgents()).called(1);
    });

    test('should emit Left(GatewayFailure) on GatewayException in stream', () async {
      when(() => mockDataSource.watchAgents()).thenAnswer(
        (_) => Stream.error(const GatewayException('stream error', code: 'STREAM_ERR')),
      );

      final result = repository.watchAgents();

      final emitted = await result.first;
      expect(emitted.isLeft(), isTrue);
      emitted.fold(
        (failure) {
          expect(failure, isA<GatewayFailure>());
          expect(failure.message, 'stream error');
        },
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.watchAgents()).called(1);
    });

    test('should emit Left(NetworkFailure) on ConnectionTimeoutException in stream', () async {
      when(() => mockDataSource.watchAgents()).thenAnswer(
        (_) => Stream.error(const ConnectionTimeoutException()),
      );

      final result = repository.watchAgents();

      final emitted = await result.first;
      expect(emitted.isLeft(), isTrue);
      emitted.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Connection timed out');
        },
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.watchAgents()).called(1);
    });

    test('should emit Left(UnexpectedFailure) on unexpected error in stream', () async {
      when(() => mockDataSource.watchAgents()).thenAnswer(
        (_) => Stream.error(Exception('stream boom')),
      );

      final result = repository.watchAgents();

      final emitted = await result.first;
      expect(emitted.isLeft(), isTrue);
      emitted.fold(
        (failure) {
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.message, 'Unexpected error in watch stream');
        },
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.watchAgents()).called(1);
    });
  });
}
