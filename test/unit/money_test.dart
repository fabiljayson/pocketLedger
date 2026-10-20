import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/utils/money.dart';

void main() {
  group('validateAmount', () {
    test('accepts plain whole amounts', () {
      expect(validateAmount('1500'), isNull);
      expect(validateAmount('1'), isNull);
      expect(validateAmount('007'), isNull);
    });

    test('accepts space-grouped amounts', () {
      expect(validateAmount('1 500'), isNull);
      expect(validateAmount('12\u00A0500'), isNull);
      expect(validateAmount('1\u202F000\u00A0000'), isNull);
      expect(validateAmount('  12500  '), isNull);
    });

    test('accepts the maximum allowed amount', () {
      expect(validateAmount('999999999999'), isNull);
    });

    test('rejects empty input', () {
      expect(validateAmount(''), 'Enter an amount');
      expect(validateAmount('   '), 'Enter an amount');
    });

    test('rejects zero', () {
      expect(validateAmount('0'), 'Amount must be greater than zero');
      expect(validateAmount('000'), 'Amount must be greater than zero');
    });

    test('rejects negative amounts', () {
      expect(validateAmount('-5'), 'Amount cannot be negative');
      expect(validateAmount('- 5'), 'Amount cannot be negative');
    });

    test('rejects decimal amounts', () {
      expect(validateAmount('1.5'), contains('whole number'));
      expect(validateAmount('12 500,50'), contains('whole number'));
      expect(validateAmount('0.01'), contains('whole number'));
    });

    test('rejects malformed values', () {
      expect(validateAmount('abc'), 'Enter a valid amount in FCFA');
      expect(validateAmount('12a'), 'Enter a valid amount in FCFA');
      expect(validateAmount('1e5'), 'Enter a valid amount in FCFA');
      expect(validateAmount('Infinity'), 'Enter a valid amount in FCFA');
      expect(validateAmount('NaN'), 'Enter a valid amount in FCFA');
    });

    test('rejects amounts above the safe cap', () {
      expect(validateAmount('1000000000000'), 'Amount is too large');
      expect(
        validateAmount(List.filled(20, '9').join()),
        'Amount is too large',
      );
    });
  });

  group('parseAmount', () {
    test('parses grouped input', () {
      expect(parseAmount('1 500'), 1500);
      expect(parseAmount('12\u00A0500'), 12500);
      expect(parseAmount('007'), 7);
    });

    test('throws FormatException on invalid input', () {
      expect(() => parseAmount('0'), throwsFormatException);
      expect(() => parseAmount('-1'), throwsFormatException);
      expect(() => parseAmount('1.5'), throwsFormatException);
    });
  });

  group('formatFcfa / formatGrouped', () {
    test('formats with non-breaking-space grouping', () {
      expect(formatGrouped(0), '0');
      expect(formatGrouped(500), '500');
      expect(formatGrouped(1500), '1\u00A0500');
      expect(formatGrouped(12500), '12\u00A0500');
      expect(formatGrouped(1000000), '1\u00A0000\u00A0000');
      expect(formatGrouped(999999999999), '999\u00A0999\u00A0999\u00A0999');
    });

    test('formats negatives for overspent budgets', () {
      expect(formatGrouped(-5000), '-5\u00A0000');
      expect(formatFcfa(-5000), '-5\u00A0000 FCFA');
    });

    test('appends the FCFA symbol', () {
      expect(formatFcfa(12500), '12\u00A0500 FCFA');
      expect(formatFcfa(0), '0 FCFA');
    });
  });

  group('safeSum', () {
    test('sums amounts', () {
      expect(safeSum([1500, 2500, 100]), 4100);
      expect(safeSum(const <int>[]), 0);
    });

    test('throws when exceeding the safe integer range', () {
      expect(() => safeSum([maxSafeInteger, 1]), throwsA(isA<StateError>()));
    });
  });
}
