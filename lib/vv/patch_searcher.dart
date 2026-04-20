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
    final ringWidth = switch (sizeClass) {
      BlemishSizeClass.small => math.max(3, (base * 0.56).ceil()),
      BlemishSizeClass.medium => math.max(4, (base * 0.44).ceil()),
      BlemishSizeClass.largeNatural => math.max(6, (base * 0.38).ceil()),
    };
    final exclusionMargin = switch (sizeClass) {
      BlemishSizeClass.small => math.max(2, (base * 0.38).ceil()),
      BlemishSizeClass.medium => math.max(3, (base * 0.34).ceil()),
      BlemishSizeClass.largeNatural => math.max(4, (base * 0.30).ceil()),
    };
    final spatialWeight = switch (sizeClass) {
      BlemishSizeClass.small => 44.0,
      BlemishSizeClass.medium => 38.0,
      BlemishSizeClass.largeNatural => 30.0,
    };
    final maxCandidates = mode == EngineQualityMode.preview ? 6 : 10;

    final targetCx = (targetRegion.left + targetRegion.right) / 2.0;
    final targetCy = (targetRegion.top + targetRegion.bottom) / 2.0;
    final targetRingFeatures = _analyzer.computeRingFeatures(
      imagePixels,
      imageWidth,
      imageHeight,
      targetRegion,
      ringWidth: ringWidth,
    );
    final targetSurface = targetRingFeatures.surfaceClass;

    final List<_ScoredCandidate> candidates = [];
    final seen = <int>{};

    void considerCandidate(
      int sx,
      int sy, {
      required double laneBias,
      required String side,
    }) {
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

      if (!_isSurfaceCompatible(targetSurface, candidateRingFeatures.surfaceClass)) {
        return;
      }

      final candidateInterior = _analyzer.computeFeatures(
        imagePixels,
        imageWidth,
        imageHeight,
        candidateBounds,
      );

      if (!_isInteriorCompatible(targetSurface, candidateInterior.surfaceClass)) {
        return;
      }

      if (targetSurface == SurfaceClass.skinLike) {
        final luminanceDelta =
            (targetRingFeatures.meanLuminance - candidateInterior.meanLuminance).abs();
        final redDelta = (targetRingFeatures.meanR - candidateInterior.meanR).abs();
        final greenDelta = (targetRingFeatures.meanG - candidateInterior.meanG).abs();
        if (luminanceDelta > 16.0 || redDelta > 20.0 || greenDelta > 18.0) {
          return;
        }
      }

      final featureDist = targetRingFeatures.distanceTo(candidateRingFeatures);
      final interiorDist = targetRingFeatures.distanceTo(candidateInterior);
      final candCx = clampedX + patchW / 2.0;
      final candCy = clampedY + patchH / 2.0;
      final dx = candCx - targetCx;
      final dy = candCy - targetCy;
      final spatialDist = math.sqrt(dx * dx + dy * dy);
      final normalizedSpatial = spatialDist / math.max(1.0, maxRadius.toDouble());

      final maxNormalizedSpatial = switch (sizeClass) {
        BlemishSizeClass.small => 0.52,
        BlemishSizeClass.medium => 0.58,
        BlemishSizeClass.largeNatural => 0.68,
      };
      final featureGate1 = sizeClass == BlemishSizeClass.largeNatural ? 34.0 : 30.0;
      final featureGate2 = sizeClass == BlemishSizeClass.largeNatural ? 42.0 : 38.0;

      if (normalizedSpatial > maxNormalizedSpatial) return;
      if (normalizedSpatial > 0.34 && featureDist > featureGate1) return;
      if (normalizedSpatial > 0.24 && featureDist > featureGate2) return;

      final axisBias = math.min(dx.abs(), dy.abs()) /
          math.max(1.0, math.max(dx.abs(), dy.abs()));
      final edgeDistance = _edgeDistancePenalty(
        clampedX,
        clampedY,
        patchW,
        patchH,
        targetRegion,
      );
      if (edgeDistance > math.max(1.2, math.max(patchW, patchH) * 0.18)) {
        return;
      }

      var score = featureDist;
      score += interiorDist * 0.10;
      score += normalizedSpatial * spatialWeight;
      score +=
          (targetRingFeatures.meanLuminance - candidateInterior.meanLuminance).abs() * 0.06;
      score += (targetRingFeatures.energy - candidateRingFeatures.energy).abs() * 0.018;
      score += _colorPenalty(targetRingFeatures, candidateInterior);
      score += axisBias * (targetSurface == SurfaceClass.skinLike ? 8.0 : 5.0);
      score += edgeDistance * 4.5;
      score += laneBias;

      candidates.add(
        _ScoredCandidate(
          candidate: PatchCandidate(
            sourceX: clampedX,
            sourceY: clampedY,
            patchWidth: patchW,
            patchHeight: patchH,
            score: score,
          ),
          score: score,
          side: side,
        ),
      );
    }

    for (final lane in _priorityLanes(
      targetRegion,
      patchW,
      patchH,
      exclusionMargin,
      targetSurface,
      sizeClass,
    )) {
      for (final point in lane.points) {
        considerCandidate(
          point.x,
          point.y,
          laneBias: lane.bias,
          side: lane.side,
        );
      }
    }

    if (candidates.isEmpty) {
      final fallback = _fallbackPatch(
        imageWidth,
        imageHeight,
        targetRegion,
        patchW,
        patchH,
        targetSurface,
      );
      sw.stop();
      return PatchSelectionResult(
        bestPatch: fallback,
        candidates: [fallback],
        searchDuration: sw.elapsed,
      );
    }

    final filtered = targetSurface == SurfaceClass.skinLike
        ? _keepOnlyBestSide(candidates)
        : candidates;
    filtered.sort((a, b) => a.score.compareTo(b.score));
    final ranked = filtered.take(maxCandidates).map((e) => e.candidate).toList();
    sw.stop();
    return PatchSelectionResult(
      bestPatch: ranked.first,
      candidates: ranked,
      searchDuration: sw.elapsed,
    );
  }

  List<_ScoredCandidate> _keepOnlyBestSide(List<_ScoredCandidate> candidates) {
    candidates.sort((a, b) => a.score.compareTo(b.score));
    final bestSide = candidates.first.side;
    final sameSide = candidates.where((c) => c.side == bestSide).toList();
    return sameSide.isEmpty ? candidates : sameSide;
  }

  List<_PriorityLane> _priorityLanes(
    MaskBounds target,
    int patchW,
    int patchH,
    int exclusionMargin,
    SurfaceClass targetSurface,
    BlemishSizeClass sizeClass,
  ) {
    final nearGapX = math.max(1, exclusionMargin);
    final nearGapY = math.max(1, exclusionMargin);
    final centerTop = target.top;
    final extraSpread =
        sizeClass == BlemishSizeClass.largeNatural ? math.max(2, patchH ~/ 4) : 0;
    final extraSpreadX =
        sizeClass == BlemishSizeClass.largeNatural ? math.max(2, patchW ~/ 4) : 0;

    List<({int x, int y})> rightLane(int anchorY, int gap) {
      final spread = math.max(1, patchH ~/ 7);
      final points = <({int x, int y})>[
        (x: target.right + gap, y: anchorY),
        (x: target.right + gap, y: anchorY - spread),
        (x: target.right + gap, y: anchorY + spread),
      ];
      if (extraSpread > 0) {
        points.add((x: target.right + gap, y: anchorY - extraSpread));
        points.add((x: target.right + gap, y: anchorY + extraSpread));
      }
      return points;
    }

    List<({int x, int y})> leftLane(int anchorY, int gap) {
      final spread = math.max(1, patchH ~/ 7);
      final points = <({int x, int y})>[
        (x: target.left - patchW - gap, y: anchorY),
        (x: target.left - patchW - gap, y: anchorY - spread),
        (x: target.left - patchW - gap, y: anchorY + spread),
      ];
      if (extraSpread > 0) {
        points.add((x: target.left - patchW - gap, y: anchorY - extraSpread));
        points.add((x: target.left - patchW - gap, y: anchorY + extraSpread));
      }
      return points;
    }

    List<({int x, int y})> topLane(int anchorX, int gap) {
      final spread = math.max(1, patchW ~/ 7);
      final points = <({int x, int y})>[
        (x: anchorX, y: target.top - patchH - gap),
        (x: anchorX - spread, y: target.top - patchH - gap),
        (x: anchorX + spread, y: target.top - patchH - gap),
      ];
      if (extraSpreadX > 0) {
        points.add((x: anchorX - extraSpreadX, y: target.top - patchH - gap));
        points.add((x: anchorX + extraSpreadX, y: target.top - patchH - gap));
      }
      return points;
    }

    if (targetSurface == SurfaceClass.skinLike) {
      return <_PriorityLane>[
        _PriorityLane(points: rightLane(centerTop, nearGapX), bias: 0.0, side: 'right'),
        _PriorityLane(points: leftLane(centerTop, nearGapX), bias: 0.0, side: 'left'),
        _PriorityLane(points: topLane(target.left, nearGapY), bias: 1.6, side: 'top'),
      ];
    }

    List<({int x, int y})> bottomLane(int anchorX, int gap) {
      final spread = math.max(1, patchW ~/ 6);
      final points = <({int x, int y})>[
        (x: anchorX, y: target.bottom + gap),
        (x: anchorX - spread, y: target.bottom + gap),
        (x: anchorX + spread, y: target.bottom + gap),
      ];
      if (extraSpreadX > 0) {
        points.add((x: anchorX - extraSpreadX, y: target.bottom + gap));
        points.add((x: anchorX + extraSpreadX, y: target.bottom + gap));
      }
      return points;
    }

    return <_PriorityLane>[
      _PriorityLane(points: rightLane(centerTop, nearGapX), bias: 0.0, side: 'right'),
      _PriorityLane(points: leftLane(centerTop, nearGapX), bias: 0.0, side: 'left'),
      _PriorityLane(points: topLane(target.left, nearGapY), bias: 0.4, side: 'top'),
      _PriorityLane(points: bottomLane(target.left, nearGapY), bias: 0.4, side: 'bottom'),
    ];
  }

  bool _isSurfaceCompatible(SurfaceClass a, SurfaceClass b) {
    if (a == SurfaceClass.skinLike) {
      return b == SurfaceClass.skinLike;
    }
    if (a == SurfaceClass.unknown || b == SurfaceClass.unknown) return true;
    if (a == b) return true;
    if ((a == SurfaceClass.darkFabric && b == SurfaceClass.fabricTextured) ||
        (a == SurfaceClass.fabricTextured && b == SurfaceClass.darkFabric)) {
      return true;
    }
    return false;
  }

  bool _isInteriorCompatible(SurfaceClass targetSurface, SurfaceClass candidateSurface) {
    if (targetSurface == SurfaceClass.skinLike) {
      return candidateSurface == SurfaceClass.skinLike ||
          candidateSurface == SurfaceClass.unknown;
    }
    if (targetSurface == SurfaceClass.flatBrightWall) {
      return candidateSurface != SurfaceClass.darkFabric;
    }
    return true;
  }

  double _colorPenalty(PatchFeatures target, PatchFeatures candidate) {
    final dr = (target.meanR - candidate.meanR).abs();
    final dg = (target.meanG - candidate.meanG).abs();
    final db = (target.meanB - candidate.meanB).abs();
    var penalty = dr * 0.10 + dg * 0.08 + db * 0.08;
    if (target.surfaceClass == SurfaceClass.skinLike) {
      penalty += dr * 0.22 + dg * 0.18 + db * 0.16;
    }
    return penalty;
  }

  double _edgeDistancePenalty(
    int sx,
    int sy,
    int pw,
    int ph,
    MaskBounds target,
  ) {
    final leftGap = (target.left - (sx + pw)).abs();
    final rightGap = (sx - target.right).abs();
    final topGap = (target.top - (sy + ph)).abs();
    final bottomGap = (sy - target.bottom).abs();

    final horizontalGap = math.min(leftGap, rightGap).toDouble();
    final verticalGap = math.min(topGap, bottomGap).toDouble();
    return math.min(horizontalGap, verticalGap);
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
        return mode == EngineQualityMode.preview ? (base * 0.56).ceil() : (base * 0.72).ceil();
      case BlemishSizeClass.medium:
        return mode == EngineQualityMode.preview ? (base * 0.68).ceil() : (base * 0.84).ceil();
      case BlemishSizeClass.largeNatural:
        return mode == EngineQualityMode.preview ? (base * 1.02).ceil() : (base * 1.26).ceil();
    }
  }

  PatchCandidate _fallbackPatch(
    int imageWidth,
    int imageHeight,
    MaskBounds target,
    int patchW,
    int patchH,
    SurfaceClass targetSurface,
  ) {
    final gapX = math.max(1, patchW ~/ 5);
    final gapY = math.max(1, patchH ~/ 5);
    final tryPoints = targetSurface == SurfaceClass.skinLike
        ? <({int x, int y, String side})>[
            (x: target.right + gapX, y: target.top, side: 'right'),
            (x: target.left - patchW - gapX, y: target.top, side: 'left'),
            (x: target.left, y: target.top - patchH - gapY, side: 'top'),
          ]
        : <({int x, int y, String side})>[
            (x: target.right + gapX, y: target.top, side: 'right'),
            (x: target.left - patchW - gapX, y: target.top, side: 'left'),
            (x: target.left, y: target.bottom + gapY, side: 'bottom'),
            (x: target.left, y: target.top - patchH - gapY, side: 'top'),
          ];

    for (final p in tryPoints) {
      final x = p.x.clamp(0, math.max(0, imageWidth - patchW)).toInt();
      final y = p.y.clamp(0, math.max(0, imageHeight - patchH)).toInt();
      if (_overlaps(x, y, patchW, patchH, target, margin: math.max(1, patchW ~/ 5))) {
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

class _PriorityLane {
  final List<({int x, int y})> points;
  final double bias;
  final String side;

  const _PriorityLane({
    required this.points,
    required this.bias,
    required this.side,
  });
}

class _ScoredCandidate {
  final PatchCandidate candidate;
  final double score;
  final String side;

  const _ScoredCandidate({
    required this.candidate,
    required this.score,
    required this.side,
  });
}
