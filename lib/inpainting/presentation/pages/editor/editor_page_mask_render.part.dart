part of 'editor_page.dart';

// ══════════════════════════════════════════════════════════════
// Bytes helper
// ══════════════════════════════════════════════════════════════

Future<Uint8List> _uiToBytes(ui.Image image) async {
  final bd = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bd == null) throw StateError('_uiToBytes: toByteData returned null');
  return bd.buffer.asUint8List();
}

// ══════════════════════════════════════════════════════════════
// Mask render
//
// Strokes are stored in IMAGE-PIXEL coordinates by DrawingCubit.
// We call renderMaskPng() directly — it renders at full image
// resolution with correct 600px width cap + bezier smoothing.
//
// DO NOT use MaskStrokesPainter here. That class is for the
// visual preview layer only and has a 180px screen cap.
// ══════════════════════════════════════════════════════════════

extension _EditorPageMaskRender on _EditorPageState {
  Future<Uint8List> _renderBinaryMask(ui.Image image, DrawingState s) async {
    debugPrint('════════════ [MASK RENDER] ════════════');
    debugPrint('  strokes : ${s.strokes.length}');
    debugPrint('  image   : ${image.width} × ${image.height} px');

    if (s.strokes.isEmpty) {
      throw StateError('No strokes to render');
    }

    // ✅ renderMaskPng:
    //   • Renders at full imageW × imageH
    //   • strokeWidth clamped at 600px (not 180)
    //   • Bezier smoothing (no gaps on fast swipes)
    //   • White = inpaint, Black = keep
    final raw = await renderMaskPng(
      imageW: image.width,
      imageH: image.height,
      strokes: s.strokes,
    );

    debugPrint('  raw mask: ${raw.length} bytes');
    debugPrint('═══════════════════════════════════════');
    return raw;
  }
}
