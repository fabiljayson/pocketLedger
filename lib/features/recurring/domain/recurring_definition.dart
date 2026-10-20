import '../../../core/constants/payment_methods.dart';
import '../../../core/utils/date_utils.dart';

// ── Recurring frequency ──────────────────────────────────────────────────

enum RecurrenceFrequency {
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  yearly('yearly', 'Yearly');

  const RecurrenceFrequency(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static RecurrenceFrequency fromDb(String? value) =>
      RecurrenceFrequency.values.firstWhere(
        (f) => f.dbValue == value,
        orElse: () => RecurrenceFrequency.monthly,
      );

  /// Advances [day] by one period. Monthly and yearly schedules begin on the
  /// 29th–31st clamp to the target month's last day (Jan 31 + 1 month →
  /// Feb 28/29); later occurrences stay clamped to that day-of-month.
  DateTime nextOccurrence(DateTime day) => switch (this) {
    RecurrenceFrequency.daily => day.add(const Duration(days: 1)),
    RecurrenceFrequency.weekly => day.add(const Duration(days: 7)),
    RecurrenceFrequency.monthly => addMonthsClamped(day, 1),
    RecurrenceFrequency.yearly => addYearsClamped(day, 1),
  };
}

// ── Recurring definition model ───────────────────────────────────────────
//
// A template that *schedules* expenses; it is never a recorded transaction
// itself. Due occurrences are confirmed by the user and recorded as real
// expenses linked through `recurring_definition_id`.

class RecurringDefinition {
  const RecurringDefinition({
    this.id,
    required this.title,
    required this.amountFcfa,
    required this.categoryId,
    required this.paymentMethod,
    this.notes,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.endDate,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final int amountFcfa;
  final int categoryId;
  final PaymentMethod paymentMethod;
  final String? notes;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime nextDueDate;
  final DateTime? endDate;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RecurringDefinition.fromMap(
    Map<String, Object?> map,
  ) => RecurringDefinition(
    id: map['id'] as int?,
    title: map['title'] as String,
    amountFcfa: map['amount_fcfa'] as int,
    categoryId: map['category_id'] as int,
    paymentMethod: PaymentMethod.fromDb(map['payment_method'] as String?),
    notes: map['notes'] as String?,
    frequency: RecurrenceFrequency.fromDb(map['frequency'] as String?),
    startDate: parseIsoDate(map['start_date'] as String),
    nextDueDate: parseIsoDate(map['next_due_date'] as String),
    endDate: map['end_date'] == null
        ? null
        : parseIsoDate(map['end_date'] as String),
    active: (map['active'] as int? ?? 1) != 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'amount_fcfa': amountFcfa,
    'category_id': categoryId,
    'payment_method': paymentMethod.dbValue,
    'notes': notes,
    'frequency': frequency.dbValue,
    'start_date': toIsoDate(startDate),
    'next_due_date': toIsoDate(nextDueDate),
    'end_date': endDate == null ? null : toIsoDate(endDate!),
    'active': active ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  RecurringDefinition copyWith({
    int? id,
    String? title,
    int? amountFcfa,
    int? categoryId,
    PaymentMethod? paymentMethod,
    String? notes,
    bool clearNotes = false,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RecurringDefinition(
    id: id ?? this.id,
    title: title ?? this.title,
    amountFcfa: amountFcfa ?? this.amountFcfa,
    categoryId: categoryId ?? this.categoryId,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    notes: clearNotes ? null : (notes ?? this.notes),
    frequency: frequency ?? this.frequency,
    startDate: startDate ?? this.startDate,
    nextDueDate: nextDueDate ?? this.nextDueDate,
    endDate: clearEndDate ? null : (endDate ?? this.endDate),
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is RecurringDefinition && other.id == id;

  @override
  int get hashCode => id?.hashCode ?? Object.hash(title, startDate);
}
