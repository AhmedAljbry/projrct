import 'dart:math' as math;
import 'dart:typed_data';

import 'package:untitled2/vv/mask_data.dart';

class PatchBlender {
  double _effectiveStrength(double strength, MaskBounds targetBounds) {
    final base = math.max(targetBounds.width, targetBounds.height).toDouble();
    final sizePenalty = base <= 18 ? 0.96 : (base <= 42 ? 0.89 : 0.82);
    return (strength * sizePenalty).clamp(0.22, 0.78);
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
    final effectiveStrength = _effectiveStrength(strength, targetBounds);

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
        final maskAlpha = (rawMask * effectiveStrength * (0.92 + (rawMask * 0.18))).clamp(0.0, 0.78);

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
      passes: 1,
    );
  }

  void _poissonDiffuse(
    Uint8List pixels,
    int imageWidth,
    int imageHeight,
    MaskBounds bounds,
    MaskData mask,
    double strength, {
    required int passes,
  }) {
    const borderExpand = 3;
    final base = math.max(bounds.width, bounds.height);

    double blendWeight;
    if (base <= 18) {
      blendWeight = 0.11;
    } else if (base <= 42) {
      blendWeight = 0.15;
    } else {
      blendWeight = 0.18;
    }

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
  ) {
    final contextStats = _borderStats(outputPixels, imageWidth, imageHeight, target);
    final sourceStats = _patchBorderStats(sourcePatch, patchWidth, patchHeight);

    if (sourceStats.count == 0 || contextStats.count == 0) {
      return const _ToneShift(dr: 0, dg: 0, db: 0);
    }

    const maxShift = 18.0;
    final dr = (contextStats.meanR - sourceStats.meanR).clamp(-maxShift, maxShift);
    final dg = (contextStats.meanG - sourceStats.meanG).clamp(-maxShift, maxShift);
    final db = (contextStats.meanB - sourceStats.meanB).clamp(-maxShift, maxShift);

    return _ToneShift(dr: dr, dg: dg, db: db);
  }

  _RGBStats _borderStats(
    Uint8List pixels,
    int imageWidth,
    int imageHeight,
    MaskBounds region,
  ) {
    const borderWidth = 4;
    double rSum = 0, gSum = 0, bSum = 0;
    int count = 0;

    void sample(int x, int y) {
      if (x < 0 || y < 0 || x >= imageWidth || y >= imageHeight) return;
      final idx = (y * imageWidth + x) * 4;
      rSum += pixels[idx];
      gSum += pixels[idx + 1];
      bSum += pixels[idx + 2];
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
      return const _RGBStats(meanR: 128, meanG: 128, meanB: 128, count: 0);
    }

    return _RGBStats(
      meanR: rSum / count,
      meanG: gSum / count,
      meanB: bSum / count,
      count: count,
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
      return const _RGBStats(meanR: 128, meanG: 128, meanB: 128, count: 0);
    }

    return _RGBStats(
      meanR: rSum / count,
      meanG: gSum / count,
      meanB: bSum / count,
      count: count,
    );
  }
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

  const _RGBStats({
    required this.meanR,
    required this.meanG,
    required this.meanB,
    required this.count,
  });
}
