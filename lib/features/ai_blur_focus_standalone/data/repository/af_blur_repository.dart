import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/models/af_blur_mode.dart';
import '../../domain/models/af_blur_operation.dart';
import '../../domain/models/af_mask_data.dart';
import '../../domain/services/af_blur_renderer.dart';
import '../../domain/services/af_mask_refiner.dart';
import '../../domain/services/af_segmentation_engine.dart';
import '../rendering/af_isolate_renderer.dart';

/// Coordinates segmentation, refinement, and rendering.
/// Acts as the data-layer facade from the perspective of the application layer.
class AfBlurRepository {
  AfBlurRepository({
    required this.segmentation,
    required this.refiner,
    required this.renderer,
  });

  final AfSegmentationEngine segmentation;
  final AfMaskRefiner refiner;
  final AfBlurRenderer renderer;

  AfMaskData? _cachedMask;

  // ── Segmentation ──────────────────────────────────────────────────────────

  Future<AfMaskData> detectSubject({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedMask != null) return _cachedMask!;
    _cachedMask = await segmentation.detectSubject(
      imageBytes: imageBytes,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    return _cachedMask!;
  }

  // ── Mask refinement ───────────────────────────────────────────────────────

  AfBlurOperation refineOperation(AfBlurOperation op) {
    if (op.maskData == null) return op;
    final refined = refiner.refine(
      mask: op.maskData!,
      settings: op.settings,
      manualStrokes: op.manualStrokes,
    );
    return op.copyWith(maskData: refined);
  }

  // ── Preview rendering ─────────────────────────────────────────────────────

  Future<ui.Image?> renderPreview({
    required Uint8List imageBytes,
    required AfBlurOperation op,
    required AfRenderQuality quality,
  }) async {
    final bytes = await renderer.renderPreview(
        imageBytes: imageBytes, operation: op, quality: quality);
    if (bytes == null) return null;
    return AfIsolateRenderer.toUiImage(bytes);
  }

  // ── Export rendering ──────────────────────────────────────────────────────

  Future<Uint8List?> renderExport({
    required Uint8List imageBytes,
    required AfBlurOperation op,
  }) =>
      renderer.renderExport(imageBytes: imageBytes, operation: op);

  Future<void> dispose() => segmentation.dispose();
}
