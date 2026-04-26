import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/errors/exceptions.dart';
import '../datasources/message_remote_datasource.dart';
import '../models/chat_message_model.dart';
import 'database_helper.dart';

/// Local-first CRUD datasource for [ChatMessageModel] backed by SQLite.
class MessageLocalDataSource implements MessageRemoteDataSource {
  final DatabaseHelper _dbHelper;

  MessageLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => _dbHelper.database;

  // ── Helpers ───────────────────────────────────

  Map<String, dynamic> _modelToRow(ChatMessageModel m) => {
        'id': m.id,
        'sessionId': m.sessionId,
        'role': m.role,
        'text': m.text,
        'timestamp': m.timestamp,
        'status': m.status,
        'editedAt': m.editedAt,
        'agentId': m.agentId,
        'thinking': m.thinking != null ? jsonEncode(m.thinking!.toJson()) : null,
        'actionCards': m.actionCards.isNotEmpty
            ? jsonEncode(m.actionCards.map((e) => e.toJson()).toList())
            : null,
        'attachments': m.attachments.isNotEmpty
            ? jsonEncode(m.attachments.map((e) => e.toJson()).toList())
            : null,
        'metadata': m.metadata != null ? jsonEncode(m.metadata!.toJson()) : null,
      };

  ChatMessageModel _rowToModel(Map<String, dynamic> row) {
    final thinkingRaw = row['thinking'] as String?;
    final actionCardsRaw = row['actionCards'] as String?;
    final attachmentsRaw = row['attachments'] as String?;
    final metadataRaw = row['metadata'] as String?;

    return ChatMessageModel(
      id: row['id'] as String,
      sessionId: row['sessionId'] as String,
      role: row['role'] as String,
      text: row['text'] as String,
      timestamp: row['timestamp'] as String,
      status: row['status'] as String? ?? 'sent',
      editedAt: row['editedAt'] as String?,
      agentId: row['agentId'] as String?,
      thinking: thinkingRaw != null
          ? ThinkingBlockModel.fromJson(
              jsonDecode(thinkingRaw) as Map<String, dynamic>)
          : null,
      actionCards: actionCardsRaw != null
          ? (jsonDecode(actionCardsRaw) as List<dynamic>)
              .map((e) => ActionCardModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      attachments: attachmentsRaw != null
          ? (jsonDecode(attachmentsRaw) as List<dynamic>)
              .map((e) => MessageAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      metadata: metadataRaw != null
          ? MessageMetadataModel.fromJson(
              jsonDecode(metadataRaw) as Map<String, dynamic>)
          : null,
    );
  }

  // ── CRUD ────────────────────────────────────────

  /// Insert or update a message (upsert).
  Future<void> saveMessage(ChatMessageModel message) async {
    final db = await _db;
    await db.insert(
      'messages',
      _modelToRow(message),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or update multiple messages.
  Future<void> saveMessages(List<ChatMessageModel> messages) async {
    final db = await _db;
    final batch = db.batch();
    for (final m in messages) {
      batch.insert('messages', _modelToRow(m), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<ChatMessageModel>> listMessages(String sessionId) async {
    final db = await _db;
    final rows = await db.query(
      'messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(_rowToModel).toList();
  }

  @override
  Future<ChatMessageModel> sendMessage(String sessionId, String text) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final id = 'local-${now}-${sessionId.hashCode}';
    final message = ChatMessageModel(
      id: id,
      sessionId: sessionId,
      role: 'user',
      text: text,
      timestamp: now,
      status: 'pending',
    );
    await db.insert('messages', _modelToRow(message));
    return message;
  }

  /// Update the text / status of a message.
  Future<void> updateMessage(ChatMessageModel message) async {
    final db = await _db;
    await db.update(
      'messages',
      _modelToRow(message),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  /// Delete a single message.
  Future<void> deleteMessage(String id) async {
    final db = await _db;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all messages for a session.
  Future<void> deleteMessagesForSession(String sessionId) async {
    final db = await _db;
    await db.delete('messages', where: 'sessionId = ?', whereArgs: [sessionId]);
  }

  /// Delete all messages.
  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('messages');
  }

  @override
  Stream<ChatMessageModel> watchNewMessages(String sessionId) {
    ChatMessageModel? lastEmitted;

    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => listMessages(sessionId))
        .map((list) => list.isNotEmpty ? list.last : null)
        .where((m) => m != null)
        .cast<ChatMessageModel>()
        .where((message) {
          final changed =
              lastEmitted == null ||
              lastEmitted!.id != message.id ||
              lastEmitted!.status != message.status ||
              lastEmitted!.text != message.text;
          if (changed) {
            lastEmitted = message;
          }
          return changed;
        });
  }

  @override
  Stream<Map<String, dynamic>> watchMessageEvents() {
    return const Stream.empty();
  }

  /// Returns messages that have not been synced to the remote.
  Future<List<ChatMessageModel>> getUnsyncedMessages() async {
    final db = await _db;
    final rows = await db.query(
      'messages',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return rows.map(_rowToModel).toList();
  }

  /// Mark a message as synced.
  Future<void> markSynced(String id) async {
    final db = await _db;
    await db.update(
      'messages',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
