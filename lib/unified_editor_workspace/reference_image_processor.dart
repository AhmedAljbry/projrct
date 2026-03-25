import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'reference_image_state.dart';

/// Lightweight CPU analyser for reference images.
/// No ML required – uses sampled pixel statistics.
class ReferenceImageProcessor {
  ReferenceImageProcessor._();

  /// Decode [bytes] and analyse pixel statistics.
  /// Returns a [ReferenceProfile] with palette, luminance, saturation, contrast, etc.
  static Future<ReferenceProfile> analyze(Uint8List bytes) async {
    // Decode to raw RGBA via dart:ui
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64, targetHeight: 64);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();

    if (byteData == null) return ReferenceProfile.empty();

    final pixels = byteData.buffer.asUint8List();
    final int totalPixels = img.width * img.height;

    double sumR = 0, sumG = 0, sumB = 0;
    double sumLuma = 0;
    double sumSat = 0;
    final List<double> lumaValues = [];

    // Bucket colours into 6 colour bins for palette extraction
    final Map<int, int> colorBucketCount = {};

    for (int i = 0; i < totalPixels; i++) {
      final int base = i * 4;
      final double r = pixels[base] / 255.0;
      final double g = pixels[base + 1] / 255.0;
      final double b = pixels[base + 2] / 255.0;

      sumR += r;
      sumG += g;
      sumB += b;

      // Perceived luminance (BT.601)
      final double luma = 0.299 * r + 0.587 * g + 0.114 * b;
      sumLuma += luma;
      lumaValues.add(luma);

      // HSL saturation
      final double cMax = math.max(r, math.max(g, b));
      final double cMin = math.min(r, math.min(g, b));
      final double l = (cMax + cMin) / 2.0;
      final double sat = (cMax == cMin)
          ? 0.0
          : (cMax - cMin) / (l > 0.5 ? (2.0 - cMax - cMin) : (cMax + cMin));
      sumSat += sat;

      // Colour bucket (reduce to 6-bit RGB for clustering)
      final int bucket = ((r * 3).round() << 4) | ((g * 3).round() << 2) | (b * 3).round();
      colorBucketCount[bucket] = (colorBucketCount[bucket] ?? 0) + 1;
    }

    final double avgLuma = sumLuma / totalPixels;
    final double avgSat = sumSat / totalPixels;
    final double avgR = sumR / totalPixels;
    final double avgG = sumG / totalPixels;
    final double avgB = sumB / totalPixels;

    // Contrast = std-dev of luma
    double variance = 0;
    for (final l in lumaValues) {
      variance += (l - avgLuma) * (l - avgLuma);
    }
    final double contrast = math.min(1.0, math.sqrt(variance / totalPixels) * 4.0);

    // Warmth bias: positive = warm (reds/yellows dominant), negative = cool (blues dominant)
    final double warmth = ((avgR - avgB) * 0.7 + (avgG - avgB) * 0.3).clamp(-1.0, 1.0);

    // Shadow / highlight ratio heuristic
    final int darkPixels = lumaValues.where((l) => l < 0.25).length;
    final int brightPixels = lumaValues.where((l) => l > 0.75).length;
    final double shadowHighlight = brightPixels / math.max(1, darkPixels + brightPixels);

    // Tone curve hint
    final String tone = _toneHint(avgLuma, warmth);

    // Palette: top 6 buckets by count
    final sortedBuckets = colorBucketCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final List<Color> palette = sortedBuckets.take(6).map((e) {
      final int key = e.key;
      final double r = ((key >> 4) & 0x3) / 3.0;
      final double g = ((key >> 2) & 0x3) / 3.0;
      final double b2 = (key & 0x3) / 3.0;
      return Color.fromRGBO(
        (r * 255).round(),
        (g * 255).round(),
        (b2 * 255).round(),
        1.0,
      );
    }).toList();

    // Compatibility bias: well-lit, moderately saturated images match best
    final double compat = (1.0 -
            (avgLuma - 0.45).abs() * 1.2 -
            (avgSat - 0.4).abs() * 0.6)
        .clamp(0.3, 1.0);

    return ReferenceProfile(
      palette: palette,
      avgLuminance: avgLuma,
      avgSaturation: avgSat,
      contrast: contrast,
      toneCurveHint: tone,
      warmthBias: warmth,
      shadowHighlightRatio: shadowHighlight,
      compatibilityBias: compat,
    );
  }

  static String _toneHint(double luma, double warmth) {
    if (luma > 0.65) return 'bright';
    if (luma < 0.35) return 'dark';
    if (warmth > 0.15) return 'warm';
    if (warmth < -0.15) return 'cool';
    return 'balanced';
  }
}
