import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/service_locator.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/agent_repository.dart';
import 'presentation/blocs/agents/agents_bloc.dart';
import 'presentation/blocs/chat/chat_bloc.dart';
import 'presentation/blocs/connection/connection_bloc.dart' as conn;
import 'presentation/blocs/sessions/sessions_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';

/// Backward-compatible route constants.
abstract class AppRoute {
  static const connect = Routes.connect;
  static const home = Routes.home;
  static const chat = Routes.chat;
  static const agent = Routes.agent;
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
  late final SessionsBloc _sessionsBloc;
  late final AgentsBloc _agentsBloc;
  late final SettingsBloc _settingsBloc;
  late final AgentRepository _agentRepository;
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
    _agentRepository = ServiceLocator.get<AgentRepository>();
    _refreshNotifier = _ConnectionRefreshNotifier(_connectionBloc);
    _router = AppRouter.create(
      chatBloc: _chatBloc,
      connectionBloc: _connectionBloc,
      agentRepository: _agentRepository,
      refreshListenable: _refreshNotifier,
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
