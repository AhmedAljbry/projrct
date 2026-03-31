import 'package:flutter/material.dart';

class LamaMaskPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final double brushSize;
  final double softness;
  final Color color;

  LamaMaskPainter({
    required this.strokes,
    required this.brushSize,
    this.softness = 0,
    this.color = const Color(0x88FF0055),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = brushSize
      ..maskFilter =
          softness > 0 ? MaskFilter.blur(BlurStyle.normal, softness) : null;

    for (final pts in strokes) {
      if (pts.isEmpty) continue;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LamaMaskPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.brushSize != brushSize ||
        oldDelegate.softness != softness ||
        oldDelegate.color != color;
  }
}
