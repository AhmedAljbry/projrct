import 'dart:math' as math;
import 'dart:typed_data';

import 'package:untitled2/vv/mask_data.dart';

import 'texture_analyzer.dart';

class PatchBlender {
  double _effectiveStrength(double strength, MaskBounds targetBounds) {
    final base = math.max(targetBounds.width, targetBounds.height).toDouble();
    final sizePenalty = base <= 18 ? 1.05 : (base <= 42 ? 0.92 : 0.80);
    return (strength * sizePenalty).clamp(
      base <= 18 ? 0.30 : 0.24,
      base <= 18 ? 0.86 : (base <= 42 ? 0.82 : 0.76),
    );
  }

  void blend({
    required Uint8List outputPixels,
    required int imageWidth,
    required int imageHeight,
    required Uint8List sourcePatch,
    required int patchWidth,
    required int patchHeight,
    required int sourceAnchorX,
    required int sourceAnchorY,
    required MaskBounds targetBounds,
    required MaskData mask,
    required double strength,
  }) {
    final w = math.min(patchWidth, targetBounds.width);
    final h = math.min(patchHeight, targetBounds.height);
    final originalSnapshot = Uint8List.fromList(outputPixels);
    final effectiveStrength = _effectiveStrength(strength, targetBounds);
    final surfaceProfile = _buildSurfaceProfile(
      outputPixels,
      imageWidth,
      imageHeight,
      targetBounds,
    );

    final edgeBlendScale = _edgeBlendScale(surfaceProfile);

    final shift = _computeToneShiftFromPatch(
      outputPixels,
      imageWidth,
      imageHeight,
      sourcePatch,
      patchWidth,
      patchHeight,
      sourceAnchorX,
      sourceAnchorY,
      targetBounds,
      surfaceProfile,
    );

    for (int dy = 0; dy < h; dy++) {
      for (int dx = 0; dx < w; dx++) {
        final tx = targetBounds.left + dx;
        final ty = targetBounds.top + dy;

        if (tx < 0 || ty < 0 || tx >= imageWidth || ty >= imageHeight) {
          continue;
        }

        final maskX = dx.clamp(0, mask.width - 1);
        final maskY = dy.clamp(0, mask.height - 1);
        final rawMask = mask.valueAt(maskX, maskY);
        final centerBoost = w <= 18 || h <= 18 ? 1.16 : (w <= 42 || h <= 42 ? 1.08 : 1.02);
        final surfaceAlphaScale = switch (surfaceProfile.surfaceClass) {
          SurfaceClass.skinLike => 0.93,
          SurfaceClass.flatBrightWall => 0.98,
          SurfaceClass.fabricTextured => 1.00,
          SurfaceClass.darkFabric => 1.01,
          SurfaceClass.unknown => 1.0,
        };
        final alphaCap = switch (surfaceProfile.surfaceClass) {
          SurfaceClass.skinLike => w <= 18 || h <= 18 ? 0.76 : (w <= 42 || h <= 42 ? 0.72 : 0.68),
          _ => w <= 18 || h <= 18 ? 0.80 : (w <= 42 || h <= 42 ? 0.76 : 0.72),
        };
        final maskAlpha = (
          rawMask * effectiveStrength * (0.96 + (rawMask * 0.22)) * centerBoost * surfaceAlphaScale * edgeBlendScale
        ).clamp(0.0, alphaCap);

        if (maskAlpha < 0.001) continue;

        final srcIdx = (dy * patchWidth + dx) * 4;
        if (srcIdx + 3 >= sourcePatch.length) continue;

        final dstIdx = (ty * imageWidth + tx) * 4;
        final originalAlpha = outputPixels[dstIdx + 3];

        final sr = (sourcePatch[srcIdx] + shift.dr).clamp(0, 255).toInt();
        final sg = (sourcePatch[srcIdx + 1] + shift.dg).clamp(0, 255).toInt();
        final sb = (sourcePatch[srcIdx + 2] + shift.db).clamp(0, 255).toInt();

        final invAlpha = 1.0 - maskAlpha;

        outputPixels[dstIdx] =
            (sr * maskAlpha + outputPixels[dstIdx] * invAlpha).round().clamp(0, 255);
        outputPixels[dstIdx + 1] =
            (sg * maskAlpha + outputPixels[dstIdx + 1] * invAlpha).round().clamp(0, 255);
        outputPixels[dstIdx + 2] =
            (sb * maskAlpha + outputPixels[dstIdx + 2] * invAlpha).round().clamp(0, 255);
        outputPixels[dstIdx + 3] = originalAlpha;
      }
    }

    _poissonDiffuse(
      outputPixels,
      imageWidth,
      imageHeight,
      targetBounds,
      mask,
      effectiveStrength,
      surfaceProfile,
      passes: 1,
    );

    _restoreLocalDetail(
      originalSnapshot,
      outputPixels,
      imageWidth,
      imageHeight,
      targetBounds,
      mask,
      surfaceProfile,
    );

    if (math.max(w, h) <= 12) {
      _microRefineTinyBlemish(
        outputPixels,
        imageWidth,
        imageHeight,
        targetBounds,
        mask,
        surfaceProfile,
      );
    }
  }

