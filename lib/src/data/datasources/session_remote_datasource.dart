import 'dart:async';

import '../../services/gateway_websocket.dart';
import '../models/session_model.dart';

abstract class SessionRemoteDataSource {
  Future<List<SessionModel>> listSessions();
  Future<SessionModel> getSessionById(String id);
  Future<SessionModel> createSession({String? title, String? agentId});
  Future<void> pinSession(String id, bool pinned);
  Future<void> archiveSession(String id);
  Stream<List<SessionModel>> watchSessions();
}

class SessionRemoteDataSourceImpl implements SessionRemoteDataSource {
  final GatewayWebSocketClient client;

  SessionRemoteDataSourceImpl({required this.client});

  @override
  Future<List<SessionModel>> listSessions() async {
    final response = await client.sendRequest({'type': 'list_sessions'});
    final sessions = response['sessions'] as List<dynamic>? ?? [];
    return sessions
        .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SessionModel> getSessionById(String id) async {
    final response = await client.sendRequest({'type': 'get_session', 'id': id});
    return SessionModel.fromJson(response['session'] as Map<String, dynamic>);
  }

  @override
  Future<SessionModel> createSession({String? title, String? agentId}) async {
    final response = await client.sendRequest({
      'type': 'create_session',
      'title': title,
      'agentId': agentId,
    });
    return SessionModel.fromJson(response['session'] as Map<String, dynamic>);
  }

  @override
  Future<void> pinSession(String id, bool pinned) async {
    await client.sendRequest({'type': 'pin_session', 'id': id, 'pinned': pinned});
  }

  @override
  Future<void> archiveSession(String id) async {
    await client.sendRequest({'type': 'archive_session', 'id': id});
  }

  @override
  Stream<List<SessionModel>> watchSessions() {
    return client.eventStream
        .where((msg) => msg['type'] == 'session_update')
        .map((msg) {
      final sessions = msg['sessions'] as List<dynamic>? ?? [];
      return sessions
          .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

//   Future<Map<String, dynamic>> _sendRequest(Map<String, dynamic> request) async {
//     if (!client.isConnected) {
//       throw const GatewayException('Not connected', code: 'NOT_CONNECTED');
//     }
//
//     final future = client.messageStream
//         .where((msg) => msg['type'] != 'ping' && msg['type'] != 'pong')
//         .first
//         .timeout(_requestTimeout, onTimeout: () {
//       throw const GatewayException('Request timeout', code: 'TIMEOUT');
//     });
//
//     await client.send(request);
//
//     return future;
//   }
}
