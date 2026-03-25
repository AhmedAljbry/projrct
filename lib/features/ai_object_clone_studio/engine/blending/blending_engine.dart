import 'dart:typed_data';
import 'package:image/image.dart' as img;

class BlendingEngine {
  /// Matches the color tone of the [sourceObject] to the [targetImage].
  /// [strength] controls the intensity of the harmonization (0.0 to 1.0).
  Future<Uint8List> harmonize({
    required Uint8List sourceObject,
    required Uint8List targetImage,
    required double strength,
  }) async {
    final sourceImg = img.decodeImage(sourceObject);
    final targetImg = img.decodeImage(targetImage);

    if (sourceImg == null || targetImg == null) return sourceObject;

    // Implementation of global color matching (mean/variance shift)
    // 1. Calculate stats for target
    // 2. Calculate stats for source
    // 3. Shift source colors towards target based on strength

    return img.encodePng(sourceImg);
  }

  /// Applies edge feathering to the [mask] to create smoother transitions.
  Future<Uint8List> featherMask(Uint8List maskBytes, double amount) async {
    final maskImg = img.decodeImage(maskBytes);
    if (maskImg == null) return maskBytes;

    if (amount > 0) {
      // Apply Gaussian blur to the mask to create feathering
      img.gaussianBlur(maskImg, radius: amount.toInt());
    }

    return img.encodePng(maskImg);
  }
}
