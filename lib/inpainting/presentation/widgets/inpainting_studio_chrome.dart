import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:untitled2/core/ui/AppL10n.dart';

class InpaintingStudioTheme {
  const InpaintingStudioTheme._();

  static const background = Color(0xFF0E151A);
  static const backgroundDeep = Color(0xFF0B1116);
  static const surface = Color(0xFF18232B);
  static const surfaceStrong = Color(0xFF22313B);
  static const surfaceSoft = Color(0xD9213039);
  static const border = Color(0x24FFFFFF);
  static const textPrimary = Color(0xFFF2F6F8);
  static const textSecondary = Color(0xFFB3C0C8);
  static const textMuted = Color(0xFF7D8A93);
  static const mint = Color(0xFF6DC6B0);
  static const cyan = Color(0xFF79A9D0);
  static const violet = Color(0xFF9A95C4);
  static const amber = Color(0xFFD9B77E);
  static const rose = Color(0xFFD191A0);
  static const danger = Color(0xFFC67B87);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF161F26),
      Color(0xFF10181E),
      Color(0xFF0B1217),
    ],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF273944),
      Color(0xFF1B2831),
      Color(0xFF141E25),
    ],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      mint,
      cyan,
    ],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      cyan,
      violet,
    ],
  );

  static BoxDecoration glassDecoration({
    double radius = 28,
    Gradient? gradient,
    Color? fillColor,
    Color borderColor = border,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: gradient,
      color: gradient == null ? (fillColor ?? surfaceSoft) : null,
      border: Border.all(color: borderColor),
      boxShadow: shadows ??
          const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StudioStepBreadcrumb
// 3-step progress indicator: Draw → Remove → Done
// ─────────────────────────────────────────────────────────────────────────────

class StudioStepBreadcrumb extends StatelessWidget {
  /// 1 = Draw mask, 2 = AI running, 3 = Done
  final int currentStep;
  final AppL10n l10n;

  const StudioStepBreadcrumb({
    super.key,
    required this.l10n,
    this.currentStep = 1,
  });

  List<String> get _steps => [
        l10n.get('breadcrumb_draw'),
        l10n.get('breadcrumb_remove'),
        l10n.get('breadcrumb_done'),
      ];
  static const _colors = [
    InpaintingStudioTheme.mint,
    InpaintingStudioTheme.violet,
    InpaintingStudioTheme.cyan,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // separator line
          final stepIndex = (i ~/ 2) + 1;
          final passed = stepIndex < currentStep;
          return Container(
            width: 16,
            height: 1.5,
            color: passed
                ? InpaintingStudioTheme.mint.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.12),
          );
        }
        final stepIndex = i ~/ 2;
        final stepNum = stepIndex + 1;
        final active = stepNum == currentStep;
        final done = stepNum < currentStep;
        final color = _colors[stepIndex];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
            horizontal: active ? 10 : 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.18)
                : done
                    ? color.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.36)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done)
                Icon(Icons.check_rounded, size: 11, color: color)
              else
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? color : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              if (active) ...[
                SizedBox(width: 5),
                Text(
                  _steps[stepIndex],
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StudioFloatingPillBar
// Glass pill container for compact horizontal toolbar row on narrow screens
// ─────────────────────────────────────────────────────────────────────────────

class StudioFloatingPillBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const StudioFloatingPillBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: InpaintingStudioTheme.surfaceSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2A000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class StudioGlowBackground extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final Color primaryGlow;
  final Color secondaryGlow;

  const StudioGlowBackground({
    super.key,
    required this.animation,
    required this.child,
    this.primaryGlow = InpaintingStudioTheme.mint,
    this.secondaryGlow = InpaintingStudioTheme.violet,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: InpaintingStudioTheme.backgroundGradient,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final shift = (animation.value - 0.5) * 26;
                return Stack(
                  children: [
                    _GlowOrb(
                      size: 260,
                      color: secondaryGlow,
                      top: 62,
                      start: -44 + shift,
                    ),
                    _GlowOrb(
                      size: 240,
                      color: primaryGlow,
                      bottom: 112,
                      end: -38 - shift,
                    ),
                    _GlowOrb(
                      size: 150,
                      color: InpaintingStudioTheme.cyan,
                      top: 282,
                      end: 40 + (shift * 0.4),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.015),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class StudioGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;
  final Color? fillColor;
  final Color borderColor;
  final double blurSigma;

  const StudioGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 28,
    this.gradient,
    this.fillColor,
    this.borderColor = InpaintingStudioTheme.border,
    this.blurSigma = 22,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: InpaintingStudioTheme.glassDecoration(
            radius: radius,
            gradient: gradient,
            fillColor: fillColor,
            borderColor: borderColor,
          ),
          child: child,
        ),
      ),
    );
  }
}

class StudioPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool filled;

  const StudioPill({
    super.key,
    required this.icon,
    required this.label,
    this.accent = InpaintingStudioTheme.mint,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = filled
        ? accent.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.05);
    final border = filled
        ? accent.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.08);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: filled ? InpaintingStudioTheme.textPrimary : accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class StudioPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool expanded;

  const StudioPrimaryButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = _StudioActionButton(
      onPressed: onPressed,
      gradient: InpaintingStudioTheme.primaryGradient,
      foreground: Colors.black,
      borderColor: Colors.transparent,
      icon: icon,
      label: label,
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class StudioSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color accent;

  const StudioSecondaryButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.accent = InpaintingStudioTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return _StudioActionButton(
      onPressed: onPressed,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      foreground: accent,
      borderColor: Colors.white.withValues(alpha: 0.08),
      icon: icon,
      label: label,
    );
  }
}

class StudioStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const StudioStatTile({
    super.key,
    required this.label,
    required this.value,
    this.accent = InpaintingStudioTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: InpaintingStudioTheme.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class StudioSectionLabel extends StatelessWidget {
  final String title;
  final String? subtitle;

  const StudioSectionLabel({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: InpaintingStudioTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(
              color: InpaintingStudioTheme.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _StudioActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color foreground;
  final Color borderColor;
  final IconData icon;
  final String label;

  const _StudioActionButton({
    required this.onPressed,
    this.gradient,
    this.backgroundColor,
    required this.foreground,
    required this.borderColor,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? (backgroundColor ?? Colors.white.withValues(alpha: 0.04))
                : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: disabled || gradient == null
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x246DC6B0),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: foreground),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double? top;
  final double? bottom;
  final double? start;
  final double? end;

  const _GlowOrb({
    required this.size,
    required this.color,
    this.top,
    this.bottom,
    this.start,
    this.end,
  });

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: top,
      bottom: bottom,
      start: start,
      end: end,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 68, sigmaY: 68),
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
