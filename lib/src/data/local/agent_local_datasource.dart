import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/agent.dart';
import '../datasources/agent_remote_datasource.dart';
import '../models/agent_model.dart';
import 'database_helper.dart';

/// Local-first CRUD datasource for [AgentModel] backed by SQLite.
class AgentLocalDataSource implements AgentRemoteDataSource {
  final DatabaseHelper _dbHelper;

  AgentLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => _dbHelper.database;

  // ── Helpers ───────────────────────────────────

  Map<String, dynamic> _modelToRow(AgentModel m) => {
        'id': m.id,
        'name': m.name,
        'avatarUrl': m.avatarUrl,
        'description': m.description,
        'capabilities': jsonEncode(m.capabilities),
        'defaultAutonomy': m.defaultAutonomy,
        'isActive': m.isActive ? 1 : 0,
        'lastActiveAt': m.lastActiveAt,
      };

  AgentModel _rowToModel(Map<String, dynamic> row) => AgentModel(
        id: row['id'] as String,
        name: row['name'] as String,
        avatarUrl: row['avatarUrl'] as String?,
        description: row['description'] as String?,
        capabilities: row['capabilities'] != null
            ? (jsonDecode(row['capabilities'] as String) as List<dynamic>).cast<String>()
            : const [],
        defaultAutonomy: row['defaultAutonomy'] as String? ?? 'suggest',
        isActive: (row['isActive'] as int? ?? 0) == 1,
        lastActiveAt: row['lastActiveAt'] as String?,
      );

  // ── CRUD ────────────────────────────────────────

  /// Insert or update an agent (upsert).
  Future<void> saveAgent(AgentModel agent) async {
    final db = await _db;
    await db.insert(
      'agents',
      _modelToRow(agent),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or update multiple agents.
  Future<void> saveAgents(List<AgentModel> agents) async {
    final db = await _db;
    final batch = db.batch();
    for (final a in agents) {
      batch.insert('agents', _modelToRow(a), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<AgentModel>> getAgents() async {
    final db = await _db;
    final rows = await db.query('agents', orderBy: 'name ASC');
    return rows.map(_rowToModel).toList();
  }

  @override
  Future<AgentModel> getAgentById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'agents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const StorageException('Agent not found', code: 'NOT_FOUND');
    }
    return _rowToModel(rows.first);
  }

  @override
  Future<void> updateAutonomy(String id, AutonomyLevel level) async {
    final db = await _db;
    final count = await db.update(
      'agents',
      {'defaultAutonomy': level.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0) {
      throw const StorageException('Agent not found', code: 'NOT_FOUND');
    }
  }

  @override
  Future<void> toggleActive(String id, bool active) async {
    final db = await _db;
    final count = await db.update(
      'agents',
      {'isActive': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0) {
      throw const StorageException('Agent not found', code: 'NOT_FOUND');
    }
  }

  /// Delete an agent.
  Future<void> deleteAgent(String id) async {
    final db = await _db;
    await db.delete('agents', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all agents.
  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('agents');
  }

  @override
  Stream<List<AgentModel>> watchAgents() {
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => getAgents());
  }

  /// Returns agents that have not been synced to the remote.
  Future<List<AgentModel>> getUnsyncedAgents() async {
    final db = await _db;
    final rows = await db.query(
      'agents',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return rows.map(_rowToModel).toList();
  }

  /// Mark an agent as synced.
  Future<void> markSynced(String id) async {
    final db = await _db;
    await db.update(
      'agents',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
