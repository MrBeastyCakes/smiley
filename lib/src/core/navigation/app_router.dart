import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/repositories/agent_repository.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/connection/connection_bloc.dart' as conn;
import '../../presentation/screens/agent_detail_screen.dart';
import '../../presentation/screens/chat_screen.dart';
import '../../presentation/screens/connect_screen.dart';
import '../../presentation/screens/home_screen.dart';

/// Route names for deep linking and navigation.
abstract class Routes {
  static const connect = '/';
  static const home = '/home';
  static const chat = '/chat/:sessionId';
  static const agent = '/agent/:agentId';
}

/// App router with declarative routing and deep link support.
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter create({
    required ChatBloc chatBloc,
    required conn.ConnectionBloc connectionBloc,
    required AgentRepository agentRepository,
    required Listenable refreshListenable,
    String? initialLocation,
    bool enableConnectionRedirect = true,
  }) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: initialLocation ?? Routes.connect,
      refreshListenable: refreshListenable,
      redirect: enableConnectionRedirect
          ? (context, state) {
              final connectionState = connectionBloc.state;
              final isFullyConnected = connectionState is conn.ConnectionConnected;
              final hasBeenConnected = connectionBloc.state is conn.ConnectionConnected ||
                  connectionBloc.state is conn.ConnectionReconnecting ||
                  connectionBloc.state is conn.ConnectionOffline;
              final isOnConnect = state.matchedLocation == Routes.connect;

              if (isFullyConnected && isOnConnect) return Routes.home;
              if (!hasBeenConnected && !isOnConnect) return Routes.connect;
              return null;
            }
          : null,
      routes: [
        GoRoute(
          path: Routes.connect,
          builder: (_, __) => const ConnectScreen(),
        ),
        GoRoute(
          path: Routes.home,
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: Routes.chat,
          builder: (context, state) {
            final sessionId = state.pathParameters['sessionId']!;
            return BlocProvider.value(
              value: chatBloc,
              child: ChatScreen(sessionId: sessionId),
            );
          },
        ),
        GoRoute(
          path: Routes.agent,
          builder: (_, state) {
            final agentId = state.pathParameters['agentId']!;
            return FutureBuilder(
              future: agentRepository.getAgentById(agentId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                return snapshot.data!.fold(
                  (failure) => Scaffold(
                    appBar: AppBar(title: const Text('Agent')),
                    body: Center(child: Text(failure.message)),
                  ),
                  (agent) => AgentDetailScreen(agent: agent),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
