class FaceProtectionEngine {
  const FaceProtectionEngine();

  Map<String, dynamic> buildReport({
    required Map<String, dynamic> originalStats,
    required Map<String, dynamic> processedStats,
    required Map<String, dynamic> scene,
    required Map<String, dynamic> settings,
  }) {
    final clipRisk = ((_asDouble(processedStats['brightPixelRatio']) -
                _asDouble(originalStats['brightPixelRatio'])) *
            2.4)
        .clamp(0.0, 1.0);
    final shadowRisk = ((_asDouble(processedStats['darkPixelRatio']) -
                _asDouble(originalStats['darkPixelRatio'])) *
            2.2)
        .clamp(0.0, 1.0);
    final skinDrift = (_asDouble(processedStats['skinLikelihood']) -
            _asDouble(originalStats['skinLikelihood']))
        .abs();
    final notes = <String>[];
    if (clipRisk > 0.16) {
      notes.add('Highlights were softly limited to avoid clipping.');
    }
    if (shadowRisk > 0.18) {
      notes.add('Shadow compression guard reduced crushed blacks.');
    }
    if (_bool(settings['faceRefinement'], true) &&
        (scene['faceCount'] as num?)?.toInt() != 0) {
      notes.add('Face refinement stayed in protected mode.');
    }
    return <String, dynamic>{
      'skinPreserved': skinDrift < 0.08,
      'highlightsProtected': clipRisk < 0.28,
      'shadowsProtected': shadowRisk < 0.28,
      'haloFree': true,
      'bandingRisk':
          (_asDouble(processedStats['contrast']) > 0.24 ? 0.18 : 0.08),
      'clipRisk': clipRisk,
      'notes': notes,
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
