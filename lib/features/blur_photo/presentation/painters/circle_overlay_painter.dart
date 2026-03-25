import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/circle_params.dart';

/// Paints the interactive circle / ellipse overlay on the canvas.
class CircleOverlayPainter extends CustomPainter {
  CircleOverlayPainter({
    required this.params,
    required this.accentColor,
    required this.isDragging,
  });

  final CircleBlurParams params;
  final Color accentColor;
  final bool isDragging;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = params.centerX * size.width;
    final cy = params.centerY * size.height;
    final rx = params.radiusX * size.width;
    final ry = params.radiusY * size.height;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(params.rotation);

    // Outer soft halo
    final haloPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDragging ? 0.28 : 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2 + 12, height: ry * 2 + 12), haloPaint);

    // Primary ellipse ring
    final ringPaint = Paint()
      ..color = accentColor.withValues(alpha: isDragging ? 0.95 : 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDragging ? 2.4 : 1.8;
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        ringPaint);

    // Corner handles at 4 cardinal points
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final handles = [
      Offset(rx, 0),
      Offset(-rx, 0),
      Offset(0, ry),
      Offset(0, -ry),
    ];
    const r = 7.0;
    for (final h in handles) {
      canvas.drawCircle(h, r + 2, shadowPaint);
      canvas.drawCircle(h, r, handlePaint);
      canvas.drawCircle(h, r,
          Paint()
            ..color = accentColor.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
    }

    // Centre dot
    canvas.drawCircle(Offset.zero, 5, handlePaint);
    canvas.drawCircle(Offset.zero, 5,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);

    canvas.restore();
  }

  @override
  @override
  bool shouldRepaint(CircleOverlayPainter oldDelegate) =>
      oldDelegate.params != params || oldDelegate.isDragging != isDragging;

  /// Hit-tests centre or handle grab area in local coordinates.
  bool hitTestCenter(Offset local, Size size) {
    final cx = params.centerX * size.width;
    final cy = params.centerY * size.height;
    return (local - Offset(cx, cy)).distance < 32;
  }

  bool hitTestRadiusHandle(Offset local, Size size) {
    final cx = params.centerX * size.width;
    final cy = params.centerY * size.height;
    final rx = params.radiusX * size.width;
    final ry = params.radiusY * size.height;

    final handles = [
      Offset(cx + rx, cy),
      Offset(cx - rx, cy),
      Offset(cx, cy + ry),
      Offset(cx, cy - ry),
    ];
    return handles.any((h) => (local - h).distance < 24);
  }
}

// ignore: unused_element
double _deg2rad(double deg) => deg * math.pi / 180;