  void _microRefineTinyBlemish(
    Uint8List pixels,
    int imageWidth,
    int imageHeight,
    MaskBounds bounds,
    MaskData mask,
    _SurfaceProfile surfaceProfile,
  ) {
    final snapshot = Uint8List.fromList(pixels);
    final surfaceWeight = switch (surfaceProfile.surfaceClass) {
      SurfaceClass.skinLike => 0.34,
      SurfaceClass.flatBrightWall => 0.40,
      SurfaceClass.fabricTextured => 0.30,
      SurfaceClass.darkFabric => 0.32,
      SurfaceClass.unknown => 0.34,
    };
    final centerX = (bounds.width - 1) / 2.0;
    final centerY = (bounds.height - 1) / 2.0;
    final innerRadius = math.max(0.8, math.min(bounds.width, bounds.height) * 0.42);
    final outerRadius = innerRadius + 1.35;

    for (int dy = 0; dy < bounds.height; dy++) {
      for (int dx = 0; dx < bounds.width; dx++) {
        final imgX = bounds.left + dx;
        final imgY = bounds.top + dy;

        if (imgX < 1 || imgY < 1 || imgX >= imageWidth - 1 || imgY >= imageHeight - 1) {
          continue;
        }

        final alpha = mask.valueAt(dx.clamp(0, mask.width - 1), dy.clamp(0, mask.height - 1));
        if (alpha < 0.16) continue;

        double rSum = 0;
        double gSum = 0;
        double bSum = 0;
        double totalWeight = 0;

        for (int oy = -2; oy <= 2; oy++) {
          for (int ox = -2; ox <= 2; ox++) {
            final localX = dx + ox;
            final localY = dy + oy;
            if (localX < 0 || localY < 0 || localX >= bounds.width || localY >= bounds.height) {
              continue;
            }

            final distToCenter = math.sqrt(
              math.pow(localX - centerX, 2).toDouble() +
              math.pow(localY - centerY, 2).toDouble(),
            );
            if (distToCenter < innerRadius || distToCenter > outerRadius) {
              continue;
            }

            final ringMask = mask.valueAt(localX.clamp(0, mask.width - 1), localY.clamp(0, mask.height - 1));
            if (ringMask > 0.10) continue;

            final nx = bounds.left + localX;
            final ny = bounds.top + localY;
            if (nx < 0 || ny < 0 || nx >= imageWidth || ny >= imageHeight) continue;

            final distance = math.sqrt((ox * ox + oy * oy).toDouble());
            final weight = 1.0 / math.max(1.0, distance);
            final idx = (ny * imageWidth + nx) * 4;
            rSum += snapshot[idx] * weight;
            gSum += snapshot[idx + 1] * weight;
            bSum += snapshot[idx + 2] * weight;
            totalWeight += weight;
          }
        }

        if (totalWeight <= 0) continue;

        final idx = (imgY * imageWidth + imgX) * 4;
        final targetMix = (surfaceWeight * alpha).clamp(0.0, 0.38);
        final avgR = rSum / totalWeight;
        final avgG = gSum / totalWeight;
        final avgB = bSum / totalWeight;

        pixels[idx] =
            (snapshot[idx] * (1 - targetMix) + avgR * targetMix).round().clamp(0, 255);
        pixels[idx + 1] =
            (snapshot[idx + 1] * (1 - targetMix) + avgG * targetMix).round().clamp(0, 255);
        pixels[idx + 2] =
            (snapshot[idx + 2] * (1 - targetMix) + avgB * targetMix).round().clamp(0, 255);
      }
    }
  }



  double _edgeBlendScale(_SurfaceProfile surfaceProfile) {
    final highEdge = surfaceProfile.stats.edgeEnergy > 220000;
    final mediumEdge = surfaceProfile.stats.edgeEnergy > 120000;
    final highVariance = surfaceProfile.stats.luminanceVariance > 850;
    if (highEdge && highVariance) return 0.78;
    if (highEdge || mediumEdge) return 0.86;
    return 1.0;
  }

