class ToneProfile {
  const ToneProfile({
    required this.exposure,
    required this.contrast,
    required this.highlights,
    required this.shadows,
    required this.blacks,
    required this.whites,
    required this.fade,
  });

  const ToneProfile.neutral()
      : exposure = 0,
        contrast = 0,
        highlights = 0,
        shadows = 0,
        blacks = 0,
        whites = 0,
        fade = 0;

  final double exposure;
  final double contrast;
  final double highlights;
  final double shadows;
  final double blacks;
  final double whites;
  final double fade;

  ToneProfile copyWith({
    double? exposure,
    double? contrast,
    double? highlights,
    double? shadows,
    double? blacks,
    double? whites,
    double? fade,
  }) {
    return ToneProfile(
      exposure: exposure ?? this.exposure,
      contrast: contrast ?? this.contrast,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      blacks: blacks ?? this.blacks,
      whites: whites ?? this.whites,
      fade: fade ?? this.fade,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'exposure': exposure,
      'contrast': contrast,
      'highlights': highlights,
      'shadows': shadows,
      'blacks': blacks,
      'whites': whites,
      'fade': fade,
    };
  }

  factory ToneProfile.fromMap(Map<String, dynamic> map) {
    return ToneProfile(
      exposure: _asDouble(map['exposure']),
      contrast: _asDouble(map['contrast']),
      highlights: _asDouble(map['highlights']),
      shadows: _asDouble(map['shadows']),
      blacks: _asDouble(map['blacks']),
      whites: _asDouble(map['whites']),
      fade: _asDouble(map['fade']),
    );
  }
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}
