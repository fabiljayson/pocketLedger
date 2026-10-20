import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../database/app_database.dart';
import '../features/budgets/data/budgets_repository.dart';
import '../features/categories/data/categories_repository.dart';
import '../features/dashboard/data/summary_repository.dart';
import '../features/expenses/data/expenses_repository.dart';
import '../features/recurring/data/recurring_repository.dart';
import '../features/settings/data/settings_repository.dart';

// ── Database + repository providers ──────────────────────────────────────

/// Opens (or upgrades) the local database once per container. Overridden in
/// widget tests with an in-memory FFI database.
final databaseProvider = FutureProvider<Database>((ref) async {
  final db = await openAppDatabase();
  await seedDefaultCategories(db);
  return db;
});

// Repository providers resolve after the database future completes; async
// screens gate on `databaseProvider` before reading them.
final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(databaseProvider).requireValue);
});

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(databaseProvider).requireValue);
});

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref.watch(databaseProvider).requireValue);
});

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(databaseProvider).requireValue);
});

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  return SummaryRepository(ref.watch(databaseProvider).requireValue);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider).requireValue);
});
