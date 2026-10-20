import 'package:sqflite/sqflite.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/diagnostics.dart';
import '../domain/category.dart';

// ── Categories repository ────────────────────────────────────────────────

class CategoriesRepository {
  const CategoriesRepository(this._db);

  final Database _db;

  Future<List<Category>> getAll() async {
    try {
      final rows = await _db.query(
        'categories',
        orderBy: 'name COLLATE NOCASE ASC',
      );
      return rows.map(Category.fromMap).toList();
    } catch (error, stackTrace) {
      logDiagnostic(
        'categories',
        'getAll failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not load categories.');
    }
  }

  Future<Category> getById(int id) async {
    final rows = await _db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const StorageException('Category not found.');
    }
    return Category.fromMap(rows.first);
  }

  Future<Category> create({
    required String name,
    required String iconKey,
    required String colorHex,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Category name is required.');
    }
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = await _db.insert('categories', {
        'name': trimmed,
        'icon_key': iconKey,
        'color_hex': colorHex,
        'is_default': 0,
        'created_at': now,
        'updated_at': now,
      });
      return Category(
        id: id,
        name: trimmed,
        iconKey: iconKey,
        colorHex: colorHex,
        isDefault: false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'categories',
        'create failed',
        error: error,
        stackTrace: stackTrace,
      );
      final conflict = error.isUniqueConstraintError();
      if (conflict) {
        throw ValidationException(
          'A category named "$trimmed" already exists.',
        );
      }
      throw const StorageException('Could not save the category.');
    }
  }

  Future<void> rename(int id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Category name is required.');
    }
    try {
      final count = await _db.update(
        'categories',
        {'name': trimmed, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) throw const StorageException('Category not found.');
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'categories',
        'rename failed',
        error: error,
        stackTrace: stackTrace,
      );
      final conflict = error.isUniqueConstraintError();
      if (conflict) {
        throw ValidationException(
          'A category named "$trimmed" already exists.',
        );
      }
      throw const StorageException('Could not update the category.');
    }
  }

  /// Deletes a custom category. Fails with a clear message when expenses or
  /// budgets still reference it (FK RESTRICT / CASCADE is the last resort).
  Future<void> delete(int id, {required bool isDefault}) async {
    if (isDefault) {
      throw const ValidationException('Default categories cannot be deleted.');
    }
    try {
      final refs = await _db.rawQuery(
        'SELECT (SELECT COUNT(*) FROM expenses WHERE category_id = ?) '
        'AS expense_count, '
        '(SELECT COUNT(*) FROM recurring_definitions WHERE category_id = ?) '
        'AS recurring_count',
        [id, id],
      );
      final expenseCount = refs.first['expense_count'] as int? ?? 0;
      final recurringCount = refs.first['recurring_count'] as int? ?? 0;
      if (expenseCount > 0 || recurringCount > 0) {
        throw ValidationException(
          'This category is used by $expenseCount expense(s) and '
          '$recurringCount recurring definition(s). Reassign them first.',
        );
      }
      final count = await _db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) throw const StorageException('Category not found.');
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'categories',
        'delete failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException(
        'Could not delete the category. It may still be in use.',
      );
    }
  }
}
