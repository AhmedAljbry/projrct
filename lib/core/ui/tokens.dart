// tokens.dart — Design System Tokens
import 'package:flutter/material.dart';

class AppTokens {
  // ─── Background Layers ───────────────────────────────────────
  static const bg       = Color(0xFF0B0F14);
  static const surface  = Color(0xFF0F1720);
  static const card     = Color(0xFF111A24);
  static const card2    = Color(0xFF16202D);

  // ─── Accent Colors ────────────────────────────────────────────
  static const primary  = Color(0xFF2EE59D); // Mint Green
  static const accent   = Color(0xFF7B61FF); // Purple
  static const gold     = Color(0xFFFFD166); // Gold
  static const danger   = Color(0xFFFF4D5A);
  static const warning  = Color(0xFFFFC34D);
  static const info     = Color(0xFF5BC8FB);

  // ─── Text ─────────────────────────────────────────────────────
  static const text     = Colors.white;
  static const text2    = Colors.white70;
  static const text3    = Colors.white38;

  // ─── Gradients ────────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF2EE59D), Color(0xFF00B8D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientPurple = LinearGradient(
    colors: [Color(0xFF7B61FF), Color(0xFFE040FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientDark = LinearGradient(
    colors: [Color(0xFF0B0F14), Color(0xFF0F1720)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Border Radius ────────────────────────────────────────────
  static const r8  = 8.0;
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r24 = 24.0;
  static const r32 = 32.0;

  // ─── Spacing ─────────────────────────────────────────────────
  static const s4  = 4.0;
  static const s8  = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  // ─── Durations ───────────────────────────────────────────────
  static const fast   = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 280);
  static const slow   = Duration(milliseconds: 480);

  // ─── Shadows ─────────────────────────────────────────────────
  static List<BoxShadow> glowShadow(Color color, {double blur = 20}) => [
    BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: blur, spreadRadius: 0),
  ];

  static const defaultShadow = [
    BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, -4)),
  ];
}
