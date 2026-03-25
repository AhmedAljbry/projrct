import 'package:flutter/material.dart';

import '../../domain/models/af_mask_data.dart';

/// Draws a live brush cursor ring at the current finger position.
class AfBrushCursorPainter extends CustomPainter {
  const AfBrushCursorPainter({
    required this.position,
    required this.radius,
    required this.add,
  });

  final AfStrokePoint position;
  final double radius;
  final bool add;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = position.x * size.width;
    final cy = position.y * size.height;
    final r = (radius * size.shortestSide).clamp(4.0, size.shortestSide * 0.5);
    final center = Offset(cx, cy);

    final accent = add ? const Color(0xFF56E39F) : const Color(0xFFFF7A7A);

    // White outer ring
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white.withValues(alpha: 0.92),
    );
    // Coloured inner ring
    canvas.drawCircle(
      center,
      (r - 2).clamp(2.0, r),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = accent.withValues(alpha: 0.85),
    );
    // Centre dot
    canvas.drawCircle(center, 2.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant AfBrushCursorPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.radius != radius ||
      oldDelegate.add != add;
}

/// Paints the semi-transparent trail of a stroke in progress.
class AfStrokeTrailPainter extends CustomPainter {
  const AfStrokeTrailPainter({
    required this.points,
    required this.radius,
    required this.add,
  });

  final List<AfStrokePoint> points;
  final double radius;
  final bool add;

  @override
  void paint(Canvas canvas, Size size) {
    final color = add ? const Color(0x4A56E39F) : const Color(0x4AFF7A7A);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final r = radius * size.shortestSide;
    for (final pt in points) {
      canvas.drawCircle(
          Offset(pt.x * size.width, pt.y * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AfStrokeTrailPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.radius != radius ||
      oldDelegate.add != add;
}
