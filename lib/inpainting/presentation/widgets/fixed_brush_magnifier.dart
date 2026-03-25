import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../application/drawing/stroke.dart';

class FixedBrushMagnifier extends StatelessWidget {
  final ui.Image image;
  final List<Stroke> strokes;
  final Offset focusImagePoint;
  final double brushWidthImagePx;
  final BrushKind brushKind;
  final double diameter;

  const FixedBrushMagnifier({
    super.key,
    required this.image,
    required this.strokes,
    required this.focusImagePoint,
    required this.brushWidthImagePx,
    required this.brushKind,
    this.diameter = 118,
  });

  @override
  Widget build(BuildContext context) {
    final accent = brushKind == BrushKind.eraser
        ? const Color(0xFFFF6B6B)
        : const Color(0xFF2EE59D);

    return RepaintBoundary(
      child: Container(
        width: diameter,
        height: diameter,
        padding: EdgeInsets.all(7),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.96),
              const Color(0xFFD7E6E0),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 1.5,
          ),
        ),
        child: ClipOval(
          child: ColoredBox(
            color: const Color(0xFF07120F),
            child: CustomPaint(
              painter: _FixedBrushMagnifierPainter(
                image: image,
                strokes: strokes,
                focusImagePoint: focusImagePoint,
                brushWidthImagePx: brushWidthImagePx,
                accent: accent,
                isEraser: brushKind == BrushKind.eraser,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FixedBrushMagnifierPainter extends CustomPainter {
  final ui.Image image;
  final List<Stroke> strokes;
  final Offset focusImagePoint;
  final double brushWidthImagePx;
  final Color accent;
  final bool isEraser;

  const _FixedBrushMagnifierPainter({
    required this.image,
    required this.strokes,
    required this.focusImagePoint,
    required this.brushWidthImagePx,
    required this.accent,
    required this.isEraser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dstRect = Offset.zero & size;
    final srcRect = _buildSourceRect();

    canvas.drawImageRect(
        image, srcRect, dstRect, Paint()..filterQuality = FilterQuality.high);
    _paintGuides(canvas, size);
    _paintMaskOverlay(canvas, size, srcRect);
    _paintReticle(canvas, size, srcRect);
  }

  Rect _buildSourceRect() {
    final minDimension =
        math.min(image.width.toDouble(), image.height.toDouble());
    final side = math.min(
      math
          .max(brushWidthImagePx * 2.8, minDimension * 0.035)
          .clamp(36.0, 240.0),
      minDimension,
    );

    var left = focusImagePoint.dx - (side / 2);
    var top = focusImagePoint.dy - (side / 2);
    left = left.clamp(0.0, image.width - side);
    top = top.clamp(0.0, image.height - side);

    return Rect.fromLTWH(left, top, side, side);
  }

  void _paintGuides(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1;

    final thirdW = size.width / 3;
    final thirdH = size.height / 3;

    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), guidePaint);
    canvas.drawLine(
        Offset(thirdW * 2, 0), Offset(thirdW * 2, size.height), guidePaint);
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), guidePaint);
    canvas.drawLine(
        Offset(0, thirdH * 2), Offset(size.width, thirdH * 2), guidePaint);
  }

  void _paintMaskOverlay(Canvas canvas, Size size, Rect srcRect) {
    final scale = size.width / srcRect.width;
    final overlayPaint = Paint();
    canvas.saveLayer(Offset.zero & size, overlayPaint);

    for (final stroke in strokes) {
      if (stroke.pts.isEmpty) {
        continue;
      }

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = (stroke.width * scale).clamp(1.0, size.width * 0.45)
        ..isAntiAlias = true;

      if (stroke.mode == StrokeMode.eraser) {
        paint
          ..blendMode = BlendMode.clear
          ..color = const Color(0x00000000);
      } else {
        paint
          ..blendMode = BlendMode.srcOver
          ..color = const Color.fromARGB(165, 0, 229, 200);
      }

      final first = _mapPoint(stroke.pts.first, srcRect, size);
      if (stroke.pts.length == 1) {
        canvas.drawCircle(
            first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
        continue;
      }

      final path = Path()..moveTo(first.dx, first.dy);
      for (int i = 1; i < stroke.pts.length; i++) {
        final point = _mapPoint(stroke.pts[i], srcRect, size);
        if (i < stroke.pts.length - 1) {
          final next = _mapPoint(stroke.pts[i + 1], srcRect, size);
          final midpoint =
              Offset((point.dx + next.dx) / 2, (point.dy + next.dy) / 2);
          path.quadraticBezierTo(point.dx, point.dy, midpoint.dx, midpoint.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  void _paintReticle(Canvas canvas, Size size, Rect srcRect) {
    final center = size.center(Offset.zero);
    final brushRadius = ((brushWidthImagePx * size.width) / srcRect.width / 2)
        .clamp(7.0, size.width * 0.32);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = accent.withValues(alpha: 0.95);

    canvas.drawCircle(center, brushRadius, ringPaint);

    final focusPaint = Paint()
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.92);

    canvas.drawLine(
      Offset(center.dx - 12, center.dy),
      Offset(center.dx + 12, center.dy),
      focusPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx, center.dy + 12),
      focusPaint,
    );

    canvas.drawCircle(
      center,
      2.6,
      Paint()..color = accent,
    );

    final statusPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = isEraser ? const Color(0xFFFF8A80) : const Color(0xFF9AF6D0);
    canvas.drawCircle(center, (size.width / 2) - 2, statusPaint);
  }

  Offset _mapPoint(Offset imagePoint, Rect srcRect, Size size) {
    return Offset(
      ((imagePoint.dx - srcRect.left) * size.width) / srcRect.width,
      ((imagePoint.dy - srcRect.top) * size.height) / srcRect.height,
    );
  }

  @override
  bool shouldRepaint(covariant _FixedBrushMagnifierPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.strokes != strokes ||
        oldDelegate.focusImagePoint != focusImagePoint ||
        oldDelegate.brushWidthImagePx != brushWidthImagePx ||
        oldDelegate.accent != accent ||
        oldDelegate.isEraser != isEraser;
  }
}
