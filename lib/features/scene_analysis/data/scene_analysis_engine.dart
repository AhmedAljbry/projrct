import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class SceneAnalysisEngine {
  const SceneAnalysisEngine();

  Map<String, dynamic> analyze(img.Image source, {int maxDimension = 320}) {
    final image = _resizeDown(source, maxDimension);
    final width = image.width;
    final height = image.height;
    final total = math.max(1, width * height);

    final skinMask = Uint8List(total);
    final neutralMask = Uint8List(total);
    final hairMask = Uint8List(total);
    final skyMask = Uint8List(total);
    final foregroundMask = Uint8List(total);
    final backgroundMask = Uint8List(total);
    const histogramBins = 16;
    final luminanceHistogram = List<double>.filled(histogramBins, 0);
    final saturationHistogram = List<double>.filled(histogramBins, 0);

    final paletteCounts = <int, int>{};
    double luminanceSum = 0;
    double luminanceSquaredSum = 0;
    double saturationSum = 0;
    double warmthSum = 0;
    double edgeSum = 0;
    var brightPixels = 0;
    var darkPixels = 0;
    var skinPixels = 0;
    var skyPixels = 0;
    var neutralPixels = 0;
    var organicPixels = 0;
    var furPixels = 0;

    var skinMinX = width;
    var skinMinY = height;
    var skinMaxX = 0;
    var skinMaxY = 0;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final index = y * width + x;
        final hsl = _rgbToHsl(r, g, b);
        final luminance = _luminance(r, g, b);
        final saturation = hsl[1];
        final warmth = (r - b) / 255;

        luminanceSum += luminance;
        luminanceSquaredSum += luminance * luminance;
        saturationSum += saturation;
        warmthSum += warmth;
        luminanceHistogram[_histogramIndex(luminance, histogramBins)] +=
            1 / total;
        saturationHistogram[_histogramIndex(saturation, histogramBins)] +=
            1 / total;

        if (luminance > 0.84) {
          brightPixels++;
        }
        if (luminance < 0.18) {
          darkPixels++;
        }
        if (_isNeutral(r, g, b, saturation)) {
          neutralPixels++;
          neutralMask[index] = 255;
        }
        if (_isOrganic(r, g, b, hsl[0], saturation)) {
          organicPixels++;
        }
        if (_isFurTone(r, g, b, hsl[0], saturation, luminance)) {
          furPixels++;
        }

        final isSkin = _isSkin(r, g, b, hsl[0], saturation, luminance);
        final isSky = _isSky(r, g, b, hsl[0], saturation, luminance,
            y / math.max(1, height - 1));
        if (isSkin) {
          skinMask[index] = 255;
          skinPixels++;
          if (x < skinMinX) skinMinX = x;
          if (y < skinMinY) skinMinY = y;
          if (x > skinMaxX) skinMaxX = x;
          if (y > skinMaxY) skinMaxY = y;
        }
        if (isSky) {
          skyMask[index] = 255;
          skyPixels++;
        }

        final centerX = (x / math.max(1, width - 1)) - 0.5;
        final centerY = (y / math.max(1, height - 1)) - 0.45;
        final centerWeight =
            1 - (math.sqrt((centerX * centerX) + (centerY * centerY)) * 1.55);
        final foregroundScore =
            (centerWeight * 0.58) + (saturation * 0.18) + (luminance * 0.12);
        if (foregroundScore > 0.28 || isSkin) {
          foregroundMask[index] = 255;
        } else {
          backgroundMask[index] = 255;
        }

        final isHair = !isSkin &&
            y < height * 0.55 &&
            luminance < 0.36 &&
            saturation < 0.55;
        if (isHair) {
          hairMask[index] = 255;
        }

        if (x < width - 1 && y < height - 1) {
          final right = image.getPixel(x + 1, y);
          final bottom = image.getPixel(x, y + 1);
          final edge = ((r - right.r).abs() +
                  (g - right.g).abs() +
                  (b - right.b).abs() +
                  (r - bottom.r).abs() +
                  (g - bottom.g).abs() +
                  (b - bottom.b).abs()) /
              1530;
          edgeSum += edge;
        }

        final bucket = ((r ~/ 32) << 10) | ((g ~/ 32) << 5) | (b ~/ 32);
        paletteCounts.update(bucket, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final averageLuminance = luminanceSum / total;
    final contrast = math.sqrt(
      math.max(
          0,
          (luminanceSquaredSum / total) -
              (averageLuminance * averageLuminance)),
    );
    final averageSaturation = saturationSum / total;
    final temperature = warmthSum / total;
    final skinLikelihood = skinPixels / total;
    final skyLikelihood = skyPixels / total;
    final neutralLikelihood = neutralPixels / total;
    final organicLikelihood = organicPixels / total;
    final furLikelihood = furPixels / total;
    final edgeEnergy = edgeSum / total;

    final sceneType = _inferSceneType(
      skinLikelihood: skinLikelihood,
      skyLikelihood: skyLikelihood,
      neutralLikelihood: neutralLikelihood,
      furLikelihood: furLikelihood,
      contrast: contrast,
      averageLuminance: averageLuminance,
      averageSaturation: averageSaturation,
      organicLikelihood: organicLikelihood,
    );

    final faces = <Map<String, dynamic>>[];
    if (skinPixels > total * 0.02 &&
        skinMaxX > skinMinX &&
        skinMaxY > skinMinY) {
      final faceWidth = (skinMaxX - skinMinX + 1) / width;
      final faceHeight = (skinMaxY - skinMinY + 1) / height;
      if (faceWidth < 0.75 && faceHeight < 0.8) {
        faces.add(<String, dynamic>{
          'left': skinMinX / width,
          'top': skinMinY / height,
          'width': faceWidth,
          'height': faceHeight,
          'confidence': (0.58 + (skinLikelihood * 2.2)).clamp(0.0, 0.98),
        });
      }
    }
    if (faces.isEmpty && sceneType == 'portrait') {
      faces.add(const <String, dynamic>{
        'left': 0.28,
        'top': 0.14,
        'width': 0.44,
        'height': 0.52,
        'confidence': 0.55,
      });
    }

    final segmentationConfidence =
        (0.52 + (skinLikelihood * 1.4) + (skyLikelihood * 0.8))
            .clamp(0.0, 0.98);

    return <String, dynamic>{
      'analysis': <String, dynamic>{
        'scene': <String, dynamic>{
          'sceneType': sceneType,
          'faceCount': faces.length,
          'hasSkin': skinLikelihood > 0.02,
          'hasHair': hairMask.any((value) => value > 0),
          'hasSky': skyLikelihood > 0.05,
          'hasForegroundSubject': foregroundMask.any((value) => value > 0),
          'averageBrightness': averageLuminance,
          'contrast': contrast,
          'saturation': averageSaturation,
          'warmth': temperature,
          'segmentationConfidence': segmentationConfidence,
        },
        'faces': faces,
        'skinMask': <String, dynamic>{
          'width': width,
          'height': height,
          'values': skinMask
        },
        'neutralMask': <String, dynamic>{
          'width': width,
          'height': height,
          'values': neutralMask,
        },
        'hairMask': <String, dynamic>{
          'width': width,
          'height': height,
          'values': hairMask
        },
        'backgroundMask': <String, dynamic>{
          'width': width,
          'height': height,
          'values': backgroundMask
        },
        'skyMask': <String, dynamic>{
          'width': width,
          'height': height,
          'values': skyMask
        },
        'foregroundMask': <String, dynamic>{
          'width': width,
          'height': height,
          'values': foregroundMask
        },
      },
      'stats': <String, dynamic>{
        'averageLuminance': averageLuminance,
        'contrast': contrast,
        'averageSaturation': averageSaturation,
        'temperature': temperature,
        'brightPixelRatio': brightPixels / total,
        'darkPixelRatio': darkPixels / total,
        'skinLikelihood': skinLikelihood,
        'skyLikelihood': skyLikelihood,
        'neutralLikelihood': neutralLikelihood,
        'organicLikelihood': organicLikelihood,
        'furLikelihood': furLikelihood,
        'edgeEnergy': edgeEnergy,
        'highlightHeadroom': (1 - (brightPixels / total)).clamp(0.0, 1.0),
        'shadowHeadroom': (1 - (darkPixels / total)).clamp(0.0, 1.0),
        'palette': _buildPalette(paletteCounts),
        'luminanceHistogram': luminanceHistogram,
        'saturationHistogram': saturationHistogram,
      },
    };
  }

  img.Image _resizeDown(img.Image image, int maxDimension) {
    final maxSide = math.max(image.width, image.height);
    if (maxSide <= maxDimension) {
      return img.copyResize(image, width: image.width, height: image.height);
    }
    if (image.width >= image.height) {
      return img.copyResize(image, width: maxDimension);
    }
    return img.copyResize(image, height: maxDimension);
  }

  List<int> _buildPalette(Map<int, int> paletteCounts) {
    final sorted = paletteCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((entry) {
      final bucket = entry.key;
      final r = ((bucket >> 10) & 31) * 8;
      final g = ((bucket >> 5) & 31) * 8;
      final b = (bucket & 31) * 8;
      return 0xFF000000 | (r << 16) | (g << 8) | b;
    }).toList(growable: false);
  }

  String _inferSceneType({
    required double skinLikelihood,
    required double skyLikelihood,
    required double neutralLikelihood,
    required double furLikelihood,
    required double contrast,
    required double averageLuminance,
    required double averageSaturation,
    required double organicLikelihood,
  }) {
    if (skinLikelihood > 0.05) {
      return 'portrait';
    }
    if (furLikelihood > 0.035 &&
        organicLikelihood > 0.08 &&
        skinLikelihood < 0.03) {
      return 'wildlife';
    }
    if (averageLuminance < 0.32 && contrast > 0.14) {
      return 'night';
    }
    if (skyLikelihood > 0.07 && averageLuminance > 0.54) {
      return 'landscape';
    }
    if (neutralLikelihood > 0.18 &&
        contrast > 0.15 &&
        averageSaturation < 0.35) {
      return 'architecture';
    }
    if (neutralLikelihood > 0.2 && averageSaturation < 0.24) {
      return 'product';
    }
    if (organicLikelihood > 0.12 && averageSaturation > 0.22) {
      return 'editorial';
    }
    return 'editorial';
  }

  bool _isSkin(
      int r, int g, int b, double hue, double saturation, double luminance) {
    final maxChannel = math.max(r, math.max(g, b));
    final minChannel = math.min(r, math.min(g, b));
    final chroma = maxChannel - minChannel;
    return r > 85 &&
        g > 35 &&
        b > 20 &&
        chroma > 10 &&
        r > g &&
        r > b &&
        hue >= 8 &&
        hue <= 55 &&
        saturation > 0.12 &&
        luminance > 0.2 &&
        luminance < 0.92;
  }

  bool _isSky(int r, int g, int b, double hue, double saturation,
      double luminance, double yFactor) {
    return yFactor < 0.7 &&
        hue >= 170 &&
        hue <= 250 &&
        saturation > 0.12 &&
        luminance > 0.34 &&
        b >= g &&
        b > r;
  }

  bool _isNeutral(int r, int g, int b, double saturation) {
    return (r - g).abs() < 18 && (g - b).abs() < 18 && saturation < 0.15;
  }

  bool _isOrganic(int r, int g, int b, double hue, double saturation) {
    return hue >= 22 &&
        hue <= 130 &&
        saturation > 0.18 &&
        g >= r * 0.7 &&
        g >= b * 0.7;
  }

  bool _isFurTone(
    int r,
    int g,
    int b,
    double hue,
    double saturation,
    double luminance,
  ) {
    final warmBrown = hue >= 18 &&
        hue <= 52 &&
        saturation >= 0.16 &&
        saturation <= 0.62 &&
        luminance >= 0.12 &&
        luminance <= 0.76 &&
        r >= g &&
        g >= b * 0.7;
    final darkNeutralFur = (r - g).abs() < 26 &&
        (g - b).abs() < 28 &&
        saturation < 0.22 &&
        luminance > 0.08 &&
        luminance < 0.46;
    return warmBrown || darkNeutralFur;
  }
}

int _histogramIndex(double value, int bins) {
  return (value.clamp(0.0, 1.0) * (bins - 1)).round();
}

double _luminance(int r, int g, int b) {
  return ((0.299 * r) + (0.587 * g) + (0.114 * b)) / 255;
}

List<double> _rgbToHsl(int r, int g, int b) {
  final rd = r / 255.0;
  final gd = g / 255.0;
  final bd = b / 255.0;
  final maxValue = math.max(rd, math.max(gd, bd));
  final minValue = math.min(rd, math.min(gd, bd));
  final delta = maxValue - minValue;
  final lightness = (maxValue + minValue) / 2;

  double hue = 0;
  double saturation = 0;
  if (delta != 0) {
    saturation = delta / (1 - (2 * lightness - 1).abs());
    if (maxValue == rd) {
      hue = 60 * (((gd - bd) / delta) % 6);
    } else if (maxValue == gd) {
      hue = 60 * (((bd - rd) / delta) + 2);
    } else {
      hue = 60 * (((rd - gd) / delta) + 4);
    }
  }
  if (hue < 0) {
    hue += 360;
  }
  return <double>[hue, saturation.isNaN ? 0 : saturation, lightness];
}
