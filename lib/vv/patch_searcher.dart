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
    final maxRadius = _ringMaxRadius(patchW, patchH, mode);
    final stride = _samplingStride(patchW, patchH, mode);
    final ringWidth = switch (sizeClass) {
      BlemishSizeClass.small => math.max(4, (base * 0.72).ceil()),
      BlemishSizeClass.medium => math.max(6, (base * 0.60).ceil()),
      BlemishSizeClass.largeNatural => math.max(8, (base * 0.50).ceil()),
    };
    final exclusionMargin = switch (sizeClass) {
      BlemishSizeClass.small => math.max(4, (base * 0.92).ceil()),
      BlemishSizeClass.medium => math.max(6, (base * 1.02).ceil()),
      BlemishSizeClass.largeNatural => math.max(8, (base * 1.12).ceil()),
    };
    final spatialWeight = switch (sizeClass) {
      BlemishSizeClass.small => 30.0,
      BlemishSizeClass.medium => 24.0,
      BlemishSizeClass.largeNatural => 18.0,
    };
    final maxCandidates = mode == EngineQualityMode.preview ? 8 : 14;

    final targetCx = (targetRegion.left + targetRegion.right) / 2.0;
    final targetCy = (targetRegion.top + targetRegion.bottom) / 2.0;
    final targetRingFeatures = _analyzer.computeRingFeatures(
      imagePixels,
      imageWidth,
      imageHeight,
      targetRegion,
      ringWidth: ringWidth,
    );

    final List<PatchCandidate> candidates = [];
    final seen = <int>{};

    void considerCandidate(int sx, int sy, {required bool priority}) {
      final clampedX = sx.clamp(0, math.max(0, imageWidth - patchW)).toInt();
      final clampedY = sy.clamp(0, math.max(0, imageHeight - patchH)).toInt();
      final key = (clampedY * imageWidth) + clampedX;
      if (!seen.add(key)) return;

      if (_overlaps(
        clampedX,
        clampedY,
        patchW,
        patchH,
        targetRegion,
        margin: exclusionMargin,
      )) {
        return;
      }

      final candidateBounds = MaskBounds(
        left: clampedX,
        top: clampedY,
        right: clampedX + patchW,
        bottom: clampedY + patchH,
      );

      final candidateRingFeatures = _analyzer.computeRingFeatures(
        imagePixels,
        imageWidth,
        imageHeight,
        candidateBounds,
        ringWidth: ringWidth,
      );

      if (!_isSurfaceCompatible(
        targetRingFeatures.surfaceClass,
        candidateRingFeatures.surfaceClass,
      )) {
        return;
      }

      final candidateInterior = _analyzer.computeFeatures(
        imagePixels,
        imageWidth,
        imageHeight,
        candidateBounds,
      );

      final featureDist = targetRingFeatures.distanceTo(candidateRingFeatures);
      final interiorDist = targetRingFeatures.distanceTo(candidateInterior);
      final candCx = clampedX + patchW / 2.0;
      final candCy = clampedY + patchH / 2.0;
      final dx = candCx - targetCx;
      final dy = candCy - targetCy;
      final spatialDist = math.sqrt(dx * dx + dy * dy);
      final normalizedSpatial = spatialDist / math.max(1.0, maxRadius.toDouble());

      if (normalizedSpatial > 0.88) return;
      if (!priority && normalizedSpatial > 0.72 && featureDist > 42.0) return;
      if (normalizedSpatial > 0.54 && featureDist > 56.0) return;

      final axisBias = math.min(dx.abs(), dy.abs()) / math.max(1.0, math.max(dx.abs(), dy.abs()));
      var score = featureDist;
      score += interiorDist * 0.14;
      score += normalizedSpatial * spatialWeight;
      score += (targetRingFeatures.meanLuminance - candidateInterior.meanLuminance).abs() * 0.08;
      score += (targetRingFeatures.energy - candidateRingFeatures.energy).abs() * 0.025;
      score += axisBias * 4.0;
      if (!priority) {
        score += 3.0;
      }

      candidates.add(PatchCandidate(
        sourceX: clampedX,
        sourceY: clampedY,
        patchWidth: patchW,
        patchHeight: patchH,
        score: score,
      ));
    }

    for (final offset in _priorityOffsets(targetRegion, patchW, patchH, exclusionMargin)) {
      considerCandidate(offset.x, offset.y, priority: true);
    }

    final searchLeft = math.max(0, targetRegion.left - maxRadius);
    final searchTop = math.max(0, targetRegion.top - maxRadius);
    final searchRight = math.min(imageWidth - patchW, targetRegion.right + maxRadius);
    final searchBottom = math.min(imageHeight - patchH, targetRegion.bottom + maxRadius);

    for (int sy = searchTop; sy <= searchBottom; sy += stride) {
      for (int sx = searchLeft; sx <= searchRight; sx += stride) {
        considerCandidate(sx, sy, priority: false);
      }
    }

    if (candidates.isEmpty) {
      final fallback = _fallbackPatch(imageWidth, imageHeight, targetRegion, patchW, patchH);
      sw.stop();
      return PatchSelectionResult(
        bestPatch: fallback,
        candidates: [fallback],
        searchDuration: sw.elapsed,
      );
    }

    candidates.sort((a, b) => a.score.compareTo(b.score));
    final ranked = candidates.take(maxCandidates).toList();
    sw.stop();
    return PatchSelectionResult(
      bestPatch: ranked.first,
      candidates: ranked,
      searchDuration: sw.elapsed,
    );
  }

  List<({int x, int y})> _priorityOffsets(
    MaskBounds target,
    int patchW,
    int patchH,
    int exclusionMargin,
  ) {
    final gapX = math.max(3, exclusionMargin + patchW ~/ 6);
    final gapY = math.max(3, exclusionMargin + patchH ~/ 6);
    final nearGapX = math.max(2, gapX ~/ 2);
    final nearGapY = math.max(2, gapY ~/ 2);

    return <({int x, int y})>[
      (x: target.right + nearGapX, y: target.top),
      (x: target.left - patchW - nearGapX, y: target.top),
      (x: target.left, y: target.bottom + nearGapY),
      (x: target.left, y: target.top - patchH - nearGapY),
      (x: target.right + gapX, y: target.top),
      (x: target.left - patchW - gapX, y: target.top),
      (x: target.left, y: target.bottom + gapY),
      (x: target.left, y: target.top - patchH - gapY),
      (x: target.right + gapX, y: target.bottom + gapY),
      (x: target.left - patchW - gapX, y: target.bottom + gapY),
      (x: target.right + gapX, y: target.top - patchH - gapY),
      (x: target.left - patchW - gapX, y: target.top - patchH - gapY),
    ];
  }

  bool _isSurfaceCompatible(SurfaceClass a, SurfaceClass b) {
    if (a == SurfaceClass.unknown || b == SurfaceClass.unknown) return true;
    if (a == b) return true;
    if ((a == SurfaceClass.darkFabric && b == SurfaceClass.fabricTextured) ||
        (a == SurfaceClass.fabricTextured && b == SurfaceClass.darkFabric)) {
      return true;
    }
    return false;
  }

  bool _overlaps(int sx, int sy, int pw, int ph, MaskBounds target, {required int margin}) {
    return sx < target.right + margin &&
        sy < target.bottom + margin &&
        sx + pw > target.left - margin &&
        sy + ph > target.top - margin;
  }

  int _ringMaxRadius(int patchW, int patchH, EngineQualityMode mode) {
    final sizeClass = classifyBlemishSize(patchW, patchH);
    final base = math.max(patchW, patchH);
    switch (sizeClass) {
      case BlemishSizeClass.small:
        return mode == EngineQualityMode.preview ? (base * 1.55).ceil() : (base * 2.0).ceil();
      case BlemishSizeClass.medium:
        return mode == EngineQualityMode.preview ? (base * 2.0).ceil() : (base * 2.6).ceil();
      case BlemishSizeClass.largeNatural:
        return mode == EngineQualityMode.preview ? (base * 2.4).ceil() : (base * 3.1).ceil();
    }
  }

  int _samplingStride(int patchW, int patchH, EngineQualityMode mode) {
    final minDim = math.min(patchW, patchH);
    if (mode == EngineQualityMode.preview) {
      return math.max(minDim ~/ 2, 4);
    }
    return math.max(minDim ~/ 3, 3);
  }

  PatchCandidate _fallbackPatch(
    int imageWidth,
    int imageHeight,
    MaskBounds target,
    int patchW,
    int patchH,
  ) {
    final gapX = math.max(3, patchW ~/ 3);
    final gapY = math.max(3, patchH ~/ 3);
    final tryPoints = <({int x, int y})>[
      (x: target.right + gapX, y: target.top),
      (x: target.left - patchW - gapX, y: target.top),
      (x: target.left, y: target.bottom + gapY),
      (x: target.left, y: target.top - patchH - gapY),
      (x: target.right + gapX, y: target.bottom + gapY),
      (x: target.left - patchW - gapX, y: target.top - patchH - gapY),
    ];

    for (final p in tryPoints) {
      final x = p.x.clamp(0, math.max(0, imageWidth - patchW)).toInt();
      final y = p.y.clamp(0, math.max(0, imageHeight - patchH)).toInt();
      if (_overlaps(x, y, patchW, patchH, target, margin: math.max(2, patchW ~/ 3))) {
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
      sourceX: target.right.clamp(0, math.max(0, imageWidth - patchW)).toInt(),
      sourceY: target.top.clamp(0, math.max(0, imageHeight - patchH)).toInt(),
      patchWidth: patchW,
      patchHeight: patchH,
      score: 999999.0,
    );
  }
}
