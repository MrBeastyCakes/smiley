import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/data/datasources/agent_remote_datasource.dart';
import 'package:openclaw_client/src/data/models/agent_model.dart';
import 'package:openclaw_client/src/domain/entities/agent.dart';
import 'package:openclaw_client/src/services/gateway_websocket.dart';

class MockGatewayWebSocketClient extends Mock implements GatewayWebSocketClient {}

void main() {
  late MockGatewayWebSocketClient mockClient;
  late AgentRemoteDataSource dataSource;

  setUpAll(() {
    registerFallbackValue(AutonomyLevel.suggest);
  });

  setUp(() {
    mockClient = MockGatewayWebSocketClient();
    dataSource = AgentRemoteDataSourceImpl(client: mockClient);
  });

  group('getAgents', () {
    test('should call sendRequest and return decoded agents', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {
        'agents': [
          {'id': '1', 'name': 'Agent 1', 'defaultAutonomy': 'suggest', 'isActive': true},
          {'id': '2', 'name': 'Agent 2', 'defaultAutonomy': 'autonomous', 'isActive': false},
        ],
      });

      final result = await dataSource.getAgents();

      expect(result.length, 2);
      expect(result[0].id, '1');
      expect(result[0].name, 'Agent 1');
      expect(result[1].id, '2');
      expect(result[1].name, 'Agent 2');

      verify(() => mockClient.sendRequest({'type': 'list_agents'})).called(1);
    });

    test('should return empty list on null data', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {});

      final result = await dataSource.getAgents();
      expect(result, isEmpty);
    });
  });

  group('getAgentById', () {
    test('should call sendRequest and return decoded agent', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {
        'agent': {'id': 'agent-1', 'name': 'Test Agent', 'defaultAutonomy': 'confirm', 'isActive': true},
      });

      final result = await dataSource.getAgentById('agent-1');

      expect(result.id, 'agent-1');
      expect(result.name, 'Test Agent');
      verify(() => mockClient.sendRequest({'type': 'get_agent', 'id': 'agent-1'})).called(1);
    });

    test('should parse inline agent when no wrapper key', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {
        'id': 'agent-1',
        'name': 'Inline Agent',
        'defaultAutonomy': 'observe',
        'isActive': false,
      });

      final result = await dataSource.getAgentById('agent-1');

      expect(result.id, 'agent-1');
      expect(result.name, 'Inline Agent');
    });

    test('should throw FormatException on invalid response data', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {
        'agent': 'not a map',
      });

      expect(
        () => dataSource.getAgentById('any-id'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('updateAutonomy', () {
    test('should call sendRequest with correct payload', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {});

      await dataSource.updateAutonomy('agent-1', AutonomyLevel.autonomous);

      verify(() => mockClient.sendRequest({
        'type': 'update_autonomy',
        'id': 'agent-1',
        'level': 'autonomous',
      })).called(1);
    });
  });

  group('toggleActive', () {
    test('should call sendRequest with correct payload', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {});

      await dataSource.toggleActive('agent-1', true);

      verify(() => mockClient.sendRequest({
        'type': 'toggle_active',
        'id': 'agent-1',
        'active': true,
      })).called(1);
    });

    test('should call sendRequest with active false', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {});

      await dataSource.toggleActive('agent-1', false);

      verify(() => mockClient.sendRequest({
        'type': 'toggle_active',
        'id': 'agent-1',
        'active': false,
      })).called(1);
    });
  });

  group('watchAgents', () {
    test('should emit decoded agents on agent_update events', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.eventStream).thenAnswer((_) => controller.stream);

      final stream = dataSource.watchAgents();
      final emissions = <List<AgentModel>>[];
      final sub = stream.listen(emissions.add);

      controller.add({
        'type': 'agent_update',
        'agents': [
          {'id': '1', 'name': 'Agent 1', 'defaultAutonomy': 'suggest', 'isActive': true},
        ],
      });

      await Future.delayed(Duration.zero);
      expect(emissions.length, 1);
      expect(emissions.first.length, 1);
      expect(emissions.first.first.id, '1');

      await sub.cancel();
      await controller.close();
    });

    test('should ignore non-agent_update messages', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.eventStream).thenAnswer((_) => controller.stream);

      final stream = dataSource.watchAgents();
      final emissions = <List<AgentModel>>[];
      final sub = stream.listen(emissions.add);

      controller.add({'type': 'ping'});
      controller.add({'type': 'chat_message', 'text': 'hello'});

      await Future.delayed(Duration.zero);
      expect(emissions, isEmpty);

      await sub.cancel();
      await controller.close();
    });

    test('should emit empty list when update payload is invalid', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.eventStream).thenAnswer((_) => controller.stream);

      final stream = dataSource.watchAgents();
      final emissions = <List<AgentModel>>[];
      final sub = stream.listen(emissions.add);

      controller.add({
        'type': 'agent_update',
        'agents': 'not a list',
      });

      await Future.delayed(Duration.zero);
      expect(emissions.length, 1);
      expect(emissions.first, isEmpty);

      await sub.cancel();
      await controller.close();
    });
  });
}
