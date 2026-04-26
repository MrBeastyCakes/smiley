import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite database helper for OpenClaw client.
///
/// Tables:
/// - sessions: stores session metadata
/// - messages: stores chat messages per session
/// - agents: stores agent metadata
class DatabaseHelper {
  static const String _defaultDbName = 'openclaw.db';
  static const int _dbVersion = 2;

  final String _dbName;
  Database? _database;

  /// Default production helper (singleton-ish via shared name).
  DatabaseHelper() : _dbName = _defaultDbName;

  /// Test helper with an isolated database name.
  DatabaseHelper.test(String name) : _dbName = name;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await _runMigrations(txn, 0, version);
      await _validateSchema(txn);
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      await _runMigrations(txn, oldVersion, newVersion);
      await _validateSchema(txn);
    });
  }

  /// Migration rules:
  /// 1. Never edit historical migration blocks.
  /// 2. Only append new `if (oldVersion < X)` blocks for future versions.
  /// 3. Keep migration SQL idempotent so interrupted upgrades can safely retry.
  Future<void> _runMigrations(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion >= newVersion) return;

    if (oldVersion < 1 && newVersion >= 1) {
      await _createTableIfNotExists(
        db,
        'sessions',
        '''
        CREATE TABLE sessions (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          agentId TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          messageCount INTEGER NOT NULL DEFAULT 0,
          isPinned INTEGER NOT NULL DEFAULT 0,
          isArchived INTEGER NOT NULL DEFAULT 0,
          lastMessagePreview TEXT,
          synced INTEGER NOT NULL DEFAULT 0
        )
        ''',
      );
      await _createIndexIfNotExists(
        db,
        'idx_sessions_updated',
        'CREATE INDEX idx_sessions_updated ON sessions(updatedAt DESC)',
      );

      await _createTableIfNotExists(
        db,
        'messages',
        '''
        CREATE TABLE messages (
          id TEXT PRIMARY KEY,
          sessionId TEXT NOT NULL,
          role TEXT NOT NULL,
          text TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'sent',
          editedAt TEXT,
          agentId TEXT,
          thinking TEXT,
          actionCards TEXT,
          attachments TEXT,
          metadata TEXT,
          synced INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (sessionId) REFERENCES sessions(id) ON DELETE CASCADE
        )
        ''',
      );
      await _createIndexIfNotExists(
        db,
        'idx_messages_session',
        'CREATE INDEX idx_messages_session ON messages(sessionId, timestamp DESC)',
      );

      await _createTableIfNotExists(
        db,
        'agents',
        '''
        CREATE TABLE agents (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          avatarUrl TEXT,
          description TEXT,
          capabilities TEXT,
          defaultAutonomy TEXT NOT NULL DEFAULT 'suggest',
          isActive INTEGER NOT NULL DEFAULT 0,
          lastActiveAt TEXT,
          synced INTEGER NOT NULL DEFAULT 0
        )
        ''',
      );
    }

    if (oldVersion < 2 && newVersion >= 2) {
      await _addColumnIfMissing(db, 'agents', 'source', 'TEXT');
      await _createIndexIfNotExists(
        db,
        'idx_agents_last_active',
        'CREATE INDEX idx_agents_last_active ON agents(lastActiveAt DESC)',
      );
    }
  }

  Future<void> _createTableIfNotExists(
    DatabaseExecutor db,
    String tableName,
    String createSql,
  ) async {
    final exists = await _tableExists(db, tableName);
    if (!exists) {
      await db.execute(createSql);
    }
  }

  Future<void> _createIndexIfNotExists(
    DatabaseExecutor db,
    String indexName,
    String createSql,
  ) async {
    await db.execute(createSql.replaceFirst('CREATE INDEX', 'CREATE INDEX IF NOT EXISTS'));
  }

  Future<void> _addColumnIfMissing(
    DatabaseExecutor db,
    String tableName,
    String columnName,
    String columnDefinition,
  ) async {
    if (!await _columnExists(db, tableName, columnName)) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition',
      );
    }
  }

  Future<void> _validateSchema(DatabaseExecutor db) async {
    await _ensureTableExists(db, 'sessions');
    await _ensureTableExists(db, 'messages');
    await _ensureTableExists(db, 'agents');

    await _ensureColumnExists(db, 'sessions', 'id');
    await _ensureColumnExists(db, 'sessions', 'updatedAt');
    await _ensureColumnExists(db, 'messages', 'id');
    await _ensureColumnExists(db, 'messages', 'sessionId');
    await _ensureColumnExists(db, 'agents', 'id');
    await _ensureColumnExists(db, 'agents', 'source');

    await _ensureIndexExists(db, 'idx_sessions_updated');
    await _ensureIndexExists(db, 'idx_messages_session');
    await _ensureIndexExists(db, 'idx_agents_last_active');
  }

  Future<void> _ensureTableExists(DatabaseExecutor db, String tableName) async {
    if (!await _tableExists(db, tableName)) {
      throw StateError('Missing required table: $tableName');
    }
  }

  Future<void> _ensureColumnExists(
    DatabaseExecutor db,
    String tableName,
    String columnName,
  ) async {
    if (!await _columnExists(db, tableName, columnName)) {
      throw StateError('Missing required column: $tableName.$columnName');
    }
  }

  Future<void> _ensureIndexExists(DatabaseExecutor db, String indexName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
      [indexName],
    );
    if (result.isEmpty) {
      throw StateError('Missing required index: $indexName');
    }
  }

  Future<bool> _tableExists(DatabaseExecutor db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<bool> _columnExists(
    DatabaseExecutor db,
    String tableName,
    String columnName,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    for (final column in columns) {
      if (column['name'] == columnName) {
        return true;
      }
    }
    return false;
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Deletes the entire database file (useful for testing / logout).
  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await deleteDatabase(path);
    _database = null;
  }
}
