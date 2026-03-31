import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViralStudioTokens {
  const ViralStudioTokens._();

  static const Color background = Color(0xFF0A1017);
  static const Color surface = Color(0xFF121C28);
  static const Color surfaceSoft = Color(0xFF182434);
  static const Color outline = Color(0xFF2A3B52);
  static const Color accent = Color(0xFFFF6A3D);
  static const Color accentSoft = Color(0xFFFFB15B);
  static const Color cool = Color(0xFF45C7FF);
  static const Color textPrimary = Color(0xFFF7F4EF);
  static const Color textMuted = Color(0xFFAAB8C8);

  static LinearGradient get pageGlow => const LinearGradient(
        colors: <Color>[
          Color(0xFF0A1017),
          Color(0xFF101A27),
          Color(0xFF151117)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxDecoration panelDecoration({bool emphasized = false}) {
    return BoxDecoration(
      color: emphasized ? surfaceSoft : surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: outline.withValues(alpha: 0.9)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: emphasized ? 0.32 : 0.18),
          blurRadius: emphasized ? 32 : 18,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  static TextStyle headline([double size = 34]) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      height: 1.05,
    );
  }

  static TextStyle sectionTitle() {
    return GoogleFonts.spaceGrotesk(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: textPrimary,
    );
  }

  static TextStyle body([double size = 14]) {
    return GoogleFonts.manrope(
      fontSize: size,
      height: 1.4,
      color: textMuted,
      fontWeight: FontWeight.w500,
    );
  }

  static ButtonStyle primaryButton() {
    return FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      textStyle: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  static ButtonStyle secondaryButton() {
    return OutlinedButton.styleFrom(
      foregroundColor: textPrimary,
      side: BorderSide(color: outline.withValues(alpha: 0.9)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      textStyle: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}
