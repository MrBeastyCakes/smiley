import 'dart:async';

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

  const AgentRemoteDataSourceImpl({required this.client});

  @override
  Future<List<AgentModel>> getAgents() async {
    final response = await client.sendRequest({'type': 'list_agents'});
    final data = response['agents'] ?? response['data'];
    if (data is! List<dynamic>) return [];
    return data.map((json) => AgentModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<AgentModel> getAgentById(String id) async {
    final response = await client.sendRequest({'type': 'get_agent', 'id': id});
    final data = response['agent'] ?? response;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid agent response');
    }
    return AgentModel.fromJson(data);
  }

  @override
  Future<void> updateAutonomy(String id, AutonomyLevel level) async {
    await client.sendRequest({'type': 'update_autonomy', 'id': id, 'level': level.name});
  }

  @override
  Future<void> toggleActive(String id, bool active) async {
    await client.sendRequest({'type': 'toggle_active', 'id': id, 'active': active});
  }

  @override
  Stream<List<AgentModel>> watchAgents() {
    return client.eventStream
        .where((msg) => msg['type'] == 'agent_update')
        .map((msg) {
      final data = msg['agents'] ?? msg['data'];
      if (data is! List<dynamic>) return <AgentModel>[];
      return data.map((json) => AgentModel.fromJson(json as Map<String, dynamic>)).toList();
    });
  }
}
