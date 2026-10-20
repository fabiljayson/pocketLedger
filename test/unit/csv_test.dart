import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/utils/csv.dart';

void main() {
  group('sanitizeCsvText', () {
    test('prefixes formula triggers with an apostrophe', () {
      expect(sanitizeCsvText('=SUM(A1:A9)'), "'=SUM(A1:A9)");
      expect(sanitizeCsvText('+1+2'), "'+1+2");
      expect(sanitizeCsvText('-cmd'), "'-cmd");
      expect(sanitizeCsvText('@import'), "'@import");
      expect(sanitizeCsvText('\tcmd'), "'\tcmd");
      expect(sanitizeCsvText('\rcmd'), "'\rcmd");
    });

    test('leaves safe text untouched', () {
      expect(sanitizeCsvText('Marché Mboppi'), 'Marché Mboppi');
      expect(sanitizeCsvText('2026-10-20'), '2026-10-20');
      expect(sanitizeCsvText(''), '');
    });
  });

  group('escapeCsvCell', () {
    test('passes plain values through', () {
      expect(escapeCsvCell('Transport'), 'Transport');
      expect(escapeCsvCell(12500), '12500');
      expect(escapeCsvCell(null), '');
    });

    test('quotes commas, quotes and newlines', () {
      expect(escapeCsvCell('a,b'), '"a,b"');
      expect(escapeCsvCell('say "hi"'), '"say ""hi"""');
      expect(escapeCsvCell('line1\nline2'), '"line1\nline2"');
      expect(escapeCsvCell('line1\r\nline2'), '"line1\r\nline2"');
    });

    test('sanitizes then quotes formula-like text with commas', () {
      expect(
        escapeCsvCell('=HYPERLINK("a","b")'),
        '"\'=HYPERLINK(""a"",""b"")"',
      );
    });

    test('keeps French accents intact (UTF-8, no escaping needed)', () {
      expect(
        escapeCsvCell('Dépense — été à Yaoundé'),
        'Dépense — été à Yaoundé',
      );
    });

    test('can skip sanitization explicitly', () {
      expect(escapeCsvCell('=x', sanitizeFormula: false), '=x');
    });
  });

  group('CsvBuilder', () {
    test('joins rows with CRLF and ends with a line break', () {
      final builder = CsvBuilder()
        ..addRow(['id', 'description'])
        ..addRow([1, 'Pain, baguette']);
      expect(builder.rowCount, 2);
      expect(builder.build(), 'id,description\r\n1,"Pain, baguette"\r\n');
    });

    test('builds an empty document for no rows', () {
      expect(CsvBuilder().build(), '');
    });

    test('handles empty notes as empty cells', () {
      final builder = CsvBuilder()..addRow(['2026-10-20', 'Taxi', '', 500]);
      expect(builder.build(), '2026-10-20,Taxi,,500\r\n');
    });
  });
}
