import 'dart:async';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/agent.dart';
import '../../services/gateway_websocket.dart';
import '../models/agent_model.dart';

/// Remote datasource for agent operations via the gateway WebSocket.
abstract class AgentRemoteDataSource {
  /// Requests the list of all agents from the gateway.
  Future<List<AgentModel>> getAgents();

  /// Requests a single agent by id from the gateway.
  Future<AgentModel> getAgentById(String id);

  /// Sends an autonomy update for the given agent.
  Future<void> updateAutonomy(String id, AutonomyLevel level);

  /// Sends an active-state toggle for the given agent.
  Future<void> toggleActive(String id, bool active);

  /// Listens to real-time agent update events from the gateway.
  Stream<List<AgentModel>> watchAgents();
}

class AgentRemoteDataSourceImpl implements AgentRemoteDataSource {
  final GatewayWebSocketClient client;
  final Duration responseTimeout;

  const AgentRemoteDataSourceImpl({
    required this.client,
    this.responseTimeout = const Duration(seconds: 5),
  });

  Future<Map<String, dynamic>> _awaitResponse(String expectedType) async {
    final completer = Completer<Map<String, dynamic>>();
    late StreamSubscription<Map<String, dynamic>> sub;

    sub = client.messageStream.listen((msg) {
      if (msg['type'] == expectedType && !completer.isCompleted) {
        completer.complete(msg);
      }
    });

    final timer = Timer(responseTimeout, () {
      if (!completer.isCompleted) {
        completer.completeError(const ConnectionTimeoutException());
      }
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      await sub.cancel();
    }
  }

  @override
  Future<List<AgentModel>> getAgents() async {
    final future = _awaitResponse('agents_list');
    await client.send({'type': 'list_agents'});
    final response = await future;

    final data = response['agents'] ?? response['data'];
    if (data is! List<dynamic>) {
      throw const GatewayException('Invalid agents list response', code: 'INVALID_RESPONSE');
    }
    return data.map((json) => AgentModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<AgentModel> getAgentById(String id) async {
    final future = _awaitResponse('agent');
    await client.send({'type': 'get_agent', 'id': id});
    final response = await future;

    final data = response['agent'] ?? response;
    if (data is! Map<String, dynamic>) {
      throw const GatewayException('Invalid agent response', code: 'INVALID_RESPONSE');
    }
    return AgentModel.fromJson(data);
  }

  @override
  Future<void> updateAutonomy(String id, AutonomyLevel level) async {
    await client.send({
      'type': 'update_autonomy',
      'id': id,
      'level': level.name,
    });
  }

  @override
  Future<void> toggleActive(String id, bool active) async {
    await client.send({
      'type': 'toggle_active',
      'id': id,
      'active': active,
    });
  }

  @override
  Stream<List<AgentModel>> watchAgents() {
    return client.messageStream
        .where((msg) => msg['type'] == 'agent_update')
        .map((msg) {
          final data = msg['agents'] ?? msg['data'];
          if (data is! List<dynamic>) return <AgentModel>[];
          return data.map((json) => AgentModel.fromJson(json as Map<String, dynamic>)).toList();
        });
  }
}
