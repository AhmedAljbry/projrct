import 'dart:math' as math;
import 'dart:typed_data';

import 'package:untitled2/vv/mask_data.dart';

enum SurfaceClass {
  flatBrightWall,
  skinLike,
  fabricTextured,
  darkFabric,
  unknown,
}

class TextureAnalyzer {
  double computeMeanLuminance(
      Uint8List pixels,
      int imageWidth,
      int imageHeight,
      MaskBounds region,
      ) {
    final clamped = region.clampTo(imageWidth, imageHeight);
    if (clamped.isEmpty) return 128.0;

    double sum = 0.0;
    int count = 0;

    for (int y = clamped.top; y < clamped.bottom; y++) {
      for (int x = clamped.left; x < clamped.right; x++) {
        final idx = (y * imageWidth + x) * 4;
        sum += _luminance(pixels[idx], pixels[idx + 1], pixels[idx + 2]);
        count++;
      }
    }

    return count > 0 ? sum / count : 128.0;
  }

  double computeLuminanceVariance(
      Uint8List pixels,
      int imageWidth,
      int imageHeight,
      MaskBounds region,
      ) {
    final clamped = region.clampTo(imageWidth, imageHeight);
    if (clamped.isEmpty) return 0.0;

    double sum = 0.0, sumSq = 0.0;
    int count = 0;

    for (int y = clamped.top; y < clamped.bottom; y++) {
      for (int x = clamped.left; x < clamped.right; x++) {
        final idx = (y * imageWidth + x) * 4;
        final lum = _luminance(pixels[idx], pixels[idx + 1], pixels[idx + 2]);
        sum += lum;
        sumSq += lum * lum;
        count++;
      }
    }

    if (count == 0) return 0.0;
    final mean = sum / count;
    return (sumSq / count) - (mean * mean);
  }

  double computeTextureEnergy(
      Uint8List pixels,
      int imageWidth,
      int imageHeight,
      MaskBounds region,
      ) {
    final clamped = region.clampTo(imageWidth, imageHeight);
    if (clamped.isEmpty) return 0.0;

    double energy = 0.0;
    for (int y = clamped.top + 1; y < clamped.bottom - 1; y++) {
      for (int x = clamped.left + 1; x < clamped.right - 1; x++) {
        final gx = _sobelX(pixels, imageWidth, x, y);
        final gy = _sobelY(pixels, imageWidth, x, y);
        energy += gx * gx + gy * gy;
      }
    }

    return energy;
  }

  PatchFeatures computeFeatures(
      Uint8List pixels,
      int imageWidth,
      int imageHeight,
      MaskBounds region,
      ) {
    final clamped = region.clampTo(imageWidth, imageHeight);

    if (clamped.isEmpty) {
      return const PatchFeatures(
        meanLuminance: 128,
        variance: 0,
        energy: 0,
        meanR: 128,
        meanG: 128,
        meanB: 128,
        surfaceClass: SurfaceClass.unknown,
      );
    }

    double sumL = 0, sumSqL = 0;
    double sumR = 0, sumG = 0, sumB = 0;
    double energy = 0;
    int count = 0;

    for (int y = clamped.top; y < clamped.bottom; y++) {
      for (int x = clamped.left; x < clamped.right; x++) {
        final idx = (y * imageWidth + x) * 4;
        final r = pixels[idx].toDouble();
        final g = pixels[idx + 1].toDouble();
        final b = pixels[idx + 2].toDouble();
        final lum = 0.299 * r + 0.587 * g + 0.114 * b;

        sumL += lum;
        sumSqL += lum * lum;
        sumR += r;
        sumG += g;
        sumB += b;
        count++;
      }
    }

    final innerTop = clamped.top + 1;
    final innerBottom = clamped.bottom - 1;
    final innerLeft = clamped.left + 1;
    final innerRight = clamped.right - 1;

    if (innerBottom > innerTop && innerRight > innerLeft) {
      for (int y = innerTop; y < innerBottom; y++) {
        for (int x = innerLeft; x < innerRight; x++) {
          final gx = _sobelX(pixels, imageWidth, x, y);
          final gy = _sobelY(pixels, imageWidth, x, y);
          energy += gx * gx + gy * gy;
        }
      }
    }

    final n = count.toDouble();
    final meanL = sumL / n;
    final variance = (sumSqL / n) - (meanL * meanL);
    final meanR = sumR / n;
    final meanG = sumG / n;
    final meanB = sumB / n;

    final surfaceClass = classifySurface(
      meanLuminance: meanL,
      variance: variance,
      energy: energy,
      meanR: meanR,
      meanG: meanG,
      meanB: meanB,
    );

    return PatchFeatures(
      meanLuminance: meanL,
      variance: variance,
      energy: energy,
      meanR: meanR,
      meanG: meanG,
      meanB: meanB,
      surfaceClass: surfaceClass,
    );
  }

