class LocalRules {
  const LocalRules({
    required this.skinProtect,
    required this.faceExposureGuard,
    required this.skyAdjust,
    required this.backgroundAdjust,
  });

  const LocalRules.enabled()
      : skinProtect = true,
        faceExposureGuard = true,
        skyAdjust = true,
        backgroundAdjust = true;

  final bool skinProtect;
  final bool faceExposureGuard;
  final bool skyAdjust;
  final bool backgroundAdjust;

  LocalRules copyWith({
    bool? skinProtect,
    bool? faceExposureGuard,
    bool? skyAdjust,
    bool? backgroundAdjust,
  }) {
    return LocalRules(
      skinProtect: skinProtect ?? this.skinProtect,
      faceExposureGuard: faceExposureGuard ?? this.faceExposureGuard,
      skyAdjust: skyAdjust ?? this.skyAdjust,
      backgroundAdjust: backgroundAdjust ?? this.backgroundAdjust,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'skinProtect': skinProtect,
      'faceExposureGuard': faceExposureGuard,
      'skyAdjust': skyAdjust,
      'backgroundAdjust': backgroundAdjust,
    };
  }

  factory LocalRules.fromMap(Map<String, dynamic> map) {
    return LocalRules(
      skinProtect: map['skinProtect'] as bool? ?? true,
      faceExposureGuard: map['faceExposureGuard'] as bool? ?? true,
      skyAdjust: map['skyAdjust'] as bool? ?? true,
      backgroundAdjust: map['backgroundAdjust'] as bool? ?? true,
    );
  }
}
