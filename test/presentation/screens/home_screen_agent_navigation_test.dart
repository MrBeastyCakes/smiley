import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openclaw_client/src/app.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/domain/entities/agent.dart';
import 'package:openclaw_client/src/domain/entities/session.dart';
import 'package:openclaw_client/src/domain/repositories/agent_repository.dart';
import 'package:openclaw_client/src/domain/repositories/session_repository.dart';
import 'package:openclaw_client/src/presentation/blocs/agents/agents_bloc.dart';
import 'package:openclaw_client/src/presentation/blocs/connection/connection_bloc.dart' as conn;
import 'package:openclaw_client/src/presentation/blocs/sessions/sessions_bloc.dart';
import 'package:openclaw_client/src/presentation/screens/home_screen.dart';

void main() {
  const validAgent = Agent(
    id: 'agent-valid',
    name: 'Atlas',
    description: 'Handles valid requests.',
    capabilities: ['search', 'summarize'],
    defaultAutonomy: AutonomyLevel.suggest,
    isActive: true,
  );

  const invalidAgent = Agent(
    id: 'agent-missing',
    name: 'Ghost',
    description: 'Missing details.',
    capabilities: ['unknown'],
    defaultAutonomy: AutonomyLevel.observe,
    isActive: false,
  );

  late conn.ConnectionBloc connectionBloc;
  late SessionsBloc sessionsBloc;
  late AgentsBloc agentsBloc;

  setUp(() {
    final agentRepository = _FakeAgentRepository(
      agents: const [validAgent, invalidAgent],
      byId: const {'agent-valid': validAgent},
    );

    connectionBloc = conn.ConnectionBloc();
    sessionsBloc = SessionsBloc(repository: _FakeSessionRepository());
    agentsBloc = AgentsBloc(repository: agentRepository);
  });

  tearDown(() async {
    await agentsBloc.close();
    await sessionsBloc.close();
    await connectionBloc.close();
  });

  Future<void> pumpHomeApp(WidgetTester tester) async {
    final agentRepository = _FakeAgentRepository(
      agents: const [validAgent, invalidAgent],
      byId: const {'agent-valid': validAgent},
    );

    final router = GoRouter(
      initialLocation: AppRoute.home,
      routes: [
        GoRoute(
          path: AppRoute.home,
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoute.agent,
          builder: (_, state) => AgentDetailLoaderScreen(
            agentId: state.pathParameters['agentId']!,
            repository: agentRepository,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: connectionBloc),
          BlocProvider.value(value: sessionsBloc),
          BlocProvider.value(value: agentsBloc),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('navigates from HomeScreen agent card to real detail screen', (tester) async {
    await pumpHomeApp(tester);

    await tester.tap(find.text('Agents'));
    await tester.pumpAndSettle();

    expect(find.text('Atlas'), findsOneWidget);
    await tester.tap(find.text('Atlas'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Capabilities'), findsOneWidget);
    expect(find.text('Atlas'), findsWidgets);
  });

  testWidgets('shows not-found state for invalid agent id and allows back navigation', (tester) async {
    await pumpHomeApp(tester);

    await tester.tap(find.text('Agents'));
    await tester.pumpAndSettle();

    expect(find.text('Ghost'), findsOneWidget);
    await tester.tap(find.text('Ghost'));
    await tester.pumpAndSettle();

    expect(find.text('Agent not found'), findsOneWidget);
    expect(find.textContaining('agent-missing'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Agents'), findsWidgets);
    expect(find.text('Ghost'), findsOneWidget);
  });
}

class _FakeAgentRepository implements AgentRepository {
  final List<Agent> agents;
  final Map<String, Agent> byId;

  const _FakeAgentRepository({required this.agents, required this.byId});

  @override
  Future<Either<Failure, List<Agent>>> getAgents() async => Right(agents);

  @override
  Future<Either<Failure, Agent>> getAgentById(String id) async {
    final agent = byId[id];
    if (agent == null) {
      return const Left(StorageFailure('Agent not found'));
    }
    return Right(agent);
  }

  @override
  Future<Either<Failure, void>> toggleActive(String id, bool active) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> updateAutonomy(String id, AutonomyLevel level) async =>
      const Right(null);

  @override
  Stream<Either<Failure, List<Agent>>> watchAgents() => Stream.value(Right(agents));
}

class _FakeSessionRepository implements SessionRepository {
  @override
  Future<Either<Failure, void>> archiveSession(String id) async => const Right(null);

  @override
  Future<Either<Failure, Session>> createSession({String? title, String? agentId}) async {
    return Left(ValidationFailure('Not needed for this test'));
  }

  @override
  Future<Either<Failure, Session>> getSessionById(String id) async {
    return Left(ValidationFailure('Not needed for this test'));
  }

  @override
  Future<Either<Failure, List<Session>>> getSessions() async => const Right([]);

  @override
  Future<Either<Failure, void>> pinSession(String id, bool pinned) async =>
      const Right(null);

  @override
  Stream<Either<Failure, List<Session>>> watchSessions() =>
      const Stream<Either<Failure, List<Session>>>.empty();
}
