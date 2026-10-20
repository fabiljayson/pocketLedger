import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

// ── Frosted glass panel ──────────────────────────────────────────────────

/// The recurring frosted container of the design system: translucent fill,
/// backdrop blur, thin border, soft shadow. Use for summary cards, list
/// panels and dialogs content; keep forms and dense text on solid fills.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius = AppRadius.lg,
    this.onTap,
    this.semanticsLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final radius = BorderRadius.circular(borderRadius);

    final card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
            borderRadius: radius,
            border: Border.all(
              color: isDark
                  ? AppColors.glassBorderDark
                  : AppColors.glassBorderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.primaryStrong)
                    .withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    final wrapped = semanticsLabel == null
        ? card
        : Semantics(label: semanticsLabel, container: true, child: card);

    if (onTap == null) return wrapped;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: wrapped,
    );
  }
}
