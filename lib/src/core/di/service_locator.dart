import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/datasources/agent_remote_datasource.dart';
import '../../data/datasources/message_remote_datasource.dart';
import '../../data/datasources/session_remote_datasource.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repositories/agent_repository_impl.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/agent_repository.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../services/gateway_websocket.dart';
import '../../services/notification_service.dart';

/// Simple service locator for dependency injection.
///
/// Call [init] once at app startup, then access instances via [get].
class ServiceLocator {
  static final Map<Type, Object> _container = {};

  static void init() {
    // ── Secure storage ────────────────────────────
    const secureStorage = FlutterSecureStorage();
    final settingsDatasource = SettingsLocalDataSourceImpl(secureStorage: secureStorage);
    final settingsRepository = SettingsRepositoryImpl(localDataSource: settingsDatasource);

    // ── WebSocket client ──────────────────────────
    final gatewayClient = GatewayWebSocketClient();

    // ── Remote datasources ────────────────────────
    final messageDatasource = MessageRemoteDataSourceImpl(client: gatewayClient);
    final sessionDatasource = SessionRemoteDataSourceImpl(client: gatewayClient);
    final agentDatasource = AgentRemoteDataSourceImpl(client: gatewayClient);

    // ── Repositories ──────────────────────────────
    final messageRepository = MessageRepositoryImpl(remoteDataSource: messageDatasource);
    final sessionRepository = SessionRepositoryImpl(remoteDataSource: sessionDatasource);
    final agentRepository = AgentRepositoryImpl(remoteDataSource: agentDatasource);

    // ── Services ──────────────────────────────────
    final notificationService = NotificationService();

    // ── Register ──────────────────────────────────
    _container[FlutterSecureStorage] = secureStorage;
    _container[SettingsLocalDataSource] = settingsDatasource;
    _container[SettingsRepository] = settingsRepository;

    _container[GatewayWebSocketClient] = gatewayClient;
    _container[NotificationService] = notificationService;

    _container[MessageRemoteDataSource] = messageDatasource;
    _container[SessionRemoteDataSource] = sessionDatasource;
    _container[AgentRemoteDataSource] = agentDatasource;

    _container[MessageRepository] = messageRepository;
    _container[SessionRepository] = sessionRepository;
    _container[AgentRepository] = agentRepository;
  }

  static T get<T>() {
    final instance = _container[T];
    if (instance == null) {
      throw StateError('No instance registered for type $T. Did you call ServiceLocator.init()?');
    }
    return instance as T;
  }
}
