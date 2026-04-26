import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/chat/chat_bloc.dart';
import 'presentation/blocs/connection/connection_bloc.dart' as conn;
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/connect_screen.dart';
import 'presentation/screens/home_screen.dart';

/// Route names for deep linking.
abstract class AppRoute {
  static const connect = '/';
  static const home = '/home';
  static const chat = '/chat/:sessionId';
  static const agent = '/agent/:agentId';
}

/// Notifies GoRouter when connection state changes so redirects re-evaluate.
class _ConnectionRefreshNotifier extends ChangeNotifier {
  _ConnectionRefreshNotifier(conn.ConnectionBloc bloc) {
    _subscription = bloc.stream.listen((_) => notifyListeners());
  }
  StreamSubscription? _subscription;
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Root app widget with BLoC providers and GoRouter navigation.
class OpenClawApp extends StatefulWidget {
  const OpenClawApp({super.key});

  @override
  State<OpenClawApp> createState() => _OpenClawAppState();
}

class _OpenClawAppState extends State<OpenClawApp> {
  late final conn.ConnectionBloc _connectionBloc;
  late final ChatBloc _chatBloc;
  late final _ConnectionRefreshNotifier _refreshNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _connectionBloc = conn.ConnectionBloc();
    _chatBloc = ChatBloc();
    _refreshNotifier = _ConnectionRefreshNotifier(_connectionBloc);
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: AppRoute.connect,
      refreshListenable: _refreshNotifier,
      redirect: (context, state) {
        final connectionState = _connectionBloc.state;
        final isConnected = connectionState is conn.ConnectionConnected;
        final isOnHome = state.matchedLocation == AppRoute.home;
        final isOnConnect = state.matchedLocation == AppRoute.connect;

        if (isConnected && isOnConnect) return AppRoute.home;
        if (!isConnected && isOnHome) return AppRoute.connect;
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoute.connect,
          builder: (_, __) => const ConnectScreen(),
        ),
        GoRoute(
          path: AppRoute.home,
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoute.chat,
          builder: (_, state) {
            final sessionId = state.pathParameters['sessionId']!;
            return BlocProvider.value(
              value: _chatBloc,
              child: ChatScreen(sessionId: sessionId),
            );
          },
        ),
        GoRoute(
          path: AppRoute.agent,
          builder: (_, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Agent')),
              body: const Center(child: Text('Agent detail')),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _refreshNotifier.dispose();
    _connectionBloc.close();
    _chatBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _connectionBloc),
        BlocProvider.value(value: _chatBloc),
      ],
      child: MaterialApp.router(
        title: 'OpenClaw',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }
}
