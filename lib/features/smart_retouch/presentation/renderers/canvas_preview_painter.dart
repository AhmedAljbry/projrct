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
      _drawLiveBrushPreview(
        canvas,
        inProgressStroke!,
        scaledBrushSize,
      );
      final Paint previewPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = scaledBrushSize
        ..isAntiAlias = true
        ..color = _previewColorFor(inProgressStroke!.mode).withValues(
          alpha: inProgressStroke!.mode == RetouchMode.eraser ? 0.28 : 0.24,
        );
      final Paint outlinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = (scaledBrushSize * 0.22).clamp(1.2, 4.0)
        ..isAntiAlias = true
        ..color = Colors.white.withValues(alpha: 0.75);

      _drawPath(canvas, inProgressStroke!.path, previewPaint);
      _drawPath(canvas, inProgressStroke!.path, outlinePaint);

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

  Color _previewColorFor(RetouchMode mode) {
    switch (mode) {
      case RetouchMode.eraser:
        return const Color(0xFFFF6B6B);
      case RetouchMode.heal:
        return const Color(0xFF56E39F);
      case RetouchMode.clone:
        return const Color(0xFF56E39F);
      case RetouchMode.patch:
        return const Color(0xFF56E39F);
      case RetouchMode.none:
        return Colors.transparent;
    }
  }

  void _drawLiveBrushPreview(
    Canvas canvas,
    StrokeOperation stroke,
    double scaledBrushSize,
  ) {
    if (baseImage == null || originalImage == null) {
      return;
    }

    final List<Offset> canvasPoints = stroke.path.map(_toCanvas).toList();
    if (canvasPoints.isEmpty) {
      return;
    }

    final Rect strokeBounds = _strokeBounds(canvasPoints, scaledBrushSize)
        .intersect(imageRect);
    if (strokeBounds.isEmpty) {
      return;
    }

    canvas.saveLayer(strokeBounds, Paint());

    switch (stroke.mode) {
      case RetouchMode.clone:
      case RetouchMode.heal:
        final Offset? sourceAnchor = stroke.sourceAnchor;
        final Offset? targetAnchor = stroke.targetAnchor;
        if (sourceAnchor == null || targetAnchor == null) {
          canvas.restore();
          return;
        }
        final Offset sourceCanvasPoint = _toCanvas(sourceAnchor);
        final Offset targetAnchorCanvasPoint = _toCanvas(targetAnchor);
        final Offset translation = targetAnchorCanvasPoint - sourceCanvasPoint;
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
        if (stroke.mode == RetouchMode.heal) {
          canvas.drawColor(
            Colors.white.withValues(alpha: 0.08),
            BlendMode.softLight,
          );
        }
        break;
      case RetouchMode.eraser:
        canvas.drawImageRect(
          originalImage!,
          Rect.fromLTWH(
            0,
            0,
            originalImage!.width.toDouble(),
            originalImage!.height.toDouble(),
          ),
          imageRect,
          Paint()
            ..filterQuality = FilterQuality.low
            ..isAntiAlias = true,
        );
        break;
      case RetouchMode.patch:
      case RetouchMode.none:
        canvas.restore();
        return;
    }

    _drawStrokeMask(
      canvas,
      canvasPoints,
      scaledBrushSize,
    );
    canvas.restore();
  }

  Rect _strokeBounds(List<Offset> canvasPoints, double strokeWidth) {
    double minX = canvasPoints.first.dx;
    double maxX = canvasPoints.first.dx;
    double minY = canvasPoints.first.dy;
    double maxY = canvasPoints.first.dy;

    for (final point in canvasPoints.skip(1)) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }

    final double pad = strokeWidth / 2;
    return Rect.fromLTRB(
      minX - pad,
      minY - pad,
      maxX + pad,
      maxY + pad,
    );
  }

  void _drawStrokeMask(
    Canvas canvas,
    List<Offset> canvasPoints,
    double strokeWidth,
  ) {
    if (canvasPoints.length == 1) {
      canvas.drawCircle(
        canvasPoints.first,
        strokeWidth / 2,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..color = Colors.white
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      return;
    }

    final Path strokePath = Path()
      ..moveTo(canvasPoints.first.dx, canvasPoints.first.dy);
    for (int i = 1; i < canvasPoints.length; i++) {
      strokePath.lineTo(canvasPoints[i].dx, canvasPoints[i].dy);
    }

    canvas.drawPath(
      strokePath,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true,
    );
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    final List<Offset> canvasPoints = points.map(_toCanvas).toList();

    if (canvasPoints.length == 1) {
      final Paint pointPaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(canvasPoints.first, paint.strokeWidth / 2, pointPaint);
      return;
    }

    final path = Path();
    path.moveTo(canvasPoints.first.dx, canvasPoints.first.dy);
    for (int i = 1; i < canvasPoints.length; i++) {
      path.lineTo(canvasPoints[i].dx, canvasPoints[i].dy);
    }
    canvas.drawPath(path, paint);
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
  bool shouldRepaint(covariant CanvasPreviewPainter oldDelegate) => true;
}
