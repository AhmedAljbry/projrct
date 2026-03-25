import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/line_params.dart';

/// Paints the interactive tilt-shift line overlay on the canvas.
class LineOverlayPainter extends CustomPainter {
  LineOverlayPainter({
    required this.params,
    required this.accentColor,
    required this.isDragging,
  });

  final LineBlurParams params;
  final Color accentColor;
  final bool isDragging;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = params.centerX * size.width;
    final cy = params.centerY * size.height;
    final halfBand = params.bandWidth * size.height;
    final angle = params.angle;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    // Blur zone fill
    final zonePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(-size.width, -halfBand, size.width, halfBand),
      zonePaint,
    );

    // Top & bottom band lines
    final linePaint = Paint()
      ..color = accentColor.withValues(alpha: isDragging ? 0.90 : 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDragging ? 2.2 : 1.6;

    canvas.drawLine(
      Offset(-size.width, -halfBand),
      Offset(size.width, -halfBand),
      linePaint,
    );
    canvas.drawLine(
      Offset(-size.width, halfBand),
      Offset(size.width, halfBand),
      linePaint,
    );

    // Center line (dashed)
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    _drawDashedHLine(canvas, size.width, dashPaint);

    // Vertical centre drag handle
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final shadowP = Paint()
      ..color = Colors.black.withValues(alpha: 0.50)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, 11, shadowP);
    canvas.drawCircle(Offset.zero, 9, handlePaint);
    canvas.drawCircle(
        Offset.zero,
        9,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);

    // Rotation handle at top edge
    const rotHY = -46.0;
    canvas.drawCircle(Offset(0, -halfBand - rotHY), 8, shadowP);
    canvas.drawCircle(Offset(0, -halfBand - rotHY), 6.5, handlePaint);
    canvas.drawCircle(
        Offset(0, -halfBand - rotHY),
        6.5,
        Paint()
          ..color = accentColor.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    // Arrow icon
    canvas.drawLine(
      Offset(-5, -halfBand - rotHY),
      Offset(5, -halfBand - rotHY),
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  void _drawDashedHLine(Canvas canvas, double halfWidth, Paint paint) {
    const dashLen = 8.0;
    const gap = 6.0;
    var x = -halfWidth;
    while (x < halfWidth) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashLen, 0), paint);
      x += dashLen + gap;
    }
  }

  @override
  @override
  bool shouldRepaint(LineOverlayPainter oldDelegate) =>
      oldDelegate.params != params || oldDelegate.isDragging != isDragging;

  bool hitTestCenter(Offset local, Size size) {
    final cx = params.centerX * size.width;
    final cy = params.centerY * size.height;
    return (local - Offset(cx, cy)).distance < 34;
  }

  bool hitTestRotationHandle(Offset local, Size size) {
    final cx = params.centerX * size.width;
    final cy = params.centerY * size.height;
    final halfBand = params.bandWidth * size.height;
    const rotHY = 46.0;

    // Handle position in canvas coords (after rotation)
    final rotatedDy = -(halfBand + rotHY);
    final cosA = math.cos(params.angle);
    final sinA = math.sin(params.angle);
    final hx = cx + rotatedDy * (-sinA); // rotate (0, rotatedDy)
    final hy = cy + rotatedDy * cosA;
    return (local - Offset(hx, hy)).distance < 26;
  }
}
