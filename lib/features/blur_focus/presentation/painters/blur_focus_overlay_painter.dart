import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_mode.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_settings.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';

/// Overlay drawn on top of the live image canvas.
///
/// v2 changes:
/// - Removed the full-area dark rectangle that made previews look artificially
///   dimmed.  Replaced with a thin gradient vignette on the outer 12% of the
///   canvas so the focus region feels "lifted" without tinting everything.
/// - Circle mode: added dashed outer transition ring and a resize/rotate handle.
/// - Line mode:  added gradient bands instead of flat lines.
/// - Smart mode: uses a soft glowing outline instead of a hard stroke.
class BlurFocusOverlayPainter extends CustomPainter {
  const BlurFocusOverlayPainter({
    required this.settings,
    required this.showMaskPreview,
    required this.segmentation,
    required this.refineMaskMode,
  });

  final BlurSettings settings;
  final bool showMaskPreview;
  final SegmentationResultData? segmentation;
  final bool refineMaskMode;

  // Brand accent
  static const _accent = Color(0xFF56E39F);

  @override
  void paint(Canvas canvas, Size size) {
    // ── Soft vignette only around the edges (replaces the old flat overlay) ─
    _paintVignette(canvas, size);

    switch (settings.mode) {
      case BlurMode.full:
        return;
      case BlurMode.smart:
        _paintSmart(canvas, size);
      case BlurMode.circle:
        _paintCircle(canvas, size);
      case BlurMode.line:
        _paintLine(canvas, size);
    }
  }

  // ── Vignette ─────────────────────────────────────────────────────────────

