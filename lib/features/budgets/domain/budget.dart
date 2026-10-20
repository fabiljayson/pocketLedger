// ── Budget model ─────────────────────────────────────────────────────────
//
// A budget targets one calendar month ([monthKey] = `yyyy-MM`). When
// [categoryId] is null the budget is the total monthly budget; otherwise it
// constrains a single category. Budgets are informational only — they never
// restrict recording expenses.

class Budget {
  const Budget({
    this.id,
    required this.monthKey,
    required this.categoryId,
    required this.amountFcfa,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String monthKey;

  /// `null` = total monthly budget; otherwise the constrained category.
  final int? categoryId;
  final int amountFcfa;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTotal => categoryId == null;

  factory Budget.fromMap(Map<String, Object?> map) => Budget(
    id: map['id'] as int?,
    monthKey: map['month_key'] as String,
    categoryId: map['category_id'] as int?,
    amountFcfa: map['amount_fcfa'] as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'month_key': monthKey,
    'category_id': categoryId,
    'amount_fcfa': amountFcfa,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  Budget copyWith({
    int? id,
    String? monthKey,
    int? categoryId,
    int? amountFcfa,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Budget(
    id: id ?? this.id,
    monthKey: monthKey ?? this.monthKey,
    categoryId: categoryId ?? this.categoryId,
    amountFcfa: amountFcfa ?? this.amountFcfa,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) => other is Budget && other.id == id;

  @override
  int get hashCode => id?.hashCode ?? Object.hash(monthKey, categoryId);
}

// ── Budget progress ──────────────────────────────────────────────────────

/// Computed view of a budget against actual spending for its month.
/// [remainingFcfa] is negative when the budget has been exceeded.
class BudgetProgress {
  const BudgetProgress({required this.budget, required this.spentFcfa});

  final Budget budget;
  final int spentFcfa;

  int get budgetFcfa => budget.amountFcfa;

  int get remainingFcfa => budgetFcfa - spentFcfa;

  bool get hasBudget => budgetFcfa > 0;

  /// Utilization percentage (spent / budget × 100); `0` when no budget is
  /// set, avoiding division by zero.
  double get utilizationPercent =>
      budgetFcfa > 0 ? (spentFcfa / budgetFcfa) * 100 : 0;

  bool get isExceeded => hasBudget && spentFcfa > budgetFcfa;

  /// Utilization clamped to 0–100 for progress indicators.
  double get utilizationClamped => utilizationPercent.clamp(0, 100).toDouble();
}
