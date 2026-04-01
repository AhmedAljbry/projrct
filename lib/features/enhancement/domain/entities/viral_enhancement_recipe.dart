class ViralEnhancementRecipe {
  const ViralEnhancementRecipe({
    required this.bloomStrength,
    required this.microContrast,
    required this.glow,
    required this.depthLift,
    required this.faceLift,
    required this.highlightRollOff,
    required this.colorPop,
    required this.toneCurveStrength,
    required this.vignette,
  });

  final double bloomStrength;
  final double microContrast;
  final double glow;
  final double depthLift;
  final double faceLift;
  final double highlightRollOff;
  final double colorPop;
  final double toneCurveStrength;
  final double vignette;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bloomStrength': bloomStrength,
      'microContrast': microContrast,
      'glow': glow,
      'depthLift': depthLift,
      'faceLift': faceLift,
      'highlightRollOff': highlightRollOff,
      'colorPop': colorPop,
      'toneCurveStrength': toneCurveStrength,
      'vignette': vignette,
    };
  }

  factory ViralEnhancementRecipe.fromMap(Map<String, dynamic> map) {
    return ViralEnhancementRecipe(
      bloomStrength: _asDouble(map['bloomStrength']),
      microContrast: _asDouble(map['microContrast']),
      glow: _asDouble(map['glow']),
      depthLift: _asDouble(map['depthLift']),
      faceLift: _asDouble(map['faceLift']),
      highlightRollOff: _asDouble(map['highlightRollOff']),
      colorPop: _asDouble(map['colorPop']),
      toneCurveStrength: _asDouble(map['toneCurveStrength']),
      vignette: _asDouble(map['vignette']),
    );
  }
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}
