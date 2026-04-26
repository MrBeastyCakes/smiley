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

  setUp(() {
    mockClient = MockGatewayWebSocketClient();
    dataSource = AgentRemoteDataSourceImpl(
      client: mockClient,
      responseTimeout: const Duration(milliseconds: 50),
    );
  });

  group('getAgents', () {
    test('should send list_agents and return decoded agents', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);
      when(() => mockClient.send(any())).thenAnswer((_) async {});

      final future = dataSource.getAgents();
      await Future.delayed(Duration.zero);

      controller.add({
        'type': 'agents_list',
        'agents': [
          {'id': '1', 'name': 'Agent 1', 'defaultAutonomy': 'suggest', 'isActive': true},
          {'id': '2', 'name': 'Agent 2', 'defaultAutonomy': 'autonomous', 'isActive': false},
        ],
      });

      final result = await future;
      expect(result.length, 2);
      expect(result[0].id, '1');
      expect(result[0].name, 'Agent 1');
      expect(result[1].id, '2');
      expect(result[1].name, 'Agent 2');

      verify(() => mockClient.send({'type': 'list_agents'})).called(1);
      await controller.close();
    });

    test('should throw ConnectionTimeoutException when response times out', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);
      when(() => mockClient.send(any())).thenAnswer((_) async {});

      expect(
        () => dataSource.getAgents(),
        throwsA(isA<ConnectionTimeoutException>()),
      );

      await controller.close();
    });

    test('should throw GatewayException on invalid response data', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);
      when(() => mockClient.send(any())).thenAnswer((_) async {});

      final future = dataSource.getAgents();
      await Future.delayed(Duration.zero);

      controller.add({
        'type': 'agents_list',
        'agents': 'not a list',
      });

      expect(
        () => future,
        throwsA(isA<GatewayException>()),
      );

      await controller.close();
    });
  });

  group('getAgentById', () {
    test('should send get_agent and return decoded agent', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);
      when(() => mockClient.send(any())).thenAnswer((_) async {});

      const tId = 'agent-1';
      final future = dataSource.getAgentById(tId);
      await Future.delayed(Duration.zero);

      controller.add({
        'type': 'agent',
        'agent': {'id': tId, 'name': 'Test Agent', 'defaultAutonomy': 'confirm', 'isActive': true},
      });

      final result = await future;
      expect(result.id, tId);
      expect(result.name, 'Test Agent');
      expect(result.defaultAutonomy, 'confirm');
      expect(result.isActive, true);

      verify(() => mockClient.send({'type': 'get_agent', 'id': tId})).called(1);
      await controller.close();
    });

    test('should parse inline agent when no agent wrapper key', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);
      when(() => mockClient.send(any())).thenAnswer((_) async {});

      const tId = 'agent-1';
      final future = dataSource.getAgentById(tId);
      await Future.delayed(Duration.zero);

      controller.add({
        'type': 'agent',
        'id': tId,
        'name': 'Inline Agent',
        'defaultAutonomy': 'observe',
        'isActive': false,
      });

      final result = await future;
      expect(result.id, tId);
      expect(result.name, 'Inline Agent');

      await controller.close();
    });

    test('should throw ConnectionTimeoutException when response times out', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);
      when(() => mockClient.send(any())).thenAnswer((_) async {});

      expect(
        () => dataSource.getAgentById('any-id'),
        throwsA(isA<ConnectionTimeoutException>()),
      );

      await controller.close();
    });

    test('should throw GatewayException on invalid response data', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);
      when(() => mockClient.send(any())).thenAnswer((_) async {});

      final future = dataSource.getAgentById('any-id');
      await Future.delayed(Duration.zero);

      controller.add({
        'type': 'agent',
        'agent': 'not a map',
      });

      expect(
        () => future,
        throwsA(isA<GatewayException>()),
      );

      await controller.close();
    });
  });

  group('updateAutonomy', () {
    test('should send update_autonomy with correct payload', () async {
      when(() => mockClient.send(any())).thenAnswer((_) async {});

      await dataSource.updateAutonomy('agent-1', AutonomyLevel.autonomous);

      verify(() => mockClient.send({
        'type': 'update_autonomy',
        'id': 'agent-1',
        'level': 'autonomous',
      })).called(1);
    });

    test('should propagate GatewayException on send failure', () async {
      when(() => mockClient.send(any())).thenThrow(
        const GatewayException('Send failed: socket closed', code: 'SEND_ERROR'),
      );

      expect(
        () => dataSource.updateAutonomy('agent-1', AutonomyLevel.confirm),
        throwsA(isA<GatewayException>()),
      );
    });
  });

  group('toggleActive', () {
    test('should send toggle_active with correct payload', () async {
      when(() => mockClient.send(any())).thenAnswer((_) async {});

      await dataSource.toggleActive('agent-1', true);

      verify(() => mockClient.send({
        'type': 'toggle_active',
        'id': 'agent-1',
        'active': true,
      })).called(1);
    });

    test('should send toggle_active with active false', () async {
      when(() => mockClient.send(any())).thenAnswer((_) async {});

      await dataSource.toggleActive('agent-1', false);

      verify(() => mockClient.send({
        'type': 'toggle_active',
        'id': 'agent-1',
        'active': false,
      })).called(1);
    });

    test('should propagate GatewayException on send failure', () async {
      when(() => mockClient.send(any())).thenThrow(
        const GatewayException('Send failed: socket closed', code: 'SEND_ERROR'),
      );

      expect(
        () => dataSource.toggleActive('agent-1', true),
        throwsA(isA<GatewayException>()),
      );
    });
  });

  group('watchAgents', () {
    test('should emit decoded agents on agent_update events', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);

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
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);

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
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);

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
