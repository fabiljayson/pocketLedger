import 'package:pocket_ledger/database/app_database.dart';
import 'package:pocket_ledger/database/migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ── In-memory test database ──────────────────────────────────────────────

bool _factoryInitialized = false;

/// Initializes the FFI SQLite backend once for the test process.
void initTestDatabaseFactory() {
  if (_factoryInitialized) return;
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  _factoryInitialized = true;
}

/// Opens an isolated in-memory database through the exact production
/// configure/create/upgrade hooks. `singleInstance: false` guarantees each
/// call gets a fresh, independent database.
Future<Database> createTestDatabase({int? version}) async {
  initTestDatabaseFactory();
  final db = await databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: version ?? schemaVersion,
      singleInstance: false,
      onConfigure: configureDatabase,
      onCreate: createDatabase,
      onUpgrade: upgradeDatabase,
    ),
  );
  await seedDefaultCategories(db);
  return db;
}

/// Creates a database at the raw v1 schema (no migrations applied) with
/// default categories seeded, to exercise the v1→v2 upgrade path.
Future<Database> createV1TestDatabase() async {
  initTestDatabaseFactory();
  final db = await databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      singleInstance: false,
      onConfigure: configureDatabase,
      onCreate: createV1OnlySchema,
    ),
  );
  await seedDefaultCategories(db);
  return db;
}
