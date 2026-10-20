// ── Date utilities ───────────────────────────────────────────────────────
//
// Expense dates are persisted as local-calendar `yyyy-MM-dd` strings so that
// lexicographic comparison equals chronological comparison in SQLite.

const List<String> _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// A half-open date interval: `start` inclusive, `endExclusive` exclusive.
class DateRange {
  const DateRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;

  bool contains(DateTime day) =>
      !day.isBefore(start) && day.isBefore(endExclusive);

  int get durationDays => endExclusive.difference(start).inDays;

  @override
  bool operator ==(Object other) =>
      other is DateRange &&
      other.start == start &&
      other.endExclusive == endExclusive;

  @override
  int get hashCode => Object.hash(start, endExclusive);

  @override
  String toString() => 'DateRange($start, $endExclusive)';
}

/// Dashboard period presets.
enum PeriodKind { today, week, month, custom }

DateTime dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);

String twoDigits(int value) => value.toString().padLeft(2, '0');

/// Formats [day] as the SQLite/export date format `yyyy-MM-dd`.
String toIsoDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${twoDigits(day.month)}-${twoDigits(day.day)}';

/// Parses a strict `yyyy-MM-dd` string; throws [FormatException] when invalid.
DateTime parseIsoDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) throw FormatException('Invalid date: $value');
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    throw FormatException('Invalid date: $value');
  }
  return parsed;
}

bool isValidIsoDate(String value) {
  try {
    parseIsoDate(value);
    return true;
  } on FormatException {
    return false;
  }
}

bool isLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

int daysInMonth(int year, int month) {
  final next = month == 12 ? DateTime(year + 1, 1) : DateTime(year, month + 1);
  return next.subtract(const Duration(days: 1)).day;
}

/// Adds [months] calendar months to [day], clamping the day-of-month to the
/// target month's last day (Jan 31 + 1 month -> Feb 28/29).
DateTime addMonthsClamped(DateTime day, int months) {
  final totalMonths = day.year * 12 + (day.month - 1) + months;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final targetDay = day.day < daysInMonth(year, month)
      ? day.day
      : daysInMonth(year, month);
  return DateTime(year, month, targetDay);
}

/// Adds [years] to [day], clamping Feb 29 to Feb 28 on non-leap years.
DateTime addYearsClamped(DateTime day, int years) {
  final target = DateTime(day.year + years, day.month, 1);
  final clampedDay = day.day < daysInMonth(target.year, day.month)
      ? day.day
      : daysInMonth(target.year, day.month);
  return DateTime(target.year, day.month, clampedDay);
}

/// Monday-based start of the week containing [day].
DateTime startOfWeek(DateTime day) {
  final only = dateOnly(day);
  return only.subtract(Duration(days: only.weekday - 1));
}

DateTime startOfMonth(DateTime day) => DateTime(day.year, day.month, 1);

DateTime endOfMonthExclusive(DateTime day) =>
    addMonthsClamped(startOfMonth(day), 1);

DateTime startOfYear(DateTime day) => DateTime(day.year, 1, 1);

/// Resolves [kind] into a concrete half-open range anchored at [now].
DateRange rangeFor(
  PeriodKind kind,
  DateTime now, {
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final today = dateOnly(now);
  switch (kind) {
    case PeriodKind.today:
      return DateRange(
        start: today,
        endExclusive: today.add(const Duration(days: 1)),
      );
    case PeriodKind.week:
      final start = startOfWeek(today);
      return DateRange(
        start: start,
        endExclusive: start.add(const Duration(days: 7)),
      );
    case PeriodKind.month:
      return DateRange(
        start: startOfMonth(today),
        endExclusive: endOfMonthExclusive(today),
      );
    case PeriodKind.custom:
      final start = dateOnly(customStart ?? today);
      final end = dateOnly(customEnd ?? today);
      final clampedEnd = end.isBefore(start) ? start : end;
      return DateRange(
        start: start,
        endExclusive: clampedEnd.add(const Duration(days: 1)),
      );
  }
}

/// The last [count] calendar months (including the month of [now]), ascending.
List<DateTime> lastMonths(int count, DateTime now) {
  return List.generate(
    count,
    (i) => addMonthsClamped(startOfMonth(now), i - (count - 1)),
  );
}

/// Canonical month key used by budgets and grouping: `yyyy-MM`.
String monthKeyOf(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${twoDigits(day.month)}';

/// Parses a `yyyy-MM` key into its half-open month range.
DateRange monthRangeForKey(String key) {
  final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(key.trim());
  if (match == null) throw FormatException('Invalid month key: $key');
  final start = DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    1,
  );
  if (start.month != int.parse(match.group(2)!)) {
    throw FormatException('Invalid month key: $key');
  }
  return DateRange(start: start, endExclusive: addMonthsClamped(start, 1));
}

/// Display format: `12 Oct 2026`.
String formatDisplayDate(DateTime day) =>
    '${day.day} ${_monthAbbreviations[day.month - 1]} ${day.year}';

/// Display format: `12 October 2026`.
String formatLongDate(DateTime day) =>
    '${day.day} ${_monthNames[day.month - 1]} ${day.year}';

/// Display format: `Oct 2026`.
String formatMonthLabel(DateTime day) =>
    '${_monthAbbreviations[day.month - 1]} ${day.year}';
