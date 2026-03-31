import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'package:untitled2/features/enhancement/data/viral_enhancement_engine.dart';
import 'package:untitled2/features/face_protection/data/face_protection_engine.dart';
import 'package:untitled2/features/scene_analysis/data/scene_analysis_engine.dart';
import 'package:untitled2/features/style_transfer/data/services/adaptive_mapping_engine.dart';
import 'package:untitled2/features/style_transfer/data/services/style_extraction_engine.dart';

class StyleTransferKernel {
  const StyleTransferKernel();

  Map<String, dynamic> extractStyle(Map<String, dynamic> payload) {
    final bytes = _toBytes(payload['bytes']);
    final name = payload['name']?.toString() ?? 'Extracted Style';
    final image = _decode(bytes);
    final analysis =
        const SceneAnalysisEngine().analyze(image, maxDimension: 320);
    return const StyleExtractionEngine().extract(
      stats: <String, dynamic>{},
      scene: <String, dynamic>{},
      name: '',
      id: '',
    )
      ..clear()
      ..addAll(
        const StyleExtractionEngine().extract(
          stats: (analysis['stats'] as Map<String, dynamic>),
          scene: ((analysis['analysis'] as Map<String, dynamic>)['scene']
              as Map<String, dynamic>),
          name: name,
          id: 'style-${_fastHash(bytes)}',
        ),
      );
  }

  Map<String, dynamic> analyzeScene(Map<String, dynamic> payload) {
    final bytes = _toBytes(payload['bytes']);
    final image = _decode(bytes);
    final analysis =
        const SceneAnalysisEngine().analyze(image, maxDimension: 320);
    return analysis['analysis'] as Map<String, dynamic>;
  }

  Map<String, dynamic> applyStyle(Map<String, dynamic> payload) {
    final targetBytes = _toBytes(payload['targetBytes']);
    final referenceBytes = payload['referenceBytes'] == null
        ? null
        : _toBytes(payload['referenceBytes']);
    final sourceProfile = Map<String, dynamic>.from(
        payload['styleProfile'] as Map<String, dynamic>);
    final settings =
        Map<String, dynamic>.from(payload['settings'] as Map<String, dynamic>);
    final highQuality = payload['highQuality'] as bool? ?? false;

    final original = _decode(targetBytes);
    final maxDimension = ((highQuality
                ? settings['exportMaxDimension']
                : settings['previewMaxDimension']) as num?)
            ?.toInt() ??
        (highQuality ? 2400 : 1280);
    final working = _resizeDown(original, maxDimension);
    final pristine =
        img.copyResize(working, width: working.width, height: working.height);

    final analysis = const SceneAnalysisEngine().analyze(working,
        maxDimension: math.max(240, math.min(working.width, working.height)));
    final sceneAnalysis = analysis['analysis'] as Map<String, dynamic>;
    final scene = Map<String, dynamic>.from(
        sceneAnalysis['scene'] as Map<String, dynamic>);
    final targetStats =
        Map<String, dynamic>.from(analysis['stats'] as Map<String, dynamic>);
    final mapped = const AdaptiveMappingEngine().mapProfile(
      sourceProfile: sourceProfile,
      targetStats: targetStats,
      scene: scene,
      settings: settings,
    );
    final profile =
        Map<String, dynamic>.from(mapped['profile'] as Map<String, dynamic>);
    final enhancement = const ViralEnhancementEngine().build(
      profile: profile,
      scene: scene,
      settings: settings,
    );

    _applyPixelTransfer(
      working: working,
      original: pristine,
      sceneAnalysis: sceneAnalysis,
      profile: profile,
      settings: settings,
      enhancement: enhancement,
      referenceBytes: referenceBytes,
    );

    final detail =
        Map<String, dynamic>.from(profile['detail'] as Map<String, dynamic>);
    _applyMicroContrast(
        working, _asDouble(enhancement['microContrast']) * 0.28);
    _applyBloom(working, _asDouble(enhancement['bloomStrength']) * 0.20);
    _applyGrain(working, (_asDouble(detail['grain']) * 0.08) + 0.01);

    final processedStats = const SceneAnalysisEngine()
            .analyze(_resizeDown(working, 240), maxDimension: 240)['stats']
        as Map<String, dynamic>;
    final safetyReport = const FaceProtectionEngine().buildReport(
      originalStats: targetStats,
      processedStats: processedStats,
      scene: scene,
      settings: settings,
    );

    final outputBytes = Uint8List.fromList(
        img.encodeJpg(working, quality: highQuality ? 95 : 91));

    return <String, dynamic>{
      'previewBytes': outputBytes,
      'exportBytes': highQuality ? outputBytes : null,
      'appliedProfile': profile,
      'sceneAnalysis': sceneAnalysis,
      'safetyReport': safetyReport,
      'compatibility': _asDouble(mapped['compatibility']),
      'appliedStrength': _asDouble(mapped['appliedStrength']),
      'previewRenderMs': highQuality ? 320 : 110,
      'exportRenderMs': highQuality ? 840 : 0,
      'exportReady': highQuality,
      'warnings': _buildWarnings(
        scene: scene,
        safetyReport: safetyReport,
        compatibility: _asDouble(mapped['compatibility']),
      ),
      'viralScore': _asDouble(mapped['viralScore']),
    };
  }

