// Core type system for the unified creative engine (scene routing, masks, pipeline).

enum SceneKind {
  portrait,
  wildlife,
  landscape,
  product,
  night,
  architecture,
  general,
}

enum SmartMaskKind {
  none,
  face,
  sky,
  subject,
  vegetation,
  materials,
  facade,
}

enum RegionLabel {
  face,
  background,
  sky,
  subject,
  facade,
  vegetation,
  windows,
  interiorPlanes,
}

/// Tunable pipeline state (merged layers: pack + user + scene routing).
class StyleTransferParams {
  final double exposure; // ~ -0.12 .. 0.12 effective EV slice
  final double contrast;
  final double saturation;
  final double vibrance;
  final double highlightRoll;
  final double shadowLift;
  final double warmth;
  final double globalHue;
  final double detailRecovery;
  final double textureProtection;
  final double neutralProtection;
  final double skinProtection;
  final double edgePreservation;

  const StyleTransferParams({
    this.exposure = 0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.vibrance = 0.25,
    this.highlightRoll = 0.35,
    this.shadowLift = 0,
    this.warmth = 0,
    this.globalHue = 0,
    this.detailRecovery = 0.18,
    this.textureProtection = 0.55,
    this.neutralProtection = 0.45,
    this.skinProtection = 0.62,
    this.edgePreservation = 0.5,
  });

  StyleTransferParams copyWith({
    double? exposure,
    double? contrast,
    double? saturation,
    double? vibrance,
    double? highlightRoll,
    double? shadowLift,
    double? warmth,
    double? globalHue,
    double? detailRecovery,
    double? textureProtection,
    double? neutralProtection,
    double? skinProtection,
    double? edgePreservation,
  }) =>
      StyleTransferParams(
        exposure: exposure ?? this.exposure,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
        vibrance: vibrance ?? this.vibrance,
        highlightRoll: highlightRoll ?? this.highlightRoll,
        shadowLift: shadowLift ?? this.shadowLift,
        warmth: warmth ?? this.warmth,
        globalHue: globalHue ?? this.globalHue,
        detailRecovery: detailRecovery ?? this.detailRecovery,
        textureProtection: textureProtection ?? this.textureProtection,
        neutralProtection: neutralProtection ?? this.neutralProtection,
        skinProtection: skinProtection ?? this.skinProtection,
        edgePreservation: edgePreservation ?? this.edgePreservation,
      );

  static StyleTransferParams weightedMean(
    List<StyleTransferParams> ps,
    List<double> w,
  ) {
    if (ps.isEmpty) return const StyleTransferParams();
    var tw = 0.0;
    for (var i = 0; i < ps.length && i < w.length; i++) {
      tw += w[i].clamp(0.0, 1.0);
    }
    if (tw < 1e-9) return mean(ps);
    double wavg(double Function(StyleTransferParams p) f) {
      var s = 0.0;
      for (var i = 0; i < ps.length && i < w.length; i++) {
        s += f(ps[i]) * w[i];
      }
      return s / tw;
    }

    return StyleTransferParams(
      exposure: wavg((p) => p.exposure),
      contrast: wavg((p) => p.contrast),
      saturation: wavg((p) => p.saturation),
      vibrance: wavg((p) => p.vibrance),
      highlightRoll: wavg((p) => p.highlightRoll),
      shadowLift: wavg((p) => p.shadowLift),
      warmth: wavg((p) => p.warmth),
      globalHue: wavg((p) => p.globalHue),
      detailRecovery: wavg((p) => p.detailRecovery),
      textureProtection: wavg((p) => p.textureProtection),
      neutralProtection: wavg((p) => p.neutralProtection),
      skinProtection: wavg((p) => p.skinProtection),
      edgePreservation: wavg((p) => p.edgePreservation),
    );
  }

  static StyleTransferParams mean(List<StyleTransferParams> ps) {
    if (ps.isEmpty) return const StyleTransferParams();
    double a(double Function(StyleTransferParams p) f) =>
        ps.map(f).reduce((x, y) => x + y) / ps.length;
    return StyleTransferParams(
      exposure: a((p) => p.exposure),
      contrast: a((p) => p.contrast),
      saturation: a((p) => p.saturation),
      vibrance: a((p) => p.vibrance),
      highlightRoll: a((p) => p.highlightRoll),
      shadowLift: a((p) => p.shadowLift),
      warmth: a((p) => p.warmth),
      globalHue: a((p) => p.globalHue),
      detailRecovery: a((p) => p.detailRecovery),
      textureProtection: a((p) => p.textureProtection),
      neutralProtection: a((p) => p.neutralProtection),
      skinProtection: a((p) => p.skinProtection),
      edgePreservation: a((p) => p.edgePreservation),
    );
  }

