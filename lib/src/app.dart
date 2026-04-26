import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/agent_repository.dart';
import 'presentation/blocs/agents/agents_bloc.dart';
import 'presentation/blocs/chat/chat_bloc.dart';
import 'presentation/blocs/connection/connection_bloc.dart' as conn;
import 'presentation/blocs/sessions/sessions_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/screens/agent_detail_screen.dart';
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

/// Loads an agent by route id and renders the detail screen.
class AgentDetailLoaderScreen extends StatelessWidget {
  final String agentId;
  final AgentRepository repository;

  const AgentDetailLoaderScreen({
    super.key,
    required this.agentId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: repository.getAgentById(agentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading agent')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _AgentRouteMessageState(
            title: 'Unable to load agent',
            message: 'Something went wrong while opening this agent. Please try again.',
          );
        }

        final result = snapshot.data;
        if (result == null) {
          return _AgentRouteMessageState(
            title: 'Unable to load agent',
            message: 'No agent data was returned for id "$agentId".',
          );
        }

        return result.fold(
          (failure) {
            final isNotFound = failure.message.toLowerCase().contains('not found');
            return _AgentRouteMessageState(
              title: isNotFound ? 'Agent not found' : 'Unable to load agent',
              message: isNotFound
                  ? 'No agent exists with id "$agentId".'
                  : failure.message,
            );
          },
          (agent) => AgentDetailScreen(agent: agent),
        );
      },
    );
  }
}

class _AgentRouteMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _AgentRouteMessageState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(AppRoute.home);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
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
  late final SessionsBloc _sessionsBloc;
  late final AgentsBloc _agentsBloc;
  late final SettingsBloc _settingsBloc;
  late final _ConnectionRefreshNotifier _refreshNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _connectionBloc = conn.ConnectionBloc();
    _chatBloc = ChatBloc(connectionBloc: _connectionBloc);
    _sessionsBloc = ServiceLocator.get<SessionsBloc>();
    _agentsBloc = ServiceLocator.get<AgentsBloc>();
    _settingsBloc = ServiceLocator.get<SettingsBloc>();
    _refreshNotifier = _ConnectionRefreshNotifier(_connectionBloc);
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: AppRoute.connect,
      refreshListenable: _refreshNotifier,
      redirect: (context, state) {
        final connectionState = _connectionBloc.state;
        final isFullyConnected = connectionState is conn.ConnectionConnected;
        final hasBeenConnected = _connectionBloc.state is conn.ConnectionConnected ||
                                   _connectionBloc.state is conn.ConnectionReconnecting ||
                                   _connectionBloc.state is conn.ConnectionOffline;
        final isOnConnect = state.matchedLocation == AppRoute.connect;

        // Only redirect to home when first-time connected.
        if (isFullyConnected && isOnConnect) return AppRoute.home;

        // Only kick to connect screen if we've never connected at all.
        // If reconnecting or offline, stay where the user is.
        if (!hasBeenConnected && !isOnConnect) return AppRoute.connect;
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
            final agentId = state.pathParameters['agentId']!;
            final repository = ServiceLocator.get<AgentRepository>();
            return AgentDetailLoaderScreen(
              agentId: agentId,
              repository: repository,
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
    _sessionsBloc.close();
    _agentsBloc.close();
    _settingsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _connectionBloc),
        BlocProvider.value(value: _chatBloc),
        BlocProvider.value(value: _sessionsBloc),
        BlocProvider.value(value: _agentsBloc),
        BlocProvider.value(value: _settingsBloc),
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
