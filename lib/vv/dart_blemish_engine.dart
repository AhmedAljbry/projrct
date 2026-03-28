import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:untitled2/vv/blemish_operation.dart';
import 'package:untitled2/vv/blemish_removal_engine.dart';
import 'package:untitled2/vv/healing_region.dart';
import 'package:untitled2/vv/mask_data.dart';
import 'package:untitled2/vv/patch_candidate.dart';

import 'patch_blender.dart';
import 'patch_searcher.dart';

/// Pure-Dart blemish removal engine.
class DartBlemishEngine implements BlemishRemovalEngine {
  final PatchSearcher _searcher;
  final PatchBlender _blender;

  bool _disposed = false;

  DartBlemishEngine({
    PatchSearcher? searcher,
    PatchBlender? blender,
  })  : _searcher = searcher ?? PatchSearcher(),
        _blender = blender ?? PatchBlender();

  @override
  String get engineName => 'DartBlemishEngine v2.3 (Adaptive Natural Heal)';

  @override
  bool get supportsIsolateProcessing => true;

  @override
  Future<bool> checkAvailability() async => !_disposed;

  @override
  Future<EngineResult> heal({
    required Uint8List imagePixels,
    required int imageWidth,
    required int imageHeight,
    required BlemishOperation operation,
    EngineQualityMode mode = EngineQualityMode.preview,
  }) async {
    _assertNotDisposed();
    final sw = Stopwatch()..start();

    try {
      final tightBounds =
      operation.mask.computeTightBounds().clampTo(imageWidth, imageHeight);

      if (tightBounds.isEmpty) {
        return const EngineResult.failure(
          EngineError(
            code: 'EMPTY_MASK',
            message: 'Mask bounds computed to empty region.',
          ),
        );
      }

      final patchResult = _searcher.findCandidates(
        imagePixels: imagePixels,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        targetRegion: tightBounds,
        mode: mode,
      );

      var bestPatch = patchResult.bestPatch;

      final targetCx = (tightBounds.left + tightBounds.right) / 2.0;
      final targetCy = (tightBounds.top + tightBounds.bottom) / 2.0;
      final sourceCx = bestPatch.sourceX + bestPatch.patchWidth / 2.0;
      final sourceCy = bestPatch.sourceY + bestPatch.patchHeight / 2.0;

      final dx = sourceCx - targetCx;
      final dy = sourceCy - targetCy;
      final spatialDist = math.sqrt(dx * dx + dy * dy);

      final base = math.max(tightBounds.width, tightBounds.height);

      double maxAllowed;
      if (base <= 18) {
        maxAllowed = base * (mode == EngineQualityMode.preview ? 1.6 : 2.1);
      } else if (base <= 42) {
        maxAllowed = base * (mode == EngineQualityMode.preview ? 2.1 : 2.8);
      } else {
        maxAllowed = base * (mode == EngineQualityMode.preview ? 2.5 : 3.4);
      }

      // Use nearby fallback instead of failing.
      if (spatialDist > maxAllowed) {
        debugPrint(
          '[DartBlemishEngine] Patch too far ($spatialDist > $maxAllowed), using nearby fallback.',
        );

        final fallback = _buildNearbyFallbackPatch(
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          targetBounds: tightBounds,
        );

        bestPatch = PatchCandidate(
          sourceX: fallback.sourceX,
          sourceY: fallback.sourceY,
          patchWidth: fallback.patchWidth,
          patchHeight: fallback.patchHeight,
          score: bestPatch.score + 5000.0,
        );
      }

      final sourceBounds = MaskBounds(
        left: bestPatch.sourceX,
        top: bestPatch.sourceY,
        right: bestPatch.sourceX + tightBounds.width,
        bottom: bestPatch.sourceY + tightBounds.height,
      ).clampTo(imageWidth, imageHeight);

      if (sourceBounds.width != tightBounds.width ||
          sourceBounds.height != tightBounds.height) {
        final fallback = _buildNearbyFallbackPatch(
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          targetBounds: tightBounds,
        );

        final fallbackBounds = MaskBounds(
          left: fallback.sourceX,
          top: fallback.sourceY,
          right: fallback.sourceX + tightBounds.width,
          bottom: fallback.sourceY + tightBounds.height,
        ).clampTo(imageWidth, imageHeight);

        if (fallbackBounds.width != tightBounds.width ||
            fallbackBounds.height != tightBounds.height) {
          return const EngineResult.failure(
            EngineError(
              code: 'INVALID_SOURCE_BOUNDS',
              message: 'Source patch bounds do not match target dimensions.',
            ),
          );
        }

        final extractedFallbackPatch = _extractRegion(
          imagePixels,
          imageWidth,
          fallbackBounds,
        );

        _blender.blend(
          outputPixels: imagePixels,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          sourcePatch: extractedFallbackPatch,
          patchWidth: tightBounds.width,
          patchHeight: tightBounds.height,
          sourceAnchorX: fallback.sourceX,
          sourceAnchorY: fallback.sourceY,
          targetBounds: tightBounds,
          mask: operation.mask,
          strength: operation.brushSettings.strength,
        );

        final healedPixels = _extractRegion(imagePixels, imageWidth, tightBounds);

        sw.stop();
        return EngineResult.success(
          HealedRegion(
            bounds: tightBounds,
            healedPixels: healedPixels,
            confidence: 0.45,
            processingTime: sw.elapsed,
          ),
        );
      }

      final extractedPatch = _extractRegion(
        imagePixels,
        imageWidth,
        sourceBounds,
      );

      _blender.blend(
        outputPixels: imagePixels,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        sourcePatch: extractedPatch,
        patchWidth: tightBounds.width,
        patchHeight: tightBounds.height,
        sourceAnchorX: bestPatch.sourceX,
        sourceAnchorY: bestPatch.sourceY,
        targetBounds: tightBounds,
        mask: operation.mask,
        strength: operation.brushSettings.strength,
      );

      final healedPixels = _extractRegion(imagePixels, imageWidth, tightBounds);

      sw.stop();

      return EngineResult.success(
        HealedRegion(
          bounds: tightBounds,
          healedPixels: healedPixels,
          confidence: _computeConfidence(bestPatch.score),
          processingTime: sw.elapsed,
        ),
      );
    } catch (e, stack) {
      debugPrint('[DartBlemishEngine] heal error: $e\n$stack');
      sw.stop();

      return EngineResult.failure(
        EngineError(
          code: 'HEAL_FAILED',
          message: 'Healing pipeline error: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Uint8List> applyAll({
    required Uint8List imagePixels,
    required int imageWidth,
    required int imageHeight,
    required List<BlemishOperation> operations,
    EngineQualityMode mode = EngineQualityMode.finalQuality,
    void Function(int completed, int total)? onProgress,
  }) async {
    _assertNotDisposed();

    final workingCopy = Uint8List.fromList(imagePixels);
    int completed = 0;

    for (final op in operations) {
      final result = await heal(
        imagePixels: workingCopy,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        operation: op,
        mode: mode,
      );

      if (result.isFailure) {
        throw StateError(result.error!.message);
      }

      completed++;
      onProgress?.call(completed, operations.length);
    }

    return workingCopy;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
  }

  Uint8List _extractRegion(
      Uint8List pixels,
      int imageWidth,
      MaskBounds bounds,
      ) {
    final w = bounds.width;
    final h = bounds.height;
    final buffer = Uint8List(w * h * 4);

    for (int dy = 0; dy < h; dy++) {
      final sy = bounds.top + dy;
      final srcOffset = (sy * imageWidth + bounds.left) * 4;
      final dstOffset = dy * w * 4;
      buffer.setRange(dstOffset, dstOffset + w * 4, pixels, srcOffset);
    }

    return buffer;
  }

  PatchCandidate _buildNearbyFallbackPatch({
    required int imageWidth,
    required int imageHeight,
    required MaskBounds targetBounds,
  }) {
    final patchW = targetBounds.width;
    final patchH = targetBounds.height;

    final positions = <({int x, int y})>[
      (x: targetBounds.right + 2, y: targetBounds.top),
      (x: targetBounds.left - patchW - 2, y: targetBounds.top),
      (x: targetBounds.left, y: targetBounds.bottom + 2),
      (x: targetBounds.left, y: targetBounds.top - patchH - 2),
    ];

    for (final p in positions) {
      final x = p.x.clamp(0, math.max(0, imageWidth - patchW)).toInt();
      final y = p.y.clamp(0, math.max(0, imageHeight - patchH)).toInt();

      final overlapsTarget = x < targetBounds.right &&
          y < targetBounds.bottom &&
          x + patchW > targetBounds.left &&
          y + patchH > targetBounds.top;

      if (overlapsTarget) continue;

      return PatchCandidate(
        sourceX: x,
        sourceY: y,
        patchWidth: patchW,
        patchHeight: patchH,
        score: 99999.0,
      );
    }

    return PatchCandidate(
      sourceX: targetBounds.right
          .clamp(0, math.max(0, imageWidth - patchW))
          .toInt(),
      sourceY: targetBounds.top
          .clamp(0, math.max(0, imageHeight - patchH))
          .toInt(),
      patchWidth: patchW,
      patchHeight: patchH,
      score: 999999.0,
    );
  }

  double _computeConfidence(double score) {
    return math.exp(-score / 150.0).clamp(0.0, 1.0);
  }

  void _assertNotDisposed() {
    if (_disposed) {
      throw StateError('DartBlemishEngine has been disposed.');
    }
  }
}

