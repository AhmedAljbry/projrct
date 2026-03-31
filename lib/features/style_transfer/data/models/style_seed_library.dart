import 'package:flutter/material.dart';

import 'package:untitled2/features/style_transfer/domain/entities/color_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/curve_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/detail_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/hsl_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/local_rules.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/tone_profile.dart';

class StyleSeedLibrary {
  const StyleSeedLibrary._();

  static List<StyleProfile> get trendingStyles => <StyleProfile>[
        _cinematicEmber,
        _luxPortrait,
        _neonPulse,
        _skylineDrift,
      ];

  static Map<String, List<StyleProfile>> get categorizedStyles =>
      <String, List<StyleProfile>>{
        'Cinematic': <StyleProfile>[_cinematicEmber, _skylineDrift],
        'Portrait': <StyleProfile>[_luxPortrait],
        'Luxury': <StyleProfile>[_goldVelvet],
        'Neon': <StyleProfile>[_neonPulse],
      };

  static const StyleProfile _cinematicEmber = StyleProfile(
    id: 'seed-cinematic-ember',
    name: 'Cinematic Ember',
    confidence: 0.94,
    sceneType: 'editorial',
    tone: ToneProfile(
      exposure: 0.08,
      contrast: 0.24,
      highlights: -0.18,
      shadows: 0.14,
      blacks: -0.08,
      whites: 0.06,
      fade: 0.08,
    ),
    color: ColorProfile(
      temperature: 0.18,
      tint: 0.04,
      saturation: 0.10,
      vibrance: 0.18,
      palette: <Color>[
        Color(0xFF181C2D),
        Color(0xFF8E4A3F),
        Color(0xFFDAA56E),
        Color(0xFFF6DFC5),
      ],
    ),
    hsl: HslProfile(
      red: HslChannel(h: 2, s: 0.06, l: 0.02),
      orange: HslChannel(h: -4, s: 0.12, l: 0.06),
      yellow: HslChannel(h: -5, s: 0.06, l: 0.02),
      green: HslChannel(h: 0, s: -0.08, l: 0),
      aqua: HslChannel(h: -2, s: -0.04, l: 0),
      blue: HslChannel(h: -6, s: -0.08, l: -0.02),
      purple: HslChannel(h: 0, s: 0, l: 0),
      magenta: HslChannel(h: 1, s: 0.03, l: 0),
    ),
    curves: CurveProfile(
      master: <double>[0, 0.23, 0.56, 0.8, 1],
      red: <double>[0, 0.26, 0.56, 0.79, 1],
      green: <double>[0, 0.22, 0.51, 0.76, 1],
      blue: <double>[0, 0.18, 0.44, 0.71, 1],
    ),
    detail: DetailProfile(
      sharpness: 0.18,
      clarity: 0.26,
      texture: 0.18,
      grain: 0.10,
      vignette: 0.22,
      bloom: 0.18,
    ),
    local: LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: true,
      backgroundAdjust: true,
    ),
  );

  static const StyleProfile _luxPortrait = StyleProfile(
    id: 'seed-luxe-portrait',
    name: 'Luxe Portrait',
    confidence: 0.96,
    sceneType: 'portrait',
    tone: ToneProfile(
      exposure: 0.10,
      contrast: 0.12,
      highlights: -0.16,
      shadows: 0.18,
      blacks: -0.03,
      whites: 0.08,
      fade: 0.04,
    ),
    color: ColorProfile(
      temperature: 0.10,
      tint: 0.02,
      saturation: 0.06,
      vibrance: 0.12,
      palette: <Color>[
        Color(0xFF2A1E1B),
        Color(0xFFB07B6D),
        Color(0xFFDDB49F),
        Color(0xFFF6E8D8),
      ],
    ),
    hsl: HslProfile(
      red: HslChannel(h: 0, s: 0.04, l: 0.01),
      orange: HslChannel(h: -2, s: 0.08, l: 0.08),
      yellow: HslChannel(h: -3, s: 0.04, l: 0.02),
      green: HslChannel(h: 0, s: -0.06, l: 0),
      aqua: HslChannel(h: 0, s: -0.05, l: 0),
      blue: HslChannel(h: -2, s: -0.06, l: 0),
      purple: HslChannel(h: 0, s: -0.02, l: 0),
      magenta: HslChannel(h: 0, s: 0.02, l: 0.01),
    ),
    curves: CurveProfile(
      master: <double>[0, 0.24, 0.54, 0.79, 1],
      red: <double>[0, 0.25, 0.56, 0.81, 1],
      green: <double>[0, 0.23, 0.53, 0.78, 1],
      blue: <double>[0, 0.22, 0.5, 0.75, 1],
    ),
    detail: DetailProfile(
      sharpness: 0.10,
      clarity: 0.16,
      texture: 0.08,
      grain: 0.02,
      vignette: 0.08,
      bloom: 0.10,
    ),
    local: LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: false,
      backgroundAdjust: true,
    ),
  );

  static const StyleProfile _neonPulse = StyleProfile(
    id: 'seed-neon-pulse',
    name: 'Neon Pulse',
    confidence: 0.91,
    sceneType: 'night',
    tone: ToneProfile(
      exposure: -0.02,
      contrast: 0.28,
      highlights: -0.10,
      shadows: 0.08,
      blacks: -0.14,
      whites: 0.10,
      fade: 0.02,
    ),
    color: ColorProfile(
      temperature: -0.10,
      tint: 0.14,
      saturation: 0.22,
      vibrance: 0.30,
      palette: <Color>[
        Color(0xFF08111F),
        Color(0xFF16A0E0),
        Color(0xFFE941D1),
        Color(0xFFF5B1FF),
      ],
    ),
    hsl: HslProfile(
      red: HslChannel(h: 3, s: 0.08, l: 0),
      orange: HslChannel(h: -8, s: -0.02, l: 0),
      yellow: HslChannel(h: -8, s: -0.08, l: -0.03),
      green: HslChannel(h: 4, s: 0.04, l: 0),
      aqua: HslChannel(h: 4, s: 0.10, l: 0.04),
      blue: HslChannel(h: -6, s: 0.20, l: 0.04),
      purple: HslChannel(h: 5, s: 0.18, l: 0.04),
      magenta: HslChannel(h: 4, s: 0.16, l: 0.06),
    ),
    curves: CurveProfile(
      master: <double>[0, 0.19, 0.52, 0.82, 1],
      red: <double>[0, 0.2, 0.54, 0.84, 1],
      green: <double>[0, 0.18, 0.49, 0.78, 1],
      blue: <double>[0, 0.22, 0.56, 0.87, 1],
    ),
    detail: DetailProfile(
      sharpness: 0.22,
      clarity: 0.28,
      texture: 0.14,
      grain: 0.08,
      vignette: 0.18,
      bloom: 0.24,
    ),
    local: LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: true,
      backgroundAdjust: true,
    ),
  );

  static const StyleProfile _skylineDrift = StyleProfile(
    id: 'seed-skyline-drift',
    name: 'Skyline Drift',
    confidence: 0.90,
    sceneType: 'architecture',
    tone: ToneProfile(
      exposure: 0.04,
      contrast: 0.20,
      highlights: -0.12,
      shadows: 0.10,
      blacks: -0.10,
      whites: 0.06,
      fade: 0.05,
    ),
    color: ColorProfile(
      temperature: -0.04,
      tint: -0.02,
      saturation: 0.08,
      vibrance: 0.14,
      palette: <Color>[
        Color(0xFF142033),
        Color(0xFF3A5679),
        Color(0xFF91A9C7),
        Color(0xFFE4EDF8),
      ],
    ),
    hsl: HslProfile(
      red: HslChannel(h: 0, s: -0.02, l: 0),
      orange: HslChannel(h: -2, s: -0.04, l: 0),
      yellow: HslChannel(h: -4, s: -0.06, l: 0),
      green: HslChannel(h: 2, s: -0.02, l: 0),
      aqua: HslChannel(h: -2, s: 0.04, l: 0.02),
      blue: HslChannel(h: -4, s: 0.08, l: 0.02),
      purple: HslChannel(h: 0, s: 0.02, l: 0),
      magenta: HslChannel(h: 0, s: 0, l: 0),
    ),
    curves: CurveProfile(
      master: <double>[0, 0.22, 0.51, 0.79, 1],
      red: <double>[0, 0.21, 0.49, 0.76, 1],
      green: <double>[0, 0.23, 0.51, 0.8, 1],
      blue: <double>[0, 0.25, 0.56, 0.84, 1],
    ),
    detail: DetailProfile(
      sharpness: 0.20,
      clarity: 0.24,
      texture: 0.16,
      grain: 0.02,
      vignette: 0.12,
      bloom: 0.08,
    ),
    local: LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: true,
      backgroundAdjust: true,
    ),
  );

  static const StyleProfile _goldVelvet = StyleProfile(
    id: 'seed-gold-velvet',
    name: 'Gold Velvet',
    confidence: 0.92,
    sceneType: 'product',
    tone: ToneProfile(
      exposure: 0.07,
      contrast: 0.14,
      highlights: -0.10,
      shadows: 0.06,
      blacks: -0.04,
      whites: 0.04,
      fade: 0.04,
    ),
    color: ColorProfile(
      temperature: 0.16,
      tint: 0.02,
      saturation: 0.05,
      vibrance: 0.10,
      palette: <Color>[
        Color(0xFF221912),
        Color(0xFF8F6734),
        Color(0xFFD9B16C),
        Color(0xFFF7E7BE),
      ],
    ),
    hsl: HslProfile(
      red: HslChannel(h: 0, s: 0.02, l: 0),
      orange: HslChannel(h: -5, s: 0.10, l: 0.04),
      yellow: HslChannel(h: -6, s: 0.08, l: 0.04),
      green: HslChannel(h: 0, s: -0.08, l: 0),
      aqua: HslChannel(h: 0, s: -0.06, l: 0),
      blue: HslChannel(h: -2, s: -0.08, l: -0.01),
      purple: HslChannel(h: 0, s: -0.02, l: 0),
      magenta: HslChannel(h: 0, s: 0, l: 0),
    ),
    curves: CurveProfile(
      master: <double>[0, 0.24, 0.53, 0.78, 1],
      red: <double>[0, 0.26, 0.56, 0.81, 1],
      green: <double>[0, 0.23, 0.51, 0.77, 1],
      blue: <double>[0, 0.2, 0.47, 0.74, 1],
    ),
    detail: DetailProfile(
      sharpness: 0.14,
      clarity: 0.14,
      texture: 0.08,
      grain: 0.03,
      vignette: 0.06,
      bloom: 0.09,
    ),
    local: LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: false,
      backgroundAdjust: true,
    ),
  );
}
