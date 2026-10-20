import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/constants/payment_methods.dart';
import 'package:pocket_ledger/core/errors/app_exception.dart';
import 'package:pocket_ledger/core/utils/date_utils.dart';
import 'package:pocket_ledger/database/app_database.dart';
import 'package:pocket_ledger/database/migrations.dart';
import 'package:pocket_ledger/features/categories/data/categories_repository.dart';
import 'package:pocket_ledger/features/expenses/domain/expense.dart';
import 'package:pocket_ledger/features/expenses/data/expenses_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late ExpensesRepository expenses;
  late CategoriesRepository categories;

  setUp(() async {
    db = await createTestDatabase();
    expenses = ExpensesRepository(db);
    categories = CategoriesRepository(db);
  });

  tearDown(() async => db.close());

  Future<int> categoryIdNamed(String name) async {
    final all = await categories.getAll();
    return all.firstWhere((c) => c.name == name).id;
  }

  Expense makeExpense({
    required int amountFcfa,
    required int categoryId,
    required String title,
    required DateTime date,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? notes,
  }) {
    final now = DateTime(2026, 1, 1, 12);
    return Expense(
      amountFcfa: amountFcfa,
      categoryId: categoryId,
      title: title,
      date: date,
      paymentMethod: paymentMethod,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('schema creation', () {
    test('seeds default categories exactly once', () async {
      final all = await categories.getAll();
      expect(all.length, 12);
      expect(all.every((c) => c.isDefault), isTrue);
      expect(all.map((c) => c.name), contains('Food and groceries'));

      // Re-running the seeder must not duplicate (unique name index).
      await seedDefaultCategories(db);
      expect((await categories.getAll()).length, 12);
    });

    test('foreign keys are enforced', () async {
      await expectLater(
        db.insert('expenses', {
          'amount_fcfa': 500,
          'category_id': 99999,
          'title': 'orphan',
          'date': '2026-10-01',
          'payment_method': 'cash',
          'created_at': 0,
          'updated_at': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rejects zero and negative amounts at the schema level', () async {
      final catId = await categoryIdNamed('Other');
      for (final amount in [0, -100]) {
        await expectLater(
          db.insert('expenses', {
            'amount_fcfa': amount,
            'category_id': catId,
            'title': 'bad',
            'date': '2026-10-01',
            'payment_method': 'cash',
            'created_at': 0,
            'updated_at': 0,
          }),
          throwsA(isA<DatabaseException>()),
        );
      }
    });

    test('schema version is current', () async {
      final rows = await db.rawQuery('PRAGMA user_version');
      expect(rows.first.values.first, schemaVersion);
    });
  });

  group('expense CRUD', () {
    test('creates, reads, edits and deletes', () async {
      final catId = await categoryIdNamed('Transport');
      final created = await expenses.create(
        makeExpense(
          amountFcfa: 1500,
          categoryId: catId,
          title: 'Taxi to work',
          date: DateTime(2026, 10, 15),
          paymentMethod: PaymentMethod.mobileMoney,
          notes: 'Morning ride',
        ),
      );
      expect(created, greaterThan(0));

      final loaded = await expenses.getById(created);
      expect(loaded.amountFcfa, 1500);
      expect(loaded.title, 'Taxi to work');
      expect(loaded.paymentMethod, PaymentMethod.mobileMoney);
      expect(loaded.notes, 'Morning ride');
      expect(loaded.date, DateTime(2026, 10, 15));

      await expenses.update(
        loaded.copyWith(
          amountFcfa: 1800,
          title: 'Taxi to work (revised)',
          clearNotes: true,
          updatedAt: DateTime(2026, 10, 16),
        ),
      );
      final edited = await expenses.getById(created);
      expect(edited.amountFcfa, 1800);
      expect(edited.title, 'Taxi to work (revised)');
      expect(edited.notes, isNull);
      expect(edited.updatedAt, DateTime(2026, 10, 16));

      await expenses.delete(created);
      await expectLater(
        expenses.getById(created),
        throwsA(isA<StorageException>()),
      );
    });

    test('validates amount and title in the repository layer', () async {
      final catId = await categoryIdNamed('Other');
      await expectLater(
        expenses.create(
          makeExpense(
            amountFcfa: 0,
            categoryId: catId,
            title: 'x',
            date: DateTime(2026, 1, 1),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        expenses.create(
          makeExpense(
            amountFcfa: 100,
            categoryId: catId,
            title: '   ',
            date: DateTime(2026, 1, 1),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('updating a deleted row reports not-found', () async {
      final catId = await categoryIdNamed('Other');
      final ghost = makeExpense(
        amountFcfa: 100,
        categoryId: catId,
        title: 'ghost',
        date: DateTime(2026, 1, 1),
      ).copyWith(id: 424242);
      await expectLater(
        expenses.update(ghost),
        throwsA(isA<StorageException>()),
      );
      await expectLater(
        expenses.delete(424242),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('expense querying', () {
    setUp(() async {
      final food = await categoryIdNamed('Food and groceries');
      final transport = await categoryIdNamed('Transport');
      await expenses.create(
        makeExpense(
          amountFcfa: 2000,
          categoryId: food,
          title: 'Market shopping',
          date: DateTime(2026, 10, 1),
          notes: 'tomatoes, plantain',
        ),
      );
      await expenses.create(
        makeExpense(
          amountFcfa: 5000,
          categoryId: transport,
          title: 'Benskin',
          date: DateTime(2026, 10, 10),
          paymentMethod: PaymentMethod.mobileMoney,
        ),
      );
      await expenses.create(
        makeExpense(
          amountFcfa: 1500,
          categoryId: food,
          title: 'Bread',
          date: DateTime(2026, 9, 28),
        ),
      );
      await expenses.create(
        makeExpense(
          amountFcfa: 12000,
          categoryId: transport,
          title: 'Bus ticket Douala',
          date: DateTime(2026, 11, 2),
          paymentMethod: PaymentMethod.bankCard,
          notes: 'travel = expensive',
        ),
      );
    });

    test('filters by half-open date range (month boundary)', () async {
      final october = rangeFor(PeriodKind.month, DateTime(2026, 10, 15));
      final rows = await expenses.query(ExpenseQuery(dateRange: october));
      expect(rows.length, 2);
      expect(
        rows.map((e) => e.title),
        containsAll(['Market shopping', 'Benskin']),
      );
    });

    test('filters by category', () async {
      final food = await categoryIdNamed('Food and groceries');
      final rows = await expenses.query(ExpenseQuery(categoryId: food));
      expect(rows.length, 2);
      expect(rows.every((e) => e.categoryId == food), isTrue);
    });

    test('filters by payment method and combines with date range', () async {
      final rows = await expenses.query(
        ExpenseQuery(paymentMethod: PaymentMethod.mobileMoney),
      );
      expect(rows.single.title, 'Benskin');

      final october = rangeFor(PeriodKind.month, DateTime(2026, 10, 15));
      final combined = await expenses.query(
        ExpenseQuery(paymentMethod: PaymentMethod.cash, dateRange: october),
      );
      expect(combined.single.title, 'Market shopping');
    });

    test('searches title and notes', () async {
      final byTitle = await expenses.query(ExpenseQuery(search: 'benskin'));
      expect(byTitle.single.title, 'Benskin');

      final byNotes = await expenses.query(ExpenseQuery(search: 'plantain'));
      expect(byNotes.single.title, 'Market shopping');

      final none = await expenses.query(ExpenseQuery(search: 'zzz'));
      expect(none, isEmpty);
    });

    test('sorts newest, oldest, highest and lowest', () async {
      final newest = await expenses.query(
        ExpenseQuery(sort: ExpenseSort.newest),
      );
      expect(newest.first.title, 'Bus ticket Douala');

      final oldest = await expenses.query(
        ExpenseQuery(sort: ExpenseSort.oldest),
      );
      expect(oldest.first.title, 'Bread');

      final highest = await expenses.query(
        ExpenseQuery(sort: ExpenseSort.highestAmount),
      );
      expect(highest.first.amountFcfa, 12000);

      final lowest = await expenses.query(
        ExpenseQuery(sort: ExpenseSort.lowestAmount),
      );
      expect(lowest.first.amountFcfa, 1500);
    });

    test('paginates with limit/offset', () async {
      final page = await expenses.query(
        const ExpenseQuery(sort: ExpenseSort.highestAmount, limit: 2),
      );
      expect(page.length, 2);
      expect(page.first.amountFcfa, 12000);

      final next = await expenses.query(
        const ExpenseQuery(
          sort: ExpenseSort.highestAmount,
          limit: 2,
          offset: 2,
        ),
      );
      expect(next.length, 2);
      expect(next.first.amountFcfa, 2000);
      expect(next.map((e) => e.amountFcfa), isNot(contains(12000)));
    });

    test('countMatching mirrors query filters', () async {
      final food = await categoryIdNamed('Food and groceries');
      expect(await expenses.countMatching(ExpenseQuery()), 4);
      expect(await expenses.countMatching(ExpenseQuery(categoryId: food)), 2);
    });
  });

  group('category repository', () {
    test('creates custom categories and rejects duplicates', () async {
      final created = await categories.create(
        name: 'Bible study',
        iconKey: 'other',
        colorHex: '#123456',
      );
      expect(created.isDefault, isFalse);
      expect((await categories.getAll()).length, 13);

      await expectLater(
        categories.create(
          name: 'bible study',
          iconKey: 'other',
          colorHex: '#123456',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('deleting a referenced category fails with guidance', () async {
      final food = await categoryIdNamed('Food and groceries');
      await expenses.create(
        makeExpense(
          amountFcfa: 500,
          categoryId: food,
          title: 'snack',
          date: DateTime(2026, 10, 5),
        ),
      );
      await expectLater(
        categories.delete(food, isDefault: true),
        throwsA(isA<ValidationException>()),
      );
    });

    test('deleting an unused custom category succeeds', () async {
      final custom = await categories.create(
        name: 'Bawo',
        iconKey: 'other',
        colorHex: '#111111',
      );
      await categories.delete(custom.id, isDefault: custom.isDefault);
      expect((await categories.getAll()).length, 12);
    });
  });

  group('migration v1 → v2', () {
    test('preserves existing rows and adds new tables', () async {
      final v1 = await createV1TestDatabase();
      final v1Categories = await CategoriesRepository(v1).getAll();
      final foodId = v1Categories
          .firstWhere((c) => c.name == 'Food and groceries')
          .id;
      await v1.insert('expenses', {
        'amount_fcfa': 750,
        'category_id': foodId,
        'title': 'Legacy expense',
        'date': '2026-08-14',
        'payment_method': 'cash',
        'created_at': 1,
        'updated_at': 1,
      });

      // Apply the production upgrade path to the populated v1 database
      // (this is exactly what sqflite invokes on reopen at a higher version).
      await upgradeDatabase(v1, 1, schemaVersion);

      final tables = await v1.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = tables.map((t) => t['name']).toSet();
      expect(
        names,
        containsAll([
          'budgets',
          'recurring_definitions',
          'recurring_occurrences',
        ]),
      );

      final rows = await v1.query('expenses');
      expect(rows.length, 1);
      expect(rows.first['title'], 'Legacy expense');
      expect(rows.first['amount_fcfa'], 750);

      // v2 constraints are live on the upgraded database.
      await v1.insert('budgets', {
        'month_key': '2026-10',
        'category_id': null,
        'amount_fcfa': 50000,
        'created_at': 0,
        'updated_at': 0,
      });
      await expectLater(
        v1.insert('budgets', {
          'month_key': '2026-10',
          'category_id': null,
          'amount_fcfa': 60000,
          'created_at': 0,
          'updated_at': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
      await v1.close();
    });
  });
}
