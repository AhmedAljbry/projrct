class StyleSafetyReport {
  const StyleSafetyReport({
    required this.skinPreserved,
    required this.highlightsProtected,
    required this.shadowsProtected,
    required this.haloFree,
    required this.bandingRisk,
    required this.clipRisk,
    required this.notes,
  });

  final bool skinPreserved;
  final bool highlightsProtected;
  final bool shadowsProtected;
  final bool haloFree;
  final double bandingRisk;
  final double clipRisk;
  final List<String> notes;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'skinPreserved': skinPreserved,
      'highlightsProtected': highlightsProtected,
      'shadowsProtected': shadowsProtected,
      'haloFree': haloFree,
      'bandingRisk': bandingRisk,
      'clipRisk': clipRisk,
      'notes': notes,
    };
  }

  factory StyleSafetyReport.fromMap(Map<String, dynamic> map) {
    return StyleSafetyReport(
      skinPreserved: map['skinPreserved'] as bool? ?? true,
      highlightsProtected: map['highlightsProtected'] as bool? ?? true,
      shadowsProtected: map['shadowsProtected'] as bool? ?? true,
      haloFree: map['haloFree'] as bool? ?? true,
      bandingRisk: _asDouble(map['bandingRisk']),
      clipRisk: _asDouble(map['clipRisk']),
      notes: (map['notes'] as List<dynamic>? ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(growable: false),
    );
  }
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}
