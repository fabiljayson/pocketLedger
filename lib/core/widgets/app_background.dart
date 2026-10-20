import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

// ── Gradient canvas ──────────────────────────────────────────────────────

/// Full-screen background providing the glassmorphism depth: a sky gradient
/// with soft luminous glows that frosted panels sit over.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final base = isDark
        ? const [Color(0xFF082F49), Color(0xFF04101C)]
        : const [Color(0xFFE0F2FE), Color(0xFFF0F9FF), Color(0xFFFFFFFF)];
    final glow = isDark
        ? AppColors.primary.withValues(alpha: 0.28)
        : AppColors.primary.withValues(alpha: 0.18);
    final glowSoft = isDark
        ? AppColors.primaryStrong.withValues(alpha: 0.35)
        : AppColors.primarySoft.withValues(alpha: 0.8);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: base,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _Glow(color: glow, size: 260),
          ),
          Positioned(
            bottom: 40,
            left: -100,
            child: _Glow(color: glowSoft, size: 240),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
