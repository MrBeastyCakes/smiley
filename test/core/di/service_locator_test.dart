import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/core/di/service_locator.dart';
import 'package:openclaw_client/src/data/datasources/agent_remote_datasource.dart';
import 'package:openclaw_client/src/data/datasources/message_remote_datasource.dart';
import 'package:openclaw_client/src/data/datasources/session_remote_datasource.dart';
import 'package:openclaw_client/src/data/datasources/settings_local_datasource.dart';
import 'package:openclaw_client/src/domain/repositories/agent_repository.dart';
import 'package:openclaw_client/src/domain/repositories/message_repository.dart';
import 'package:openclaw_client/src/domain/repositories/session_repository.dart';
import 'package:openclaw_client/src/domain/repositories/settings_repository.dart';
import 'package:openclaw_client/src/services/gateway_websocket.dart';
import 'package:openclaw_client/src/services/notification_service.dart';

void main() {
  group('ServiceLocator', () {
    setUpAll(() {
      ServiceLocator.init();
    });

    test('provides SettingsRepository', () {
      expect(ServiceLocator.get<SettingsRepository>(), isA<SettingsRepository>());
    });

    test('provides SettingsLocalDataSource', () {
      expect(ServiceLocator.get<SettingsLocalDataSource>(), isA<SettingsLocalDataSource>());
    });

    test('provides GatewayWebSocketClient', () {
      expect(ServiceLocator.get<GatewayWebSocketClient>(), isA<GatewayWebSocketClient>());
    });

    test('provides MessageRepository', () {
      expect(ServiceLocator.get<MessageRepository>(), isA<MessageRepository>());
    });

    test('provides MessageRemoteDataSource', () {
      expect(ServiceLocator.get<MessageRemoteDataSource>(), isA<MessageRemoteDataSource>());
    });

    test('provides SessionRepository', () {
      expect(ServiceLocator.get<SessionRepository>(), isA<SessionRepository>());
    });

    test('provides SessionRemoteDataSource', () {
      expect(ServiceLocator.get<SessionRemoteDataSource>(), isA<SessionRemoteDataSource>());
    });

    test('provides AgentRepository', () {
      expect(ServiceLocator.get<AgentRepository>(), isA<AgentRepository>());
    });

    test('provides AgentRemoteDataSource', () {
      expect(ServiceLocator.get<AgentRemoteDataSource>(), isA<AgentRemoteDataSource>());
    });

    test('throws when unregistered type requested', () {
      expect(() => ServiceLocator.get<String>(), throwsA(isA<StateError>()));
    });
  });
}
