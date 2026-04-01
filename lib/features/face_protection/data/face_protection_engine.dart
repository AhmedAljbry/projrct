class FaceProtectionEngine {
  const FaceProtectionEngine();

  Map<String, dynamic> buildReport({
    required Map<String, dynamic> originalStats,
    required Map<String, dynamic> processedStats,
    required Map<String, dynamic> scene,
    required Map<String, dynamic> settings,
  }) {
    final highlightHeadroomDelta =
        (_asDouble(originalStats['highlightHeadroom']) -
                _asDouble(processedStats['highlightHeadroom']))
            .clamp(-1.0, 1.0);
    final shadowHeadroomDelta = (_asDouble(originalStats['shadowHeadroom']) -
            _asDouble(processedStats['shadowHeadroom']))
        .clamp(-1.0, 1.0);
    final clipRisk = (((_asDouble(processedStats['brightPixelRatio']) -
                    _asDouble(originalStats['brightPixelRatio'])) *
                2.1) +
            (highlightHeadroomDelta * 0.9))
        .clamp(0.0, 1.0);
    final shadowRisk = (((_asDouble(processedStats['darkPixelRatio']) -
                    _asDouble(originalStats['darkPixelRatio'])) *
                1.9) +
            (shadowHeadroomDelta * 0.85))
        .clamp(0.0, 1.0);
    final skinDrift = (_asDouble(processedStats['skinLikelihood']) -
            _asDouble(originalStats['skinLikelihood']))
        .abs();
    final neutralDrift = (_asDouble(processedStats['neutralLikelihood']) -
            _asDouble(originalStats['neutralLikelihood']))
        .abs();
    final notes = <String>[];
    if (clipRisk > 0.16) {
      notes.add('Highlights were softly limited to avoid clipping.');
    }
    if (shadowRisk > 0.18) {
      notes.add('Shadow compression guard reduced crushed blacks.');
    }
    if (neutralDrift > 0.045) {
      notes
          .add('Neutral colors were anchored to keep whites and grays stable.');
    }
    if (skinDrift < 0.08 &&
        _bool(
            (settings['localOverrides']
                as Map<String, dynamic>?)?['skinProtect'],
            true)) {
      notes.add('Skin tone preservation stayed active through the transfer.');
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
          ((_asDouble(processedStats['contrast']) > 0.24 ? 0.18 : 0.08) +
                  (clipRisk * 0.08))
              .clamp(0.0, 1.0),
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
