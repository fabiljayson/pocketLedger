import 'package:flutter/material.dart';

// ── Color tokens (source: DESIGN.md) ─────────────────────────────────────

abstract final class AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryStrong = Color(0xFF075985);
  static const primarySoft = Color(0xFFBAE6FD);
  static const accent = Color(0xFF0EA5E9);
  static const surface = Color(0xFFE0F2FE);
  static const surfaceMuted = Color(0xFFBAE6FD);
  static const text = Color(0xFF082F49);
  static const border = Color(0xFF075985);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);

  // Derived surfaces — light canvas and glass fills.
  static const scaffoldLight = Color(0xFFEFF8FF);
  static const glassFillLight = Color(0xB3FFFFFF);
  static const glassBorderLight = Color(0x400EA5E9);

  // Derived surfaces — dark canvas (glassmorphism over deep sky).
  static const scaffoldDark = Color(0xFF06121F);
  static const textOnDark = Color(0xFFE0F2FE);
  static const glassFillDark = Color(0x14FFFFFF);
  static const glassBorderDark = Color(0x33BAE6FD);
}

// ── Spacing / radius / motion ─────────────────────────────────────────────

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 48;
}

abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 260);
}

// ── Typography ────────────────────────────────────────────────────────────

abstract final class AppFonts {
  static const String family = 'Georgia';
  static const List<String> fallback = ['serif', 'Noto Serif'];
  static const String mono = 'monospace';
}
