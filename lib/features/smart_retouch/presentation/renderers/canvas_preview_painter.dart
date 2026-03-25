import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:untitled2/features/smart_retouch/domain/models/retouch_mode.dart';
import '../../domain/models/retouch_operation.dart';
import '../../infrastructure/engine/image_coordinate_mapper.dart';

class CanvasPreviewPainter extends CustomPainter {
  final List<RetouchOperation> operations;
  final StrokeOperation? inProgressStroke;
  final Offset? inProgressSourceAnchor; // In image coordinates
  final Offset? activeBrushPosition;
  final double brushSize;
  final Rect imageRect;
  final Size imageSize;
  final ui.Image? baseImage; // Added for real-time pixel preview

  CanvasPreviewPainter({
    required this.operations,
    this.inProgressStroke,
    this.inProgressSourceAnchor,
    this.activeBrushPosition,
    required this.brushSize,
    required this.imageRect,
    required this.imageSize,
    this.baseImage,
  });

  Offset _toCanvas(Offset imagePoint) {
    return ImageCoordinateMapper.imageToScreen(
        imagePoint, imageRect, imageSize);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect.isEmpty) return;

    final double scaleFactor = imageRect.width / imageSize.width;

    canvas.save();
    canvas.clipRect(imageRect);

    // DRAW IN-PROGRESS STROKE
    if (inProgressStroke != null && inProgressStroke!.path.isNotEmpty) {
      final paintLine = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final settings = inProgressStroke!.settings;
      final double scaledBrushSize = settings.size * scaleFactor;

      if ((inProgressStroke!.mode == RetouchMode.clone ||
              inProgressStroke!.mode == RetouchMode.heal) &&
          baseImage != null &&
          inProgressSourceAnchor != null) {
        final Offset sourceA = inProgressSourceAnchor!;
        final Offset targetA =
            inProgressStroke!.targetAnchor ?? inProgressStroke!.path.first;
        final Offset vectorD = sourceA - targetA;

        // Draw pixel dabs for clone
        final dabPaint = Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.medium;

        // Draw the cloned pixels by clipping the image
        // To keep it smooth, we only draw the dabs along the path
        for (final point in inProgressStroke!.path) {
          final Offset currentSource =
              (inProgressStroke!.alignmentMode == SourceAlignmentMode.aligned)
                  ? point + vectorD
                  : sourceA;

          final Offset canvasTarget = _toCanvas(point);

          // Draw the original image offset to the target
          // target = screen target, source = image source
          // We want the pixels at currentSource (image) to appear at canvasTarget (screen)
          final double imgR = settings.size / 2;
          final Rect srcRect =
              Rect.fromCircle(center: currentSource, radius: imgR);
          final Rect dstRect = Rect.fromCircle(
              center: canvasTarget, radius: scaledBrushSize / 2);

          final Rect layerBounds = Rect.fromCircle(
            center: canvasTarget,
            radius: scaledBrushSize / 2 + 2,
          );
          canvas.saveLayer(
            layerBounds,
            Paint()..color = Colors.white.withValues(alpha: settings.opacity),
          );
          canvas.drawImageRect(baseImage!, srcRect, dstRect, dabPaint);

          final double hardnessStop = settings.hardness.clamp(0.0, 0.98);
          final Paint featherMask = Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = ui.Gradient.radial(
              canvasTarget,
              scaledBrushSize / 2,
              const [
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              [
                0.0,
                hardnessStop,
                1.0,
              ],
            );
          canvas.drawCircle(canvasTarget, scaledBrushSize / 2, featherMask);
          canvas.restore();
        }

        // Also draw the moving source crosshair
        final Offset currentPoint = inProgressStroke!.path.last;
        final Offset startPoint = inProgressStroke!.path.first;
        final Offset dragVector = currentPoint - startPoint;
        final Offset currentSourcePos =
            (inProgressStroke!.alignmentMode == SourceAlignmentMode.aligned)
                ? inProgressSourceAnchor! + dragVector
                : inProgressSourceAnchor!;
        _drawCrosshair(canvas, _toCanvas(currentSourcePos), Colors.blueAccent);
      } else {
        // Only show eraser tint. Avoid any white brush overlay on the actual image.
        paintLine.strokeWidth = scaledBrushSize;
        paintLine.color = (inProgressStroke!.mode == RetouchMode.eraser)
            ? Colors.red.withValues(alpha: 0.4)
            : Colors.transparent;
        if (paintLine.color.a > 0) {
          _drawPath(canvas, inProgressStroke!.path, paintLine);
        }
      }
    }

    canvas.restore();

    // Draw active cursor (not clipped)
    if (activeBrushPosition != null) {
      _drawBrushCursor(
          canvas, _toCanvas(activeBrushPosition!), brushSize * scaleFactor);
    }

    // Draw static source anchor if selected but not painting
    if (inProgressSourceAnchor != null && inProgressStroke == null) {
      _drawCrosshair(canvas, _toCanvas(inProgressSourceAnchor!), Colors.blue);
    }
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    final List<Offset> canvasPoints = points.map((p) => _toCanvas(p)).toList();

    if (canvasPoints.length == 1) {
      canvas.drawCircle(canvasPoints.first, paint.strokeWidth / 2,
          paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path();
    path.moveTo(canvasPoints.first.dx, canvasPoints.first.dy);
    for (int i = 1; i < canvasPoints.length; i++) {
      path.lineTo(canvasPoints[i].dx, canvasPoints[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawCrosshair(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 10, paint);
    canvas.drawLine(
        center - const Offset(0, 15), center + const Offset(0, 15), paint);
    canvas.drawLine(
        center - const Offset(15, 0), center + const Offset(15, 0), paint);
  }

  void _drawBrushCursor(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw shadow/outline for visibility on light and dark backgrounds
    final shadowPaint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, size / 2, shadowPaint);
    canvas.drawCircle(center, size / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CanvasPreviewPainter oldDelegate) => true;
}
