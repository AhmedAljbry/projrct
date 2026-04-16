import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:untitled2/features/smart_retouch/domain/models/retouch_mode.dart';

import '../../domain/models/retouch_operation.dart';
import '../../infrastructure/engine/image_coordinate_mapper.dart';

class CanvasPreviewPainter extends CustomPainter {
  final List<RetouchOperation> operations;
  final StrokeOperation? inProgressStroke;
  final Offset? inProgressSourceAnchor;
  final Offset? activeBrushPosition;
  final double brushSize;
  final Rect imageRect;
  final Size imageSize;
  final ui.Image? baseImage;
  final ui.Image? originalImage;

  CanvasPreviewPainter({
    required this.operations,
    this.inProgressStroke,
    this.inProgressSourceAnchor,
    this.activeBrushPosition,
    required this.brushSize,
    required this.imageRect,
    required this.imageSize,
    this.baseImage,
    this.originalImage,
  });

  Offset _toCanvas(Offset imagePoint) {
    return ImageCoordinateMapper.imageToScreen(
      imagePoint,
      imageRect,
      imageSize,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect.isEmpty) return;

    final double scaleFactor = imageRect.width / imageSize.width;

    canvas.save();
    canvas.clipRect(imageRect);

    if (inProgressStroke != null && inProgressStroke!.path.isNotEmpty) {
      final settings = inProgressStroke!.settings;
      final double scaledBrushSize = settings.size * scaleFactor;
      final List<Offset> previewPath = _buildPreviewPathForBrush(
        inProgressStroke!.path,
        settings.size,
      );
      _drawLiveBrushPreview(
        canvas,
        inProgressStroke!,
        previewPath,
        scaledBrushSize,
      );

      if ((inProgressStroke!.mode == RetouchMode.clone ||
              inProgressStroke!.mode == RetouchMode.heal ||
              inProgressStroke!.mode == RetouchMode.patch) &&
          inProgressSourceAnchor != null) {
        final Offset currentPoint = inProgressStroke!.path.last;
        final Offset startPoint = inProgressStroke!.path.first;
        final Offset dragVector = currentPoint - startPoint;
        final Offset currentSourcePos = inProgressSourceAnchor! + dragVector;
        _drawSourceMarker(
          canvas,
          _toCanvas(currentSourcePos),
          canvasTarget: _toCanvas(currentPoint),
        );
      }
    }

    canvas.restore();

    if (activeBrushPosition != null) {
      _drawBrushCursor(
        canvas,
        _toCanvas(activeBrushPosition!),
        brushSize * scaleFactor,
      );
    }

    if (inProgressSourceAnchor != null && inProgressStroke == null) {
      _drawSourceMarker(canvas, _toCanvas(inProgressSourceAnchor!));
    }
  }

  void _drawLiveBrushPreview(
    Canvas canvas,
    StrokeOperation stroke,
    List<Offset> previewPath,
    double scaledBrushSize,
  ) {
    if (baseImage == null || originalImage == null || previewPath.isEmpty) {
      return;
    }

    switch (stroke.mode) {
      case RetouchMode.clone:
      case RetouchMode.heal:
        final Offset? sourceAnchor = stroke.sourceAnchor;
        final Offset? targetAnchor = stroke.targetAnchor;
        if (sourceAnchor == null || targetAnchor == null) {
          return;
        }
        for (final targetImagePoint in previewPath) {
          final Offset currentSourceImage =
              sourceAnchor + (targetImagePoint - targetAnchor);
          _drawPreviewDab(
            canvas: canvas,
            targetImagePoint: targetImagePoint,
            sourceImagePoint: currentSourceImage,
            scaledBrushSize: scaledBrushSize,
          );
        }
        break;
      case RetouchMode.eraser:
        for (final targetImagePoint in previewPath) {
          _drawPreviewDab(
            canvas: canvas,
            targetImagePoint: targetImagePoint,
            sourceImagePoint: targetImagePoint,
            scaledBrushSize: scaledBrushSize,
          );
        }
        break;
      case RetouchMode.patch:
      case RetouchMode.none:
        return;
    }
  }

  void _drawPreviewDab({
    required Canvas canvas,
    required Offset targetImagePoint,
    required Offset sourceImagePoint,
    required double scaledBrushSize,
  }) {
    final Offset targetCanvasPoint = _toCanvas(targetImagePoint);
    final Rect dabBounds = Rect.fromCircle(
      center: targetCanvasPoint,
      radius: scaledBrushSize / 2,
    ).intersect(imageRect);
    if (dabBounds.isEmpty) {
      return;
    }

    final Offset sourceCanvasPoint = _toCanvas(sourceImagePoint);
    final Offset translation = targetCanvasPoint - sourceCanvasPoint;

    canvas.saveLayer(dabBounds, Paint());
    canvas.drawImageRect(
      originalImage!,
      Rect.fromLTWH(
        0,
        0,
        originalImage!.width.toDouble(),
        originalImage!.height.toDouble(),
      ),
      imageRect.shift(translation),
      Paint()
        ..filterQuality = FilterQuality.low
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      targetCanvasPoint,
      scaledBrushSize / 2,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  List<Offset> _buildPreviewPathForBrush(List<Offset> points, double brushSize) {
    if (points.length <= 2) {
      return points;
    }

    final int pointBudget = _previewPointBudgetForBrush(brushSize);
    if (points.length <= pointBudget) {
      return points;
    }

    final List<Offset> reduced = [points.first];
    final double step = (points.length - 1) / (pointBudget - 1);
    final double minRetainedDistance = (brushSize * 0.20).clamp(1.5, 10.0);

    for (int i = 1; i < pointBudget - 1; i++) {
      final int index = (i * step).round().clamp(1, points.length - 2);
      final Offset candidate = points[index];
      if ((candidate - reduced.last).distance >= minRetainedDistance) {
        reduced.add(candidate);
      }
    }

    if ((points.last - reduced.last).distance > 0.1) {
      reduced.add(points.last);
    }
    return reduced;
  }

  int _previewPointBudgetForBrush(double brushSize) {
    final double normalized = (brushSize / 42.0).clamp(0.0, 1.0);
    return (10 + (normalized * 28)).round().clamp(10, 38);
  }

  void _drawSourceMarker(Canvas canvas, Offset center, {Offset? canvasTarget}) {
    final outerPaint = Paint()
      ..color = const Color(0xFF56E39F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final linkPaint = Paint()
      ..color = const Color(0xFF56E39F).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    if (canvasTarget != null) {
      canvas.drawLine(center, canvasTarget, linkPaint);
    }

    canvas.drawCircle(center, 12, outerPaint);
    canvas.drawCircle(center, 7, innerPaint);
    canvas.drawLine(
      center - const Offset(0, 16),
      center + const Offset(0, 16),
      outerPaint,
    );
    canvas.drawLine(
      center - const Offset(16, 0),
      center + const Offset(16, 0),
      outerPaint,
    );
  }

  void _drawBrushCursor(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final shadowPaint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, size / 2, shadowPaint);
    canvas.drawCircle(center, size / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CanvasPreviewPainter oldDelegate) {
    return oldDelegate.inProgressStroke != inProgressStroke ||
        oldDelegate.inProgressSourceAnchor != inProgressSourceAnchor ||
        oldDelegate.activeBrushPosition != activeBrushPosition ||
        oldDelegate.brushSize != brushSize ||
        oldDelegate.imageRect != imageRect ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.baseImage != baseImage ||
        oldDelegate.originalImage != originalImage;
  }
}
