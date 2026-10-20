import '../constants/app_constants.dart';

// ── XAF money utilities ──────────────────────────────────────────────────
//
// PocketLedger stores money as whole FCFA integers (XAF has no commonly used
// fractional unit for consumer transactions). These helpers are the single
// source of truth for parsing, validating and formatting amounts.

/// Non-breaking space used as the thousands separator (French convention).
const String _groupSeparator = '\u00A0';

final RegExp _groupingSeparators = RegExp(r'[\s\u00A0\u202F]');
final RegExp _digitsOnly = RegExp(r'^[0-9]+$');

/// Returns a user-facing error message when [raw] is not a valid whole-FCFA
/// amount, or `null` when the input is valid.
String? validateAmount(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return 'Enter an amount';
  if (value.contains('.') || value.contains(',')) {
    return 'Amounts are whole FCFA — enter a whole number, no decimals';
  }
  if (value.contains('-') || value.contains('\u2212')) {
    return 'Amount cannot be negative';
  }
  if (value.contains(_groupingSeparators)) {
    final digits = value.replaceAll(_groupingSeparators, '');
    if (!_digitsOnly.hasMatch(digits)) return 'Enter a valid amount in FCFA';
    if (digits.length > 15) return 'Amount is too large';
    final amount = int.parse(digits);
    if (amount == 0) return 'Amount must be greater than zero';
    if (amount > maxAmountFcfa) return 'Amount is too large';
    return null;
  }
  if (!_digitsOnly.hasMatch(value)) return 'Enter a valid amount in FCFA';
  if (value.length > 15) return 'Amount is too large';
  final amount = int.parse(value);
  if (amount == 0) return 'Amount must be greater than zero';
  if (amount > maxAmountFcfa) return 'Amount is too large';
  return null;
}

/// Parses [raw] into whole FCFA. Throws [FormatException] when invalid; call
/// [validateAmount] first to surface errors in the UI.
int parseAmount(String raw) {
  final error = validateAmount(raw);
  if (error != null) throw FormatException(error);
  return int.parse(raw.trim().replaceAll(_groupingSeparators, ''));
}

/// Groups [amount] by thousands with a non-breaking space: 12500 -> 12 500.
String formatGrouped(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_groupSeparator);
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}

/// Formats [amount] for display: 12500 -> `12 500 FCFA`. Negative values are
/// supported so overspent budgets can render as `-5 000 FCFA`.
String formatFcfa(int amount) => '${formatGrouped(amount)} $currencySymbol';

/// Upper bound used to detect (improbable) integer overflow in Dart-side
/// aggregations.
const int maxSafeInteger = 9007199254740991;

/// Sums [values], throwing [StateError] if the total exceeds the safe integer
/// range. Use for Dart-side aggregation of persisted amounts.
int safeSum(Iterable<int> values) {
  var total = 0;
  for (final value in values) {
    total += value;
    if (total > maxSafeInteger || total < -maxSafeInteger) {
      throw StateError('Amount total exceeds the safe integer range');
    }
  }
  return total;
}
