import '../errors/app_exception.dart';
import 'date_utils.dart';

// ── Date helpers for pickers ─────────────────────────────────────────────

/// Clamps [picked] against an optional [firstDate] / [lastDate] window.
DateTime clampDate(DateTime picked, DateTime? firstDate, DateTime? lastDate) {
  var result = dateOnly(picked);
  if (firstDate != null && result.isBefore(dateOnly(firstDate))) {
    result = dateOnly(firstDate);
  }
  if (lastDate != null && result.isAfter(dateOnly(lastDate))) {
    result = dateOnly(lastDate);
  }
  return result;
}

// ── User-facing error mapping ────────────────────────────────────────────

/// Converts any thrown error into a safe, user-facing message. Stack traces
/// and exception internals are never surfaced.
String userMessageFor(Object error) {
  if (error is AppException) return error.message;
  if (error is FormatException) return 'The provided data is not valid.';
  return 'An unexpected problem occurred. Please try again.';
}
