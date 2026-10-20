import 'package:sqflite/sqflite.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/diagnostics.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/budget.dart';

// ── Budgets repository ───────────────────────────────────────────────────
//
// Aggregation uses a half-open `date` window built from the month key so
// month/year boundaries and leap years are handled by [monthRangeForKey].

class BudgetsRepository {
  const BudgetsRepository(this._db);

  final Database _db;

  Future<List<Budget>> getForMonth(String monthKey) async {
    try {
      final rows = await _db.query(
        'budgets',
        where: 'month_key = ?',
        whereArgs: [monthKey],
        orderBy: 'category_id ASC',
      );
      return rows.map(Budget.fromMap).toList();
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'budgets',
        'getForMonth failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not load budgets.');
    }
  }

  Future<List<Budget>> getAll() async {
    try {
      final rows = await _db.query('budgets', orderBy: 'month_key DESC');
      return rows.map(Budget.fromMap).toList();
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'budgets',
        'getAll failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not load budgets.');
    }
  }

  /// Creates or updates the budget for (monthKey, scope). [categoryId] null
  /// targets the total monthly budget.
  Future<Budget> upsert({
    required String monthKey,
    required int? categoryId,
    required int amountFcfa,
  }) async {
    if (amountFcfa < 0) {
      throw const ValidationException('Budget amount cannot be negative.');
    }
    monthRangeForKey(monthKey); // validates the key format
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final existing = await _db.query(
        'budgets',
        where: 'month_key = ? AND IFNULL(category_id, 0) = IFNULL(?, 0)',
        whereArgs: [monthKey, categoryId],
        limit: 1,
      );
      final Map<String, Object?> values = {
        'month_key': monthKey,
        'category_id': categoryId,
        'amount_fcfa': amountFcfa,
        'created_at': now,
        'updated_at': now,
      };
      if (existing.isEmpty) {
        final id = await _db.insert('budgets', values);
        return Budget.fromMap({...values, 'id': id});
      }
      await _db.update(
        'budgets',
        {'amount_fcfa': amountFcfa, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      return Budget.fromMap({
        ...existing.first,
        'amount_fcfa': amountFcfa,
        'updated_at': now,
      });
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'budgets',
        'upsert failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not save the budget.');
    }
  }

  Future<void> delete(int id) async {
    try {
      final count = await _db.delete(
        'budgets',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) throw const StorageException('Budget not found.');
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'budgets',
        'delete failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not delete the budget.');
    }
  }

  /// Sums expenses of [monthKey], optionally restricted to one category.
  Future<int> spentInMonth(String monthKey, {int? categoryId}) async {
    final range = monthRangeForKey(monthKey);
    final args = <Object?>[
      toIsoDate(range.start),
      toIsoDate(range.endExclusive),
    ];
    var sql =
        'SELECT IFNULL(SUM(amount_fcfa), 0) AS total FROM expenses '
        'WHERE date >= ? AND date < ?';
    if (categoryId != null) {
      sql += ' AND category_id = ?';
      args.add(categoryId);
    }
    final rows = await _db.rawQuery(sql, args);
    return (rows.first['total'] as int?) ?? 0;
  }

  /// Per-category totals for [monthKey] in one pass. Returns
  /// `categoryId -> spentFcfa`.
  Future<Map<int, int>> categoryTotalsForMonth(String monthKey) async {
    final range = monthRangeForKey(monthKey);
    final rows = await _db.rawQuery(
      'SELECT category_id, SUM(amount_fcfa) AS total FROM expenses '
      'WHERE date >= ? AND date < ? GROUP BY category_id',
      [toIsoDate(range.start), toIsoDate(range.endExclusive)],
    );
    return {
      for (final row in rows)
        row['category_id'] as int: (row['total'] as int?) ?? 0,
    };
  }

  /// Builds [BudgetProgress] for every budget of [monthKey], pairing each
  /// with its actual spending.
  Future<List<BudgetProgress>> progressForMonth(String monthKey) async {
    final budgets = await getForMonth(monthKey);
    if (budgets.isEmpty) return const [];
    final totals = await categoryTotalsForMonth(monthKey);
    var totalSpent = 0;
    for (final entry in totals.entries) {
      totalSpent += entry.value;
    }
    return [
      for (final budget in budgets)
        BudgetProgress(
          budget: budget,
          spentFcfa: budget.categoryId == null
              ? totalSpent
              : (totals[budget.categoryId] ?? 0),
        ),
    ];
  }
}
