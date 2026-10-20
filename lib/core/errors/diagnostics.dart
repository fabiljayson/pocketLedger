import 'dart:developer' as developer;

// ── Diagnostics ──────────────────────────────────────────────────────────
//
// Financial privacy rule: log event names and error *types* only. Never log
// transaction descriptions, amounts, notes or backup contents.

void logDiagnostic(
  String scope,
  String event, {
  Object? error,
  StackTrace? stackTrace,
}) {
  final suffix = error == null ? '' : ' error=${error.runtimeType}';
  developer.log('[$scope] $event$suffix', name: 'pocketledger');
  if (error != null && stackTrace != null) {
    developer.log('$error', name: 'pocketledger', stackTrace: stackTrace);
  }
}
