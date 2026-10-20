import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/features/budgets/data/budgets_repository.dart';
import 'package:pocket_ledger/core/errors/app_exception.dart';
import 'package:pocket_ledger/features/categories/data/categories_repository.dart';
import 'package:pocket_ledger/features/expenses/data/expenses_repository.dart';
import 'package:pocket_ledger/features/expenses/domain/expense.dart';
import 'package:pocket_ledger/core/constants/payment_methods.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late BudgetsRepository budgets;
  late ExpensesRepository expenses;

  setUp(() async {
    db = await createTestDatabase();
    budgets = BudgetsRepository(db);
    expenses = ExpensesRepository(db);
  });

  tearDown(() async => db.close());

  Future<int> categoryIdNamed(String name) async {
    final all = await CategoriesRepository(db).getAll();
    return all.firstWhere((c) => c.name == name).id;
  }

  Future<void> addExpense(int amount, int categoryId, DateTime date) {
    final now = DateTime(2026, 1, 1);
    return expenses.create(
      Expense(
        amountFcfa: amount,
        categoryId: categoryId,
        title: 'e',
        date: date,
        paymentMethod: PaymentMethod.cash,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('budget upsert', () {
    test('creates total and category budgets', () async {
      final food = await categoryIdNamed('Food and groceries');
      final total = await budgets.upsert(
        monthKey: '2026-10',
        categoryId: null,
        amountFcfa: 200000,
      );
      final category = await budgets.upsert(
        monthKey: '2026-10',
        categoryId: food,
        amountFcfa: 80000,
      );
      expect(total.isTotal, isTrue);
      expect(category.isTotal, isFalse);

      final all = await budgets.getForMonth('2026-10');
      expect(all.length, 2);
    });

    test('upserting the same scope updates in place', () async {
      final first = await budgets.upsert(
        monthKey: '2026-10',
        categoryId: null,
        amountFcfa: 100000,
      );
      final second = await budgets.upsert(
        monthKey: '2026-10',
        categoryId: null,
        amountFcfa: 150000,
      );
      expect(second.id, first.id);
      final all = await budgets.getForMonth('2026-10');
      expect(all.single.amountFcfa, 150000);
    });

    test('rejects negative amounts and invalid month keys', () async {
      await expectLater(
        budgets.upsert(monthKey: '2026-10', categoryId: null, amountFcfa: -1),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        budgets.upsert(monthKey: 'bad', categoryId: null, amountFcfa: 100),
        throwsFormatException,
      );
    });

    test('deletes budgets', () async {
      final budget = await budgets.upsert(
        monthKey: '2026-10',
        categoryId: null,
        amountFcfa: 1000,
      );
      await budgets.delete(budget.id!);
      expect(await budgets.getForMonth('2026-10'), isEmpty);
    });
  });

  group('budget progress calculations', () {
    test('computes spent, remaining and utilization', () async {
      final food = await categoryIdNamed('Food and groceries');
      final transport = await categoryIdNamed('Transport');
      await budgets.upsert(
        monthKey: '2026-10',
        categoryId: null,
        amountFcfa: 10000,
      );
      await budgets.upsert(
        monthKey: '2026-10',
        categoryId: food,
        amountFcfa: 5000,
      );

      await addExpense(2000, food, DateTime(2026, 10, 2));
      await addExpense(3000, food, DateTime(2026, 10, 20));
      await addExpense(1000, transport, DateTime(2026, 10, 15));
      // Out-of-month expense must not count.
      await addExpense(9000, food, DateTime(2026, 9, 30));

      final progress = await budgets.progressForMonth('2026-10');
      expect(progress.length, 2);

      final total = progress.firstWhere((p) => p.budget.isTotal);
      expect(total.spentFcfa, 6000);
      expect(total.remainingFcfa, 4000);
      expect(total.utilizationPercent, closeTo(60, 0.001));
      expect(total.isExceeded, isFalse);

      final foodProgress = progress.firstWhere(
        (p) => p.budget.categoryId == food,
      );
      expect(foodProgress.spentFcfa, 5000);
      expect(foodProgress.remainingFcfa, 0);
      expect(foodProgress.utilizationPercent, closeTo(100, 0.001));
      expect(foodProgress.isExceeded, isFalse);
    });

    test('reports overspending with negative remaining', () async {
      final food = await categoryIdNamed('Food and groceries');
      await budgets.upsert(
        monthKey: '2026-10',
        categoryId: food,
        amountFcfa: 3000,
      );
      await addExpense(4500, food, DateTime(2026, 10, 3));

      final progress = await budgets.progressForMonth('2026-10');
      final foodProgress = progress.single;
      expect(foodProgress.spentFcfa, 4500);
      expect(foodProgress.remainingFcfa, -1500);
      expect(foodProgress.isExceeded, isTrue);
      expect(foodProgress.utilizationPercent, closeTo(150, 0.001));
      expect(foodProgress.utilizationClamped, 100);
    });

    test('zero budget does not divide by zero', () async {
      await budgets.upsert(
        monthKey: '2026-10',
        categoryId: null,
        amountFcfa: 0,
      );
      final progress = await budgets.progressForMonth('2026-10');
      final total = progress.single;
      expect(total.utilizationPercent, 0);
      expect(total.hasBudget, isFalse);
      expect(total.isExceeded, isFalse);
    });

    test('month boundary: February expenses excluded from January', () async {
      await budgets.upsert(
        monthKey: '2026-01',
        categoryId: null,
        amountFcfa: 10000,
      );
      final food = await categoryIdNamed('Food and groceries');
      await addExpense(500, food, DateTime(2026, 1, 31));
      await addExpense(700, food, DateTime(2026, 2, 1));

      final jan = (await budgets.progressForMonth('2026-01')).single;
      expect(jan.spentFcfa, 500);
      expect(await budgets.spentInMonth('2026-02'), 700);
    });

    test('leap-day expense lands in February 2024 only', () async {
      await budgets.upsert(
        monthKey: '2024-02',
        categoryId: null,
        amountFcfa: 100,
      );
      final food = await categoryIdNamed('Food and groceries');
      await addExpense(2900, food, DateTime(2024, 2, 29));

      final feb = (await budgets.progressForMonth('2024-02')).single;
      expect(feb.spentFcfa, 2900);
      final march = await budgets.progressForMonth('2024-03');
      expect(march, isEmpty);
    });
  });
}
