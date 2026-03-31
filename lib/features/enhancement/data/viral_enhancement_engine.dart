class ViralEnhancementEngine {
  const ViralEnhancementEngine();

  Map<String, dynamic> build({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> scene,
    required Map<String, dynamic> settings,
  }) {
    final detail =
        Map<String, dynamic>.from(profile['detail'] as Map<String, dynamic>);
    final bloom = (_asDouble(detail['bloom']) +
            (_bool(settings['cinematicGlow'], true)
                ? _asDouble(settings['glowBoost']) * 0.3
                : 0))
        .clamp(0.0, 1.0);
    final clarity = _asDouble(detail['clarity']);
    final depthLift = (_bool(settings['depthIllusion'], true) ? 0.18 : 0.05) +
        (_asDouble(detail['vignette']) * 0.2);
    final faceLift = (_bool(settings['faceRefinement'], true) &&
            (scene['faceCount'] as num?)?.toInt() != 0)
        ? 0.14
        : 0.04;
    return <String, dynamic>{
      'bloomStrength': bloom,
      'microContrast': (clarity * 0.8).clamp(0.0, 1.0),
      'glow': (_asDouble(settings['glowBoost']) * 0.8).clamp(0.0, 1.0),
      'depthLift': depthLift.clamp(0.0, 1.0),
      'faceLift': faceLift,
      'vignette': (_asDouble(detail['vignette']) * 0.85).clamp(0.0, 1.0),
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
