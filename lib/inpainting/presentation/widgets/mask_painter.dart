import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/cover_mapping.dart';
import 'package:untitled2/inpainting/application/drawing/stroke.dart';

// ═══════════════════════════════════════════════════════════════
//  MaskPreviewPainter
//
//  Renders the brush overlay the user sees while painting.
//  PREVIEW only — does NOT affect the exported LaMa mask.
//
//  Stroke pts are in IMAGE-PIXEL space. This painter maps them
//  to widget-pixel space using cover_mapping utilities.
//
//  Brush color = electric mint (#00E5C8 at 66% opacity)
//  Eraser = BlendMode.clear (true hole through the overlay)
// ═══════════════════════════════════════════════════════════════

const _kBrushColor = Color.fromARGB(170, 0, 229, 200); // mint tint

class MaskPreviewPainter extends CustomPainter {
  final List<Stroke> strokes;
  final int imageW;
  final int imageH;

  const MaskPreviewPainter({
    required this.strokes,
    required this.imageW,
    required this.imageH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    // saveLayer required for BlendMode.clear (eraser)
    canvas.saveLayer(Offset.zero & size, Paint());

    // ── Map image-px → widget-px via cover_mapping ──────────
    final imageRect = applyBoxFitContainRect(
      inputImageSize: Size(imageW.toDouble(), imageH.toDouble()),
      outputSize: size,
    );
    final scale = imageRect.width / imageW;

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

    for (final s in strokes) {
      if (s.pts.isEmpty) continue;

      final sw = (s.width * scale).clamp(1.0, 180.0);
      final isEraser = s.mode == StrokeMode.eraser;

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..isAntiAlias = true;

      if (isEraser) {
        paint
          ..blendMode = BlendMode.clear
          ..color = const Color(0x00000000);
      } else {
        paint
          ..blendMode = BlendMode.srcOver
          ..color = _kBrushColor;
      }

      final p0 = mapPt(s.pts.first);

      if (s.pts.length == 1) {
        canvas.drawCircle(p0, sw / 2, paint..style = PaintingStyle.fill);
        continue;
      }

      // Smooth bezier path (matches renderMaskPng visually)
      final path = Path()..moveTo(p0.dx, p0.dy);
      for (int i = 1; i < s.pts.length; i++) {
        final p = mapPt(s.pts[i]);
        if (i < s.pts.length - 1) {
          final pn = mapPt(s.pts[i + 1]);
          final mid = Offset((p.dx + pn.dx) / 2, (p.dy + pn.dy) / 2);
          path.quadraticBezierTo(p.dx, p.dy, mid.dx, mid.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MaskPreviewPainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.imageW != imageW ||
      oldDelegate.imageH != imageH;
}
