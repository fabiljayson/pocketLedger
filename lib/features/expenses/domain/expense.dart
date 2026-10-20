import '../../../core/constants/payment_methods.dart';

// ── Expense model ────────────────────────────────────────────────────────
//
// [date] is persisted as a local-calendar `yyyy-MM-dd` string (see
// core/utils/date_utils.dart); [createdAt]/[updatedAt] are UTC epoch
// milliseconds.

class Expense {
  const Expense({
    this.id,
    required this.amountFcfa,
    required this.categoryId,
    required this.title,
    required this.date,
    required this.paymentMethod,
    this.notes,
    this.recurringDefinitionId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int amountFcfa;
  final int categoryId;
  final String title;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final String? notes;
  final int? recurringDefinitionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRecordedFromRecurring => recurringDefinitionId != null;

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
    id: map['id'] as int?,
    amountFcfa: map['amount_fcfa'] as int,
    categoryId: map['category_id'] as int,
    title: map['title'] as String,
    date: DateTime.parse(map['date'] as String),
    paymentMethod: PaymentMethod.fromDb(map['payment_method'] as String?),
    notes: map['notes'] as String?,
    recurringDefinitionId: map['recurring_definition_id'] as int?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'amount_fcfa': amountFcfa,
    'category_id': categoryId,
    'title': title,
    'date':
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}',
    'payment_method': paymentMethod.dbValue,
    'notes': notes,
    'recurring_definition_id': recurringDefinitionId,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  Expense copyWith({
    int? id,
    int? amountFcfa,
    int? categoryId,
    String? title,
    DateTime? date,
    PaymentMethod? paymentMethod,
    String? notes,
    bool clearNotes = false,
    int? recurringDefinitionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Expense(
    id: id ?? this.id,
    amountFcfa: amountFcfa ?? this.amountFcfa,
    categoryId: categoryId ?? this.categoryId,
    title: title ?? this.title,
    date: date ?? this.date,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    notes: clearNotes ? null : (notes ?? this.notes),
    recurringDefinitionId: recurringDefinitionId ?? this.recurringDefinitionId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) => other is Expense && other.id == id;

  @override
  int get hashCode => id?.hashCode ?? Object.hash(amountFcfa, title, date);
}