  double _edgeDetailBoost(_SurfaceProfile surfaceProfile) {
    final highEdge = surfaceProfile.stats.edgeEnergy > 220000;
    final mediumEdge = surfaceProfile.stats.edgeEnergy > 120000;
    final highVariance = surfaceProfile.stats.luminanceVariance > 850;
    if (highEdge && highVariance) return 0.10;
    if (highEdge || mediumEdge) return 0.06;
    return 0.0;
  }
  void _restoreLocalDetail(
    Uint8List originalPixels,
    Uint8List healedPixels,
    int imageWidth,
    int imageHeight,
    MaskBounds bounds,
    MaskData mask,
    _SurfaceProfile surfaceProfile,
  ) {
    final detailAmount = (switch (surfaceProfile.surfaceClass) {
      SurfaceClass.skinLike => 0.24,
      SurfaceClass.flatBrightWall => 0.12,
      SurfaceClass.fabricTextured => 0.18,
      SurfaceClass.darkFabric => 0.16,
      SurfaceClass.unknown => 0.18,
    } + _edgeDetailBoost(surfaceProfile)).clamp(0.10, 0.34);

    for (int dy = 0; dy < bounds.height; dy++) {
      for (int dx = 0; dx < bounds.width; dx++) {
        final imgX = bounds.left + dx;
        final imgY = bounds.top + dy;
        if (imgX < 0 || imgY < 0 || imgX >= imageWidth || imgY >= imageHeight) {
          continue;
        }

        final alpha = mask.valueAt(
          dx.clamp(0, mask.width - 1),
          dy.clamp(0, mask.height - 1),
        );
        if (alpha < 0.10) continue;

        final idx = (imgY * imageWidth + imgX) * 4;
        final restored = (detailAmount * alpha).clamp(0.0, 0.28);
        final keep = 1.0 - restored;

        healedPixels[idx] =
            (healedPixels[idx] * keep + originalPixels[idx] * restored).round().clamp(0, 255);
        healedPixels[idx + 1] =
            (healedPixels[idx + 1] * keep + originalPixels[idx + 1] * restored).round().clamp(0, 255);
        healedPixels[idx + 2] =
            (healedPixels[idx + 2] * keep + originalPixels[idx + 2] * restored).round().clamp(0, 255);
      }
    }
  }
  void _poissonDiffuse(
    Uint8List pixels,
    int imageWidth,
    int imageHeight,
    MaskBounds bounds,
    MaskData mask,
    double strength,
    _SurfaceProfile surfaceProfile, {
    required int passes,
  }) {
    const borderExpand = 3;
    final base = math.max(bounds.width, bounds.height);

    double blendWeight;
    if (base <= 18) {
      blendWeight = 0.13;
    } else if (base <= 42) {
      blendWeight = 0.17;
    } else {
      blendWeight = 0.19;
    }

    blendWeight *= switch (surfaceProfile.surfaceClass) {
      SurfaceClass.skinLike => 0.62,
      SurfaceClass.flatBrightWall => 0.82,
      SurfaceClass.fabricTextured => 0.90,
      SurfaceClass.darkFabric => 1.01,
      SurfaceClass.unknown => 1.0,
    };

    for (int pass = 0; pass < passes; pass++) {
      for (int dy = -borderExpand; dy <= bounds.height + borderExpand; dy++) {
        for (int dx = -borderExpand; dx <= bounds.width + borderExpand; dx++) {
          final imgX = bounds.left + dx;
          final imgY = bounds.top + dy;

          if (imgX < 1 || imgY < 1 || imgX >= imageWidth - 1 || imgY >= imageHeight - 1) {
            continue;
          }

          final maskX = dx.clamp(0, mask.width - 1);
          final maskY = dy.clamp(0, mask.height - 1);
          final alpha = mask.valueAt(maskX, maskY) * strength;

          if (alpha < 0.04 || alpha > 0.96) continue;

          double rSum = 0, gSum = 0, bSum = 0;
          int count = 0;

          for (final n in [
            [imgX - 1, imgY],
            [imgX + 1, imgY],
            [imgX, imgY - 1],
            [imgX, imgY + 1],
          ]) {
            final nx = n[0];
            final ny = n[1];
            if (nx < 0 || ny < 0 || nx >= imageWidth || ny >= imageHeight) {
              continue;
            }

            final ni = (ny * imageWidth + nx) * 4;
            rSum += pixels[ni];
            gSum += pixels[ni + 1];
            bSum += pixels[ni + 2];
            count++;
          }

          if (count == 0) continue;

          final dstIdx = (imgY * imageWidth + imgX) * 4;
          final seam = 1.0 - (alpha - 0.5).abs() * 2.0;
          final w = seam * blendWeight;

          pixels[dstIdx] =
              ((rSum / count) * w + pixels[dstIdx] * (1 - w)).round().clamp(0, 255);
          pixels[dstIdx + 1] =
              ((gSum / count) * w + pixels[dstIdx + 1] * (1 - w)).round().clamp(0, 255);
          pixels[dstIdx + 2] =
              ((bSum / count) * w + pixels[dstIdx + 2] * (1 - w)).round().clamp(0, 255);
        }
      }
    }
  }

