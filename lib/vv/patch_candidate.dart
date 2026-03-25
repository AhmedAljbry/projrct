import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'mask_data.dart';

/// A candidate replacement patch identified during the patch search phase.
/// Sorted by ascending score (lower = better match).
@immutable
class PatchCandidate {
  /// Top-left pixel position of this patch in the source image.
  final int sourceX;
  final int sourceY;

  /// Patch dimensions (matches the target blemish region dimensions).
  final int patchWidth;
  final int patchHeight;

  /// Similarity score: lower is better.
  /// Composed of texture variance difference + luminance gradient similarity.
  final double score;

  /// Optional: pre-extracted RGBA pixel data (used in caching scenarios).
  final Uint8List? pixelData;

  const PatchCandidate({
    required this.sourceX,
    required this.sourceY,
    required this.patchWidth,
    required this.patchHeight,
    required this.score,
    this.pixelData,
  });

  MaskBounds get bounds => MaskBounds(
        left: sourceX,
        top: sourceY,
        right: sourceX + patchWidth,
        bottom: sourceY + patchHeight,
      );

  PatchCandidate withPixelData(Uint8List data) => PatchCandidate(
        sourceX: sourceX,
        sourceY: sourceY,
        patchWidth: patchWidth,
        patchHeight: patchHeight,
        score: score,
        pixelData: data,
      );

  @override
  String toString() =>
      'PatchCandidate(src=($sourceX,$sourceY), size=${patchWidth}x$patchHeight, score=${score.toStringAsFixed(4)})';
}

/// Result from the patch selection engine.
@immutable
class PatchSelectionResult {
  final PatchCandidate bestPatch;
  final List<PatchCandidate> candidates;
  final Duration searchDuration;

  const PatchSelectionResult({
    required this.bestPatch,
    required this.candidates,
    required this.searchDuration,
  });
}
