import 'package:flutter/material.dart';
import '../../../inpainting/application/drawing/stroke.dart';

// ═══════════════════════════════════════════════════════════════
//  Design tokens (local — shared with other UI files)
// ═══════════════════════════════════════════════════════════════
const _kAccent = Color(0xFF00E5C8); // electric mint  → brush mode
const _kEraser = Color(0xFFFF5252); // coral-red       → eraser mode
const _kDotSz = 5.0;

// ═══════════════════════════════════════════════════════════════
//  BrushCursor
//
//  Premium floating cursor:
//   • Outer pulse ring  — slow breath animation
//   • Accent inner ring — thin, solid mode-color
//   • Center dot        — glowing pinpoint
//   • Radial halo       — soft ambient glow
// ═══════════════════════════════════════════════════════════════
class BrushCursor extends StatefulWidget {
  final Offset? point;
  final double size; // screen-px diameter
  final bool visible;
  final BrushKind kind;

  const BrushCursor({
    super.key,
    required this.point,
    required this.size,
    required this.visible,
    required this.kind,
  });

  @override
  State<BrushCursor> createState() => _BrushCursorState();
}

class _BrushCursorState extends State<BrushCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _breathe;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _breathe = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || widget.point == null) return SizedBox.shrink();

    final r = (widget.size / 2).clamp(5.0, 130.0);
    final accent = widget.kind == BrushKind.eraser ? _kEraser : _kAccent;

    return Positioned(
      left: widget.point!.dx - r,
      top: widget.point!.dy - r,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _breathe,
          builder: (_, __) {
            final pulse = _breathe.value; // 0 → 1
            return SizedBox(
              width: r * 2,
              height: r * 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Ambient glow halo ────────────────────
                  Container(
                    width: r * 2,
                    height: r * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(
                            alpha: 0.22 * (0.5 + pulse * 0.5),
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // ── Outer breathing ring ─────────────────
                  Container(
                    width: r * 2,
                    height: r * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.25 + pulse * 0.45,
                        ),
                        width: 1.0,
                      ),
                    ),
                  ),

                  // ── Accent inner ring ────────────────────
                  Container(
                    width: (r - 4).clamp(2.0, double.infinity) * 2,
                    height: (r - 4).clamp(2.0, double.infinity) * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.7),
                        width: 0.75,
                      ),
                    ),
                  ),

                  // ── Center glowing dot ───────────────────
                  Container(
                    width: _kDotSz,
                    height: _kDotSz,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.9),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
