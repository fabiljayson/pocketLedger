import 'package:sqflite/sqflite.dart';

import '../../../core/constants/payment_methods.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/diagnostics.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/expense.dart';

// ── Expense query model ──────────────────────────────────────────────────

enum ExpenseSort { newest, oldest, highestAmount, lowestAmount }

class ExpenseQuery {
  const ExpenseQuery({
    this.search,
    this.categoryId,
    this.paymentMethod,
    this.dateRange,
    this.sort = ExpenseSort.newest,
    this.limit,
    this.offset = 0,
  });

  final String? search;
  final int? categoryId;
  final PaymentMethod? paymentMethod;
  final DateRange? dateRange;
  final ExpenseSort sort;
  final int? limit;
  final int offset;

  ExpenseQuery copyWith({
    String? search,
    int? categoryId,
    PaymentMethod? paymentMethod,
    DateRange? dateRange,
    ExpenseSort? sort,
    int? limit,
    int? offset,
  }) => ExpenseQuery(
    search: search ?? this.search,
    categoryId: categoryId ?? this.categoryId,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    dateRange: dateRange ?? this.dateRange,
    sort: sort ?? this.sort,
    limit: limit ?? this.limit,
    offset: offset ?? this.offset,
  );

  bool get hasFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      categoryId != null ||
      paymentMethod != null ||
      dateRange != null;
}

// ── Expenses repository ──────────────────────────────────────────────────
//
// All queries are parameterized. Date filtering compares `yyyy-MM-dd` text,
// which is lexicographically chronological by construction.

class ExpensesRepository {
  const ExpensesRepository(this._db);

  final Database _db;

  ({List<String> where, List<Object?> args}) _buildWhere(ExpenseQuery query) {
    final where = <String>[];
    final args = <Object?>[];

    final search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      where.add('(title LIKE ? OR IFNULL(notes, \'\') LIKE ?)');
      final like = '%$search%';
      args.addAll([like, like]);
    }
    if (query.categoryId != null) {
      where.add('category_id = ?');
      args.add(query.categoryId);
    }
    if (query.paymentMethod != null) {
      where.add('payment_method = ?');
      args.add(query.paymentMethod!.dbValue);
    }
    if (query.dateRange != null) {
      where.add('date >= ? AND date < ?');
      args.add(toIsoDate(query.dateRange!.start));
      args.add(toIsoDate(query.dateRange!.endExclusive));
    }
    return (where: where, args: args);
  }

  static String _orderBy(ExpenseSort sort) => switch (sort) {
    ExpenseSort.newest => 'date DESC, id DESC',
    ExpenseSort.oldest => 'date ASC, id ASC',
    ExpenseSort.highestAmount => 'amount_fcfa DESC, date DESC, id DESC',
    ExpenseSort.lowestAmount => 'amount_fcfa ASC, date ASC, id ASC',
  };

  Future<List<Expense>> query(ExpenseQuery params) async {
    try {
      final (:where, :args) = _buildWhere(params);
      final rows = await _db.query(
        'expenses',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: _orderBy(params.sort),
        limit: params.limit,
        offset: params.offset > 0 ? params.offset : null,
      );
      return rows.map(Expense.fromMap).toList();
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'expenses',
        'query failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not load transactions.');
    }
  }

  Future<int> countMatching(ExpenseQuery params) async {
    final (:where, :args) = _buildWhere(params);
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS n FROM expenses${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}',
      args,
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<Expense> getById(int id) async {
    final rows = await _db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw const StorageException('Transaction not found.');
    return Expense.fromMap(rows.first);
  }

  /// Inserts an expense and returns its persisted id.
  Future<int> create(Expense expense) async {
    _validate(expense);
    try {
      return await _db.insert('expenses', expense.toMap());
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'expenses',
        'create failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not save the transaction.');
    }
  }

  Future<void> update(Expense expense) async {
    if (expense.id == null) {
      throw const ValidationException(
        'Transaction id is required for updates.',
      );
    }
    _validate(expense);
    try {
      final count = await _db.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      if (count == 0) throw const StorageException('Transaction not found.');
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'expenses',
        'update failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not update the transaction.');
    }
  }

  Future<void> delete(int id) async {
    try {
      final count = await _db.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) throw const StorageException('Transaction not found.');
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'expenses',
        'delete failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not delete the transaction.');
    }
  }

  void _validate(Expense expense) {
    if (expense.amountFcfa <= 0) {
      throw const ValidationException('Amount must be greater than zero.');
    }
    if (expense.title.trim().isEmpty) {
      throw const ValidationException('A title is required.');
    }
  }
}
