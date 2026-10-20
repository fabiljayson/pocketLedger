import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/constants/payment_methods.dart';
import 'package:pocket_ledger/core/errors/app_exception.dart';
import 'package:pocket_ledger/core/utils/date_utils.dart';
import 'package:pocket_ledger/features/categories/data/categories_repository.dart';
import 'package:pocket_ledger/features/expenses/data/expenses_repository.dart';
import 'package:pocket_ledger/features/recurring/data/recurring_repository.dart';
import 'package:pocket_ledger/features/recurring/domain/recurring_definition.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late RecurringRepository recurring;
  late ExpensesRepository expenses;

  setUp(() async {
    db = await createTestDatabase();
    recurring = RecurringRepository(db);
    expenses = ExpensesRepository(db);
  });

  tearDown(() async => db.close());

  Future<int> foodCategoryId() async {
    final all = await CategoriesRepository(db).getAll();
    return all.firstWhere((c) => c.name == 'Food and groceries').id;
  }

  Future<RecurringDefinition> makeDefinition({
    RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
    DateTime? startDate,
    DateTime? endDate,
    int amountFcfa = 5000,
  }) async {
    final start = startDate ?? DateTime(2026, 1, 5);
    return RecurringDefinition(
      title: 'Monthly provisions',
      amountFcfa: amountFcfa,
      categoryId: await foodCategoryId(),
      paymentMethod: PaymentMethod.cash,
      frequency: frequency,
      startDate: start,
      nextDueDate: start,
      endDate: endDate,
      active: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  group('definition CRUD', () {
    test('creates and persists definitions', () async {
      final id = await recurring.create(await makeDefinition());
      final loaded = await recurring.getById(id);
      expect(loaded.title, 'Monthly provisions');
      expect(loaded.frequency, RecurrenceFrequency.monthly);
      expect(loaded.startDate, DateTime(2026, 1, 5));
    });

    test('validates amounts, dates and titles', () async {
      final invalidAmount = (await makeDefinition()).copyWith(amountFcfa: 0);
      await expectLater(
        recurring.create(invalidAmount),
        throwsA(isA<ValidationException>()),
      );

      final invalidEnd = (await makeDefinition()).copyWith(
        startDate: DateTime(2026, 1, 5),
        endDate: DateTime(2025, 12, 31),
      );
      await expectLater(
        recurring.create(invalidEnd),
        throwsA(isA<ValidationException>()),
      );
    });

    test('pausing sets active false without deleting history', () async {
      final id = await recurring.create(await makeDefinition());
      final definition = await recurring.getById(id);
      await recurring.recordOccurrence(
        definition: definition,
        dueDate: DateTime(2026, 1, 5),
      );

      await recurring.update(definition.copyWith(active: false));
      final paused = await recurring.getById(id);
      expect(paused.active, isFalse);
      expect((await expenses.query(const ExpenseQuery())).length, 1);
    });

    test(
      'deleting a definition detaches but keeps recorded expenses',
      () async {
        final id = await recurring.create(await makeDefinition());
        final definition = await recurring.getById(id);
        await recurring.recordOccurrence(
          definition: definition,
          dueDate: DateTime(2026, 1, 5),
        );

        await recurring.delete(id);
        final remaining = await expenses.query(const ExpenseQuery());
        expect(remaining.single.recurringDefinitionId, isNull);
        expect(remaining.single.amountFcfa, 5000);
      },
    );
  });

  group('idempotent occurrence processing', () {
    test('recording twice creates exactly one expense', () async {
      final id = await recurring.create(await makeDefinition());
      final definition = await recurring.getById(id);
      final due = DateTime(2026, 1, 5);

      final first = await recurring.recordOccurrence(
        definition: definition,
        dueDate: due,
      );
      final second = await recurring.recordOccurrence(
        definition: definition,
        dueDate: due,
      );

      expect(first, isNotNull);
      expect(second, isNull);
      final all = await expenses.query(const ExpenseQuery());
      expect(all.length, 1);
      expect(all.single.date, due);
      expect(all.single.recurringDefinitionId, id);
    });

    test('advances next_due_date only after recording', () async {
      final id = await recurring.create(await makeDefinition());
      var definition = await recurring.getById(id);
      expect(definition.nextDueDate, DateTime(2026, 1, 5));

      await recurring.recordOccurrence(
        definition: definition,
        dueDate: DateTime(2026, 1, 5),
      );
      definition = await recurring.getById(id);
      expect(definition.nextDueDate, DateTime(2026, 2, 5));

      await recurring.recordOccurrence(
        definition: definition,
        dueDate: DateTime(2026, 2, 5),
      );
      definition = await recurring.getById(id);
      expect(definition.nextDueDate, DateTime(2026, 3, 5));
    });

    test('catches up missed periods one occurrence at a time', () async {
      final id = await recurring.create(await makeDefinition());
      var definition = await recurring.getById(id);
      // "Today" is five months later: process each missed due date.
      final today = DateTime(2026, 6, 10);
      var guard = 0;
      while (definition.nextDueDate.isBefore(today) && guard < 24) {
        await recurring.recordOccurrence(
          definition: definition,
          dueDate: definition.nextDueDate,
        );
        definition = await recurring.getById(id);
        guard++;
      }
      expect(guard, 6); // Jan–Jun due dates
      final all = await expenses.query(
        const ExpenseQuery(sort: ExpenseSort.oldest),
      );
      expect(all.map((e) => toIsoDate(e.date)).toList(), [
        '2026-01-05',
        '2026-02-05',
        '2026-03-05',
        '2026-04-05',
        '2026-05-05',
        '2026-06-05',
      ]);
      expect(definition.nextDueDate, DateTime(2026, 7, 5));
    });

    test('month-end schedules clamp and stay clamped (Jan 31)', () async {
      final id = await recurring.create(
        await makeDefinition(startDate: DateTime(2026, 1, 31)),
      );
      var definition = await recurring.getById(id);
      final dues = <DateTime>[];
      for (var i = 0; i < 5; i++) {
        final due = definition.nextDueDate;
        dues.add(due);
        await recurring.recordOccurrence(definition: definition, dueDate: due);
        definition = await recurring.getById(id);
      }
      expect(dues.map(toIsoDate).toList(), [
        '2026-01-31',
        '2026-02-28',
        '2026-03-28',
        '2026-04-28',
        '2026-05-28',
      ]);
    });

    test('yearly leap-day schedule skips non-leap years (Feb 29)', () async {
      final id = await recurring.create(
        await makeDefinition(
          frequency: RecurrenceFrequency.yearly,
          startDate: DateTime(2024, 2, 29),
        ),
      );
      var definition = await recurring.getById(id);
      final dues = <DateTime>[];
      for (var i = 0; i < 3; i++) {
        final due = definition.nextDueDate;
        dues.add(due);
        await recurring.recordOccurrence(definition: definition, dueDate: due);
        definition = await recurring.getById(id);
      }
      expect(dues.map(toIsoDate).toList(), [
        '2024-02-29',
        '2025-02-28',
        '2026-02-28',
      ]);
    });

    test('daily and weekly schedules advance by fixed steps', () async {
      final daily = await recurring.create(
        await makeDefinition(
          frequency: RecurrenceFrequency.daily,
          startDate: DateTime(2026, 3, 1),
        ),
      );
      var d = await recurring.getById(daily);
      await recurring.recordOccurrence(definition: d, dueDate: d.nextDueDate);
      d = await recurring.getById(daily);
      expect(d.nextDueDate, DateTime(2026, 3, 2));

      final weekly = await recurring.create(
        await makeDefinition(
          frequency: RecurrenceFrequency.weekly,
          startDate: DateTime(2026, 3, 1),
        ),
      );
      var w = await recurring.getById(weekly);
      await recurring.recordOccurrence(definition: w, dueDate: w.nextDueDate);
      w = await recurring.getById(weekly);
      expect(w.nextDueDate, DateTime(2026, 3, 8));
    });

    test('does not produce occurrences past the end date', () async {
      final id = await recurring.create(
        await makeDefinition(
          frequency: RecurrenceFrequency.daily,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 3),
        ),
      );
      var definition = await recurring.getById(id);
      final today = DateTime(2026, 1, 10);
      var guard = 0;
      while (definition.active &&
          !definition.nextDueDate.isAfter(today) &&
          (definition.endDate == null ||
              !definition.nextDueDate.isAfter(definition.endDate!)) &&
          guard < 10) {
        await recurring.recordOccurrence(
          definition: definition,
          dueDate: definition.nextDueDate,
        );
        definition = await recurring.getById(id);
        guard++;
      }
      final all = await expenses.query(
        const ExpenseQuery(sort: ExpenseSort.oldest),
      );
      expect(all.map((e) => toIsoDate(e.date)).toList(), [
        '2026-01-01',
        '2026-01-02',
        '2026-01-03',
      ]);
    });

    test('occurrenceExists reports markers', () async {
      final id = await recurring.create(await makeDefinition());
      final definition = await recurring.getById(id);
      expect(
        await recurring.occurrenceExists(id, DateTime(2026, 1, 5)),
        isFalse,
      );
      await recurring.recordOccurrence(
        definition: definition,
        dueDate: DateTime(2026, 1, 5),
      );
      expect(
        await recurring.occurrenceExists(id, DateTime(2026, 1, 5)),
        isTrue,
      );
    });

    test('getActiveDueOnOrBefore returns only due active items', () async {
      final due = await recurring.create(
        await makeDefinition(startDate: DateTime(2026, 1, 5)),
      );
      final later = await recurring.create(
        await makeDefinition(startDate: DateTime(2026, 6, 5)),
      );
      final paused = await recurring.create(
        await makeDefinition(startDate: DateTime(2026, 1, 1)),
      );
      await recurring.update(
        (await recurring.getById(paused)).copyWith(active: false),
      );

      final result = await recurring.getActiveDueOnOrBefore(
        DateTime(2026, 3, 1),
      );
      expect(result.map((d) => d.id), [due]);
      expect(result.map((d) => d.id), isNot(contains(later)));
    });
  });
}
