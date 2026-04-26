import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/blocs/chat/chat_bloc.dart';
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
    String? initialLocation,
  }) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: initialLocation ?? Routes.connect,
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
            // TODO: fetch agent from repository via state.pathParameters['agentId']
            return const Scaffold(
              body: Center(child: Text('Agent detail')),
            );
          },
        ),
      ],
    );
  }
}
