// ── Application-wide constants ───────────────────────────────────────────

const String appName = 'PocketLedger';

/// ISO 4217 code of the application's default (and only) currency.
const String currencyCode = 'XAF';

/// Display symbol used after formatted amounts.
const String currencySymbol = 'FCFA';

/// Currency name shown in settings.
const String currencyName = 'Central African CFA franc (XAF)';

/// Highest amount accepted for a single record. Keeps every stored value and
/// any aggregation well inside Dart's safe integer range (2^53 - 1).
const int maxAmountFcfa = 999999999999;
