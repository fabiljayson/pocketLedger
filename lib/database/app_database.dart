import 'dart:io' show File;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants/categories.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/diagnostics.dart';
import 'migrations.dart';

// ── Application database ─────────────────────────────────────────────────

const String databaseFileName = 'pocket_ledger.db';

Database? _override;

/// Development/testing hook. Pass a database to force (used by widget tests
/// with an in-memory FFI database); pass `null` to restore normal behavior.
@visibleForTesting
void overrideDatabase(Database? db) {
  _override = db;
}

Future<Database> _defaultDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  return openDatabase(
    p.join(dir.path, databaseFileName),
    version: schemaVersion,
    onConfigure: configureDatabase,
    onCreate: createDatabase,
    onUpgrade: upgradeDatabase,
  );
}

/// Opens (and if needed upgrades) the application database.
Future<Database> openAppDatabase() async {
  if (_override != null) return _override!;
  try {
    return await _defaultDatabase();
  } catch (error, stackTrace) {
    logDiagnostic(
      'database',
      'open failed',
      error: error,
      stackTrace: stackTrace,
    );
    throw const StorageException(
      'Could not open the local database. Please restart the app.',
    );
  }
}

/// Public so tests can exercise the exact production open path.
Future<void> configureDatabase(Database db) async {
  // SQLite requires this pragma per-connection for foreign keys to apply.
  await db.execute('PRAGMA foreign_keys = ON');
}

Future<void> createDatabase(Database db, int version) async {
  await _createV1Schema(db);
  await runMigrations(db, 1, version);
}

/// Creates only the v1 schema (no migrations). Exposed for upgrade tests.
Future<void> createV1OnlySchema(Database db, int version) =>
    _createV1Schema(db);

Future<void> upgradeDatabase(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  await runMigrations(db, oldVersion, newVersion);
}

// ── Schema ───────────────────────────────────────────────────────────────

Future<void> _createV1Schema(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      icon_key TEXT NOT NULL,
      color_hex TEXT NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE UNIQUE INDEX idx_categories_name ON categories (name COLLATE NOCASE)
  ''');

  await db.execute('''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount_fcfa INTEGER NOT NULL CHECK (amount_fcfa > 0),
      category_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      date TEXT NOT NULL,
      payment_method TEXT NOT NULL,
      notes TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
    )
  ''');
  await db.execute('CREATE INDEX idx_expenses_date ON expenses (date)');
  await db.execute(
    'CREATE INDEX idx_expenses_category ON expenses (category_id)',
  );
  await db.execute(
    'CREATE INDEX idx_expenses_category_date ON expenses (category_id, date)',
  );

  await db.execute('''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');
}

// ── Default category seeding ─────────────────────────────────────────────

/// Inserts the default categories exactly once. Runs inside the creation
/// transaction; the unique-name index guarantees no duplicates even if
/// invoked twice.
Future<void> seedDefaultCategories(DatabaseExecutor db) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final batch = db.batch();
  for (final seed in seedCategories) {
    batch.insert('categories', {
      'name': seed.name,
      'icon_key': seed.key,
      'color_hex': seed.colorHex,
      'is_default': 1,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  await batch.commit(noResult: true);
}

/// Deletes the database file. Used only by tests and the "reset data"
/// settings action, never by ordinary application flows.
Future<void> deleteAppDatabaseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, databaseFileName));
  if (await file.exists()) await file.delete();
}
