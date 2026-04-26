import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/core/navigation/app_router.dart';
import 'package:openclaw_client/src/domain/entities/agent.dart';
import 'package:openclaw_client/src/domain/entities/chat_message.dart';
import 'package:openclaw_client/src/domain/repositories/agent_repository.dart';
import 'package:openclaw_client/src/domain/repositories/message_repository.dart';
import 'package:openclaw_client/src/presentation/blocs/chat/chat_bloc.dart';
import 'package:openclaw_client/src/presentation/blocs/connection/connection_bloc.dart';
import 'package:openclaw_client/src/services/gateway_websocket.dart';

class _FakeMessageRepository implements MessageRepository {
  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(String sessionId) async => const Right([]);

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(String sessionId, String text) async =>
      Left(UnexpectedFailure('not used'));

  @override
  Stream<Either<Failure, ChatMessage>> watchNewMessages(String sessionId) => const Stream.empty();

  @override
  Stream<Either<Failure, String>> watchMessageStream(String sessionId) => const Stream.empty();
}

class _FakeAgentRepository implements AgentRepository {
  @override
  Future<Either<Failure, List<Agent>>> getAgents() async =>
      Right([_agent]);

  @override
  Future<Either<Failure, Agent>> getAgentById(String id) async {
    if (id == _agent.id) return Right(_agent);
    return Left(ValidationFailure('Agent not found: $id'));
  }

  @override
  Future<Either<Failure, void>> toggleActive(String id, bool active) async => const Right(null);

  @override
  Future<Either<Failure, void>> updateAutonomy(String id, AutonomyLevel level) async => const Right(null);

  @override
  Stream<Either<Failure, List<Agent>>> watchAgents() => Stream.value(Right([_agent]));
}

const _agent = Agent(
  id: 'agent-123',
  name: 'Regression Bot',
  description: 'Valid detail page content',
  capabilities: ['routing'],
  defaultAutonomy: AutonomyLevel.suggest,
  isActive: true,
);

void main() {
  group('Routes constants', () {
    test('connect route is root', () {
      expect(Routes.connect, '/');
    });

    test('home route is /home', () {
      expect(Routes.home, '/home');
    });

    test('chat route has sessionId parameter', () {
      expect(Routes.chat, '/chat/:sessionId');
    });

    test('agent route has agentId parameter', () {
      expect(Routes.agent, '/agent/:agentId');
    });
  });

  testWidgets('has a single agent route and renders real agent detail content', (tester) async {
    final connectionBloc = ConnectionBloc(client: GatewayWebSocketClient());
    final chatBloc = ChatBloc(
      repository: _FakeMessageRepository(),
      connectionBloc: connectionBloc,
    );
    final router = AppRouter.create(
      chatBloc: chatBloc,
      connectionBloc: connectionBloc,
      agentRepository: _FakeAgentRepository(),
      refreshListenable: ValueNotifier<int>(0),
      initialLocation: '/agent/${_agent.id}',
      enableConnectionRedirect: false,
    );

    final agentRouteCount = router.configuration.routes
        .whereType<GoRoute>()
        .where((route) => route.path == Routes.agent)
        .length;
    expect(agentRouteCount, 1);

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('Regression Bot'), findsOneWidget);
    expect(find.text('Valid detail page content'), findsOneWidget);
    expect(find.text('Agent detail'), findsNothing);

    await chatBloc.close();
    await connectionBloc.close();
  });
}
