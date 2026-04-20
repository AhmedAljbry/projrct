import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:untitled2/vv/blemish_state.dart';
import 'package:untitled2/vv/brush_settings.dart';

class BlemishCanvasPainter extends CustomPainter {
  final ui.Image? sourceImage;
  final ui.Image? previewImage;
  final List<Offset> activeStrokePoints;
  final BrushSettings brushSettings;
  final double canvasScale;
  final Offset canvasTranslation;
  final CompareMode compareMode;

  const BlemishCanvasPainter({
    required this.sourceImage,
    required this.previewImage,
    required this.activeStrokePoints,
    required this.brushSettings,
    required this.canvasScale,
    required this.canvasTranslation,
    required this.compareMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0C0C0C),
    );

    canvas.save();
    canvas.translate(canvasTranslation.dx, canvasTranslation.dy);
    canvas.scale(canvasScale);

    final img = compareMode == CompareMode.original
        ? (sourceImage ?? previewImage)
        : (previewImage ?? sourceImage);

    if (img != null) {
      canvas.drawImage(img, Offset.zero, Paint());
    }

    if (activeStrokePoints.isNotEmpty) {
      _paintActiveStroke(canvas);
    }

    canvas.restore();
  }

  void _paintActiveStroke(Canvas canvas) {
    final fillPaint = Paint()
      ..color = const Color(0xFF16B07E).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 / canvasScale.clamp(0.2, 12.0);

    for (final point in activeStrokePoints) {
      canvas.drawCircle(point, brushSettings.radius, fillPaint);
      canvas.drawCircle(point, brushSettings.radius, edgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BlemishCanvasPainter oldDelegate) =>
      oldDelegate.sourceImage != sourceImage ||
      oldDelegate.previewImage != previewImage ||
      oldDelegate.activeStrokePoints != activeStrokePoints ||
      oldDelegate.brushSettings != brushSettings ||
      oldDelegate.canvasScale != canvasScale ||
      oldDelegate.canvasTranslation != canvasTranslation ||
      oldDelegate.compareMode != compareMode;
}
