import 'package:sqflite/sqflite.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/diagnostics.dart';

// ── Settings repository ──────────────────────────────────────────────────
//
// Small key-value store for preferences that must survive restarts. Only
// non-sensitive display preferences belong here — never financial records.

class SettingsRepository {
  const SettingsRepository(this._db);

  final Database _db;

  Future<String?> get(String key) async {
    try {
      final rows = await _db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      return rows.isEmpty ? null : rows.first['value'] as String?;
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'settings',
        'get failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not load settings.');
    }
  }

  Future<void> set(String key, String value) async {
    try {
      await _db.insert('settings', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'settings',
        'set failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not save the setting.');
    }
  }

  Future<Map<String, String>> getAll() async {
    final rows = await _db.query('settings');
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
  }
}
