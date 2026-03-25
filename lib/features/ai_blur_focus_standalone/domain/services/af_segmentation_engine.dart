import 'dart:typed_data';
import '../models/af_mask_data.dart';

/// Contract for AI subject segmentation engines.
/// Implementations may use ML Kit, CoreML, or a CPU fallback.
abstract interface class AfSegmentationEngine {
  Future<AfMaskData> detectSubject({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  });

  Future<void> dispose();
}
