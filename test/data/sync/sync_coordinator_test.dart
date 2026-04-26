import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/data/datasources/agent_remote_datasource.dart';
import 'package:openclaw_client/src/data/datasources/message_remote_datasource.dart';
import 'package:openclaw_client/src/data/datasources/session_remote_datasource.dart';
import 'package:openclaw_client/src/data/local/agent_local_datasource.dart';
import 'package:openclaw_client/src/data/local/message_local_datasource.dart';
import 'package:openclaw_client/src/data/local/session_local_datasource.dart';
import 'package:openclaw_client/src/data/sync/sync_coordinator.dart';
import 'package:openclaw_client/src/domain/entities/gateway_settings.dart';
import 'package:openclaw_client/src/services/gateway_websocket.dart';

class MockGatewayWebSocketClient extends Mock implements GatewayWebSocketClient {}
class MockSessionRemoteDataSource extends Mock implements SessionRemoteDataSource {}
class MockAgentRemoteDataSource extends Mock implements AgentRemoteDataSource {}
class MockMessageRemoteDataSource extends Mock implements MessageRemoteDataSource {}
class MockSessionLocalDataSource extends Mock implements SessionLocalDataSource {}
class MockAgentLocalDataSource extends Mock implements AgentLocalDataSource {}
class MockMessageLocalDataSource extends Mock implements MessageLocalDataSource {}

void main() {
  late MockGatewayWebSocketClient client;
  late MockSessionRemoteDataSource sessionRemote;
  late MockAgentRemoteDataSource agentRemote;
  late MockMessageRemoteDataSource messageRemote;
  late MockSessionLocalDataSource sessionLocal;
  late MockAgentLocalDataSource agentLocal;
  late MockMessageLocalDataSource messageLocal;
  late SyncCoordinator coordinator;

  const settings = GatewaySettings(host: '127.0.0.1', port: 18789, token: 'token');

  setUp(() {
    client = MockGatewayWebSocketClient();
    sessionRemote = MockSessionRemoteDataSource();
    agentRemote = MockAgentRemoteDataSource();
    messageRemote = MockMessageRemoteDataSource();
    sessionLocal = MockSessionLocalDataSource();
    agentLocal = MockAgentLocalDataSource();
    messageLocal = MockMessageLocalDataSource();

    coordinator = SyncCoordinator(
      client: client,
      sessionRemote: sessionRemote,
      agentRemote: agentRemote,
      messageRemote: messageRemote,
      sessionLocal: sessionLocal,
      agentLocal: agentLocal,
      messageLocal: messageLocal,
    );

    when(() => sessionRemote.watchSessions()).thenAnswer((_) => const Stream.empty());
    when(() => agentRemote.watchAgents()).thenAnswer((_) => const Stream.empty());
    when(() => messageRemote.watchMessageEvents()).thenAnswer((_) => const Stream.empty());
    when(() => sessionRemote.listSessions()).thenAnswer((_) async => []);
    when(() => agentRemote.getAgents()).thenAnswer((_) async => []);
    when(() => sessionLocal.saveSessions(any())).thenAnswer((_) async {});
    when(() => agentLocal.saveAgents(any())).thenAnswer((_) async {});
    when(() => messageLocal.saveMessage(any())).thenAnswer((_) async {});
    when(() => client.connect(any())).thenAnswer((_) async {});
    when(() => client.disconnect()).thenAnswer((_) async {});
  });

  test('startSync does not call client.connect', () async {
    when(() => client.isConnected).thenReturn(true);

    await coordinator.startSync(settings);

    verifyNever(() => client.connect(any()));
  });

  test('stopSync does not call client.disconnect', () async {
    when(() => client.isConnected).thenReturn(true);

    await coordinator.startSync(settings);
    await coordinator.stopSync();

    verifyNever(() => client.disconnect());
  });
}