  void _paintVignette(Canvas canvas, Size size) {
    // A radial gradient from transparent center to a very subtle dark ring at
    // the edges — depth of field effect without killing the whole image.
    final vignetteRadius = size.longestSide * 0.72;
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: showMaskPreview ? 0.06 : 0.18),
      ],
      stops: const [0.58, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: vignetteRadius * 2,
          height: vignetteRadius * 2,
        ),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  // ── Smart mode ────────────────────────────────────────────────────────────

  void _paintSmart(Canvas canvas, Size size) {
    final bounds = segmentation?.primaryBounds;
    if (bounds == null) {
      // No subject yet — don't show any circle fallback in smart mode
      return;
    }

    final rect = Rect.fromLTWH(
      bounds.left * size.width,
      bounds.top * size.height,
      bounds.width * size.width,
      bounds.height * size.height,
    );
    final rrect = RRect.fromRectAndRadius(rect.inflate(8), const Radius.circular(28));

    // Glow outer stroke
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = refineMaskMode ? 3.4 : 2.6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..color = refineMaskMode
            ? _accent.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.30),
    );
    // Crisp inner stroke
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = refineMaskMode ? 2.4 : 1.6
        ..color =
            refineMaskMode ? _accent : Colors.white.withValues(alpha: 0.88),
    );

    // Mask highlight fill
    if (showMaskPreview) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(24)),
        Paint()..color = _accent.withValues(alpha: 0.22),
      );
    }
  }

  // ── Circle mode ───────────────────────────────────────────────────────────

  void _paintCircle(Canvas canvas, Size size) {
    final circle = settings.circleSettings;
    final cx = circle.centerX * size.width;
    final cy = circle.centerY * size.height;
    final rw = circle.radiusX * 2 * size.width;
    final rh = circle.radiusY * 2 * size.height;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(circle.rotation);

    final focusRect = Rect.fromCenter(
        center: Offset.zero, width: rw, height: rh);
    final transitionInflate = settings.transitionAmount * size.shortestSide * 0.26;
    final transitionRect = focusRect.inflate(transitionInflate);

    // Gradient inside the focus ellipse (subtle brightening hint)
    final innerGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.04),
        Colors.transparent,
      ],
    );
    canvas.drawOval(
      focusRect,
      Paint()
        ..shader = innerGradient.createShader(focusRect)
        ..blendMode = BlendMode.screen,
    );

    // Outer transition ring (dashed)
    _drawDashedOval(canvas, transitionRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.30),
        dashLength: 6, gapLength: 5);

    // Main focus ellipse
    canvas.drawOval(
      focusRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white,
    );

    // Resize handle
    canvas.drawCircle(
      Offset(focusRect.width / 2, 0),
      7,
      Paint()..color = _accent,
    );
    canvas.drawCircle(
      Offset(focusRect.width / 2, 0),
      5,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    canvas.restore();
  }

  /// Draws a dashed oval approximated with short line segments.
  void _drawDashedOval(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    double dashLength = 6,
    double gapLength = 4,
  }) {
    const steps = 180;
    const fullCircle = math.pi * 2;
    final rx = rect.width / 2;
    final ry = rect.height / 2;
    var drawing = true;
    var remaining = 0.0;
    Offset? prev;

    for (var i = 0; i <= steps; i++) {
      final angle = (i / steps) * fullCircle;
      final pt = Offset(
        rect.center.dx + rx * math.cos(angle),
        rect.center.dy + ry * math.sin(angle),
      );
      if (prev != null) {
        final segLen = (pt - prev).distance;
        remaining += segLen;
        if (drawing) {
          if (remaining >= dashLength) {
            canvas.drawLine(prev, pt, paint);
            remaining -= dashLength;
            drawing = false;
          }
        } else {
          if (remaining >= gapLength) {
            remaining -= gapLength;
            drawing = true;
          }
        }
      }
      prev = pt;
    }
  }

  // ── Line mode ─────────────────────────────────────────────────────────────

  void _paintLine(Canvas canvas, Size size) {
    final line = settings.lineSettings;
    final center = Offset(line.centerX * size.width, line.centerY * size.height);
    final dir = Offset(math.cos(line.angle), math.sin(line.angle));
    final perp = Offset(-dir.dy, dir.dx);
    final bandHalf = perp * (line.width * size.shortestSide);
    final transHalf =
        perp * ((line.width + line.transition) * size.shortestSide);
    final length = size.longestSide * 1.2;

    // Gradient between bands for soft transition feel
    final bandEdge1 = center - bandHalf;
    final bandEdge2 = center + bandHalf;
    final gradientRect = Rect.fromPoints(
      bandEdge1 - Offset(perp.dx * size.shortestSide * 0.3, perp.dy * size.shortestSide * 0.3),
      bandEdge2 + Offset(perp.dx * size.shortestSide * 0.3, perp.dy * size.shortestSide * 0.3),
    );
    canvas.drawRect(
      gradientRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(gradientRect),
    );

    // Solid focus band lines
    final solidPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2;
    canvas.drawLine(
        center - (dir * length) - bandHalf, center + (dir * length) - bandHalf, solidPaint);
    canvas.drawLine(
        center - (dir * length) + bandHalf, center + (dir * length) + bandHalf, solidPaint);

    // Dashed transition lines
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..strokeWidth = 1.2;
    _drawDashedLine(canvas,
        center - (dir * length) - transHalf, center + (dir * length) - transHalf, dashPaint);
    _drawDashedLine(canvas,
        center - (dir * length) + transHalf, center + (dir * length) + transHalf, dashPaint);

    // Center anchor dot
    canvas.drawCircle(center, 7, Paint()..color = _accent);
    canvas.drawCircle(center, 5, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashLength = 8,
    double gapLength = 5,
  }) {
    final total = (end - start).distance;
    if (total < 1) return;
    final dir = (end - start) / total;
    var pos = 0.0;
    var drawing = true;
    while (pos < total) {
      final segLen = drawing ? dashLength : gapLength;
      final nextPos = math.min(pos + segLen, total);
      if (drawing) {
        canvas.drawLine(start + dir * pos, start + dir * nextPos, paint);
      }
      pos = nextPos;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant BlurFocusOverlayPainter oldDelegate) {
    return oldDelegate.settings != settings ||
        oldDelegate.showMaskPreview != showMaskPreview ||
        oldDelegate.segmentation != segmentation ||
        oldDelegate.refineMaskMode != refineMaskMode;
  }
}



