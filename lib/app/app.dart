import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/widgets/app_background.dart';
import '../core/widgets/state_views.dart';
import 'theme/app_theme.dart';

// ── Application root ─────────────────────────────────────────────────────

class PocketLedgerApp extends StatelessWidget {
  const PocketLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: AppBackground(child: LoadingView(label: 'Starting PocketLedger')),
      ),
    );
  }
}
