class AdaptiveMappingEngine {
  const AdaptiveMappingEngine();

  Map<String, dynamic> mapProfile({
    required Map<String, dynamic> sourceProfile,
    required Map<String, dynamic> targetStats,
    required Map<String, dynamic> scene,
    required Map<String, dynamic> settings,
  }) {
    final compatibility = _computeCompatibility(
      sourceProfile: sourceProfile,
      targetStats: targetStats,
      scene: scene,
    );
    final requestedStrength = _asDouble(settings['strength'], 0.82);
    var appliedStrength = requestedStrength * (0.72 + (compatibility * 0.3));
    if ((scene['faceCount'] as num?)?.toInt() != 0) {
      appliedStrength -= 0.06;
    }
    appliedStrength = appliedStrength.clamp(0.26, 0.96);

    final tone = Map<String, dynamic>.from(
        sourceProfile['tone'] as Map<String, dynamic>);
    final color = Map<String, dynamic>.from(
        sourceProfile['color'] as Map<String, dynamic>);
    final detail = Map<String, dynamic>.from(
        sourceProfile['detail'] as Map<String, dynamic>);
    final toneAdjustment = Map<String, dynamic>.from(
      settings['toneAdjustment'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );
    final detailAdjustment = Map<String, dynamic>.from(
      settings['detailAdjustment'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );
    final localOverrides = Map<String, dynamic>.from(
      settings['localOverrides'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

    final toneMix =
        (scene['sceneType'] == sourceProfile['sceneType']) ? 1.0 : 0.84;
    tone['exposure'] = _clampSigned(
      ((_asDouble(tone['exposure']) * appliedStrength * toneMix) +
              ((0.5 - _asDouble(targetStats['averageLuminance'])) * 0.16) +
              _asDouble(toneAdjustment['exposure'])) *
          (_bool(settings['exposureLock'], true) ? 0.78 : 1.0),
      0.34,
    );
    tone['contrast'] = _clampSigned(
      ((_asDouble(tone['contrast']) * appliedStrength * toneMix) +
          ((0.22 - _asDouble(targetStats['contrast'])) * 0.22) +
          _asDouble(toneAdjustment['contrast'])),
      0.38,
    );
    tone['highlights'] = _clampSigned(
      (_asDouble(tone['highlights']) * appliedStrength) +
          _asDouble(toneAdjustment['highlights']),
      0.22,
    );
    tone['shadows'] = _clampSigned(
      (_asDouble(tone['shadows']) * appliedStrength) +
          _asDouble(toneAdjustment['shadows']),
      0.24,
    );
    tone['blacks'] = _clampSigned(
      (_asDouble(tone['blacks']) * appliedStrength) +
          _asDouble(toneAdjustment['blacks']),
      0.16,
    );
    tone['whites'] = _clampSigned(
      (_asDouble(tone['whites']) * appliedStrength) +
          _asDouble(toneAdjustment['whites']),
      0.18,
    );
    tone['fade'] = ((_asDouble(tone['fade']) * (0.7 + appliedStrength * 0.22)) +
            _asDouble(toneAdjustment['fade']))
        .clamp(0.0, 1.0);

    color['temperature'] = _clampSigned(
      ((_asDouble(color['temperature']) * appliedStrength) -
          (_asDouble(scene['warmth']) * 0.08)),
      0.24,
    );
    color['tint'] =
        _clampSigned(_asDouble(color['tint']) * appliedStrength, 0.16);
    color['saturation'] = _clampSigned(
      ((_asDouble(color['saturation']) * appliedStrength) +
          ((0.34 - _asDouble(targetStats['averageSaturation'])) * 0.14)),
      0.24,
    );
    color['vibrance'] = _clampSigned(
      (_asDouble(color['vibrance']) * (0.64 + (compatibility * 0.24))) +
          (_asDouble(settings['glowBoost']) * 0.05),
      0.36,
    );

    detail['sharpness'] = _clamp01(
      (_asDouble(detail['sharpness']) * (0.72 + appliedStrength * 0.2)) +
          _asDouble(detailAdjustment['sharpness']) +
          (_asDouble(settings['detailBoost']) * 0.08),
    );
    detail['clarity'] = _clamp01(
      (_asDouble(detail['clarity']) * (0.62 + compatibility * 0.28)) +
          _asDouble(detailAdjustment['clarity']),
    );
    detail['texture'] = _clamp01(
      (_asDouble(detail['texture']) * (0.6 + appliedStrength * 0.24)) +
          _asDouble(detailAdjustment['texture']),
    );
    detail['grain'] = _clamp01(
        _asDouble(detail['grain']) + _asDouble(detailAdjustment['grain']));
    detail['vignette'] = _clamp01(
      (_asDouble(detail['vignette']) *
              (_bool(settings['depthIllusion'], true) ? 1.0 : 0.6)) +
          _asDouble(detailAdjustment['vignette']),
    );
    detail['bloom'] = _clamp01(
      (_asDouble(detail['bloom']) +
              (_bool(settings['cinematicGlow'], true)
                  ? _asDouble(settings['glowBoost']) * 0.22
                  : 0)) +
          _asDouble(detailAdjustment['bloom']),
    );

    final mappedCurves = _mergeCurves(
      Map<String, dynamic>.from(
          sourceProfile['curves'] as Map<String, dynamic>),
      Map<String, dynamic>.from(
          settings['curveAdjustment'] as Map<String, dynamic>? ??
              const <String, dynamic>{}),
      appliedStrength,
    );
    final mappedHsl = _mergeHsl(
      Map<String, dynamic>.from(sourceProfile['hsl'] as Map<String, dynamic>),
      Map<String, dynamic>.from(
          settings['hslAdjustment'] as Map<String, dynamic>? ??
              const <String, dynamic>{}),
      appliedStrength,
    );

    return <String, dynamic>{
      'profile': <String, dynamic>{
        ...sourceProfile,
        'confidence': compatibility,
        'tone': tone,
        'color': color,
        'detail': detail,
        'curves': mappedCurves,
        'hsl': mappedHsl,
        'local': <String, dynamic>{
          ...(sourceProfile['local'] as Map<String, dynamic>? ??
              const <String, dynamic>{}),
          ...localOverrides,
        },
      },
      'compatibility': compatibility,
      'appliedStrength': appliedStrength,
      'viralScore': (0.58 +
              (appliedStrength * 0.22) +
              (_asDouble(detail['bloom']) * 0.12) +
              (_asDouble(detail['clarity']) * 0.08))
          .clamp(0.0, 0.99),
    };
  }

  double _computeCompatibility({
    required Map<String, dynamic> sourceProfile,
    required Map<String, dynamic> targetStats,
    required Map<String, dynamic> scene,
  }) {
    var score = 0.44;
    if (sourceProfile['sceneType'] == scene['sceneType']) {
      score += 0.22;
    } else if (sourceProfile['sceneType'] == 'portrait' &&
        (scene['faceCount'] as num?)?.toInt() != 0) {
      score += 0.12;
    } else if (sourceProfile['sceneType'] == 'landscape' &&
        _bool(scene['hasSky'], false)) {
      score += 0.12;
    }
    final sourceTone = Map<String, dynamic>.from(
        sourceProfile['tone'] as Map<String, dynamic>);
    final sourceColor = Map<String, dynamic>.from(
        sourceProfile['color'] as Map<String, dynamic>);
    final brightnessAffinity = 1 -
        (_asDouble(sourceTone['exposure']) -
                ((_asDouble(targetStats['averageLuminance']) - 0.5) * 0.6))
            .abs();
    final contrastAffinity = 1 -
        (_asDouble(sourceTone['contrast']) -
                ((_asDouble(targetStats['contrast']) - 0.2) * 1.8))
            .abs();
    final saturationAffinity = 1 -
        (_asDouble(sourceColor['saturation']) -
                ((_asDouble(targetStats['averageSaturation']) - 0.32) * 1.2))
            .abs();
    score += _clamp01(brightnessAffinity) * 0.1;
    score += _clamp01(contrastAffinity) * 0.12;
    score += _clamp01(saturationAffinity) * 0.12;
    return score.clamp(0.0, 0.99);
  }

  Map<String, dynamic> _mergeCurves(
    Map<String, dynamic> base,
    Map<String, dynamic> delta,
    double strength,
  ) {
    List<double> merge(String key) {
      final baseCurve = (base[key] as List<dynamic>? ??
              const <dynamic>[0, 0.25, 0.5, 0.75, 1])
          .map((value) => (value as num).toDouble())
          .toList(growable: false);
      final deltaCurve = (delta[key] as List<dynamic>? ??
              List<dynamic>.filled(baseCurve.length, 0))
          .map((value) => (value as num).toDouble())
          .toList(growable: false);
      return List<double>.generate(baseCurve.length, (index) {
        final deltaValue = index < deltaCurve.length ? deltaCurve[index] : 0;
        return (baseCurve[index] + (deltaValue * strength * 0.35))
            .clamp(0.0, 1.0)
            .toDouble();
      });
    }

    return <String, dynamic>{
      'master': merge('master'),
      'red': merge('red'),
      'green': merge('green'),
      'blue': merge('blue'),
    };
  }

  Map<String, dynamic> _mergeHsl(
    Map<String, dynamic> base,
    Map<String, dynamic> delta,
    double strength,
  ) {
    Map<String, dynamic> mergeChannel(String key) {
      final baseChannel = Map<String, dynamic>.from(
          base[key] as Map<String, dynamic>? ?? const <String, dynamic>{});
      final deltaChannel = Map<String, dynamic>.from(
          delta[key] as Map<String, dynamic>? ?? const <String, dynamic>{});
      return <String, dynamic>{
        'h': _asDouble(baseChannel['h']) +
            (_asDouble(deltaChannel['h']) * strength),
        's': _asDouble(baseChannel['s']) +
            (_asDouble(deltaChannel['s']) * strength),
        'l': _asDouble(baseChannel['l']) +
            (_asDouble(deltaChannel['l']) * strength),
      };
    }

    return <String, dynamic>{
      'red': mergeChannel('red'),
      'orange': mergeChannel('orange'),
      'yellow': mergeChannel('yellow'),
      'green': mergeChannel('green'),
      'aqua': mergeChannel('aqua'),
      'blue': mergeChannel('blue'),
      'purple': mergeChannel('purple'),
      'magenta': mergeChannel('magenta'),
    };
  }
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

double _clampSigned(double value, double limit) {
  return value.clamp(-limit, limit).toDouble();
}

double _clamp01(double value) {
  return value.clamp(0.0, 1.0).toDouble();
}
