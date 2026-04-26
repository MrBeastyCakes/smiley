import 'dart:async';

import '../datasources/agent_remote_datasource.dart';
import '../datasources/message_remote_datasource.dart';
import '../datasources/session_remote_datasource.dart';
import '../local/agent_local_datasource.dart';
import '../local/message_local_datasource.dart';
import '../local/session_local_datasource.dart';
import '../models/agent_model.dart';
import '../models/chat_message_model.dart';
import '../models/session_model.dart';
import '../../domain/entities/gateway_settings.dart';
import '../../services/gateway_websocket.dart';

/// Coordinates background sync between the gateway (remote) and SQLite (local).
///
/// When the WebSocket is connected, this subscribes to real-time event
/// streams and persists incoming updates to the local cache.  This makes
/// the local-first repositories immediately reflect remote changes without
/// requiring manual refresh.
///
/// Typical lifecycle:
///   1. [startSync] called when ConnectionBloc emits Connected
///   2. Subscriptions to remote watch streams are established
///   3. Remote data is merged into local SQLite
///   4. [stopSync] called when ConnectionBloc emits Disconnected
class SyncCoordinator {
  final GatewayWebSocketClient client;
  final SessionRemoteDataSource sessionRemote;
  final AgentRemoteDataSource agentRemote;
  final MessageRemoteDataSource messageRemote;
  final SessionLocalDataSource sessionLocal;
  final AgentLocalDataSource agentLocal;
  final MessageLocalDataSource messageLocal;

  final List<StreamSubscription<void>> _subscriptions = [];
  bool _syncing = false;

  SyncCoordinator({
    required this.client,
    required this.sessionRemote,
    required this.agentRemote,
    required this.messageRemote,
    required this.sessionLocal,
    required this.agentLocal,
    required this.messageLocal,
  });

  bool get isSyncing => _syncing;

  /// Begin background sync. Safe to call multiple times — subsequent calls
  /// are ignored while already syncing.
  Future<void> startSync(GatewaySettings _settings) async {
    if (_syncing) return;
    if (!client.isConnected) return;

    _syncing = true;

    // ── Session events ──────────────────────────
    _subscriptions.add(
      sessionRemote.watchSessions().listen(
        (models) => _saveSessions(models),
        onError: (_) {},
      ),
    );

    // ── Agent events ──────────────────────────
    _subscriptions.add(
      agentRemote.watchAgents().listen(
        (models) => _saveAgents(models),
        onError: (_) {},
      ),
    );

    // ── Message events (new messages + chunks) ──
    _subscriptions.add(
      messageRemote.watchMessageEvents().listen(
        (event) => _onMessageEvent(event),
        onError: (_) {},
      ),
    );

    // ── Initial full sync (pull remote state) ──
    // ignore: unawaited_futures
    _initialFullSync();
  }

  /// Stop all sync subscriptions.
  Future<void> stopSync() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _syncing = false;
  }

  // ── Internal helpers ─────────────────────────

  Future<void> _saveSessions(List<SessionModel> models) async {
    try {
      await sessionLocal.saveSessions(models);
    } catch (_) {}
  }

  Future<void> _saveAgents(List<AgentModel> models) async {
    try {
      await agentLocal.saveAgents(models);
    } catch (_) {}
  }

  Future<void> _saveMessage(ChatMessageModel model) async {
    try {
      await messageLocal.saveMessage(model);
    } catch (_) {}
  }

  void _onMessageEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == 'message') {
      try {
        final model = ChatMessageModel.fromJson(
          event['message'] as Map<String, dynamic>,
        );
        // ignore: unawaited_futures
        _saveMessage(model);
      } catch (_) {}
    }
    // message_chunk events are consumed directly by UI via
    // MessageRepository.watchMessageStream(sessionId).
  }

  Future<void> _initialFullSync() async {
    try {
      final sessions = await sessionRemote.listSessions();
      await sessionLocal.saveSessions(sessions);
    } catch (_) {}

    try {
      final agents = await agentRemote.getAgents();
      await agentLocal.saveAgents(agents);
    } catch (_) {}
  }

  void dispose() {
    stopSync();
  }
}
