import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/data/local/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/sqflite_test_helper.dart';

void main() {
  initSqfliteFfi();

  group('DatabaseHelper', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper();
      await dbHelper.deleteDatabaseFile();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('should create the database with the correct version', () async {
      final db = await dbHelper.database;
      expect(db, isNotNull);
      final info = await db.getVersion();
      expect(info, equals(1));
    });

    test('should create sessions table with correct columns', () async {
      final db = await dbHelper.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='sessions'",
      );
      expect(result.length, 1);
    });

    test('should create messages table with correct columns', () async {
      final db = await dbHelper.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='messages'",
      );
      expect(result.length, 1);
    });

    test('should create agents table with correct columns', () async {
      final db = await dbHelper.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='agents'",
      );
      expect(result.length, 1);
    });

    test('should create indexes', () async {
      final db = await dbHelper.database;
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index'",
      );
      final names = indexes.map((r) => r['name'] as String).toList();
      expect(names, contains('idx_sessions_updated'));
      expect(names, contains('idx_messages_session'));
    });
  });
}
