import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/cover_mapping.dart';
import '../../application/drawing/stroke.dart';

/// ══════════════════════════════════════════════════════════════════
///  MaskStrokesPainter
///
///  PURPOSE: PREVIEW layer only (what the user sees while drawing).
///
///  For the actual mask export → use renderMaskPng() in mask_exporter.dart.
///  _renderBinaryMask() in editor_page_mask_render.part.dart calls
///  renderMaskPng() directly, NOT this painter.
///
///  PREVIEW rendering:
///   • Brush  → semi-transparent pink overlay  (Color.fromARGB(180,255,64,129))
///   • Eraser → BlendMode.clear (punches a hole through the overlay)
///   • Stroke widths are SCALED from image-px → widget-px via cover mapping
///   • 180px screen cap is fine here (it's only visual)
/// ══════════════════════════════════════════════════════════════════
class MaskStrokesPainter extends CustomPainter {
  final List<Stroke> strokes;

  /// Always true in practice — this painter is preview-only.
  /// Keep the flag for backward compatibility with existing call sites.
  final bool isPreview;

  final int imageW;
  final int imageH;

  const MaskStrokesPainter({
    required this.strokes,
    this.isPreview = true,
    required this.imageW,
    required this.imageH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    canvas.saveLayer(Offset.zero & size, Paint());

    // Cover-mapping: image pixels → widget pixels
    final imageRect = applyBoxFitContainRect(
      inputImageSize: Size(imageW.toDouble(), imageH.toDouble()),
      outputSize: size,
    );
    final scale = imageRect.width / imageW; // widget_px / image_px

    // Map a point from image-pixel space → widget-pixel space
    Offset mapPt(Offset imagePx) {
      final x01 = (imagePx.dx / imageW).clamp(0.0, 1.0);
      final y01 = (imagePx.dy / imageH).clamp(0.0, 1.0);
      return image01ToWidgetPoint(
        p01: Offset(x01, y01),
        widgetSize: size,
        imageW: imageW,
        imageH: imageH,
        fit: BoxFit.contain,
      );
    }

    for (final stroke in strokes) {
      if (stroke.pts.isEmpty) continue;

      // Scale width to screen; 180px cap is enough for display purposes
      final screenW = (stroke.width * scale).clamp(1.0, 180.0);

      final isEraser = stroke.mode == StrokeMode.eraser;

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = screenW
        ..isAntiAlias = true; // smooth preview

      if (isEraser) {
        paint
          ..blendMode = BlendMode.clear
          ..color = const Color(0x00000000);
      } else {
        paint
          ..blendMode = BlendMode.srcOver
          ..color = const Color.fromARGB(180, 255, 64, 129);
      }

      final p0 = mapPt(stroke.pts.first);

      if (stroke.pts.length == 1) {
        canvas.drawCircle(
          p0,
          screenW / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }

      // Bezier smoothing for preview too (matches export visual)
      final path = Path()..moveTo(p0.dx, p0.dy);
      for (int i = 1; i < stroke.pts.length; i++) {
        final p = mapPt(stroke.pts[i]);
        if (i < stroke.pts.length - 1) {
          final pNext = mapPt(stroke.pts[i + 1]);
          final midX = (p.dx + pNext.dx) / 2;
          final midY = (p.dy + pNext.dy) / 2;
          path.quadraticBezierTo(p.dx, p.dy, midX, midY);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MaskStrokesPainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.imageW != imageW ||
      oldDelegate.imageH != imageH;
}
