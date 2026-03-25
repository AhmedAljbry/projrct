import 'dart:typed_data';
import '../models/af_blur_operation.dart';
import '../models/af_blur_mode.dart';

/// Contract for blur renderers (preview + export).
abstract interface class AfBlurRenderer {
  /// Render a preview frame. Returns JPEG bytes for speed.
  Future<Uint8List?> renderPreview({
    required Uint8List imageBytes,
    required AfBlurOperation operation,
    required AfRenderQuality quality,
  });

  /// Render the final full-res export. Returns PNG bytes.
  Future<Uint8List?> renderExport({
    required Uint8List imageBytes,
    required AfBlurOperation operation,
  });
}
