import 'dart:math' as math;
import 'dart:typed_data';

import '../../domain/models/af_focus_geometry.dart';
import '../../domain/models/af_mask_data.dart';
import '../../domain/services/af_segmentation_engine.dart';

/// CPU-based fallback segmentation engine.
///
/// When a real ML engine is unavailable (non-Android, no model loaded),
/// this generates a radial ellipse mask centred at a portrait-typical
/// position so the feature is still fully usable.
class AfFallbackSegmentationEngine implements AfSegmentationEngine {
  @override
  Future<AfMaskData> detectSubject({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    return _buildEllipseMask(imageWidth, imageHeight);
  }

  AfMaskData _buildEllipseMask(int w, int h) {
    const cx = 0.5, cy = 0.40, rx = 0.26, ry = 0.36;
    final mask = List<double>.filled(w * h, 0.0);

    for (var y = 0; y < h; y++) {
      final dy = ((y / h) - cy) / ry;
      for (var x = 0; x < w; x++) {
        final dx = ((x / w) - cx) / rx;
        final dist = math.sqrt(dx * dx + dy * dy);
        final v = (1.0 - (dist - 0.60).clamp(0.0, 1.0)).clamp(0.0, 1.0);
        mask[y * w + x] = v * v; // quadratic falloff
      }
    }

    return AfMaskData(
      width: w,
      height: h,
      confidenceMask: mask,
      primaryBounds: const AfSegmentationBounds(
        left: 0.22,
        top: 0.06,
        width: 0.56,
        height: 0.78,
      ),
      usedFallback: true,
    );
  }

  @override
  Future<void> dispose() async {}
}
