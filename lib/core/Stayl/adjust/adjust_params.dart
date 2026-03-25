import 'package:flutter/foundation.dart';

@immutable
class AdjustParams {
  final double exposure;      // -1..1 (preview: mapped to brightness)
  final double contrast;      // 0.5..1.5
  final double saturation;    // 0..2
  final double vibrance;      // -1..1 (preview: placeholder)
  final double brightness;    // -0.5..0.5
  final double warmth;        // -1..1 (preview: applied)
  final double tint;          // -1..1 (preview: placeholder)
  final double highlights;    // -1..1 (preview: placeholder)
  final double shadows;       // -1..1 (preview: placeholder)
  final double clarity;       // -1..1 (preview: placeholder)
  final double dehaze;        // -1..1 (preview: placeholder)
  final double gamma;         // 0.5..1.5 (preview: placeholder)
  final double fade;          // 0..1 (preview: placeholder)
  final double vignette;      // 0..1 (preview: placeholder)
  final double vignetteSize;  // 0..1 (preview: placeholder)
  final double sharpen;       // 0..1 (preview: placeholder)
  final double grain;         // 0..1 (preview: placeholder)
  final bool removeBg;        // hook for your segmentation pipeline
  final bool portraitBlur;    // placeholder hook

  const AdjustParams({
    required this.exposure,
    required this.contrast,
    required this.saturation,
    required this.vibrance,
    required this.brightness,
    required this.warmth,
    required this.tint,
    required this.highlights,
    required this.shadows,
    required this.clarity,
    required this.dehaze,
    required this.gamma,
    required this.fade,
    required this.vignette,
    required this.vignetteSize,
    required this.sharpen,
    required this.grain,
    required this.removeBg,
    required this.portraitBlur,
  });

  static const defaults = AdjustParams(
    exposure: 0.0,
    contrast: 1.0,
    saturation: 1.0,
    vibrance: 0.0,
    brightness: 0.0,
    warmth: 0.0,
    tint: 0.0,
    highlights: 0.0,
    shadows: 0.0,
    clarity: 0.0,
    dehaze: 0.0,
    gamma: 1.0,
    fade: 0.0,
    vignette: 0.0,
    vignetteSize: 0.5,
    sharpen: 0.0,
    grain: 0.0,
    removeBg: false,
    portraitBlur: false,
  );

  AdjustParams copyWith({
    double? exposure,
    double? contrast,
    double? saturation,
    double? vibrance,
    double? brightness,
    double? warmth,
    double? tint,
    double? highlights,
    double? shadows,
    double? clarity,
    double? dehaze,
    double? gamma,
    double? fade,
    double? vignette,
    double? vignetteSize,
    double? sharpen,
    double? grain,
    bool? removeBg,
    bool? portraitBlur,
  }) {
    return AdjustParams(
      exposure: exposure ?? this.exposure,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      vibrance: vibrance ?? this.vibrance,
      brightness: brightness ?? this.brightness,
      warmth: warmth ?? this.warmth,
      tint: tint ?? this.tint,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      clarity: clarity ?? this.clarity,
      dehaze: dehaze ?? this.dehaze,
      gamma: gamma ?? this.gamma,
      fade: fade ?? this.fade,
      vignette: vignette ?? this.vignette,
      vignetteSize: vignetteSize ?? this.vignetteSize,
      sharpen: sharpen ?? this.sharpen,
      grain: grain ?? this.grain,
      removeBg: removeBg ?? this.removeBg,
      portraitBlur: portraitBlur ?? this.portraitBlur,
    );
  }
}

class AdjustPreset {
  final String id;
  final String name;
  final AdjustParams params;
  const AdjustPreset({required this.id, required this.name, required this.params});
}

final kAdjustPresets = <AdjustPreset>[
  AdjustPreset(
    id: 'clean',
    name: 'Clean',
    params: AdjustParams.defaults.copyWith(contrast: 1.08, saturation: 1.05, brightness: 0.02),
  ),
  AdjustPreset(
    id: 'cinematic',
    name: 'Cinematic',
    params: AdjustParams.defaults.copyWith(
      contrast: 1.18,
      saturation: 0.92,
      warmth: -0.18,
      brightness: -0.02,
    ),
  ),
  AdjustPreset(
    id: 'pop',
    name: 'Pop',
    params: AdjustParams.defaults.copyWith(contrast: 1.22, saturation: 1.25, brightness: 0.05),
  ),
  AdjustPreset(
    id: 'matte',
    name: 'Matte',
    params: AdjustParams.defaults.copyWith(contrast: 0.92, saturation: 0.95, brightness: 0.02, warmth: 0.10),
  ),
  AdjustPreset(
    id: 'bw_soft',
    name: 'B&W Soft',
    params: AdjustParams.defaults.copyWith(saturation: 0.0, contrast: 1.10, brightness: 0.01),
  ),
];