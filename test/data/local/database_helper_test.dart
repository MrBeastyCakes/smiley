import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/data/local/database_helper.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/sqflite_test_helper.dart';

void main() {
  initSqfliteFfi();

  group('DatabaseHelper', () {
    late DatabaseHelper dbHelper;
    const dbName = 'db_helper_test';

    setUp(() async {
      dbHelper = DatabaseHelper.test(dbName);
      await dbHelper.deleteDatabaseFile();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('create-from-scratch builds latest schema and version', () async {
      final db = await dbHelper.database;
      expect(db, isNotNull);

      final version = await db.getVersion();
      expect(version, equals(2));

      await _expectTableExists(db, 'sessions');
      await _expectTableExists(db, 'messages');
      await _expectTableExists(db, 'agents');

      await _expectColumnExists(db, 'agents', 'source');

      await _expectIndexExists(db, 'idx_sessions_updated');
      await _expectIndexExists(db, 'idx_messages_session');
      await _expectIndexExists(db, 'idx_agents_last_active');
    });

    test('upgrade-from-version-1 applies versioned migrations', () async {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, dbName);

      final legacyDb = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
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
          await db.execute(
            'CREATE INDEX idx_sessions_updated ON sessions(updatedAt DESC)',
          );

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
          await db.execute(
            'CREATE INDEX idx_messages_session ON messages(sessionId, timestamp DESC)',
          );

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

          await db.insert('agents', {
            'id': 'agent-1',
            'name': 'Legacy Agent',
            'defaultAutonomy': 'suggest',
            'isActive': 0,
            'synced': 0,
          });
        },
      );
      await legacyDb.close();

      final db = await dbHelper.database;

      final version = await db.getVersion();
      expect(version, equals(2));

      await _expectColumnExists(db, 'agents', 'source');
      await _expectIndexExists(db, 'idx_agents_last_active');

      final agentRows = await db.query(
        'agents',
        where: 'id = ?',
        whereArgs: ['agent-1'],
      );
      expect(agentRows, hasLength(1));
    });
  });
}

Future<void> _expectTableExists(Database db, String tableName) async {
  final result = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
    [tableName],
  );
  expect(result, isNotEmpty);
}

Future<void> _expectColumnExists(
  Database db,
  String tableName,
  String columnName,
) async {
  final columns = await db.rawQuery('PRAGMA table_info($tableName)');
  final names = columns.map((row) => row['name'] as String).toList();
  expect(names, contains(columnName));
}

Future<void> _expectIndexExists(Database db, String indexName) async {
  final indexes = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
    [indexName],
  );
  expect(indexes, isNotEmpty);
}
