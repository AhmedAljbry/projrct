import 'package:flutter/material.dart';

/// ─────────────────────────────────────────
///  StudioPro Design Tokens
///  Single source of truth for all visual values
/// ─────────────────────────────────────────
abstract class AppTokens {
  // ── Colours ──────────────────────────────
  static const Color bg = Color(0xFF08141B);
  static const Color surface = Color(0xFF0E1D25);
  static const Color card = Color(0xFF132733);
  static const Color card2 = Color(0xFF1A3442);

  static const Color primary = Color(0xFF69E6C3);
  static const Color accent = Color(0xFF27C9BC);
  static const Color gold = Color(0xFFFFD58A);
  static const Color warning = Color(0xFFFFB86A);
  static const Color danger = Color(0xFFF36F6F);
  static const Color success = Color(0xFF74D8A7);
  static const Color info = Color(0xFF74D5FF);

  static const Color text = Color(0xFFF3FAFF);
  static const Color text2 = Color(0xFF97AFBD);
  static const Color border = Color(0xFF24424F);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF61E1C5), Color(0xFF7DDFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD58A), Color(0xFFFFB86A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF10212B), Color(0xFF0A171E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Spacing ───────────────────────────────
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s7 = 7;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;

  // ── Radius ────────────────────────────────
  static const double r8 = 8;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r16 = 16;
  static const double r18 = 18;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r32 = 32;
  static const double rFull = 999;

  // ── Typography ────────────────────────────
  static const TextStyle headingXL = TextStyle(
    color: text,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
  );
  static const TextStyle headingL = TextStyle(
    color: text,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle headingM = TextStyle(
    color: text,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle bodyM = TextStyle(
    color: text2,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle labelBold = TextStyle(
    color: text,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle caption = TextStyle(
    color: text2,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // ── Shadows ───────────────────────────────
  static List<BoxShadow> primaryGlow(double opacity) => [
        BoxShadow(
            color: primary.withValues(alpha: opacity),
            blurRadius: 24,
            spreadRadius: 2),
      ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: 18,
        offset: const Offset(0, 6)),
  ];

  // ── Breakpoints ───────────────────────────
  static bool isTablet(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600;
  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 1024;
}
