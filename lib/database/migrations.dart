import 'package:sqflite/sqflite.dart';

// ── Migration framework ──────────────────────────────────────────────────
//
// Versioned migrations, applied in ascending order inside the `onUpgrade`
// transaction provided by sqflite. Migrations must only ever *add or
// transform* data — never drop user records.

const int schemaVersion = 2;

typedef MigrationStep = Future<void> Function(DatabaseExecutor txn);

/// Maps "upgrade to version N" to its migration function. Version 1 is the
/// base schema (created in `onCreate`), so entries start at 2.
final Map<int, MigrationStep> migrations = {2: _migrateV1ToV2};

Future<void> runMigrations(
  DatabaseExecutor txn,
  int fromVersion,
  int toVersion,
) async {
  for (var version = fromVersion + 1; version <= toVersion; version++) {
    final step = migrations[version];
    if (step != null) await step(txn);
  }
}

// ── v1 → v2 ──────────────────────────────────────────────────────────────
//
// v1 stored core data: categories, expenses, settings. v2 introduces monthly
// budgets, recurring definitions and idempotent occurrences, plus supporting
// indexes. Existing rows are untouched.

Future<void> _migrateV1ToV2(DatabaseExecutor txn) async {
  // Recurring templates are created first so the new expenses column can
  // reference them.
  await txn.execute('''
    CREATE TABLE recurring_definitions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount_fcfa INTEGER NOT NULL CHECK (amount_fcfa > 0),
      category_id INTEGER NOT NULL,
      payment_method TEXT NOT NULL,
      notes TEXT,
      frequency TEXT NOT NULL,
      start_date TEXT NOT NULL,
      next_due_date TEXT NOT NULL,
      end_date TEXT,
      active INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
    )
  ''');

  await txn.execute('''
    ALTER TABLE expenses
    ADD COLUMN recurring_definition_id INTEGER
    REFERENCES recurring_definitions (id) ON DELETE SET NULL
  ''');

  await txn.execute('''
    CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      month_key TEXT NOT NULL,
      category_id INTEGER REFERENCES categories (id) ON DELETE CASCADE,
      amount_fcfa INTEGER NOT NULL CHECK (amount_fcfa >= 0),
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
    )
  ''');
  // NULL category_id means the total monthly budget; SQLite treats NULLs as
  // distinct in UNIQUE constraints, so enforce scope with an expression index.
  await txn.execute('''
    CREATE UNIQUE INDEX idx_budgets_scope
    ON budgets (month_key, IFNULL(category_id, 0))
  ''');

  await txn.execute('''
    CREATE TABLE recurring_occurrences (
      id TEXT PRIMARY KEY,
      recurring_definition_id INTEGER NOT NULL,
      due_date TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      UNIQUE (recurring_definition_id, due_date),
      FOREIGN KEY (recurring_definition_id) REFERENCES recurring_definitions (id) ON DELETE CASCADE
    )
  ''');
  await txn.execute(
    'CREATE INDEX idx_occurrences_due ON recurring_occurrences (due_date)',
  );

  await txn.execute('''
    CREATE INDEX idx_expenses_definition
    ON expenses (recurring_definition_id)
  ''');
}
