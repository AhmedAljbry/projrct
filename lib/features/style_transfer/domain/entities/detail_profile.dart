class DetailProfile {
  const DetailProfile({
    required this.sharpness,
    required this.clarity,
    required this.texture,
    required this.grain,
    required this.vignette,
    required this.bloom,
  });

  const DetailProfile.neutral()
      : sharpness = 0,
        clarity = 0,
        texture = 0,
        grain = 0,
        vignette = 0,
        bloom = 0;

  final double sharpness;
  final double clarity;
  final double texture;
  final double grain;
  final double vignette;
  final double bloom;

  DetailProfile copyWith({
    double? sharpness,
    double? clarity,
    double? texture,
    double? grain,
    double? vignette,
    double? bloom,
  }) {
    return DetailProfile(
      sharpness: sharpness ?? this.sharpness,
      clarity: clarity ?? this.clarity,
      texture: texture ?? this.texture,
      grain: grain ?? this.grain,
      vignette: vignette ?? this.vignette,
      bloom: bloom ?? this.bloom,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sharpness': sharpness,
      'clarity': clarity,
      'texture': texture,
      'grain': grain,
      'vignette': vignette,
      'bloom': bloom,
    };
  }

  factory DetailProfile.fromMap(Map<String, dynamic> map) {
    return DetailProfile(
      sharpness: _asDouble(map['sharpness']),
      clarity: _asDouble(map['clarity']),
      texture: _asDouble(map['texture']),
      grain: _asDouble(map['grain']),
      vignette: _asDouble(map['vignette']),
      bloom: _asDouble(map['bloom']),
    );
  }
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}
