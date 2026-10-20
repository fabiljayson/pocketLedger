// ── CSV generation ───────────────────────────────────────────────────────
//
// RFC 4180-compatible CSV writer with OWASP spreadsheet formula-injection
// protection. Text cells that begin with a formula trigger character
// (=, +, -, @, tab, carriage return) are prefixed with an apostrophe so
// spreadsheet applications treat them as plain text.

const String csvLineBreak = '\r\n';

const int _charEquals = 0x3D; // =
const int _charPlus = 0x2B; // +
const int _charMinus = 0x2D; // -
const int _charAt = 0x40; // @
const int _charTab = 0x09;
const int _charCarriageReturn = 0x0D;

bool _isFormulaTrigger(int codeUnit) =>
    codeUnit == _charEquals ||
    codeUnit == _charPlus ||
    codeUnit == _charMinus ||
    codeUnit == _charAt ||
    codeUnit == _charTab ||
    codeUnit == _charCarriageReturn;

/// Neutralizes leading formula characters in untrusted text.
String sanitizeCsvText(String value) {
  if (value.isEmpty) return value;
  return _isFormulaTrigger(value.codeUnits.first) ? "'$value" : value;
}

bool _needsQuoting(String value) =>
    value.contains(',') ||
    value.contains('"') ||
    value.contains('\n') ||
    value.contains('\r');

String _toIsoLike(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

/// Converts a single cell to CSV text. `null` becomes an empty cell, [num]
/// values render without grouping, and strings receive formula protection.
String escapeCsvCell(Object? value, {bool sanitizeFormula = true}) {
  var text = switch (value) {
    null => '',
    DateTime d => _toIsoLike(d),
    num n => n.toString(),
    bool b => b ? 'true' : 'false',
    String s => sanitizeFormula ? sanitizeCsvText(s) : s,
    Object o => o.toString(),
  };
  if (_needsQuoting(text)) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

/// Incrementally builds a CSV document. Rows are joined with CRLF and the
/// document ends with a trailing line break.
class CsvBuilder {
  final List<String> _rows = [];

  int get rowCount => _rows.length;

  /// Adds one row. Each cell is escaped independently.
  void addRow(Iterable<Object?> cells) {
    _rows.add(cells.map(escapeCsvCell).join(','));
  }

  String build() =>
      _rows.isEmpty ? '' : '${_rows.join(csvLineBreak)}$csvLineBreak';
}
