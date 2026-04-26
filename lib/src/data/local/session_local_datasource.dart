import 'package:sqflite/sqflite.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/session.dart';
import '../datasources/session_remote_datasource.dart';
import '../models/session_model.dart';
import 'database_helper.dart';

/// Local-first CRUD datasource for [SessionModel] backed by SQLite.
class SessionLocalDataSource implements SessionRemoteDataSource {
  final DatabaseHelper _dbHelper;

  SessionLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => _dbHelper.database;

  // ── Helpers ───────────────────────────────────

  Map<String, dynamic> _modelToRow(SessionModel m) => {
        'id': m.id,
        'title': m.title,
        'agentId': m.agentId,
        'createdAt': m.createdAt,
        'updatedAt': m.updatedAt,
        'messageCount': m.messageCount,
        'isPinned': m.isPinned ? 1 : 0,
        'isArchived': m.isArchived ? 1 : 0,
        'lastMessagePreview': m.lastMessagePreview,
      };

  SessionModel _rowToModel(Map<String, dynamic> row) => SessionModel(
        id: row['id'] as String,
        title: row['title'] as String,
        agentId: row['agentId'] as String?,
        createdAt: row['createdAt'] as String,
        updatedAt: row['updatedAt'] as String,
        messageCount: row['messageCount'] as int? ?? 0,
        isPinned: (row['isPinned'] as int? ?? 0) == 1,
        isArchived: (row['isArchived'] as int? ?? 0) == 1,
        lastMessagePreview: row['lastMessagePreview'] as String?,
      );

  // ── CRUD ────────────────────────────────────────

  /// Insert or update a session (upsert).
  Future<void> saveSession(SessionModel session) async {
    final db = await _db;
    await db.insert(
      'sessions',
      _modelToRow(session),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or update multiple sessions.
  Future<void> saveSessions(List<SessionModel> sessions) async {
    final db = await _db;
    final batch = db.batch();
    for (final s in sessions) {
      batch.insert('sessions', _modelToRow(s), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<SessionModel>> listSessions() async {
    final db = await _db;
    final rows = await db.query(
      'sessions',
      orderBy: 'updatedAt DESC',
    );
    return rows.map(_rowToModel).toList();
  }

  @override
  Future<SessionModel> getSessionById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const StorageException('Session not found', code: 'NOT_FOUND');
    }
    return _rowToModel(rows.first);
  }

  @override
  Future<void> pinSession(String id, bool pinned) async {
    final db = await _db;
    final count = await db.update(
      'sessions',
      {'isPinned': pinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0) {
      throw const StorageException('Session not found', code: 'NOT_FOUND');
    }
  }

  @override
  Future<void> archiveSession(String id) async {
    final db = await _db;
    final count = await db.update(
      'sessions',
      {'isArchived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0) {
      throw const StorageException('Session not found', code: 'NOT_FOUND');
    }
  }

  /// Physically delete a session.
  Future<void> deleteSession(String id) async {
    final db = await _db;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all sessions (useful for logout / reset).
  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('sessions');
  }

  @override
  Stream<List<SessionModel>> watchSessions() {
    // SQLite on Flutter doesn't have built-in notify; we poll every 2s.
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => listSessions());
  }

  /// Returns sessions that have not been synced to the remote.
  Future<List<SessionModel>> getUnsyncedSessions() async {
    final db = await _db;
    final rows = await db.query(
      'sessions',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return rows.map(_rowToModel).toList();
  }

  /// Mark a session as synced.
  Future<void> markSynced(String id) async {
    final db = await _db;
    await db.update(
      'sessions',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
