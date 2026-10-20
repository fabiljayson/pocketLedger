import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

// ── Theme factory ────────────────────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static ThemeData _build(Brightness brightness) {
    final isDarkTheme = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.text,
      primaryContainer: isDarkTheme
          ? AppColors.primaryStrong
          : AppColors.primarySoft,
      onPrimaryContainer: isDarkTheme ? AppColors.textOnDark : AppColors.text,
      secondary: AppColors.primaryStrong,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.primarySoft,
      onSecondaryContainer: AppColors.text,
      tertiary: AppColors.success,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: isDarkTheme ? AppColors.scaffoldDark : Colors.white,
      onSurface: isDarkTheme ? AppColors.textOnDark : AppColors.text,
      onSurfaceVariant: isDarkTheme
          ? const Color(0xFFB6D7EC)
          : const Color(0xFF3D6A85),
      outline: isDarkTheme
          ? AppColors.glassBorderDark
          : const Color(0x66075985),
      outlineVariant: isDarkTheme
          ? const Color(0x22BAE6FD)
          : const Color(0x33075985),
      shadow: Colors.black,
      surfaceContainerHighest: isDarkTheme
          ? const Color(0xFF0E2438)
          : AppColors.surface,
      surfaceTint: AppColors.primary,
    );

    final baseText = ThemeData(brightness: brightness).textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppFonts.family,
      textTheme: _applyFallback(_buildText(baseText, isDarkTheme)),
      scaffoldBackgroundColor: isDarkTheme
          ? AppColors.scaffoldDark
          : AppColors.scaffoldLight,
      splashFactory: InkSparkle.splashFactory,
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      highlightColor: AppColors.primary.withValues(alpha: 0.08),
      cardTheme: CardThemeData(
        color: isDarkTheme ? AppColors.glassFillDark : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: isDarkTheme
                ? AppColors.glassBorderDark
                : AppColors.glassBorderLight,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkTheme
            ? const Color(0xCC10263A)
            : const Color(0xCCFFFFFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        labelStyle: TextStyle(
          color: isDarkTheme ? AppColors.textOnDark : AppColors.text,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: (isDarkTheme ? AppColors.textOnDark : AppColors.text)
              .withValues(alpha: 0.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.primaryStrong.withValues(alpha: 0.35),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.primaryStrong.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.text,
          disabledBackgroundColor: AppColors.primarySoft,
          disabledForegroundColor: AppColors.text.withValues(alpha: 0.45),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryStrong,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primarySoft,
          disabledForegroundColor: AppColors.text.withValues(alpha: 0.45),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryStrong,
          side: const BorderSide(color: AppColors.primaryStrong),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryStrong,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          minimumSize: const Size(48, 44),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primaryStrong,
          minimumSize: const Size(44, 44),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDarkTheme ? const Color(0xFF0E2438) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDarkTheme ? AppColors.textOnDark : AppColors.text,
        ),
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDarkTheme ? AppColors.textOnDark : AppColors.text,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: (isDarkTheme ? AppColors.textOnDark : AppColors.border)
            .withValues(alpha: 0.15),
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDarkTheme
            ? const Color(0xE60E2438)
            : const Color(0xF2FFFFFF),
        selectedItemColor: AppColors.primaryStrong,
        unselectedItemColor: isDarkTheme
            ? const Color(0xFF9FBEDA)
            : const Color(0xFF547C96),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        elevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.text,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primarySoft.withValues(alpha: 0.45),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isDarkTheme ? AppColors.textOnDark : AppColors.text,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.primaryStrong,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surfaceMuted,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primaryStrong,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 4,
        ),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDarkTheme ? AppColors.textOnDark : AppColors.text,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: isDarkTheme
              ? const Color(0xFFB6D7EC)
              : const Color(0xFF3D6A85),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── Typography scale ───────────────────────────────────────────────────

  static TextTheme _buildText(TextTheme _, bool isDarkTheme) {
    final color = isDarkTheme ? AppColors.textOnDark : AppColors.text;
    final mutedColor = isDarkTheme
        ? const Color(0xFFB6D7EC)
        : const Color(0xFF3D6A85);
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0,
        height: 1.15,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: mutedColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: mutedColor,
      ),
    );
  }

  static TextTheme _applyFallback(TextTheme base) {
    TextStyle? apply(TextStyle? style) =>
        style?.copyWith(fontFamilyFallback: AppFonts.fallback);
    return base.copyWith(
      displayLarge: apply(base.displayLarge),
      displayMedium: apply(base.displayMedium),
      displaySmall: apply(base.displaySmall),
      headlineLarge: apply(base.headlineLarge),
      headlineMedium: apply(base.headlineMedium),
      headlineSmall: apply(base.headlineSmall),
      titleLarge: apply(base.titleLarge),
      titleMedium: apply(base.titleMedium),
      titleSmall: apply(base.titleSmall),
      bodyLarge: apply(base.bodyLarge),
      bodyMedium: apply(base.bodyMedium),
      bodySmall: apply(base.bodySmall),
      labelLarge: apply(base.labelLarge),
      labelMedium: apply(base.labelMedium),
      labelSmall: apply(base.labelSmall),
    );
  }
}
