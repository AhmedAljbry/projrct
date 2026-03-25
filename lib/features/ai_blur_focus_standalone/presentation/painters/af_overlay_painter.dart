import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/af_blur_mode.dart';
import '../../domain/models/af_blur_settings.dart';
import '../../domain/models/af_mask_data.dart';

class AfOverlayPainter extends CustomPainter {
  const AfOverlayPainter({
    required this.settings,
    required this.showMaskOverlay,
    required this.segmentation,
    required this.refineMaskMode,
  });

  final AfBlurSettings settings;
  final bool showMaskOverlay;
  final AfMaskData? segmentation;
  final bool refineMaskMode;

  static const _accent = Color(0xFF56E39F);

  @override
  void paint(Canvas canvas, Size size) {
    _paintVignette(canvas, size);
    switch (settings.mode) {
      case AfBlurMode.smart:
        _paintSmart(canvas, size);
      case AfBlurMode.circle:
        _paintCircle(canvas, size);
      case AfBlurMode.line:
        _paintLine(canvas, size);
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: showMaskOverlay ? 0.04 : 0.16),
      ],
      stops: const [0.55, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.longestSide * 1.4,
            height: size.longestSide * 1.4,
          ),
        ),
    );
  }

  void _paintSmart(Canvas canvas, Size size) {
    final mask = segmentation;
    final bounds = mask?.primaryBounds;
    if (mask == null || bounds == null || mask.usedFallback) {
      return;
    }

    final rect = Rect.fromLTWH(
      bounds.left * size.width,
      bounds.top * size.height,
      bounds.width * size.width,
      bounds.height * size.height,
    );
    final rrect =
        RRect.fromRectAndRadius(rect.inflate(8), const Radius.circular(28));

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = refineMaskMode ? 3.4 : 2.6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        ..color = refineMaskMode
            ? _accent.withValues(alpha: 0.52)
            : Colors.white.withValues(alpha: 0.24),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = refineMaskMode ? 2.2 : 1.4
        ..color =
            refineMaskMode ? _accent : Colors.white.withValues(alpha: 0.88),
    );

    if (showMaskOverlay) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(22)),
        Paint()..color = _accent.withValues(alpha: 0.18),
      );
    }
  }

  void _paintCircle(Canvas canvas, Size size) {
    final circle = settings.circleSettings;
    final cx = circle.centerX * size.width;
    final cy = circle.centerY * size.height;
    final rw = circle.radiusX * 2 * size.width;
    final rh = circle.radiusY * 2 * size.height;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(circle.rotation);

    final focus = Rect.fromCenter(center: Offset.zero, width: rw, height: rh);
    final transition = settings.transitionAmount * size.shortestSide * 0.26;
    final outer = focus.inflate(transition);

    canvas.drawOval(
      focus,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ).createShader(focus)
        ..blendMode = BlendMode.screen,
    );
    _dashedOval(
      canvas,
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.30),
    );
    canvas.drawOval(
      focus,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white,
    );
    _handle(canvas, Offset(focus.width / 2, 0));
    canvas.restore();
  }

  void _paintLine(Canvas canvas, Size size) {
    final line = settings.lineSettings;
    final center =
        Offset(line.centerX * size.width, line.centerY * size.height);
    final dir = Offset(math.cos(line.angle), math.sin(line.angle));
    final perp = Offset(-dir.dy, dir.dx);
    final bandHalf = perp * (line.width * size.shortestSide);
    final transitionHalf =
        perp * ((line.width + line.transition) * size.shortestSide);
    final length = size.longestSide * 1.2;

    final solid = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawLine(center - dir * length - bandHalf,
        center + dir * length - bandHalf, solid);
    canvas.drawLine(center - dir * length + bandHalf,
        center + dir * length + bandHalf, solid);

    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 1.2;
    _dashedLine(canvas, center - dir * length - transitionHalf,
        center + dir * length - transitionHalf, dash);
    _dashedLine(canvas, center - dir * length + transitionHalf,
        center + dir * length + transitionHalf, dash);

    _handle(canvas, center);
  }

  void _handle(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 7, Paint()..color = _accent);
    canvas.drawCircle(
        pos, 5, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  void _dashedOval(Canvas canvas, Rect rect, Paint paint,
      {double dash = 7, double gap = 5}) {
    const steps = 200;
    const twoPi = math.pi * 2;
    final rx = rect.width / 2;
    final ry = rect.height / 2;
    var drawing = true;
    var remaining = 0.0;
    Offset? previous;

    for (var i = 0; i <= steps; i++) {
      final angle = (i / steps) * twoPi;
      final point = Offset(
        rect.center.dx + rx * math.cos(angle),
        rect.center.dy + ry * math.sin(angle),
      );
      if (previous != null) {
        remaining += (point - previous).distance;
        if (drawing) {
          if (remaining >= dash) {
            canvas.drawLine(previous, point, paint);
            remaining -= dash;
            drawing = false;
          }
        } else if (remaining >= gap) {
          remaining -= gap;
          drawing = true;
        }
      }
      previous = point;
    }
  }

  void _dashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      {double dash = 8, double gap = 5}) {
    final total = (end - start).distance;
    if (total < 1) {
      return;
    }
    final dir = (end - start) / total;
    var pos = 0.0;
    var drawing = true;
    while (pos < total) {
      final segment = drawing ? dash : gap;
      final next = math.min(pos + segment, total);
      if (drawing) {
        canvas.drawLine(start + dir * pos, start + dir * next, paint);
      }
      pos = next;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant AfOverlayPainter oldDelegate) {
    return oldDelegate.settings != settings ||
        oldDelegate.showMaskOverlay != showMaskOverlay ||
        oldDelegate.segmentation != segmentation ||
        oldDelegate.refineMaskMode != refineMaskMode;
  }
}
