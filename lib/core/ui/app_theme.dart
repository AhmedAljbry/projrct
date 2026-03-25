// app_theme.dart — Dark & Light Theme
import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTheme {
  AppTheme._();

  // ─── Dark Theme ───────────────────────────────────────────────
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.primary,
      brightness: Brightness.dark,
      surface: AppTokens.surface,
      background: AppTokens.bg,
      error: AppTokens.danger,
      primary: AppTokens.primary,
      onPrimary: Colors.black,
      secondary: AppTokens.accent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTokens.bg,
      fontFamily: 'Inter',

      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppTokens.text,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppTokens.text2),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTokens.card2,
        contentTextStyle: const TextStyle(
          color: AppTokens.text,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      sliderTheme: SliderThemeData(
        trackHeight: 2,
        activeTrackColor: AppTokens.primary.withValues(alpha: 0.9),
        inactiveTrackColor: AppTokens.text2.withValues(alpha: 0.15),
        thumbColor: AppTokens.primary,
        overlayColor: AppTokens.primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        valueIndicatorColor: AppTokens.primary,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        showValueIndicator: ShowValueIndicator.always,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppTokens.card,
        selectedColor: AppTokens.primary.withValues(alpha: 0.16),
        labelStyle: const TextStyle(
          color: AppTokens.text2,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppTokens.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        side: BorderSide(color: AppTokens.text2.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.primary,
          side: const BorderSide(color: AppTokens.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppTokens.text2,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.card,
        hintStyle: TextStyle(color: AppTokens.text2.withValues(alpha: 0.4), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      tabBarTheme: const TabBarTheme(
        labelColor: AppTokens.primary,
        unselectedLabelColor: AppTokens.text2,
        indicatorColor: AppTokens.primary,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),

      cardColor: AppTokens.card,
      cardTheme: CardTheme(
        color: AppTokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: AppTokens.text2.withValues(alpha: 0.1),
        thickness: 1,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppTokens.text,
          fontWeight: FontWeight.w900,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: AppTokens.text,
          fontWeight: FontWeight.w900,
          fontSize: 26,
        ),
        titleLarge: TextStyle(
          color: AppTokens.text,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: AppTokens.text,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          color: AppTokens.text2,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        bodyLarge: TextStyle(
          color: AppTokens.text,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: AppTokens.text2,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        bodySmall: TextStyle(
          color: AppTokens.text3,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        labelLarge: TextStyle(
          color: AppTokens.text,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ─── Light Theme ─────────────────────────────────────────────
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.primary,
      brightness: Brightness.light,
      primary: AppTokens.primary,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: AppTokens.primary,
        thumbColor: AppTokens.primary,
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }
}
