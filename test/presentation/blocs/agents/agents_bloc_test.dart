import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/domain/entities/agent.dart';
import 'package:openclaw_client/src/domain/repositories/agent_repository.dart';
import 'package:openclaw_client/src/presentation/blocs/agents/agents_bloc.dart';

class _MockAgentRepository implements AgentRepository {
  final List<Agent> _agents;
  final Failure? _failure;
  final Stream<List<Agent>>? _watchStream;

  _MockAgentRepository({
    List<Agent> agents = const [],
    Failure? failure,
    Stream<List<Agent>>? watchStream,
  })  : _agents = agents,
        _failure = failure,
        _watchStream = watchStream;

  @override
  Future<Either<Failure, List<Agent>>> getAgents() async {
    if (_failure != null) return Left(_failure!);
    return Right(_agents);
  }

  @override
  Future<Either<Failure, Agent>> getAgentById(String id) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> updateAutonomy(String id, AutonomyLevel level) async => const Right(null);

  @override
  Future<Either<Failure, void>> toggleActive(String id, bool active) async => const Right(null);

  @override
  Stream<Either<Failure, List<Agent>>> watchAgents() {
    return (_watchStream ?? const Stream.empty()).map((list) => Right(list));
  }
}

void main() {
  group('AgentsBloc', () {
    final mockAgents = [
      Agent(
        id: 'a1', name: 'Rosalina',
        description: 'Galaxy queen',
        capabilities: const ['chat'],
        isActive: true,
      ),
    ];

    blocTest<AgentsBloc, AgentsState>(
      'emits [AgentsLoading, AgentsLoaded] on LoadAgents',
      build: () => AgentsBloc(
        repository: _MockAgentRepository(agents: mockAgents),
      ),
      act: (bloc) => bloc.add(const LoadAgents()),
      expect: () => [
        isA<AgentsLoading>(),
        isA<AgentsLoaded>().having((s) => s.agents.length, 'count', 1),
      ],
    );

    blocTest<AgentsBloc, AgentsState>(
      'emits [AgentsLoading, AgentsError] on failure',
      build: () => AgentsBloc(
        repository: _MockAgentRepository(failure: const NetworkFailure('oops')),
      ),
      act: (bloc) => bloc.add(const LoadAgents()),
      expect: () => [
        isA<AgentsLoading>(),
        isA<AgentsError>().having((s) => s.message, 'message', 'oops'),
      ],
    );

    blocTest<AgentsBloc, AgentsState>(
      'emits updated AgentsLoaded on watch stream',
      build: () {
        final updated = [
          Agent(id: 'a2', name: 'Updated', capabilities: const []),
        ];
        return AgentsBloc(
          repository: _MockAgentRepository(
            agents: mockAgents,
            watchStream: Stream.fromFuture(Future.delayed(Duration.zero, () => updated)),
          ),
        );
      },
      act: (bloc) => bloc.add(const LoadAgents()),
      expect: () => [
        isA<AgentsLoading>(),
        isA<AgentsLoaded>().having((s) => s.agents.length, 'count', 1),
        isA<AgentsLoaded>().having((s) => s.agents.first.id, 'id', 'a2'),
      ],
    );

    blocTest<AgentsBloc, AgentsState>(
      'refreshes after ToggleAgent',
      build: () => AgentsBloc(
        repository: _MockAgentRepository(agents: mockAgents),
      ),
      act: (bloc) => bloc.add(const ToggleAgent(id: 'a1', active: false)),
      expect: () => [
        isA<AgentsLoading>(),
        isA<AgentsLoaded>().having((s) => s.agents.length, 'count', 1),
      ],
    );
  });
}
