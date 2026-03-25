import 'dart:math' as math;
import 'dart:typed_data';

import 'package:untitled2/vv/blemish_removal_engine.dart';
import 'package:untitled2/vv/mask_data.dart';
import 'package:untitled2/vv/patch_candidate.dart';

import 'texture_analyzer.dart';

enum BlemishSizeClass {
  small,
  medium,
  largeNatural,
}

BlemishSizeClass classifyBlemishSize(int w, int h) {
  final base = math.max(w, h);

  if (base <= 18) return BlemishSizeClass.small;
  if (base <= 42) return BlemishSizeClass.medium;
  return BlemishSizeClass.largeNatural;
}

class PatchSearcher {
  final TextureAnalyzer _analyzer;

  PatchSearcher({TextureAnalyzer? analyzer})
      : _analyzer = analyzer ?? TextureAnalyzer();

  PatchSelectionResult findCandidates({
    required Uint8List imagePixels,
    required int imageWidth,
    required int imageHeight,
    required MaskBounds targetRegion,
    required EngineQualityMode mode,
  }) {
    final sw = Stopwatch()..start();

    final patchW = targetRegion.width;
    final patchH = targetRegion.height;

    if (patchW <= 0 || patchH <= 0) {
      throw ArgumentError('Target region must have positive dimensions.');
    }

    final sizeClass = classifyBlemishSize(patchW, patchH);
    final base = math.max(patchW, patchH);
    final minRadius = _ringMinRadius(patchW, patchH, mode);
    final maxRadius = _ringMaxRadius(patchW, patchH, mode);
    final stride = _samplingStride(patchW, patchH, mode);

    final exclusionMargin = switch (sizeClass) {
      BlemishSizeClass.small => math.max(2, (base * 0.24).ceil()),
      BlemishSizeClass.medium => math.max(3, (base * 0.34).ceil()),
      BlemishSizeClass.largeNatural => math.max(4, (base * 0.45).ceil()),
    };

    final spatialWeight = switch (sizeClass) {
      BlemishSizeClass.small => 26.0,
      BlemishSizeClass.medium => 20.0,
      BlemishSizeClass.largeNatural => 14.0,
    };

    final maxCandidates = mode == EngineQualityMode.preview ? 14 : 28;

    final targetCx = (targetRegion.left + targetRegion.right) / 2.0;
    final targetCy = (targetRegion.top + targetRegion.bottom) / 2.0;

    final borderPad = switch (sizeClass) {
      BlemishSizeClass.small => math.max(3, (base * 0.18).ceil()),
      BlemishSizeClass.medium => math.max(4, (base * 0.22).ceil()),
      BlemishSizeClass.largeNatural => math.max(5, (base * 0.25).ceil()),
    };

    final targetBorderRegion =
    targetRegion.expand(borderPad).clampTo(imageWidth, imageHeight);

    final targetBorderFeatures = _analyzer.computeFeatures(
      imagePixels,
      imageWidth,
      imageHeight,
      targetBorderRegion,
    );

    final List<PatchCandidate> candidates = [];

    final searchLeft = math.max(0, targetRegion.left - maxRadius);
    final searchTop = math.max(0, targetRegion.top - maxRadius);
    final searchRight =
    math.min(imageWidth - patchW, targetRegion.right + maxRadius);
    final searchBottom =
    math.min(imageHeight - patchH, targetRegion.bottom + maxRadius);

    for (int sy = searchTop; sy <= searchBottom; sy += stride) {
      for (int sx = searchLeft; sx <= searchRight; sx += stride) {
        if (_overlaps(
          sx,
          sy,
          patchW,
          patchH,
          targetRegion,
          margin: math.max(minRadius, exclusionMargin),
        )) {
          continue;
        }

        final candidateBounds = MaskBounds(
          left: sx,
          top: sy,
          right: sx + patchW,
          bottom: sy + patchH,
        );

        final candidateBorderRegion =
        candidateBounds.expand(borderPad).clampTo(imageWidth, imageHeight);

        final candidateFeatures = _analyzer.computeFeatures(
          imagePixels,
          imageWidth,
          imageHeight,
          candidateBorderRegion,
        );

        // لا تسمح بالقفز بين أسطح مختلفة بوضوح
        final targetSurface = targetBorderFeatures.surfaceClass;
        final candidateSurface = candidateFeatures.surfaceClass;

        if (!_isSurfaceCompatible(targetSurface, candidateSurface)) {
          continue;
        }

        final featureDist = targetBorderFeatures.distanceTo(candidateFeatures);

        final candCx = sx + patchW / 2.0;
        final candCy = sy + patchH / 2.0;

        final spatialDist = math.sqrt(
          (candCx - targetCx) * (candCx - targetCx) +
              (candCy - targetCy) * (candCy - targetCy),
        );

        final normalizedSpatial =
            spatialDist / math.max(1.0, maxRadius.toDouble());

        if (normalizedSpatial > 1.12 && featureDist > 82.0) {
          continue;
        }

        double score;

        if (featureDist < 95.0) {
          final sad = _analyzer.computeSAD(
            imagePixels,
            imageWidth,
            imageHeight,
            targetBorderRegion,
            candidateBorderRegion,
          );

          score = (0.60 * featureDist) + (0.24 * sad);
        } else {
          score = featureDist * 2.8;
        }

        score += normalizedSpatial * spatialWeight;

        final energyPenalty =
            (targetBorderFeatures.energy - candidateFeatures.energy).abs() *
                0.05;
        score += energyPenalty;

        candidates.add(PatchCandidate(
          sourceX: sx,
          sourceY: sy,
          patchWidth: patchW,
          patchHeight: patchH,
          score: score,
        ));
      }
    }

    // ignore: avoid_print
    print('[PatchSearcher] candidates found: ${candidates.length}');

    if (candidates.isEmpty) {
      final fallback = _fallbackPatch(
        imageWidth,
        imageHeight,
        targetRegion,
        patchW,
        patchH,
      );
      sw.stop();
      return PatchSelectionResult(
        bestPatch: fallback,
        candidates: [fallback],
        searchDuration: sw.elapsed,
      );
    }

    candidates.sort((a, b) => a.score.compareTo(b.score));
    final ranked = candidates.take(maxCandidates).toList();

    // ignore: avoid_print
    print(
      '[PatchSearcher] best score: ${ranked.first.score}, '
          'source=(${ranked.first.sourceX}, ${ranked.first.sourceY})',
    );

    sw.stop();
    return PatchSelectionResult(
      bestPatch: ranked.first,
      candidates: ranked,
      searchDuration: sw.elapsed,
    );
  }

