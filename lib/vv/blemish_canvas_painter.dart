import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:untitled2/vv/blemish_state.dart';
import 'package:untitled2/vv/brush_settings.dart';

/// يرسم الصورة فقط — المؤشر في layer منفصل في blemish_edit_canvas
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
    // خلفية سوداء
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0C0C0C),
    );

    canvas.save();
    canvas.translate(canvasTranslation.dx, canvasTranslation.dy);
    canvas.scale(canvasScale);

    // الصورة — Original أو Preview
    final img = compareMode == CompareMode.original
        ? (sourceImage ?? previewImage)
        : (previewImage ?? sourceImage);

    if (img != null) {
      canvas.drawImage(img, Offset.zero, Paint());
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BlemishCanvasPainter o) =>
      o.sourceImage       != sourceImage       ||
          o.previewImage      != previewImage      ||
          o.canvasScale       != canvasScale       ||
          o.canvasTranslation != canvasTranslation ||
          o.compareMode       != compareMode;
}
