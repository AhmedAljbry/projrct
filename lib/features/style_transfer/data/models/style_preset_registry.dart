import 'package:flutter/material.dart';

import 'package:untitled2/features/style_transfer/domain/entities/color_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/curve_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/detail_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/hsl_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/local_rules.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_preset_definition.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/tone_profile.dart';

/// Central source of truth for the productized built-in style packs.
class StylePresetRegistry {
  const StylePresetRegistry._();

  static List<StylePresetDefinition> get allPresets => <StylePresetDefinition>[
        _naturalPremium,
        _cinematicSoft,
        _luxuryPortrait,
        _darkCinemaPro,
        _goldenHourRich,
        _cleanInfluencer,
        _matteFilmVintage,
        _neonNight,
        _wildlifeNaturalPro,
        _hdrLuxuryRealistic,
      ];

  static List<StylePresetDefinition> get featuredPresets =>
      allPresets.where((preset) => preset.featured).toList(growable: false);

  static Map<String, List<StylePresetDefinition>> get categorizedPresets {
    final grouped = <String, List<StylePresetDefinition>>{};
    for (final preset in allPresets) {
      grouped.putIfAbsent(preset.category, () => <StylePresetDefinition>[]);
      grouped[preset.category]!.add(preset);
    }
    return grouped;
  }

  static StylePresetDefinition? byId(String? id) {
    if (id == null) {
      return null;
    }
    for (final preset in allPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  static final StylePresetDefinition _naturalPremium = StylePresetDefinition(
    id: 'preset-natural-premium',
    name: 'Natural Premium',
    description: 'Subtle premium polish with strong luminance protection.',
    category: 'Natural',
    profile: const StyleProfile(
      id: 'profile-natural-premium',
      name: 'Natural Premium',
      confidence: 0.97,
      sceneType: 'editorial',
      tone: ToneProfile(
        exposure: 0.04,
        contrast: 0.10,
        highlights: -0.10,
        shadows: 0.10,
        blacks: -0.02,
        whites: 0.03,
        fade: 0.02,
      ),
      color: ColorProfile(
        temperature: 0.04,
        tint: 0.01,
        saturation: 0.03,
        vibrance: 0.07,
        palette: <Color>[
          Color(0xFF1B2430),
          Color(0xFF617488),
          Color(0xFFB5C1CF),
          Color(0xFFF1E9DE),
        ],
      ),
      hsl: HslProfile(
        red: HslChannel(h: 0, s: 0.02, l: 0.01),
        orange: HslChannel(h: -1, s: 0.03, l: 0.03),
        yellow: HslChannel(h: -2, s: 0.02, l: 0.01),
        green: HslChannel(h: 0, s: -0.02, l: 0),
        aqua: HslChannel(h: 0, s: -0.01, l: 0),
        blue: HslChannel(h: -1, s: 0.02, l: 0),
        purple: HslChannel(h: 0, s: 0, l: 0),
        magenta: HslChannel(h: 0, s: 0.01, l: 0),
      ),
      curves: CurveProfile(
        master: <double>[0, 0.24, 0.52, 0.77, 1],
        red: <double>[0, 0.24, 0.52, 0.77, 1],
        green: <double>[0, 0.24, 0.51, 0.77, 1],
        blue: <double>[0, 0.23, 0.5, 0.76, 1],
      ),
      detail: DetailProfile(
        sharpness: 0.10,
        clarity: 0.12,
        texture: 0.12,
        grain: 0.01,
        vignette: 0.04,
        bloom: 0.05,
      ),
      local: LocalRules(
        skinProtect: true,
        faceExposureGuard: true,
        skyAdjust: true,
        backgroundAdjust: true,
      ),
    ),
    adaptiveRule: const StylePresetAdaptiveRule(
      defaultStrength: 0.72,
      safeFallbackStrength: 0.56,
      mismatchDamping: 0.20,
      hslDamping: 0.30,
      curveDamping: 0.26,
      detailRecoveryBoost: 0.18,
    ),
    maskPolicy: const LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: true,
      backgroundAdjust: true,
    ),
    supportedScenes: const <String>[
      'portrait',
      'wildlife',
      'landscape',
      'product',
      'night',
      'architecture',
      'editorial',
    ],
    featured: true,
    naturalMode: true,
  );

  static final StylePresetDefinition _cinematicSoft = StylePresetDefinition(
    id: 'preset-cinematic-soft',
    name: 'Cinematic Soft',
    description: 'Soft contrast filmic polish without flattening the frame.',
    category: 'Cinematic',
    profile: const StyleProfile(
      id: 'profile-cinematic-soft',
      name: 'Cinematic Soft',
      confidence: 0.95,
      sceneType: 'editorial',
      tone: ToneProfile(
        exposure: 0.05,
        contrast: 0.18,
        highlights: -0.16,
        shadows: 0.12,
        blacks: -0.06,
        whites: 0.04,
        fade: 0.06,
      ),
      color: ColorProfile(
        temperature: 0.10,
        tint: 0.03,
        saturation: 0.06,
        vibrance: 0.12,
        palette: <Color>[
          Color(0xFF181E2A),
          Color(0xFF665A57),
          Color(0xFFC2A47E),
          Color(0xFFF4E7D7),
        ],
      ),
      hsl: HslProfile(
        red: HslChannel(h: 2, s: 0.03, l: 0),
        orange: HslChannel(h: -3, s: 0.09, l: 0.04),
        yellow: HslChannel(h: -5, s: 0.03, l: 0.01),
        green: HslChannel(h: 0, s: -0.06, l: 0),
        aqua: HslChannel(h: -1, s: -0.02, l: 0),
        blue: HslChannel(h: -4, s: -0.04, l: -0.01),
        purple: HslChannel(h: 0, s: 0, l: 0),
        magenta: HslChannel(h: 1, s: 0.02, l: 0),
      ),
      curves: CurveProfile(
        master: <double>[0, 0.23, 0.55, 0.79, 1],
        red: <double>[0, 0.24, 0.56, 0.8, 1],
        green: <double>[0, 0.22, 0.52, 0.77, 1],
        blue: <double>[0, 0.19, 0.47, 0.73, 1],
      ),
      detail: DetailProfile(
        sharpness: 0.14,
        clarity: 0.18,
        texture: 0.12,
        grain: 0.06,
        vignette: 0.12,
        bloom: 0.12,
      ),
      local: LocalRules(
        skinProtect: true,
        faceExposureGuard: true,
        skyAdjust: true,
        backgroundAdjust: true,
      ),
    ),
    adaptiveRule: const StylePresetAdaptiveRule(
      defaultStrength: 0.82,
      safeFallbackStrength: 0.60,
      mismatchDamping: 0.24,
      hslDamping: 0.32,
      curveDamping: 0.28,
      detailRecoveryBoost: 0.20,
    ),
    maskPolicy: const LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: true,
      backgroundAdjust: true,
    ),
    supportedScenes: const <String>['portrait', 'landscape', 'editorial'],
    featured: true,
    naturalMode: true,
  );

