import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initializes sqflite for desktop (ffi) testing.
/// Uses no-isolate mode to avoid database-locked errors in parallel tests.
void initSqfliteFfi() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
}
