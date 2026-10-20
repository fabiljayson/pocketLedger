import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ── Database factory ─────────────────────────────────────────────────────

/// Selects the SQLite backend. Android/iOS keep the default `sqflite`
/// factory; desktop platforms use the FFI build so the app (and headless
/// tests) run fully offline on Linux, macOS and Windows.
Future<void> setupDatabaseFactory() async {
  if (kIsWeb) return;
  if (Platform.isAndroid || Platform.isIOS) return;
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
