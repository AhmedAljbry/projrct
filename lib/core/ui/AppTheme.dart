import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled2/core/ui/AppTokens.dart';



class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppTokens.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppTokens.primary,
      secondary: AppTokens.accent,
      surface: AppTokens.surface,
      error: AppTokens.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTokens.surface,
      foregroundColor: AppTokens.text,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.black,
        elevation: 8,
        shadowColor: AppTokens.primary.withValues(alpha: 0.4),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.r16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTokens.text,
        side: const BorderSide(color: AppTokens.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.r16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppTokens.primary,
      thumbColor: AppTokens.primary,
      inactiveTrackColor: AppTokens.card2,
      overlayColor: Color(0x33B388FF),
      trackHeight: 3,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppTokens.primary : AppTokens.text2),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppTokens.primary.withValues(alpha: 0.3) : AppTokens.card),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppTokens.card,
      selectedColor: AppTokens.primary.withValues(alpha: 0.2),
      labelStyle: const TextStyle(color: AppTokens.text, fontWeight: FontWeight.w700, fontSize: 12),
      secondaryLabelStyle: const TextStyle(color: AppTokens.primary, fontWeight: FontWeight.w700, fontSize: 12),
      side: BorderSide(color: AppTokens.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rFull)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppTokens.surface,
      contentTextStyle: const TextStyle(color: AppTokens.text, fontWeight: FontWeight.w700),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r16),
        side: const BorderSide(color: AppTokens.border),
      ),
    ),
    fontFamily: 'SF Pro Display',
  );
}
