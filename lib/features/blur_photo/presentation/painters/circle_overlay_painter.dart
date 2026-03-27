import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/circle_params.dart';

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
    final shapeRect = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(params.rotation);

    final haloPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDragging ? 0.24 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final ringPaint = Paint()
      ..color = accentColor.withValues(alpha: isDragging ? 0.95 : 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDragging ? 2.2 : 1.6;

    if (params.shapeType == BlurShapeType.rectangle) {
      final haloRect = shapeRect.inflate(6);
      final radius = Radius.circular(math.min(rx, ry) * 0.18 + 8);
      canvas.drawRRect(RRect.fromRectAndRadius(haloRect, radius), haloPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(shapeRect, radius), ringPaint);
    } else {
      canvas.drawOval(shapeRect.inflate(6), haloPaint);
      canvas.drawOval(shapeRect, ringPaint);
    }

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.50)
      ..style = PaintingStyle.fill;

    final handles = [
      Offset(rx, 0),
      Offset(-rx, 0),
      Offset(0, ry),
      Offset(0, -ry),
    ];
    const handleRadius = 6.0;
    for (final handle in handles) {
      canvas.drawCircle(handle, handleRadius + 2, shadowPaint);
      canvas.drawCircle(handle, handleRadius, handlePaint);
      canvas.drawCircle(
        handle,
        handleRadius,
        Paint()
          ..color = accentColor.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    canvas.drawCircle(Offset.zero, 5, handlePaint);
    canvas.drawCircle(
      Offset.zero,
      5,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(CircleOverlayPainter oldDelegate) =>
      oldDelegate.params != params || oldDelegate.isDragging != isDragging;

  bool hitTestCenter(Offset local, Size size) {
    final cx = params.centerX * size.width;
    final cy = params.centerY * size.height;
    return (local - Offset(cx, cy)).distance < 30;
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
    return handles.any((handle) => (local - handle).distance < 20);
  }
}
