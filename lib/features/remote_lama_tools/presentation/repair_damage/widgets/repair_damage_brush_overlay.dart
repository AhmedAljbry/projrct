import 'package:flutter/material.dart';

import 'package:untitled2/core/ui/cover_mapping.dart';

class RepairDamageBrushOverlay extends StatelessWidget {
  const RepairDamageBrushOverlay({
    super.key,
    required this.imageSize,
    required this.strokeImagePoints,
    required this.brushRadiusImage,
    required this.color,
    this.activeImagePoint,
  });

  final Size imageSize;
  final List<Offset> strokeImagePoints;
  final Offset? activeImagePoint;
  final double brushRadiusImage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RepairDamageBrushOverlayPainter(
        imageSize: imageSize,
        strokeImagePoints: strokeImagePoints,
        activeImagePoint: activeImagePoint,
        brushRadiusImage: brushRadiusImage,
        color: color,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class RepairDamageBrushOverlayPainter extends CustomPainter {
  const RepairDamageBrushOverlayPainter({
    required this.imageSize,
    required this.strokeImagePoints,
    required this.brushRadiusImage,
    required this.color,
    this.activeImagePoint,
  });

  final Size imageSize;
  final List<Offset> strokeImagePoints;
  final Offset? activeImagePoint;
  final double brushRadiusImage;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final imageRect = applyBoxFitContainRect(
      inputImageSize: imageSize,
      outputSize: size,
    );
    final imageToSceneScale = imageRect.width / imageSize.width;
    final brushRadiusScene =
        (brushRadiusImage * imageToSceneScale).clamp(2.0, size.shortestSide);

    if (strokeImagePoints.isNotEmpty) {
      final strokePaint = Paint()
        ..color = color.withValues(alpha: 0.42)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = brushRadiusScene * 2
        ..isAntiAlias = true;

      if (strokeImagePoints.length == 1) {
        final center = _mapImagePoint(strokeImagePoints.first, imageRect);
        canvas.drawCircle(
            center, brushRadiusScene, strokePaint..style = PaintingStyle.fill);
      } else {
        final path = Path();
        final first = _mapImagePoint(strokeImagePoints.first, imageRect);
        path.moveTo(first.dx, first.dy);

        for (var index = 1; index < strokeImagePoints.length; index++) {
          final point = _mapImagePoint(strokeImagePoints[index], imageRect);
          if (index < strokeImagePoints.length - 1) {
            final next =
                _mapImagePoint(strokeImagePoints[index + 1], imageRect);
            final midpoint =
                Offset((point.dx + next.dx) / 2, (point.dy + next.dy) / 2);
            path.quadraticBezierTo(
                point.dx, point.dy, midpoint.dx, midpoint.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }

        canvas.drawPath(path, strokePaint);
      }
    }

    if (activeImagePoint == null) {
      return;
    }

    final center = _mapImagePoint(activeImagePoint!, imageRect);
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.94)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final focusPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);

    canvas.drawCircle(center, brushRadiusScene, haloPaint);
    canvas.drawCircle(center, brushRadiusScene, ringPaint);
    canvas.drawCircle(center, 2.2, focusPaint);
  }

  Offset _mapImagePoint(Offset imagePoint, Rect imageRect) {
    final normalized = Offset(
      imagePoint.dx / imageSize.width,
      imagePoint.dy / imageSize.height,
    );

    return Offset(
      imageRect.left + (normalized.dx * imageRect.width),
      imageRect.top + (normalized.dy * imageRect.height),
    );
  }

  @override
  bool shouldRepaint(covariant RepairDamageBrushOverlayPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.strokeImagePoints != strokeImagePoints ||
        oldDelegate.activeImagePoint != activeImagePoint ||
        oldDelegate.brushRadiusImage != brushRadiusImage ||
        oldDelegate.color != color;
  }
}