  double computeSAD(
      Uint8List pixels,
      int imageWidth,
      int imageHeight,
      MaskBounds regionA,
      MaskBounds regionB,
      ) {
    final w = math.min(regionA.width, regionB.width);
    final h = math.min(regionA.height, regionB.height);
    double sad = 0.0;

    for (int dy = 0; dy < h; dy++) {
      for (int dx = 0; dx < w; dx++) {
        final ax = regionA.left + dx;
        final ay = regionA.top + dy;
        final bx = regionB.left + dx;
        final by = regionB.top + dy;

        if (ax >= imageWidth ||
            ay >= imageHeight ||
            bx >= imageWidth ||
            by >= imageHeight ||
            ax < 0 ||
            ay < 0 ||
            bx < 0 ||
            by < 0) {
          sad += 128.0;
          continue;
        }

        final idxA = (ay * imageWidth + ax) * 4;
        final idxB = (by * imageWidth + bx) * 4;
        final dr = (pixels[idxA] - pixels[idxB]).abs().toDouble();
        final dg = (pixels[idxA + 1] - pixels[idxB + 1]).abs().toDouble();
        final db = (pixels[idxA + 2] - pixels[idxB + 2]).abs().toDouble();

        sad += 0.299 * dr + 0.587 * dg + 0.114 * db;
      }
    }

    final area = (w * h).toDouble();
    return area > 0 ? sad / area : double.infinity;
  }

  SurfaceClass classifySurface({
    required double meanLuminance,
    required double variance,
    required double energy,
    required double meanR,
    required double meanG,
    required double meanB,
  }) {
    final isBrightFlat =
        meanLuminance > 170 && variance < 180 && energy < 250000;
    if (isBrightFlat) {
      return SurfaceClass.flatBrightWall;
    }

    final isSkinLike =
        meanR > meanG &&
            meanG > meanB &&
            meanR > 120 &&
            meanG > 85 &&
            meanB > 60 &&
            variance < 900;
    if (isSkinLike) {
      return SurfaceClass.skinLike;
    }

    final isDarkFabric =
        meanLuminance < 95 && variance > 150 && energy > 120000;
    if (isDarkFabric) {
      return SurfaceClass.darkFabric;
    }

    final isFabricTextured =
        variance > 120 &&
            energy > 80000 &&
            (meanB > meanR || meanB > meanG || meanLuminance < 160);
    if (isFabricTextured) {
      return SurfaceClass.fabricTextured;
    }

    return SurfaceClass.unknown;
  }

  double _luminance(int r, int g, int b) => 0.299 * r + 0.587 * g + 0.114 * b;

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
    return _luminance(pixels[idx], pixels[idx + 1], pixels[idx + 2]);
  }
}

class PatchFeatures {
  final double meanLuminance;
  final double variance;
  final double energy;
  final double meanR;
  final double meanG;
  final double meanB;
  final SurfaceClass surfaceClass;

  const PatchFeatures({
    required this.meanLuminance,
    required this.variance,
    required this.energy,
    required this.meanR,
    required this.meanG,
    required this.meanB,
    required this.surfaceClass,
  });

  double distanceTo(PatchFeatures other) {
    final dl = (meanLuminance - other.meanLuminance).abs() * 0.45;
    final dv = (variance - other.variance).abs() * 0.18;
    final de = (energy - other.energy).abs() * 0.08;
    final dr = (meanR - other.meanR).abs() * 0.12;
    final dg = (meanG - other.meanG).abs() * 0.12;
    final db = (meanB - other.meanB).abs() * 0.12;

    double surfacePenalty = 0.0;
    if (surfaceClass != other.surfaceClass) {
      surfacePenalty = 35.0;
    }

    return dl + dv + de + dr + dg + db + surfacePenalty;
  }
}