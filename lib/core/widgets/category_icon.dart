import 'package:flutter/material.dart';

import '../constants/categories.dart';

// ── Category visuals ─────────────────────────────────────────────────────

/// Resolves the icon for a persisted [iconKey] with a safe fallback.
IconData iconForCategoryKey(String? key) {
  for (final seed in seedCategories) {
    if (seed.key == key) return seed.icon;
  }
  return Icons.category_outlined;
}

/// Resolves the display color for a persisted `#RRGGBB` hex value with a
/// safe fallback. Invalid or missing values return the neutral category color.
Color colorForCategoryHex(String? hex) {
  if (hex == null) return _fallbackColor;
  final value = hex.replaceFirst('#', '');
  if (value.length != 6) return _fallbackColor;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return _fallbackColor;
  return Color(0xFF000000 | parsed);
}

const Color _fallbackColor = Color(0xFF64748B);
