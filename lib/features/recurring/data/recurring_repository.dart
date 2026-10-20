import 'package:sqflite/sqflite.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/diagnostics.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/recurring_definition.dart';

// ── Recurring repository ─────────────────────────────────────────────────
//
// [recordOccurrence] is the idempotency guarantee: the
// (definition, due_date) unique index means processing the same due date
// twice can never create two expenses. The caller's transaction contains the
// expense insert, the occurrence marker and the next-due advance, so a
// failure rolls back all three together.

class RecurringRepository {
  const RecurringRepository(this._db);

  final Database _db;

  Future<List<RecurringDefinition>> getAll() async {
    try {
      final rows = await _db.query(
        'recurring_definitions',
        orderBy: 'next_due_date ASC, id ASC',
      );
      return rows.map(RecurringDefinition.fromMap).toList();
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'recurring',
        'getAll failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not load recurring expenses.');
    }
  }

  Future<List<RecurringDefinition>> getActiveDueOnOrBefore(DateTime day) async {
    final rows = await _db.query(
      'recurring_definitions',
      where: 'active = 1 AND next_due_date <= ?',
      whereArgs: [toIsoDate(day)],
      orderBy: 'next_due_date ASC',
    );
    return rows.map(RecurringDefinition.fromMap).toList();
  }

  Future<RecurringDefinition> getById(int id) async {
    final rows = await _db.query(
      'recurring_definitions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const StorageException('Recurring definition not found.');
    }
    return RecurringDefinition.fromMap(rows.first);
  }

  Future<int> create(RecurringDefinition definition) async {
    _validate(definition);
    try {
      return await _db.insert('recurring_definitions', definition.toMap());
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'recurring',
        'create failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not save the recurring expense.');
    }
  }

  Future<void> update(RecurringDefinition definition) async {
    if (definition.id == null) {
      throw const ValidationException('Id is required for updates.');
    }
    _validate(definition);
    try {
      final count = await _db.update(
        'recurring_definitions',
        definition.toMap(),
        where: 'id = ?',
        whereArgs: [definition.id],
      );
      if (count == 0) {
        throw const StorageException('Recurring definition not found.');
      }
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'recurring',
        'update failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not update the recurring expense.');
    }
  }

  Future<void> delete(int id) async {
    try {
      // Expenses recorded from this definition keep existing; the FK
      // ON DELETE SET NULL detaches them without losing records.
      final count = await _db.delete(
        'recurring_definitions',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const StorageException('Recurring definition not found.');
      }
    } on DatabaseException catch (error, stackTrace) {
      logDiagnostic(
        'recurring',
        'delete failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageException('Could not delete the recurring expense.');
    }
  }

  /// Whether an occurrence for (definitionId, dueDate) has been recorded.
  Future<bool> occurrenceExists(int definitionId, DateTime dueDate) async {
    final rows = await _db.query(
      'recurring_occurrences',
      where: 'recurring_definition_id = ? AND due_date = ?',
      whereArgs: [definitionId, toIsoDate(dueDate)],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Idempotently records one due occurrence: inserts the real expense, the
  /// occurrence marker and advances `next_due_date`, all atomically. Returns
  /// the new expense id, or `null` when the occurrence already existed
  /// (duplicate processing is a safe no-op).
  Future<int?> recordOccurrence({
    required RecurringDefinition definition,
    required DateTime dueDate,
  }) async {
    if (definition.id == null) {
      throw const ValidationException('Definition id is required.');
    }
    return _db.transaction<int?>((txn) async {
      final marker = '${definition.id}:${toIsoDate(dueDate)}';
      final existing = await txn.query(
        'recurring_occurrences',
        where: 'id = ?',
        whereArgs: [marker],
        limit: 1,
      );
      if (existing.isNotEmpty) return null;

      final now = DateTime.now();
      final expenseId = await txn.insert('expenses', {
        'amount_fcfa': definition.amountFcfa,
        'category_id': definition.categoryId,
        'title': definition.title,
        'date': toIsoDate(dueDate),
        'payment_method': definition.paymentMethod.dbValue,
        'notes': definition.notes,
        'recurring_definition_id': definition.id,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
      await txn.insert('recurring_occurrences', {
        'id': marker,
        'recurring_definition_id': definition.id,
        'due_date': toIsoDate(dueDate),
        'created_at': now.millisecondsSinceEpoch,
      });

      var nextDue = definition.frequency.nextOccurrence(dueDate);
      while (nextDue.isBefore(dueDate)) {
        // Defensive guard: never move the due date backwards.
        nextDue = definition.frequency.nextOccurrence(nextDue);
      }
      await txn.update(
        'recurring_definitions',
        {
          'next_due_date': toIsoDate(nextDue),
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [definition.id],
      );
      return expenseId;
    });
  }

  /// Resets `next_due_date` to the earliest unprocessed due date after a
  /// template edit (e.g. frequency or start-date change). Idempotent.
  Future<void> recomputeNextDue(int definitionId) async {
    final definition = await getById(definitionId);
    var candidate = definition.startDate.isBefore(definition.nextDueDate)
        ? definition.startDate
        : definition.nextDueDate;
    // Skip due dates that were already recorded.
    while (await occurrenceExists(definitionId, candidate)) {
      candidate = definition.frequency.nextOccurrence(candidate);
    }
    await _db.update(
      'recurring_definitions',
      {
        'next_due_date': toIsoDate(candidate),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [definitionId],
    );
  }

  void _validate(RecurringDefinition definition) {
    if (definition.amountFcfa <= 0) {
      throw const ValidationException('Amount must be greater than zero.');
    }
    if (definition.title.trim().isEmpty) {
      throw const ValidationException('A title is required.');
    }
    final end = definition.endDate;
    if (end != null && end.isBefore(definition.startDate)) {
      throw const ValidationException(
        'The end date cannot be before the start date.',
      );
    }
    if (definition.nextDueDate.isBefore(definition.startDate)) {
      throw const ValidationException(
        'The next due date cannot be before the start date.',
      );
    }
    if (end != null && definition.nextDueDate.isAfter(end)) {
      throw const ValidationException(
        'The next due date is after the end date.',
      );
    }
  }
}