  _ToneShift _computeToneShiftFromPatch(
    Uint8List outputPixels,
    int imageWidth,
    int imageHeight,
    Uint8List sourcePatch,
    int patchWidth,
    int patchHeight,
    int srcAnchorX,
    int srcAnchorY,
    MaskBounds target,
    _SurfaceProfile surfaceProfile,
  ) {
    final contextStats = _borderStats(outputPixels, imageWidth, imageHeight, target);
    final sourceStats = _patchBorderStats(sourcePatch, patchWidth, patchHeight);

    if (sourceStats.count == 0 || contextStats.count == 0) {
      return const _ToneShift(dr: 0, dg: 0, db: 0);
    }

    final maxShift = switch (surfaceProfile.surfaceClass) {
      SurfaceClass.skinLike => 12.0,
      SurfaceClass.flatBrightWall => 16.0,
      SurfaceClass.fabricTextured => 18.0,
      SurfaceClass.darkFabric => 18.0,
      SurfaceClass.unknown => 16.0,
    };
    final dr = (contextStats.meanR - sourceStats.meanR).clamp(-maxShift, maxShift);
    final dg = (contextStats.meanG - sourceStats.meanG).clamp(-maxShift, maxShift);
    final db = (contextStats.meanB - sourceStats.meanB).clamp(-maxShift, maxShift);

    return _ToneShift(dr: dr, dg: dg, db: db);
  }

  _SurfaceProfile _buildSurfaceProfile(
    Uint8List pixels,
    int imageWidth,
    int imageHeight,
    MaskBounds region,
  ) {
    final stats = _borderStats(pixels, imageWidth, imageHeight, region);
    final surfaceClass = _classifySurface(stats);
    return _SurfaceProfile(stats: stats, surfaceClass: surfaceClass);
  }

  SurfaceClass _classifySurface(_RGBStats stats) {
    final meanLuminance = 0.299 * stats.meanR + 0.587 * stats.meanG + 0.114 * stats.meanB;
    final variance = stats.luminanceVariance;
    final energy = stats.edgeEnergy;

    final isBrightFlat = meanLuminance > 170 && variance < 180 && energy < 250000;
    if (isBrightFlat) return SurfaceClass.flatBrightWall;

    final isSkinLike =
        stats.meanR > stats.meanG &&
        stats.meanG > stats.meanB &&
        stats.meanR > 120 &&
        stats.meanG > 85 &&
        stats.meanB > 60 &&
        variance < 900;
    if (isSkinLike) return SurfaceClass.skinLike;

    final isDarkFabric = meanLuminance < 95 && variance > 150 && energy > 120000;
    if (isDarkFabric) return SurfaceClass.darkFabric;

    final isFabricTextured =
        variance > 120 &&
        energy > 80000 &&
        (stats.meanB > stats.meanR || stats.meanB > stats.meanG || meanLuminance < 160);
    if (isFabricTextured) return SurfaceClass.fabricTextured;

    return SurfaceClass.unknown;
  }