  static final StylePresetDefinition _luxuryPortrait = StylePresetDefinition(
    id: 'preset-luxury-portrait',
    name: 'Luxury Portrait',
    description:
        'Clean skin-safe portrait finish with rich but realistic depth.',
    category: 'Portrait',
    profile: const StyleProfile(
      id: 'profile-luxury-portrait',
      name: 'Luxury Portrait',
      confidence: 0.97,
      sceneType: 'portrait',
      tone: ToneProfile(
        exposure: 0.08,
        contrast: 0.12,
        highlights: -0.18,
        shadows: 0.16,
        blacks: -0.03,
        whites: 0.05,
        fade: 0.03,
      ),
      color: ColorProfile(
        temperature: 0.08,
        tint: 0.02,
        saturation: 0.04,
        vibrance: 0.10,
        palette: <Color>[
          Color(0xFF2A1F1A),
          Color(0xFF9E725E),
          Color(0xFFD9B094),
          Color(0xFFF6E4D3),
        ],
      ),
      hsl: HslProfile(
        red: HslChannel(h: 0, s: 0.03, l: 0),
        orange: HslChannel(h: -2, s: 0.08, l: 0.07),
        yellow: HslChannel(h: -2, s: 0.03, l: 0.01),
        green: HslChannel(h: 0, s: -0.04, l: 0),
        aqua: HslChannel(h: 0, s: -0.03, l: 0),
        blue: HslChannel(h: -2, s: -0.04, l: 0),
        purple: HslChannel(h: 0, s: -0.02, l: 0),
        magenta: HslChannel(h: 0, s: 0.01, l: 0),
      ),
      curves: CurveProfile(
        master: <double>[0, 0.25, 0.54, 0.78, 1],
        red: <double>[0, 0.26, 0.56, 0.8, 1],
        green: <double>[0, 0.24, 0.53, 0.78, 1],
        blue: <double>[0, 0.22, 0.5, 0.75, 1],
      ),
      detail: DetailProfile(
        sharpness: 0.08,
        clarity: 0.12,
        texture: 0.06,
        grain: 0.01,
        vignette: 0.05,
        bloom: 0.08,
      ),
      local: LocalRules(
        skinProtect: true,
        faceExposureGuard: true,
        skyAdjust: false,
        backgroundAdjust: true,
      ),
    ),
    adaptiveRule: const StylePresetAdaptiveRule(
      defaultStrength: 0.78,
      safeFallbackStrength: 0.54,
      mismatchDamping: 0.28,
      hslDamping: 0.38,
      curveDamping: 0.34,
      detailRecoveryBoost: 0.16,
    ),
    maskPolicy: const LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: false,
      backgroundAdjust: true,
    ),
    supportedScenes: const <String>['portrait', 'editorial'],
    featured: true,
    naturalMode: true,
  );

  static final StylePresetDefinition _darkCinemaPro = StylePresetDefinition(
    id: 'preset-dark-cinema-pro',
    name: 'Dark Cinema Pro',
    description: 'Deep contrast night styling with controlled blacks.',
    category: 'Cinematic',
    profile: const StyleProfile(
      id: 'profile-dark-cinema-pro',
      name: 'Dark Cinema Pro',
      confidence: 0.94,
      sceneType: 'night',
      tone: ToneProfile(
        exposure: -0.04,
        contrast: 0.24,
        highlights: -0.14,
        shadows: 0.10,
        blacks: -0.10,
        whites: 0.06,
        fade: 0.02,
      ),
      color: ColorProfile(
        temperature: -0.05,
        tint: 0.02,
        saturation: 0.08,
        vibrance: 0.15,
        palette: <Color>[
          Color(0xFF090F18),
          Color(0xFF253449),
          Color(0xFF7A8CA5),
          Color(0xFFE4DFD3),
        ],
      ),
      hsl: HslProfile(
        red: HslChannel(h: 2, s: 0.02, l: 0),
        orange: HslChannel(h: -5, s: -0.03, l: 0),
        yellow: HslChannel(h: -6, s: -0.08, l: -0.02),
        green: HslChannel(h: 2, s: -0.02, l: 0),
        aqua: HslChannel(h: 2, s: 0.04, l: 0.01),
        blue: HslChannel(h: -4, s: 0.12, l: 0.03),
        purple: HslChannel(h: 2, s: 0.04, l: 0.01),
        magenta: HslChannel(h: 2, s: 0.02, l: 0.01),
      ),
      curves: CurveProfile(
        master: <double>[0, 0.18, 0.49, 0.8, 1],
        red: <double>[0, 0.18, 0.48, 0.79, 1],
        green: <double>[0, 0.19, 0.49, 0.79, 1],
        blue: <double>[0, 0.22, 0.55, 0.86, 1],
      ),
      detail: DetailProfile(
        sharpness: 0.18,
        clarity: 0.24,
        texture: 0.14,
        grain: 0.05,
        vignette: 0.16,
        bloom: 0.10,
      ),
      local: LocalRules(
        skinProtect: true,
        faceExposureGuard: true,
        skyAdjust: true,
        backgroundAdjust: true,
      ),
    ),
    adaptiveRule: const StylePresetAdaptiveRule(
      defaultStrength: 0.84,
      safeFallbackStrength: 0.60,
      mismatchDamping: 0.26,
      hslDamping: 0.34,
      curveDamping: 0.28,
      detailRecoveryBoost: 0.22,
    ),
    maskPolicy: const LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: true,
      backgroundAdjust: true,
    ),
    supportedScenes: const <String>['night', 'architecture', 'editorial'],
    featured: false,
    naturalMode: false,
  );

  static final StylePresetDefinition _goldenHourRich = StylePresetDefinition(
    id: 'preset-golden-hour-rich',
    name: 'Golden Hour Rich',
    description: 'Warm sunset depth with premium highlight control.',
    category: 'Natural',
    profile: const StyleProfile(
      id: 'profile-golden-hour-rich',
      name: 'Golden Hour Rich',
      confidence: 0.95,
      sceneType: 'landscape',
      tone: ToneProfile(
        exposure: 0.06,
        contrast: 0.14,
        highlights: -0.16,
        shadows: 0.12,
        blacks: -0.04,
        whites: 0.05,
        fade: 0.04,
      ),
      color: ColorProfile(
        temperature: 0.18,
        tint: 0.02,
        saturation: 0.07,
        vibrance: 0.14,
        palette: <Color>[
          Color(0xFF2B2020),
          Color(0xFFA55F45),
          Color(0xFFE8AF68),
          Color(0xFFF7E6C4),
        ],
      ),
      hsl: HslProfile(
        red: HslChannel(h: 1, s: 0.04, l: 0),
        orange: HslChannel(h: -5, s: 0.12, l: 0.05),
        yellow: HslChannel(h: -6, s: 0.08, l: 0.03),
        green: HslChannel(h: -2, s: -0.04, l: 0),
        aqua: HslChannel(h: -3, s: -0.02, l: 0),
        blue: HslChannel(h: -4, s: -0.06, l: -0.01),
        purple: HslChannel(h: 0, s: 0, l: 0),
        magenta: HslChannel(h: 0, s: 0.02, l: 0),
      ),
      curves: CurveProfile(
        master: <double>[0, 0.24, 0.54, 0.8, 1],
        red: <double>[0, 0.26, 0.57, 0.83, 1],
        green: <double>[0, 0.23, 0.52, 0.78, 1],
        blue: <double>[0, 0.18, 0.45, 0.71, 1],
      ),
      detail: DetailProfile(
        sharpness: 0.14,
        clarity: 0.18,
        texture: 0.12,
        grain: 0.03,
        vignette: 0.10,
        bloom: 0.10,
      ),
      local: LocalRules(
        skinProtect: true,
        faceExposureGuard: true,
        skyAdjust: true,
        backgroundAdjust: true,
      ),
    ),
    adaptiveRule: const StylePresetAdaptiveRule(
      defaultStrength: 0.80,
      safeFallbackStrength: 0.58,
      mismatchDamping: 0.24,
      hslDamping: 0.30,
      curveDamping: 0.28,
      detailRecoveryBoost: 0.18,
    ),
    maskPolicy: const LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: true,
      backgroundAdjust: true,
    ),
    supportedScenes: const <String>['landscape', 'editorial', 'portrait'],
    featured: true,
    naturalMode: true,
  );

  static final StylePresetDefinition _cleanInfluencer = StylePresetDefinition(
    id: 'preset-clean-influencer',
    name: 'Clean Influencer',
    description: 'Bright clean social-ready look with restrained contrast.',
    category: 'Portrait',
    profile: const StyleProfile(
      id: 'profile-clean-influencer',
      name: 'Clean Influencer',
      confidence: 0.96,
      sceneType: 'portrait',
      tone: ToneProfile(
        exposure: 0.07,
        contrast: 0.08,
        highlights: -0.12,
        shadows: 0.10,
        blacks: -0.01,
        whites: 0.04,
        fade: 0.01,
      ),
      color: ColorProfile(
        temperature: 0.03,
        tint: 0.01,
        saturation: 0.04,
        vibrance: 0.08,
        palette: <Color>[
          Color(0xFF28313E),
          Color(0xFF73869A),
          Color(0xFFD0DCE8),
          Color(0xFFF9F3EC),
        ],
      ),
      hsl: HslProfile(
        red: HslChannel(h: 0, s: 0.02, l: 0),
        orange: HslChannel(h: -1, s: 0.05, l: 0.05),
        yellow: HslChannel(h: -2, s: 0.01, l: 0.01),
        green: HslChannel(h: 0, s: -0.03, l: 0),
        aqua: HslChannel(h: -1, s: 0.01, l: 0),
        blue: HslChannel(h: -1, s: 0.03, l: 0.01),
        purple: HslChannel(h: 0, s: 0, l: 0),
        magenta: HslChannel(h: 0, s: 0.01, l: 0),
      ),
      curves: CurveProfile(
        master: <double>[0, 0.25, 0.53, 0.78, 1],
        red: <double>[0, 0.25, 0.54, 0.79, 1],
        green: <double>[0, 0.24, 0.52, 0.78, 1],
        blue: <double>[0, 0.24, 0.51, 0.77, 1],
      ),
      detail: DetailProfile(
        sharpness: 0.08,
        clarity: 0.10,
        texture: 0.05,
        grain: 0,
        vignette: 0.02,
        bloom: 0.04,
      ),
      local: LocalRules(
        skinProtect: true,
        faceExposureGuard: true,
        skyAdjust: false,
        backgroundAdjust: true,
      ),
    ),
    adaptiveRule: const StylePresetAdaptiveRule(
      defaultStrength: 0.74,
      safeFallbackStrength: 0.54,
      mismatchDamping: 0.24,
      hslDamping: 0.34,
      curveDamping: 0.32,
      detailRecoveryBoost: 0.14,
    ),
    maskPolicy: const LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: false,
      backgroundAdjust: true,
    ),
    supportedScenes: const <String>['portrait', 'product', 'editorial'],
    featured: false,
    naturalMode: true,
  );

  static final StylePresetDefinition _matteFilmVintage = StylePresetDefinition(
    id: 'preset-matte-film-vintage',
    name: 'Matte Film Vintage',
    description: 'Matte film nostalgia with stable shadows and muted color.',
    category: 'Editorial',
    profile: const StyleProfile(
      id: 'profile-matte-film-vintage',
      name: 'Matte Film Vintage',
      confidence: 0.93,
      sceneType: 'editorial',
      tone: ToneProfile(
        exposure: 0.02,
        contrast: 0.10,
        highlights: -0.10,
        shadows: 0.08,
        blacks: 0.04,
        whites: -0.02,
        fade: 0.12,
      ),
      color: ColorProfile(
        temperature: 0.07,
        tint: -0.01,
        saturation: -0.03,
        vibrance: 0.04,
        palette: <Color>[
          Color(0xFF2E2623),
          Color(0xFF8B7764),
          Color(0xFFC8B6A0),
          Color(0xFFF0E5D6),
        ],
      ),
      hsl: HslProfile(
        red: HslChannel(h: 0, s: -0.01, l: 0),
        orange: HslChannel(h: -2, s: 0.04, l: 0.02),
        yellow: HslChannel(h: -3, s: -0.02, l: 0.01),
        green: HslChannel(h: 1, s: -0.08, l: 0),
        aqua: HslChannel(h: -2, s: -0.05, l: 0),
        blue: HslChannel(h: -2, s: -0.06, l: -0.01),
        purple: HslChannel(h: 0, s: -0.02, l: 0),
        magenta: HslChannel(h: 0, s: -0.01, l: 0),
      ),
      curves: CurveProfile(
        master: <double>[0.05, 0.28, 0.52, 0.74, 0.96],
        red: <double>[0.05, 0.29, 0.53, 0.75, 0.96],
        green: <double>[0.05, 0.28, 0.51, 0.73, 0.95],
        blue: <double>[0.06, 0.29, 0.51, 0.72, 0.93],
      ),
      detail: DetailProfile(
        sharpness: 0.06,
        clarity: 0.08,
        texture: 0.08,
        grain: 0.10,
        vignette: 0.08,
        bloom: 0.04,
      ),
      local: LocalRules(
        skinProtect: true,
        faceExposureGuard: true,
        skyAdjust: true,
        backgroundAdjust: true,
      ),
    ),
    adaptiveRule: const StylePresetAdaptiveRule(
      defaultStrength: 0.76,
      safeFallbackStrength: 0.56,
      mismatchDamping: 0.22,
      hslDamping: 0.30,
      curveDamping: 0.26,
      detailRecoveryBoost: 0.16,
    ),
    maskPolicy: const LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: true,
      backgroundAdjust: true,
    ),
    supportedScenes: const <String>['editorial', 'architecture', 'portrait'],
    featured: false,
    naturalMode: true,
  );

  static final StylePresetDefinition _neonNight = StylePresetDefinition(
    id: 'preset-neon-night',
    name: 'Neon Night',
    description: 'Premium neon color separation for night scenes only.',
    category: 'Night',
    profile: const StyleProfile(
      id: 'profile-neon-night',
      name: 'Neon Night',
      confidence: 0.92,
      sceneType: 'night',
      tone: ToneProfile(
        exposure: -0.01,
        contrast: 0.26,
        highlights: -0.12,
        shadows: 0.08,
        blacks: -0.12,
        whites: 0.10,
        fade: 0.01,
      ),
      color: ColorProfile(
        temperature: -0.08,
        tint: 0.12,
        saturation: 0.18,
        vibrance: 0.28,
        palette: <Color>[
          Color(0xFF09101D),
          Color(0xFF0FA2E1),
          Color(0xFFD548CE),
          Color(0xFFF2B0FF),
        ],
      ),
      hsl: HslProfile(
        red: HslChannel(h: 3, s: 0.08, l: 0),
        orange: HslChannel(h: -7, s: -0.04, l: -0.01),
        yellow: HslChannel(h: -8, s: -0.10, l: -0.03),
        green: HslChannel(h: 4, s: 0.04, l: 0),
        aqua: HslChannel(h: 4, s: 0.10, l: 0.04),
        blue: HslChannel(h: -5, s: 0.18, l: 0.04),
        purple: HslChannel(h: 5, s: 0.16, l: 0.04),
        magenta: HslChannel(h: 4, s: 0.14, l: 0.05),
      ),
      curves: CurveProfile(
        master: <double>[0, 0.18, 0.5, 0.82, 1],
        red: <double>[0, 0.2, 0.53, 0.84, 1],
        green: <double>[0, 0.18, 0.49, 0.78, 1],
        blue: <double>[0, 0.23, 0.56, 0.88, 1],
      ),
      detail: DetailProfile(
        sharpness: 0.20,
        clarity: 0.26,
        texture: 0.14,
        grain: 0.06,
        vignette: 0.14,
        bloom: 0.20,
      ),
      local: LocalRules(
        skinProtect: true,
        faceExposureGuard: true,
        skyAdjust: true,
        backgroundAdjust: true,
      ),
    ),
    adaptiveRule: const StylePresetAdaptiveRule(
      defaultStrength: 0.86,
      safeFallbackStrength: 0.58,
      mismatchDamping: 0.30,
      hslDamping: 0.38,
      curveDamping: 0.30,
      detailRecoveryBoost: 0.20,
    ),
    maskPolicy: const LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: true,
      backgroundAdjust: true,
    ),
    supportedScenes: const <String>['night'],
    featured: true,
    naturalMode: false,
  );

  static final StylePresetDefinition _wildlifeNaturalPro =
      StylePresetDefinition(
    id: 'preset-wildlife-natural-pro',
    name: 'Wildlife Natural Pro',
    description:
        'Wildlife-safe color and texture treatment for fur and feathers.',
    category: 'Wildlife',
    profile: const StyleProfile(
      id: 'profile-wildlife-natural-pro',
      name: 'Wildlife Natural Pro',
      confidence: 0.96,
      sceneType: 'wildlife',
      tone: ToneProfile(
        exposure: 0.03,
        contrast: 0.14,
        highlights: -0.12,
        shadows: 0.12,
        blacks: -0.03,
        whites: 0.04,
        fade: 0.01,
      ),
      color: ColorProfile(
        temperature: 0.06,
        tint: 0,
        saturation: 0.05,
        vibrance: 0.09,
        palette: <Color>[
          Color(0xFF221A12),
          Color(0xFF73522F),
          Color(0xFFB18656),
          Color(0xFFE8D6BC),
        ],
      ),
      hsl: HslProfile(
        red: HslChannel(h: 0, s: 0.01, l: 0),
        orange: HslChannel(h: -2, s: 0.06, l: 0.03),
        yellow: HslChannel(h: -3, s: 0.04, l: 0.02),
        green: HslChannel(h: 0, s: -0.03, l: 0),
        aqua: HslChannel(h: 0, s: -0.02, l: 0),
        blue: HslChannel(h: 0, s: -0.03, l: 0),
        purple: HslChannel(h: 0, s: 0, l: 0),
        magenta: HslChannel(h: 0, s: 0, l: 0),
      ),
      curves: CurveProfile(
        master: <double>[0, 0.24, 0.52, 0.79, 1],
        red: <double>[0, 0.25, 0.54, 0.8, 1],
        green: <double>[0, 0.24, 0.52, 0.78, 1],
        blue: <double>[0, 0.23, 0.49, 0.75, 1],
      ),
      detail: DetailProfile(
        sharpness: 0.18,
        clarity: 0.18,
        texture: 0.22,
        grain: 0.01,
        vignette: 0.04,
        bloom: 0.03,
      ),
      local: LocalRules(
        skinProtect: true,
        faceExposureGuard: true,
        skyAdjust: true,
        backgroundAdjust: true,
      ),
    ),
    adaptiveRule: const StylePresetAdaptiveRule(
      defaultStrength: 0.76,
      safeFallbackStrength: 0.55,
      mismatchDamping: 0.30,
      hslDamping: 0.40,
      curveDamping: 0.34,
      detailRecoveryBoost: 0.26,
    ),
    maskPolicy: const LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: true,
      backgroundAdjust: true,
    ),
    supportedScenes: const <String>['wildlife', 'landscape'],
    featured: true,
    naturalMode: true,
  );

  static final StylePresetDefinition _hdrLuxuryRealistic =
      StylePresetDefinition(
    id: 'preset-hdr-luxury-realistic',
    name: 'HDR Luxury Realistic',
    description: 'Expanded dynamic range feel without the fake HDR glow.',
    category: 'Editorial',
    profile: const StyleProfile(
      id: 'profile-hdr-luxury-realistic',
      name: 'HDR Luxury Realistic',
      confidence: 0.95,
      sceneType: 'architecture',
      tone: ToneProfile(
        exposure: 0.05,
        contrast: 0.16,
        highlights: -0.20,
        shadows: 0.18,
        blacks: -0.04,
        whites: 0.08,
        fade: 0.01,
      ),
      color: ColorProfile(
        temperature: 0.02,
        tint: 0.01,
        saturation: 0.05,
        vibrance: 0.10,
        palette: <Color>[
          Color(0xFF1A2532),
          Color(0xFF556D86),
          Color(0xFFA9BED0),
          Color(0xFFF1EEE7),
        ],
      ),
      hsl: HslProfile(
        red: HslChannel(h: 0, s: 0.01, l: 0),
        orange: HslChannel(h: -1, s: 0.03, l: 0.02),
        yellow: HslChannel(h: -2, s: 0.02, l: 0.01),
        green: HslChannel(h: 0, s: -0.03, l: 0),
        aqua: HslChannel(h: -1, s: 0.03, l: 0.01),
        blue: HslChannel(h: -2, s: 0.06, l: 0.02),
        purple: HslChannel(h: 0, s: 0.01, l: 0),
        magenta: HslChannel(h: 0, s: 0.01, l: 0),
      ),
      curves: CurveProfile(
        master: <double>[0, 0.23, 0.52, 0.8, 1],
        red: <double>[0, 0.23, 0.52, 0.8, 1],
        green: <double>[0, 0.23, 0.52, 0.8, 1],
        blue: <double>[0, 0.24, 0.54, 0.82, 1],
      ),
      detail: DetailProfile(
        sharpness: 0.16,
        clarity: 0.20,
        texture: 0.16,
        grain: 0.01,
        vignette: 0.03,
        bloom: 0.04,
      ),
      local: LocalRules(
        skinProtect: true,
        faceExposureGuard: true,
        skyAdjust: true,
        backgroundAdjust: true,
      ),
    ),
    adaptiveRule: const StylePresetAdaptiveRule(
      defaultStrength: 0.80,
      safeFallbackStrength: 0.58,
      mismatchDamping: 0.24,
      hslDamping: 0.28,
      curveDamping: 0.26,
      detailRecoveryBoost: 0.24,
    ),
    maskPolicy: const LocalRules(
      skinProtect: true,
      faceExposureGuard: true,
      skyAdjust: true,
      backgroundAdjust: true,
    ),
    supportedScenes: const <String>['architecture', 'landscape', 'product'],
    featured: false,
    naturalMode: true,
  );
}
