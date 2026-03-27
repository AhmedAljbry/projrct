import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/line_params.dart';

/// Paints the interactive one-sided line overlay on the canvas.
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
    final protectedDepth = params.bandWidth * size.height * 0.35;
    final fadeDepth = (params.bandWidth + params.feather) * size.height;
    final angle = params.angle;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    final protectedPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(-size.width, -size.height, size.width, protectedDepth),
      protectedPaint,
    );

    final fadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.12),
          accentColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(
        Rect.fromLTRB(-size.width, protectedDepth, size.width, fadeDepth),
      );
    canvas.drawRect(
      Rect.fromLTRB(-size.width, protectedDepth, size.width, fadeDepth),
      fadePaint,
    );

    final linePaint = Paint()
      ..color = accentColor.withValues(alpha: isDragging ? 0.92 : 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDragging ? 2.2 : 1.6;

    canvas.drawLine(
      Offset(-size.width, 0),
      Offset(size.width, 0),
      linePaint,
    );

    final edgePaint = Paint()
      ..color = accentColor.withValues(alpha: isDragging ? 0.5 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(-size.width, protectedDepth),
      Offset(size.width, protectedDepth),
      edgePaint,
    );

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    _drawDashedHLine(canvas, size.width, dashPaint);

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
        ..strokeWidth = 1.6,
    );

    const rotHY = -46.0;
    canvas.drawCircle(Offset(0, rotHY), 8, shadowP);
    canvas.drawCircle(Offset(0, rotHY), 6.5, handlePaint);
    canvas.drawCircle(
      Offset(0, rotHY),
      6.5,
      Paint()
        ..color = accentColor.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawLine(
      const Offset(-5, rotHY),
      const Offset(5, rotHY),
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
    const rotatedDy = -46.0;
    final cosA = math.cos(params.angle);
    final sinA = math.sin(params.angle);
    final hx = cx + rotatedDy * (-sinA);
    final hy = cy + rotatedDy * cosA;
    return (local - Offset(hx, hy)).distance < 26;
  }
}
