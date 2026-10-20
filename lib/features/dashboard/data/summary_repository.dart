import 'package:sqflite/sqflite.dart';

import '../../../core/utils/date_utils.dart';

// ── Summary aggregation repository ───────────────────────────────────────
//
// All dashboard numbers are computed by SQLite from persisted rows — never
// by summing lists in the UI. Each period is a half-open `date` window so
// month/year boundaries and leap years cannot skew totals.

class SummaryRepository {
  const SummaryRepository(this._db);

  final Database _db;

  /// `SUM(amount)` and `COUNT(*)` for expenses in [range], optionally for
  /// one category.
  Future<({int totalFcfa, int count})> totalsForRange(
    DateRange range, {
    int? categoryId,
  }) async {
    final args = <Object?>[
      toIsoDate(range.start),
      toIsoDate(range.endExclusive),
    ];
    var sql =
        'SELECT IFNULL(SUM(amount_fcfa), 0) AS total, COUNT(*) AS n '
        'FROM expenses WHERE date >= ? AND date < ?';
    if (categoryId != null) {
      sql += ' AND category_id = ?';
      args.add(categoryId);
    }
    final rows = await _db.rawQuery(sql, args);
    return (
      totalFcfa: (rows.first['total'] as int?) ?? 0,
      count: (rows.first['n'] as int?) ?? 0,
    );
  }

  /// Per-category totals inside [range], descending by amount. Includes the
  /// category's name for display without a second query.
  Future<
    List<
      ({
        int categoryId,
        String name,
        String colorHex,
        String iconKey,
        int totalFcfa,
      })
    >
  >
  categoryTotals(DateRange range) async {
    final rows = await _db.rawQuery(
      'SELECT e.category_id AS category_id, c.name AS name, '
      'c.color_hex AS color_hex, c.icon_key AS icon_key, '
      'SUM(e.amount_fcfa) AS total '
      'FROM expenses e JOIN categories c ON c.id = e.category_id '
      'WHERE e.date >= ? AND e.date < ? '
      'GROUP BY e.category_id '
      'ORDER BY total DESC',
      [toIsoDate(range.start), toIsoDate(range.endExclusive)],
    );
    return [
      for (final row in rows)
        (
          categoryId: row['category_id'] as int,
          name: row['name'] as String,
          colorHex: row['color_hex'] as String? ?? '#64748B',
          iconKey: row['icon_key'] as String? ?? 'other',
          totalFcfa: (row['total'] as int?) ?? 0,
        ),
    ];
  }

  /// Daily totals inside [range] (one entry per day with expenses).
  Future<List<({DateTime day, int totalFcfa})>> dailyTotals(
    DateRange range,
  ) async {
    final rows = await _db.rawQuery(
      'SELECT date, SUM(amount_fcfa) AS total FROM expenses '
      'WHERE date >= ? AND date < ? GROUP BY date ORDER BY date ASC',
      [toIsoDate(range.start), toIsoDate(range.endExclusive)],
    );
    return [
      for (final row in rows)
        (
          day: DateTime.parse(row['date'] as String),
          totalFcfa: (row['total'] as int?) ?? 0,
        ),
    ];
  }

  /// Month totals for the last [count] months (ascending), one entry per
  /// month, including months without expenses (total 0).
  Future<List<({String monthKey, DateTime month, int totalFcfa})>>
  monthlyTotals(int count, DateTime now) async {
    final months = lastMonths(count, now);
    final result = <({String monthKey, DateTime month, int totalFcfa})>[];
    for (final month in months) {
      final range = DateRange(
        start: month,
        endExclusive: addMonthsClamped(month, 1),
      );
      final totals = await totalsForRange(range);
      result.add((
        monthKey: monthKeyOf(month),
        month: month,
        totalFcfa: totals.totalFcfa,
      ));
    }
    return result;
  }

  /// Most recent [limit] expenses for the dashboard feed.
  Future<List<Map<String, Object?>>> recentExpenses(int limit) {
    return _db.query('expenses', orderBy: 'date DESC, id DESC', limit: limit);
  }
}
