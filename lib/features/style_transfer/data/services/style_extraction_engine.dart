import 'dart:math' as math;

class StyleExtractionEngine {
  const StyleExtractionEngine();

  Map<String, dynamic> extract({
    required Map<String, dynamic> stats,
    required Map<String, dynamic> scene,
    required String name,
    required String id,
  }) {
    final averageLuminance = _asDouble(stats['averageLuminance']);
    final contrast = _asDouble(stats['contrast']);
    final averageSaturation = _asDouble(stats['averageSaturation']);
    final temperature = _asDouble(stats['temperature']);
    final brightPixelRatio = _asDouble(stats['brightPixelRatio']);
    final darkPixelRatio = _asDouble(stats['darkPixelRatio']);
    final edgeEnergy = _asDouble(stats['edgeEnergy']);
    final skinLikelihood = _asDouble(stats['skinLikelihood']);
    final skyLikelihood = _asDouble(stats['skyLikelihood']);

    final tone = <String, dynamic>{
      'exposure': _clampSigned((averageLuminance - 0.5) * 0.44, 0.24),
      'contrast': _clampSigned((contrast - 0.18) * 1.8, 0.34),
      'highlights': _clampSigned((0.22 - brightPixelRatio) * 0.45, 0.2),
      'shadows': _clampSigned((darkPixelRatio - 0.14) * 0.52, 0.2),
      'blacks': _clampSigned((darkPixelRatio - 0.18) * 0.22, 0.14),
      'whites': _clampSigned((brightPixelRatio - 0.14) * 0.28, 0.16),
      'fade': _clamp01((0.25 - contrast) * 0.8),
    };
    final color = <String, dynamic>{
      'temperature': _clampSigned(temperature * 0.72, 0.24),
      'tint': _clampSigned(temperature * 0.18, 0.16),
      'saturation': _clampSigned((averageSaturation - 0.32) * 0.9, 0.22),
      'vibrance': _clampSigned(
          ((averageSaturation - 0.24) * 0.5) + (edgeEnergy * 0.18), 0.34),
      'palette': stats['palette'] as List<dynamic>? ?? const <dynamic>[],
    };
    final detail = <String, dynamic>{
      'sharpness': _clamp01(edgeEnergy * 1.2),
      'clarity': _clamp01((edgeEnergy * 1.4) + (contrast * 0.4)),
      'texture': _clamp01((contrast * 1.3) + (edgeEnergy * 0.5)),
      'grain': _clamp01((darkPixelRatio - 0.10) * 0.5),
      'vignette': _clamp01(darkPixelRatio * 0.7),
      'bloom': _clamp01(brightPixelRatio * 0.9),
    };

    return <String, dynamic>{
      'id': id,
      'name': name,
      'confidence': (0.58 + (contrast * 0.45) + (averageSaturation * 0.12))
          .clamp(0.0, 0.99),
      'sceneType': scene['sceneType']?.toString() ?? 'editorial',
      'tone': tone,
      'color': color,
      'hsl': _buildHslProfile(
        palette: color['palette'] as List<dynamic>,
        temperature: _asDouble(color['temperature']),
        saturation: _asDouble(color['saturation']),
      ),
      'curves': _buildCurveProfile(tone: tone, color: color),
      'detail': detail,
      'local': <String, dynamic>{
        'skinProtect': skinLikelihood > 0.025,
        'faceExposureGuard': (scene['faceCount'] as num?)?.toInt() != 0,
        'skyAdjust': skyLikelihood > 0.04,
        'backgroundAdjust': true,
      },
    };
  }

  Map<String, dynamic> _buildHslProfile({
    required List<dynamic> palette,
    required double temperature,
    required double saturation,
  }) {
    final avgHue = palette.isEmpty
        ? 210.0
        : palette
                .map((value) => _argbToHue((value as num).toInt()))
                .reduce((a, b) => a + b) /
            palette.length;
    final coolBias = avgHue > 180 ? 1.0 : -1.0;
    return <String, dynamic>{
      'red': <String, dynamic>{'h': 0, 's': saturation * 0.04, 'l': 0},
      'orange': <String, dynamic>{
        'h': temperature * 4,
        's': saturation * 0.09,
        'l': temperature * 0.02
      },
      'yellow': <String, dynamic>{
        'h': temperature * 3,
        's': saturation * 0.04,
        'l': 0.01
      },
      'green': <String, dynamic>{'h': 0, 's': -0.03, 'l': 0},
      'aqua': <String, dynamic>{
        'h': coolBias * -2,
        's': saturation * 0.03,
        'l': 0.01
      },
      'blue': <String, dynamic>{
        'h': temperature * -5,
        's': saturation * 0.08,
        'l': coolBias * 0.02
      },
      'purple': <String, dynamic>{
        'h': coolBias * -2,
        's': saturation * 0.04,
        'l': 0
      },
      'magenta': <String, dynamic>{
        'h': temperature * 2,
        's': saturation * 0.05,
        'l': 0.01
      },
    };
  }

  Map<String, dynamic> _buildCurveProfile({
    required Map<String, dynamic> tone,
    required Map<String, dynamic> color,
  }) {
    final exposure = _asDouble(tone['exposure']);
    final contrast = _asDouble(tone['contrast']);
    final highlights = _asDouble(tone['highlights']);
    final whites = _asDouble(tone['whites']);
    final shadows = _asDouble(tone['shadows']);
    final fade = _asDouble(tone['fade']);
    final temperature = _asDouble(color['temperature']);
    final tint = _asDouble(color['tint']);
    final master = <double>[
      0,
      _clamp01(0.25 + (shadows * 0.16) - (fade * 0.08)),
      _clamp01(0.5 + (exposure * 0.2) + (contrast * 0.06)),
      _clamp01(0.75 + (highlights * 0.08) + (whites * 0.06)),
      1,
    ];
    return <String, dynamic>{
      'master': master,
      'red': <double>[
        0,
        _clamp01(master[1] + (temperature * 0.05)),
        _clamp01(master[2] + (temperature * 0.08)),
        _clamp01(master[3] + (temperature * 0.04)),
        1
      ],
      'green': <double>[
        0,
        _clamp01(master[1] + (tint * 0.04)),
        master[2],
        _clamp01(master[3] + (tint * 0.04)),
        1
      ],
      'blue': <double>[
        0,
        _clamp01(master[1] - (temperature * 0.05)),
        _clamp01(master[2] - (temperature * 0.08)),
        _clamp01(master[3] - (temperature * 0.04)),
        1
      ],
    };
  }
}

double _argbToHue(int argb) {
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  final rd = r / 255.0;
  final gd = g / 255.0;
  final bd = b / 255.0;
  final maxValue = math.max(rd, math.max(gd, bd));
  final minValue = math.min(rd, math.min(gd, bd));
  final delta = maxValue - minValue;
  if (delta == 0) {
    return 0;
  }
  double hue;
  if (maxValue == rd) {
    hue = 60 * (((gd - bd) / delta) % 6);
  } else if (maxValue == gd) {
    hue = 60 * (((bd - rd) / delta) + 2);
  } else {
    hue = 60 * (((rd - gd) / delta) + 4);
  }
  if (hue < 0) {
    hue += 360;
  }
  return hue;
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

double _clampSigned(double value, double limit) {
  return value.clamp(-limit, limit).toDouble();
}

double _clamp01(double value) {
  return value.clamp(0.0, 1.0).toDouble();
}