  bool _isSurfaceCompatible(SurfaceClass a, SurfaceClass b) {
    if (a == SurfaceClass.unknown || b == SurfaceClass.unknown) return true;
    if (a == b) return true;

    // dark fabric <-> fabric textured مسموح
    if ((a == SurfaceClass.darkFabric && b == SurfaceClass.fabricTextured) ||
        (a == SurfaceClass.fabricTextured && b == SurfaceClass.darkFabric)) {
      return true;
    }

    return false;
  }

  bool _overlaps(
      int sx,
      int sy,
      int pw,
      int ph,
      MaskBounds target, {
        required int margin,
      }) {
    return sx < target.right + margin &&
        sy < target.bottom + margin &&
        sx + pw > target.left - margin &&
        sy + ph > target.top - margin;
  }

  int _ringMinRadius(int patchW, int patchH, EngineQualityMode mode) {
    final sizeClass = classifyBlemishSize(patchW, patchH);
    final base = math.max(patchW, patchH);

    switch (sizeClass) {
      case BlemishSizeClass.small:
        return mode == EngineQualityMode.preview
            ? (base * 0.18).ceil()
            : (base * 0.14).ceil();

      case BlemishSizeClass.medium:
        return mode == EngineQualityMode.preview
            ? (base * 0.26).ceil()
            : (base * 0.20).ceil();

      case BlemishSizeClass.largeNatural:
        return mode == EngineQualityMode.preview
            ? (base * 0.34).ceil()
            : (base * 0.26).ceil();
    }
  }

  int _ringMaxRadius(int patchW, int patchH, EngineQualityMode mode) {
    final sizeClass = classifyBlemishSize(patchW, patchH);
    final base = math.max(patchW, patchH);

    switch (sizeClass) {
      case BlemishSizeClass.small:
        return mode == EngineQualityMode.preview
            ? (base * 2.6).ceil()
            : (base * 3.4).ceil();

      case BlemishSizeClass.medium:
        return mode == EngineQualityMode.preview
            ? (base * 3.2).ceil()
            : (base * 4.2).ceil();

      case BlemishSizeClass.largeNatural:
        return mode == EngineQualityMode.preview
            ? (base * 4.0).ceil()
            : (base * 5.0).ceil();
    }
  }

  int _samplingStride(int patchW, int patchH, EngineQualityMode mode) {
    final minDim = math.min(patchW, patchH);

    if (mode == EngineQualityMode.preview) {
      return math.max(minDim ~/ 2, 3);
    }

    return math.max(minDim ~/ 3, 2);
  }

  PatchCandidate _fallbackPatch(
      int imageWidth,
      int imageHeight,
      MaskBounds target,
      int patchW,
      int patchH,
      ) {
    final tryPoints = <({int x, int y})>[
      (x: target.left - patchW - 4, y: target.top),
      (x: target.right + 4, y: target.top),
      (x: target.left, y: target.top - patchH - 4),
      (x: target.left, y: target.bottom + 4),
    ];

    for (final p in tryPoints) {
      final x = p.x.clamp(0, math.max(0, imageWidth - patchW)).toInt();
      final y = p.y.clamp(0, math.max(0, imageHeight - patchH)).toInt();

      if (_overlaps(
        x,
        y,
        patchW,
        patchH,
        target,
        margin: math.max(2, patchW ~/ 4),
      )) {
        continue;
      }

      return PatchCandidate(
        sourceX: x,
        sourceY: y,
        patchWidth: patchW,
        patchHeight: patchH,
        score: 99999.0,
      );
    }

    return PatchCandidate(
      sourceX: target.left.clamp(0, math.max(0, imageWidth - patchW)).toInt(),
      sourceY: target.top.clamp(0, math.max(0, imageHeight - patchH)).toInt(),
      patchWidth: patchW,
      patchHeight: patchH,
      score: 999999.0,
    );
  }
}