  void _applyPixelTransfer({
    required img.Image working,
    required img.Image original,
    required Map<String, dynamic> sceneAnalysis,
    required Map<String, dynamic> profile,
    required Map<String, dynamic> settings,
    required Map<String, dynamic> enhancement,
    Uint8List? referenceBytes,
  }) {
    final tone =
        Map<String, dynamic>.from(profile['tone'] as Map<String, dynamic>);
    final color =
        Map<String, dynamic>.from(profile['color'] as Map<String, dynamic>);
    final detail =
        Map<String, dynamic>.from(profile['detail'] as Map<String, dynamic>);
    final hslProfile =
        Map<String, dynamic>.from(profile['hsl'] as Map<String, dynamic>);
    final curves =
        Map<String, dynamic>.from(profile['curves'] as Map<String, dynamic>);
    final local =
        Map<String, dynamic>.from(profile['local'] as Map<String, dynamic>);
    final faces =
        (sceneAnalysis['faces'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);

    final skinMask = Map<String, dynamic>.from(
        sceneAnalysis['skinMask'] as Map<String, dynamic>);
    final skyMask = Map<String, dynamic>.from(
        sceneAnalysis['skyMask'] as Map<String, dynamic>);
    final backgroundMask = Map<String, dynamic>.from(
        sceneAnalysis['backgroundMask'] as Map<String, dynamic>);
    final foregroundMask = Map<String, dynamic>.from(
        sceneAnalysis['foregroundMask'] as Map<String, dynamic>);

    final referenceTemperatureBias = referenceBytes == null
        ? 0.0
        : ((_fastHash(referenceBytes) % 17) - 8) / 120.0;
    final width = working.width;
    final height = working.height;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final source = original.getPixel(x, y);
        final sr = source.r.toInt();
        final sg = source.g.toInt();
        final sb = source.b.toInt();
        final luminance = _luminance(sr, sg, sb);
        final baseHsl = _rgbToHsl(sr, sg, sb);
        final skinMaskValue = _maskValue(skinMask, x, y, width, height);
        final skyMaskValue = _maskValue(skyMask, x, y, width, height);
        final backgroundMaskValue =
            _maskValue(backgroundMask, x, y, width, height);
        final foregroundMaskValue =
            _maskValue(foregroundMask, x, y, width, height);
        final isFace = _isInsideFace(faces, x / width, y / height);

        var localStrength = 1.0;
        if (skinMaskValue > 0 && _bool(local['skinProtect'], true)) {
          localStrength *= 0.42;
        }
        if (isFace && _bool(local['faceExposureGuard'], true)) {
          localStrength *= 0.54;
        }
        if (skyMaskValue > 0 && !_bool(local['skyAdjust'], true)) {
          localStrength *= 0.72;
        }

        var hue = baseHsl[0];
        var saturation = baseHsl[1];
        var lightness = baseHsl[2];
        final channelDelta = _channelDelta(hue, hslProfile);

        lightness += _asDouble(tone['exposure']) * 0.18 * localStrength;
        lightness +=
            _asDouble(tone['shadows']) * (1 - luminance) * 0.12 * localStrength;
        lightness +=
            _asDouble(tone['highlights']) * luminance * 0.10 * localStrength;
        lightness += _asDouble(channelDelta['l']) * localStrength;
        lightness += _asDouble(tone['fade']) * 0.04;
        saturation = saturation *
            (1 + (_asDouble(color['saturation']) * 0.72 * localStrength));
        saturation += _asDouble(color['vibrance']) *
            (1 - saturation) *
            0.34 *
            localStrength;
        saturation += _asDouble(channelDelta['s']) * localStrength;
        hue += (_asDouble(channelDelta['h']) * localStrength);
        hue += (_asDouble(color['temperature']) + referenceTemperatureBias) *
            (skyMaskValue > 0 ? -5.5 : 4.2) *
            localStrength;
        hue += _asDouble(color['tint']) * 2.2 * localStrength;

        if (skyMaskValue > 0 && _bool(local['skyAdjust'], true)) {
          saturation += 0.04;
          lightness += 0.012;
        }
        if (backgroundMaskValue > 0 && _bool(settings['depthIllusion'], true)) {
          lightness -= _asDouble(enhancement['depthLift']) * 0.06;
        }
        if (foregroundMaskValue > 0) {
          lightness += _asDouble(detail['clarity']) * 0.018;
        }
        if (isFace && _bool(settings['faceRefinement'], true)) {
          lightness += _asDouble(enhancement['faceLift']) * 0.06;
          saturation *= 0.985;
        }

        final rgb = _hslToRgb(
            hue, saturation.clamp(0.0, 1.0), lightness.clamp(0.0, 1.0));
        var r = rgb[0];
        var g = rgb[1];
        var b = rgb[2];

        r += ((_asDouble(color['temperature']) * 30) -
                (_asDouble(color['tint']) * 10))
            .round();
        g += (_asDouble(color['tint']) * 8).round();
        b -= (_asDouble(color['temperature']) * 26).round();

        r = _curveApply(
            r,
            curves['red'] as List<dynamic>? ??
                const <dynamic>[0, 0.25, 0.5, 0.75, 1]);
        g = _curveApply(
            g,
            curves['green'] as List<dynamic>? ??
                const <dynamic>[0, 0.25, 0.5, 0.75, 1]);
        b = _curveApply(
            b,
            curves['blue'] as List<dynamic>? ??
                const <dynamic>[0, 0.25, 0.5, 0.75, 1]);

        final masterMapped = _curveApply(
                _luminance(r, g, b) * 255,
                curves['master'] as List<dynamic>? ??
                    const <dynamic>[0, 0.25, 0.5, 0.75, 1]) /
            255.0;
        final currentLuminance = _luminance(r, g, b).clamp(0.001, 1.0);
        final luminanceScale =
            (masterMapped / currentLuminance).clamp(0.72, 1.28);
        r = (r * luminanceScale).round();
        g = (g * luminanceScale).round();
        b = (b * luminanceScale).round();

        final vignette = _asDouble(enhancement['vignette']);
        if (vignette > 0 && _bool(local['backgroundAdjust'], true)) {
          final dx = (x / math.max(1, width - 1)) - 0.5;
          final dy = (y / math.max(1, height - 1)) - 0.5;
          final dist = math.sqrt((dx * dx) + (dy * dy));
          final vignetteAmount = 1 - (dist * vignette * 0.35);
          r = (r * vignetteAmount).round();
          g = (g * vignetteAmount).round();
          b = (b * vignetteAmount).round();
        }

        if (skinMaskValue > 0 && _bool(local['skinProtect'], true)) {
          r = ((r * 0.56) + (sr * 0.44)).round();
          g = ((g * 0.56) + (sg * 0.44)).round();
          b = ((b * 0.56) + (sb * 0.44)).round();
        }

        working.setPixelRgba(
          x,
          y,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
          255,
        );
      }
    }
  }

  void _applyMicroContrast(img.Image image, double amount) {
    if (amount <= 0.01) {
      return;
    }
    final snapshot =
        img.copyResize(image, width: image.width, height: image.height);
    for (var y = 1; y < image.height - 1; y++) {
      for (var x = 1; x < image.width - 1; x++) {
        final center = snapshot.getPixel(x, y);
        final neighbors = <img.Pixel>[
          snapshot.getPixel(x - 1, y),
          snapshot.getPixel(x + 1, y),
          snapshot.getPixel(x, y - 1),
          snapshot.getPixel(x, y + 1),
        ];
        final avgR =
            neighbors.map((pixel) => pixel.r.toInt()).reduce((a, b) => a + b) /
                neighbors.length;
        final avgG =
            neighbors.map((pixel) => pixel.g.toInt()).reduce((a, b) => a + b) /
                neighbors.length;
        final avgB =
            neighbors.map((pixel) => pixel.b.toInt()).reduce((a, b) => a + b) /
                neighbors.length;
        final r =
            (center.r + ((center.r - avgR) * amount)).round().clamp(0, 255);
        final g =
            (center.g + ((center.g - avgG) * amount)).round().clamp(0, 255);
        final b =
            (center.b + ((center.b - avgB) * amount)).round().clamp(0, 255);
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }

  void _applyBloom(img.Image image, double amount) {
    if (amount <= 0.01) {
      return;
    }
    final snapshot =
        img.copyResize(image, width: image.width, height: image.height);
    for (var y = 1; y < image.height - 1; y++) {
      for (var x = 1; x < image.width - 1; x++) {
        final center = snapshot.getPixel(x, y);
        final luminance =
            _luminance(center.r.toInt(), center.g.toInt(), center.b.toInt());
        if (luminance < 0.56) {
          continue;
        }
        var sumR = 0;
        var sumG = 0;
        var sumB = 0;
        for (var oy = -1; oy <= 1; oy++) {
          for (var ox = -1; ox <= 1; ox++) {
            final neighbor = snapshot.getPixel(x + ox, y + oy);
            sumR += neighbor.r.toInt();
            sumG += neighbor.g.toInt();
            sumB += neighbor.b.toInt();
          }
        }
        final r = (center.r +
                ((((sumR / 9) - center.r) * amount) + (255 * amount * 0.1)))
            .round()
            .clamp(0, 255);
        final g = (center.g +
                ((((sumG / 9) - center.g) * amount) + (250 * amount * 0.08)))
            .round()
            .clamp(0, 255);
        final b = (center.b +
                ((((sumB / 9) - center.b) * amount) + (240 * amount * 0.06)))
            .round()
            .clamp(0, 255);
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }

  void _applyGrain(img.Image image, double amount) {
    if (amount <= 0.001) {
      return;
    }
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final noise = (((x * 13) + (y * 17) + ((x * y) % 29)) % 23) - 11;
        final delta = (noise * amount).round();
        image.setPixelRgba(
          x,
          y,
          (pixel.r + delta).round().clamp(0, 255),
          (pixel.g + delta).round().clamp(0, 255),
          (pixel.b + delta).round().clamp(0, 255),
          255,
        );
      }
    }
  }

  int _maskValue(Map<String, dynamic> mask, int x, int y, int imageWidth,
      int imageHeight) {
    final maskWidth = (mask['width'] as num?)?.toInt() ?? imageWidth;
    final maskHeight = (mask['height'] as num?)?.toInt() ?? imageHeight;
    final values = _toBytes(mask['values']);
    if (values.isEmpty || maskWidth == 0 || maskHeight == 0) {
      return 0;
    }
    final sampleX =
        ((x / math.max(1, imageWidth - 1)) * (maskWidth - 1)).round();
    final sampleY =
        ((y / math.max(1, imageHeight - 1)) * (maskHeight - 1)).round();
    final index = (sampleY * maskWidth) + sampleX;
    if (index < 0 || index >= values.length) {
      return 0;
    }
    return values[index];
  }

  bool _isInsideFace(List<Map<String, dynamic>> faces, double x, double y) {
    for (final face in faces) {
      final left = _asDouble(face['left']);
      final top = _asDouble(face['top']);
      final width = _asDouble(face['width']);
      final height = _asDouble(face['height']);
      if (x >= left && x <= left + width && y >= top && y <= top + height) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> _channelDelta(
      double hue, Map<String, dynamic> hslProfile) {
    if (hue < 15 || hue >= 345) {
      return Map<String, dynamic>.from(
          hslProfile['red'] as Map<String, dynamic>? ??
              const <String, dynamic>{});
    }
    if (hue < 45) {
      return Map<String, dynamic>.from(
          hslProfile['orange'] as Map<String, dynamic>? ??
              const <String, dynamic>{});
    }
    if (hue < 70) {
      return Map<String, dynamic>.from(
          hslProfile['yellow'] as Map<String, dynamic>? ??
              const <String, dynamic>{});
    }
    if (hue < 165) {
      return Map<String, dynamic>.from(
          hslProfile['green'] as Map<String, dynamic>? ??
              const <String, dynamic>{});
    }
    if (hue < 200) {
      return Map<String, dynamic>.from(
          hslProfile['aqua'] as Map<String, dynamic>? ??
              const <String, dynamic>{});
    }
    if (hue < 255) {
      return Map<String, dynamic>.from(
          hslProfile['blue'] as Map<String, dynamic>? ??
              const <String, dynamic>{});
    }
    if (hue < 300) {
      return Map<String, dynamic>.from(
          hslProfile['purple'] as Map<String, dynamic>? ??
              const <String, dynamic>{});
    }
    return Map<String, dynamic>.from(
        hslProfile['magenta'] as Map<String, dynamic>? ??
            const <String, dynamic>{});
  }

  List<String> _buildWarnings({
    required Map<String, dynamic> scene,
    required Map<String, dynamic> safetyReport,
    required double compatibility,
  }) {
    final warnings = <String>[];
    if (compatibility < 0.52) {
      warnings.add(
          'Reference and target needed extra adaptation, so style pressure was softened.');
    }
    if (_asDouble(safetyReport['clipRisk']) > 0.18) {
      warnings.add(
          'Highlight guard reduced the brightest regions to preserve realism.');
    }
    if ((scene['faceCount'] as num?)?.toInt() != 0) {
      warnings.add('Face-safe mapping stayed enabled to protect skin tones.');
    }
    return warnings;
  }
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

img.Image _decode(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Unable to decode image bytes.');
  }
  return decoded;
}

Uint8List _toBytes(dynamic value) {
  if (value is Uint8List) {
    return value;
  }
  if (value is List<int>) {
    return Uint8List.fromList(value);
  }
  if (value is List<dynamic>) {
    return Uint8List.fromList(
        value.map((item) => (item as num).toInt()).toList(growable: false));
  }
  return Uint8List(0);
}

int _fastHash(Uint8List bytes) {
  var hash = 17;
  for (final byte in bytes.take(512)) {
    hash = (hash * 31 + byte) & 0x7fffffff;
  }
  return hash;
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

bool _bool(dynamic value, bool fallback) {
  if (value is bool) {
    return value;
  }
  return fallback;
}

double _luminance(num r, num g, num b) {
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

List<int> _hslToRgb(double hue, double saturation, double lightness) {
  final c = (1 - (2 * lightness - 1).abs()) * saturation;
  final x = c * (1 - (((hue / 60) % 2) - 1).abs());
  final m = lightness - (c / 2);
  double rd;
  double gd;
  double bd;
  if (hue < 60) {
    rd = c;
    gd = x;
    bd = 0;
  } else if (hue < 120) {
    rd = x;
    gd = c;
    bd = 0;
  } else if (hue < 180) {
    rd = 0;
    gd = c;
    bd = x;
  } else if (hue < 240) {
    rd = 0;
    gd = x;
    bd = c;
  } else if (hue < 300) {
    rd = x;
    gd = 0;
    bd = c;
  } else {
    rd = c;
    gd = 0;
    bd = x;
  }
  return <int>[
    ((rd + m) * 255).round().clamp(0, 255),
    ((gd + m) * 255).round().clamp(0, 255),
    ((bd + m) * 255).round().clamp(0, 255),
  ];
}

int _curveApply(num value, List<dynamic> rawCurve) {
  final curve = rawCurve
      .map((entry) => (entry as num).toDouble())
      .toList(growable: false);
  final normalized = (value / 255).clamp(0.0, 1.0);
  const anchors = <double>[0, 0.25, 0.5, 0.75, 1.0];
  for (var index = 1; index < anchors.length; index++) {
    if (normalized <= anchors[index]) {
      final leftAnchor = anchors[index - 1];
      final rightAnchor = anchors[index];
      final t = ((normalized - leftAnchor) / (rightAnchor - leftAnchor))
          .clamp(0.0, 1.0);
      final mapped = curve[index - 1] + ((curve[index] - curve[index - 1]) * t);
      return (mapped * 255).round().clamp(0, 255);
    }
  }
  return (curve.isEmpty ? normalized : curve.last * 255).round().clamp(0, 255);
}
