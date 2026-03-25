import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'mask_data.dart';

/// Represents the result of analyzing a blemish region — includes both
/// the damaged pixel data and the computed mask for that region.
@immutable
class HealingRegion {
  /// Bounding rectangle within the full-resolution image.
  final MaskBounds bounds;

  /// RGBA pixel data of the blemish area (width * height * 4 bytes).
  final Uint8List sourcePixels;

  /// Float mask matching the bounds — values in [0,1].
  final MaskData mask;

  /// Local mean luminance of the source region (0–255).
  final double meanLuminance;

  /// Local luminance variance.
  final double luminanceVariance;

  /// Local texture energy (sum of squared gradients).
  final double textureEnergy;

  const HealingRegion({
    required this.bounds,
    required this.sourcePixels,
    required this.mask,
    required this.meanLuminance,
    required this.luminanceVariance,
    required this.textureEnergy,
  });

  int get width => bounds.width;
  int get height => bounds.height;

  /// Whether this region qualifies as a real blemish based on structural heuristics.
  bool get looksLikeBlemish {
    // A blemish typically has elevated local variance compared to surrounding skin,
    // or is noticeably darker/lighter than median skin tone.
    return luminanceVariance > 150.0 || textureEnergy > 200.0;
  }
}

/// Describes the final healed result for a single blemish operation.
@immutable
class HealedRegion {
  /// Bounding rectangle of the healed area.
  final MaskBounds bounds;

  /// Final RGBA pixel data after healing blend.
  final Uint8List healedPixels;

  /// Quality confidence 0–1 (how well the patch matched).
  final double confidence;

  /// Processing time for this operation.
  final Duration processingTime;

  const HealedRegion({
    required this.bounds,
    required this.healedPixels,
    required this.confidence,
    required this.processingTime,
  });
}