  /// Component-wise lerp (t in 0..1 towards [b]).
  StyleTransferParams lerpTowards(StyleTransferParams b, double t) {
    double u(double x, double y) => x + (y - x) * t;
    return StyleTransferParams(
      exposure: u(exposure, b.exposure),
      contrast: u(contrast, b.contrast),
      saturation: u(saturation, b.saturation),
      vibrance: u(vibrance, b.vibrance),
      highlightRoll: u(highlightRoll, b.highlightRoll),
      shadowLift: u(shadowLift, b.shadowLift),
      warmth: u(warmth, b.warmth),
      globalHue: u(globalHue, b.globalHue),
      detailRecovery: u(detailRecovery, b.detailRecovery),
      textureProtection: u(textureProtection, b.textureProtection),
      neutralProtection: u(neutralProtection, b.neutralProtection),
      skinProtection: u(skinProtection, b.skinProtection),
      edgePreservation: u(edgePreservation, b.edgePreservation),
    );
  }
}

class SceneAnalysis {
  final SceneKind kind;
  final double confidence;
  final double meanLuma;
  final double colorVariance;
  final double skyScore;
  final double skinScore;
  final double greenScore;
  final double edgeDensity;
  final double nightScore;

  const SceneAnalysis({
    required this.kind,
    required this.confidence,
    required this.meanLuma,
    required this.colorVariance,
    required this.skyScore,
    required this.skinScore,
    required this.greenScore,
    required this.edgeDensity,
    required this.nightScore,
  });
}

class SceneRoutingWeights {
  final double maxSaturation;
  final double highlightProtection;
  final double shadowNoiseGuard;
  final double greenControl;
  final double skinLumaPreserve;
  final double architectNeutralBias;

  const SceneRoutingWeights({
    required this.maxSaturation,
    required this.highlightProtection,
    required this.shadowNoiseGuard,
    required this.greenControl,
    required this.skinLumaPreserve,
    required this.architectNeutralBias,
  });

  static SceneRoutingWeights forScene(SceneKind k) {
    switch (k) {
      case SceneKind.portrait:
        return const SceneRoutingWeights(
          maxSaturation: 1.12,
          highlightProtection: 0.72,
          shadowNoiseGuard: 0.35,
          greenControl: 0.85,
          skinLumaPreserve: 0.88,
          architectNeutralBias: 0.2,
        );
      case SceneKind.wildlife:
        return const SceneRoutingWeights(
          maxSaturation: 1.22,
          highlightProtection: 0.55,
          shadowNoiseGuard: 0.28,
          greenControl: 0.9,
          skinLumaPreserve: 0.35,
          architectNeutralBias: 0.15,
        );
      case SceneKind.landscape:
        return const SceneRoutingWeights(
          maxSaturation: 1.18,
          highlightProtection: 0.62,
          shadowNoiseGuard: 0.32,
          greenControl: 0.75,
          skinLumaPreserve: 0.45,
          architectNeutralBias: 0.18,
        );
      case SceneKind.product:
        return const SceneRoutingWeights(
          maxSaturation: 1.06,
          highlightProtection: 0.68,
          shadowNoiseGuard: 0.38,
          greenControl: 0.9,
          skinLumaPreserve: 0.4,
          architectNeutralBias: 0.35,
        );
      case SceneKind.night:
        return const SceneRoutingWeights(
          maxSaturation: 0.95,
          highlightProtection: 0.82,
          shadowNoiseGuard: 0.55,
          greenControl: 0.95,
          skinLumaPreserve: 0.55,
          architectNeutralBias: 0.2,
        );
      case SceneKind.architecture:
        return const SceneRoutingWeights(
          maxSaturation: 1.05,
          highlightProtection: 0.7,
          shadowNoiseGuard: 0.4,
          greenControl: 0.88,
          skinLumaPreserve: 0.35,
          architectNeutralBias: 0.72,
        );
      case SceneKind.general:
        return const SceneRoutingWeights(
          maxSaturation: 1.12,
          highlightProtection: 0.65,
          shadowNoiseGuard: 0.35,
          greenControl: 0.9,
          skinLumaPreserve: 0.5,
          architectNeutralBias: 0.3,
        );
    }
  }
}
