import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/utils/date_utils.dart';

void main() {
  group('ISO date conversion', () {
    test('round-trips', () {
      final day = DateTime(2026, 10, 20);
      expect(toIsoDate(day), '2026-10-20');
      expect(parseIsoDate('2026-10-20'), day);
    });

    test('pads components', () {
      expect(toIsoDate(DateTime(2026, 2, 3)), '2026-02-03');
      expect(toIsoDate(DateTime(999, 1, 1)), '0999-01-01');
    });

    test('rejects malformed and impossible dates', () {
      expect(() => parseIsoDate('2026-2-3'), throwsFormatException);
      expect(() => parseIsoDate('2026-02-30'), throwsFormatException);
      expect(() => parseIsoDate('2025-02-29'), throwsFormatException);
      expect(() => parseIsoDate('not-a-date'), throwsFormatException);
      expect(isValidIsoDate('2024-02-29'), isTrue);
      expect(isValidIsoDate('garbage'), isFalse);
    });
  });

  group('leap years and month lengths', () {
    test('isLeapYear', () {
      expect(isLeapYear(2024), isTrue);
      expect(isLeapYear(2000), isTrue);
      expect(isLeapYear(1900), isFalse);
      expect(isLeapYear(2026), isFalse);
    });

    test('daysInMonth', () {
      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2026, 1), 31);
      expect(daysInMonth(2026, 4), 30);
      expect(daysInMonth(2026, 12), 31);
    });
  });

  group('addMonthsClamped (month-end behaviour)', () {
    test('clamps Jan 31 to end of February', () {
      expect(addMonthsClamped(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonthsClamped(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
    });

    test('rolls across year boundaries', () {
      expect(
        addMonthsClamped(DateTime(2026, 12, 31), 1),
        DateTime(2027, 1, 31),
      );
      expect(
        addMonthsClamped(DateTime(2026, 11, 30), 2),
        DateTime(2027, 1, 30),
      );
    });

    test('clamps May 31 to June 30', () {
      expect(addMonthsClamped(DateTime(2026, 5, 31), 1), DateTime(2026, 6, 30));
    });

    test('supports subtracting months', () {
      expect(
        addMonthsClamped(DateTime(2026, 3, 31), -1),
        DateTime(2026, 2, 28),
      );
      expect(
        addMonthsClamped(DateTime(2024, 3, 31), -1),
        DateTime(2024, 2, 29),
      );
      expect(
        addMonthsClamped(DateTime(2026, 1, 15), -1),
        DateTime(2025, 12, 15),
      );
    });

    test('multi-month steps clamp once at the target', () {
      expect(
        addMonthsClamped(DateTime(2026, 1, 31), 13),
        DateTime(2027, 2, 28),
      );
    });
  });

  group('addYearsClamped', () {
    test('clamps Feb 29 to Feb 28 on non-leap years', () {
      expect(addYearsClamped(DateTime(2024, 2, 29), 1), DateTime(2025, 2, 28));
      expect(addYearsClamped(DateTime(2024, 2, 29), 4), DateTime(2028, 2, 29));
    });
  });

  group('rangeFor', () {
    final now = DateTime(2026, 10, 20, 15, 30);

    test('today', () {
      final range = rangeFor(PeriodKind.today, now);
      expect(range.start, DateTime(2026, 10, 20));
      expect(range.endExclusive, DateTime(2026, 10, 21));
      expect(range.contains(now), isTrue);
      expect(range.contains(DateTime(2026, 10, 20, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 10, 21)), isFalse);
    });

    test('week starts on Monday', () {
      // 2026-10-20 is a Tuesday; week starts Monday 2026-10-19.
      final range = rangeFor(PeriodKind.week, now);
      expect(range.start, DateTime(2026, 10, 19));
      expect(range.endExclusive, DateTime(2026, 10, 26));
    });

    test('week starting exactly on Monday', () {
      final monday = DateTime(2026, 10, 19, 8);
      final range = rangeFor(PeriodKind.week, monday);
      expect(range.start, DateTime(2026, 10, 19));
      expect(range.endExclusive, DateTime(2026, 10, 26));
    });

    test('month boundaries and year change', () {
      final range = rangeFor(PeriodKind.month, now);
      expect(range.start, DateTime(2026, 10, 1));
      expect(range.endExclusive, DateTime(2026, 11, 1));

      final january = DateTime(2026, 1, 31, 23);
      final janRange = rangeFor(PeriodKind.month, january);
      expect(janRange.start, DateTime(2026, 1, 1));
      expect(janRange.endExclusive, DateTime(2026, 2, 1));

      final december = DateTime(2026, 12, 31, 23);
      final decRange = rangeFor(PeriodKind.month, december);
      expect(decRange.start, DateTime(2026, 12, 1));
      expect(decRange.endExclusive, DateTime(2027, 1, 1));
    });

    test('custom range is inclusive of the end day', () {
      final range = rangeFor(
        PeriodKind.custom,
        now,
        customStart: DateTime(2026, 9, 15),
        customEnd: DateTime(2026, 9, 20),
      );
      expect(range.start, DateTime(2026, 9, 15));
      expect(range.endExclusive, DateTime(2026, 9, 21));
      expect(range.contains(DateTime(2026, 9, 20, 12)), isTrue);
    });

    test('custom range tolerates inverted dates', () {
      final range = rangeFor(
        PeriodKind.custom,
        now,
        customStart: DateTime(2026, 9, 20),
        customEnd: DateTime(2026, 9, 15),
      );
      expect(range.endExclusive, DateTime(2026, 9, 21));
    });
  });

  group('month keys', () {
    test('monthKeyOf and monthRangeForKey round-trip', () {
      expect(monthKeyOf(DateTime(2026, 10, 20)), '2026-10');
      final range = monthRangeForKey('2026-02');
      expect(range.start, DateTime(2026, 2, 1));
      expect(range.endExclusive, DateTime(2026, 3, 1));
      final dec = monthRangeForKey('2026-12');
      expect(dec.endExclusive, DateTime(2027, 1, 1));
    });

    test('rejects invalid keys', () {
      expect(() => monthRangeForKey('2026-13'), throwsFormatException);
      expect(() => monthRangeForKey('2026/10'), throwsFormatException);
    });
  });

  group('lastMonths', () {
    test('crosses the year boundary ascending', () {
      final months = lastMonths(6, DateTime(2026, 2, 10));
      expect(months.map(monthKeyOf).toList(), [
        '2025-09',
        '2025-10',
        '2025-11',
        '2025-12',
        '2026-01',
        '2026-02',
      ]);
    });
  });

  group('display formatting', () {
    test('formats dates and month labels', () {
      expect(formatDisplayDate(DateTime(2026, 10, 5)), '5 Oct 2026');
      expect(formatLongDate(DateTime(2026, 1, 31)), '31 January 2026');
      expect(formatMonthLabel(DateTime(2026, 12, 1)), 'Dec 2026');
    });
  });
}
