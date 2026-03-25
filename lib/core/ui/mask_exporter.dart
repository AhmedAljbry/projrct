import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:untitled2/inpainting/application/drawing/stroke.dart';

/// ══════════════════════════════════════════════════════════════════
///  renderMaskPng — the ONLY function that should be called to
///  produce the binary mask that is sent to the LaMa server.
///
///  Rules LaMa REQUIRES:
///   • Dimensions  = exactly [imageW] × [imageH]  (same as source image)
///   • White (255) = region to inpaint / erase
///   • Black  (0)  = region to keep
///   • Format      = PNG (lossless — never JPEG)
///   • No alpha channel issues (RGBA with alpha=255 is fine)
///
///  Key fixes vs previous version:
///   1. strokeWidth clamped at 600px (was 180px → brushes got cut)
///   2. Quadratic bezier smoothing (was lineTo → gaps on fast swipes)
///   3. Solid caps at both endpoints (eliminates gap artefacts)
///   4. Correct PictureRecorder clip rect set (avoids off-canvas pixels)
/// ══════════════════════════════════════════════════════════════════
Future<Uint8List> renderMaskPng({
  required int imageW,
  required int imageH,
  required List<Stroke> strokes,
}) async {
  assert(imageW > 0 && imageH > 0, 'Image dimensions must be positive');

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, imageW.toDouble(), imageH.toDouble()),
  );

  // ── 1. Black background = "keep everything" ───────────────────
  canvas.drawRect(
    Rect.fromLTWH(0, 0, imageW.toDouble(), imageH.toDouble()),
    Paint()
      ..color = Colors.black
      ..isAntiAlias = false,
  );

  // ── 2. Draw every stroke ──────────────────────────────────────
  for (final stroke in strokes) {
    if (stroke.pts.isEmpty) continue;

    final isEraser = stroke.mode == StrokeMode.eraser;
    final color = isEraser ? Colors.black : Colors.white;

    // ✅ FIX 1: raised cap to 600 (was 180 → broke large brushes)
    final halfW = stroke.width.clamp(1.0, 600.0) / 2;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = false
      ..blendMode = BlendMode.srcOver;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = halfW * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = false
      ..blendMode = BlendMode.srcOver;

    // Single tap → solid filled circle
    if (stroke.pts.length == 1) {
      canvas.drawCircle(stroke.pts.first, halfW, fillPaint);
      continue;
    }

    // ✅ FIX 2: smooth bezier path (was lineTo → visible gaps on fast swipes)
    final path = Path()..moveTo(stroke.pts.first.dx, stroke.pts.first.dy);

    for (int i = 1; i < stroke.pts.length; i++) {
      final curr = stroke.pts[i];
      if (i < stroke.pts.length - 1) {
        final next = stroke.pts[i + 1];
        // Midpoint between curr and next → smooth curve
        final midX = (curr.dx + next.dx) / 2;
        final midY = (curr.dy + next.dy) / 2;
        path.quadraticBezierTo(curr.dx, curr.dy, midX, midY);
      } else {
        path.lineTo(curr.dx, curr.dy);
      }
    }

    canvas.drawPath(path, strokePaint);

    // ✅ FIX 3: solid end-caps to close any remaining micro-gaps
    canvas.drawCircle(stroke.pts.first, halfW, fillPaint);
    canvas.drawCircle(stroke.pts.last, halfW, fillPaint);
  }

  // ── 3. Export ─────────────────────────────────────────────────
  final picture = recorder.endRecording();
  final image = await picture.toImage(imageW, imageH);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  if (byteData == null) {
    throw StateError('renderMaskPng: toByteData returned null');
  }

  return byteData.buffer.asUint8List();
}