  _RGBStats _borderStats(
    Uint8List pixels,
    int imageWidth,
    int imageHeight,
    MaskBounds region,
  ) {
    const borderWidth = 4;
    double rSum = 0, gSum = 0, bSum = 0;
    double luminanceSum = 0;
    double luminanceSqSum = 0;
    double edgeEnergy = 0;
    int count = 0;

    void sample(int x, int y) {
      if (x < 0 || y < 0 || x >= imageWidth || y >= imageHeight) return;
      final idx = (y * imageWidth + x) * 4;
      final r = pixels[idx].toDouble();
      final g = pixels[idx + 1].toDouble();
      final b = pixels[idx + 2].toDouble();
      final lum = 0.299 * r + 0.587 * g + 0.114 * b;
      rSum += r;
      gSum += g;
      bSum += b;
      luminanceSum += lum;
      luminanceSqSum += lum * lum;
      if (x > 0 && y > 0 && x < imageWidth - 1 && y < imageHeight - 1) {
        final gx = _sobelX(pixels, imageWidth, x, y);
        final gy = _sobelY(pixels, imageWidth, x, y);
        edgeEnergy += gx * gx + gy * gy;
      }
      count++;
    }

    for (int b = 1; b <= borderWidth; b++) {
      for (int x = region.left - b; x <= region.right + b; x++) {
        sample(x, region.top - b);
        sample(x, region.bottom + b);
      }
      for (int y = region.top - b; y <= region.bottom + b; y++) {
        sample(region.left - b, y);
        sample(region.right + b, y);
      }
    }

    if (count == 0) {
      return const _RGBStats(
        meanR: 128,
        meanG: 128,
        meanB: 128,
        count: 0,
        luminanceVariance: 0,
        edgeEnergy: 0,
      );
    }

    final inv = 1.0 / count;
    final meanL = luminanceSum * inv;
    final variance = (luminanceSqSum * inv) - (meanL * meanL);

    return _RGBStats(
      meanR: rSum * inv,
      meanG: gSum * inv,
      meanB: bSum * inv,
      count: count,
      luminanceVariance: variance,
      edgeEnergy: edgeEnergy,
    );
  }

  _RGBStats _patchBorderStats(Uint8List patch, int w, int h) {
    double rSum = 0, gSum = 0, bSum = 0;
    int count = 0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final isBorder = x == 0 || y == 0 || x == w - 1 || y == h - 1;
        if (!isBorder) continue;

        final idx = (y * w + x) * 4;
        if (idx + 3 >= patch.length) continue;

        rSum += patch[idx];
        gSum += patch[idx + 1];
        bSum += patch[idx + 2];
        count++;
      }
    }

    if (count == 0) {
      return const _RGBStats(
        meanR: 128,
        meanG: 128,
        meanB: 128,
        count: 0,
        luminanceVariance: 0,
        edgeEnergy: 0,
      );
    }

    return _RGBStats(
      meanR: rSum / count,
      meanG: gSum / count,
      meanB: bSum / count,
      count: count,
      luminanceVariance: 0,
      edgeEnergy: 0,
    );
  }

  double _sobelX(Uint8List pixels, int width, int x, int y) {
    double v = 0;
    v -= _lum(pixels, width, x - 1, y - 1);
    v -= 2 * _lum(pixels, width, x - 1, y);
    v -= _lum(pixels, width, x - 1, y + 1);
    v += _lum(pixels, width, x + 1, y - 1);
    v += 2 * _lum(pixels, width, x + 1, y);
    v += _lum(pixels, width, x + 1, y + 1);
    return v;
  }

  double _sobelY(Uint8List pixels, int width, int x, int y) {
    double v = 0;
    v -= _lum(pixels, width, x - 1, y - 1);
    v -= 2 * _lum(pixels, width, x, y - 1);
    v -= _lum(pixels, width, x + 1, y - 1);
    v += _lum(pixels, width, x - 1, y + 1);
    v += 2 * _lum(pixels, width, x, y + 1);
    v += _lum(pixels, width, x + 1, y + 1);
    return v;
  }

  double _lum(Uint8List pixels, int width, int x, int y) {
    if (x < 0 || y < 0) return 0;
    final idx = (y * width + x) * 4;
    if (idx + 2 >= pixels.length) return 0;
    return 0.299 * pixels[idx] + 0.587 * pixels[idx + 1] + 0.114 * pixels[idx + 2];
  }
}

class _SurfaceProfile {
  final _RGBStats stats;
  final SurfaceClass surfaceClass;

  const _SurfaceProfile({
    required this.stats,
    required this.surfaceClass,
  });
}

class _ToneShift {
  final double dr;
  final double dg;
  final double db;

  const _ToneShift({
    required this.dr,
    required this.dg,
    required this.db,
  });
}

class _RGBStats {
  final double meanR;
  final double meanG;
  final double meanB;
  final int count;
  final double luminanceVariance;
  final double edgeEnergy;

  const _RGBStats({
    required this.meanR,
    required this.meanG,
    required this.meanB,
    required this.count,
    required this.luminanceVariance,
    required this.edgeEnergy,
  });
}








