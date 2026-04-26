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
  static const int _dbVersion = 1;

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
    await db.execute('''
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
    ''');

    await db.execute('''
      CREATE INDEX idx_sessions_updated ON sessions(updatedAt DESC)
    ''');

    await db.execute('''
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
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_session ON messages(sessionId, timestamp DESC)
    ''');

    await db.execute('''
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
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here.
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
