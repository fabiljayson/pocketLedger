// ── Application errors ───────────────────────────────────────────────────
//
// Errors carry a user-facing [message]; internal details (causes, validation
// lists) stay available for diagnostics without being displayed verbatim.

class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Invalid user input (forms, filters, settings).
class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

/// SQLite / file-system failures while reading or writing local data.
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// CSV generation or file writing failures.
class ExportException extends AppException {
  const ExportException(super.message, {super.cause});
}

/// A backup file failed validation. [errors] lists each rejected problem.
class BackupValidationException extends AppException {
  const BackupValidationException(super.message, this.errors, {super.cause});

  final List<String> errors;
}
