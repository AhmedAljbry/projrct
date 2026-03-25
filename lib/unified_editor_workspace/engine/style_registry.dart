import 'creative_types.dart';

/// Production style pack: tone + color + safety-oriented defaults.
class StylePack {
  final String id;
  final String displayName;
  final bool architectural;
  final StyleTransferParams params;

  const StylePack({
    required this.id,
    required this.displayName,
    required this.architectural,
    required this.params,
  });
}

/// Full mandatory style set (core + architectural).
abstract final class CreativeStyleRegistry {
  static const List<StylePack> corePacks = [
    StylePack(
      id: 'natural_premium',
      displayName: 'Natural Premium',
      architectural: false,
      params: StyleTransferParams(
        exposure: 0.02,
        contrast: 1.03,
        saturation: 1.03,
        vibrance: 0.22,
        highlightRoll: 0.42,
        shadowLift: 0.04,
        warmth: 0.02,
        globalHue: 0,
        detailRecovery: 0.16,
        textureProtection: 0.58,
        neutralProtection: 0.52,
        skinProtection: 0.7,
        edgePreservation: 0.55,
      ),
    ),
    StylePack(
      id: 'cinematic_soft',
      displayName: 'Cinematic Soft',
      architectural: false,
      params: StyleTransferParams(
        exposure: -0.02,
        contrast: 1.08,
        saturation: 0.92,
        vibrance: 0.32,
        highlightRoll: 0.58,
        shadowLift: 0.08,
        warmth: 0.05,
        globalHue: -0.02,
        detailRecovery: 0.14,
        textureProtection: 0.62,
        neutralProtection: 0.48,
        skinProtection: 0.65,
        edgePreservation: 0.6,
      ),
    ),
    StylePack(
      id: 'luxury_portrait',
      displayName: 'Luxury Portrait',
      architectural: false,
      params: StyleTransferParams(
        exposure: 0.04,
        contrast: 1.02,
        saturation: 1.0,
        vibrance: 0.28,
        highlightRoll: 0.55,
        shadowLift: 0.06,
        warmth: 0.06,
        globalHue: 0.01,
        detailRecovery: 0.12,
        textureProtection: 0.7,
        neutralProtection: 0.5,
        skinProtection: 0.82,
        edgePreservation: 0.58,
      ),
    ),
    StylePack(
      id: 'dark_cinema_pro',
      displayName: 'Dark Cinema Pro',
      architectural: false,
      params: StyleTransferParams(
        exposure: -0.06,
        contrast: 1.14,
        saturation: 0.88,
        vibrance: 0.35,
        highlightRoll: 0.62,
        shadowLift: 0.1,
        warmth: 0.03,
        globalHue: -0.03,
        detailRecovery: 0.2,
        textureProtection: 0.55,
        neutralProtection: 0.42,
        skinProtection: 0.68,
        edgePreservation: 0.62,
      ),
    ),
    StylePack(
      id: 'golden_hour_rich',
      displayName: 'Golden Hour Rich',
      architectural: false,
      params: StyleTransferParams(
        exposure: 0.03,
        contrast: 1.05,
        saturation: 1.1,
        vibrance: 0.38,
        highlightRoll: 0.48,
        shadowLift: 0.07,
        warmth: 0.14,
        globalHue: 0.03,
        detailRecovery: 0.15,
        textureProtection: 0.52,
        neutralProtection: 0.45,
        skinProtection: 0.6,
        edgePreservation: 0.52,
      ),
    ),
    StylePack(
      id: 'clean_influencer',
      displayName: 'Clean Influencer',
      architectural: false,
      params: StyleTransferParams(
        exposure: 0.05,
        contrast: 1.06,
        saturation: 1.12,
        vibrance: 0.42,
        highlightRoll: 0.4,
        shadowLift: 0.05,
        warmth: 0.02,
        globalHue: 0,
        detailRecovery: 0.12,
        textureProtection: 0.48,
        neutralProtection: 0.4,
        skinProtection: 0.55,
        edgePreservation: 0.45,
      ),
    ),
    StylePack(
      id: 'matte_film_vintage',
      displayName: 'Matte Film Vintage',
      architectural: false,
      params: StyleTransferParams(
        exposure: -0.01,
        contrast: 1.05,
        saturation: 0.82,
        vibrance: 0.2,
        highlightRoll: 0.52,
        shadowLift: 0.12,
        warmth: 0.08,
        globalHue: 0.02,
        detailRecovery: 0.18,
        textureProtection: 0.6,
        neutralProtection: 0.55,
        skinProtection: 0.62,
        edgePreservation: 0.58,
      ),
    ),
    StylePack(
      id: 'wildlife_natural_pro',
      displayName: 'Wildlife Natural Pro',
      architectural: false,
      params: StyleTransferParams(
        exposure: 0.02,
        contrast: 1.07,
        saturation: 1.08,
        vibrance: 0.3,
        highlightRoll: 0.45,
        shadowLift: 0.05,
        warmth: -0.02,
        globalHue: 0,
        detailRecovery: 0.22,
        textureProtection: 0.68,
        neutralProtection: 0.38,
        skinProtection: 0.4,
        edgePreservation: 0.68,
      ),
    ),
    StylePack(
      id: 'hdr_luxury_realistic',
      displayName: 'HDR Luxury Realistic',
      architectural: false,
      params: StyleTransferParams(
        exposure: 0.01,
        contrast: 1.12,
        saturation: 1.05,
        vibrance: 0.26,
        highlightRoll: 0.72,
        shadowLift: 0.14,
        warmth: 0.02,
        globalHue: 0,
        detailRecovery: 0.25,
        textureProtection: 0.65,
        neutralProtection: 0.5,
        skinProtection: 0.58,
        edgePreservation: 0.65,
      ),
    ),
    StylePack(
      id: 'neon_night_city',
      displayName: 'Neon Night',
      architectural: false,
      params: StyleTransferParams(
        exposure: -0.03,
        contrast: 1.12,
        saturation: 1.18,
        vibrance: 0.55,
        highlightRoll: 0.52,
        shadowLift: 0.08,
        warmth: -0.08,
        globalHue: -0.05,
        detailRecovery: 0.18,
        textureProtection: 0.5,
        neutralProtection: 0.35,
        skinProtection: 0.5,
        edgePreservation: 0.52,
      ),
    ),
  ];

  static const List<StylePack> architectPacks = [
    StylePack(
      id: 'architectural_clean',
      displayName: 'Architectural Clean',
      architectural: true,
      params: StyleTransferParams(
        exposure: 0.03,
        contrast: 1.06,
        saturation: 0.98,
        vibrance: 0.15,
        highlightRoll: 0.55,
        shadowLift: 0.05,
        warmth: 0.01,
        globalHue: 0,
        detailRecovery: 0.16,
        textureProtection: 0.72,
        neutralProtection: 0.68,
        skinProtection: 0.35,
        edgePreservation: 0.7,
      ),
    ),
    StylePack(
      id: 'exterior_real_sun',
      displayName: 'Exterior Real Sun',
      architectural: true,
      params: StyleTransferParams(
        exposure: 0.05,
        contrast: 1.08,
        saturation: 1.05,
        vibrance: 0.2,
        highlightRoll: 0.6,
        shadowLift: 0.06,
        warmth: 0.1,
        globalHue: 0.01,
        detailRecovery: 0.14,
        textureProtection: 0.7,
        neutralProtection: 0.55,
        skinProtection: 0.3,
        edgePreservation: 0.68,
      ),
    ),
    StylePack(
      id: 'interior_soft_light',
      displayName: 'Interior Soft Light',
      architectural: true,
      params: StyleTransferParams(
        exposure: 0.04,
        contrast: 1.02,
        saturation: 0.95,
        vibrance: 0.18,
        highlightRoll: 0.58,
        shadowLift: 0.08,
        warmth: 0.04,
        globalHue: 0,
        detailRecovery: 0.12,
        textureProtection: 0.65,
        neutralProtection: 0.62,
        skinProtection: 0.38,
        edgePreservation: 0.55,
      ),
    ),
    StylePack(
      id: 'luxury_real_estate',
      displayName: 'Luxury Real Estate',
      architectural: true,
      params: StyleTransferParams(
        exposure: 0.045,
        contrast: 1.06,
        saturation: 1.02,
        vibrance: 0.22,
        highlightRoll: 0.56,
        shadowLift: 0.07,
        warmth: 0.06,
        globalHue: 0.01,
        detailRecovery: 0.13,
        textureProtection: 0.68,
        neutralProtection: 0.58,
        skinProtection: 0.32,
        edgePreservation: 0.62,
      ),
    ),
    StylePack(
      id: 'minimal_scandinavian',
      displayName: 'Minimal Scandinavian',
      architectural: true,
      params: StyleTransferParams(
        exposure: 0.04,
        contrast: 1.03,
        saturation: 0.92,
        vibrance: 0.12,
        highlightRoll: 0.52,
        shadowLift: 0.06,
        warmth: -0.02,
        globalHue: 0,
        detailRecovery: 0.1,
        textureProtection: 0.7,
        neutralProtection: 0.72,
        skinProtection: 0.3,
        edgePreservation: 0.58,
      ),
    ),
    StylePack(
      id: 'night_architectural',
      displayName: 'Night Architectural',
      architectural: true,
      params: StyleTransferParams(
        exposure: -0.04,
        contrast: 1.1,
        saturation: 0.9,
        vibrance: 0.22,
        highlightRoll: 0.68,
        shadowLift: 0.1,
        warmth: -0.03,
        globalHue: -0.02,
        detailRecovery: 0.2,
        textureProtection: 0.62,
        neutralProtection: 0.52,
        skinProtection: 0.28,
        edgePreservation: 0.64,
      ),
    ),
    StylePack(
      id: 'concrete_brutalism',
      displayName: 'Concrete Brutalism',
      architectural: true,
      params: StyleTransferParams(
        exposure: 0.02,
        contrast: 1.1,
        saturation: 0.93,
        vibrance: 0.12,
        highlightRoll: 0.52,
        shadowLift: 0.08,
        warmth: -0.04,
        globalHue: -0.02,
        detailRecovery: 0.22,
        textureProtection: 0.75,
        neutralProtection: 0.78,
        skinProtection: 0.28,
        edgePreservation: 0.72,
      ),
    ),
    StylePack(
      id: 'glass_modern',
      displayName: 'Glass Modern',
      architectural: true,
      params: StyleTransferParams(
        exposure: 0.03,
        contrast: 1.07,
        saturation: 1.0,
        vibrance: 0.2,
        highlightRoll: 0.65,
        shadowLift: 0.05,
        warmth: -0.03,
        globalHue: -0.01,
        detailRecovery: 0.18,
        textureProtection: 0.62,
        neutralProtection: 0.6,
        skinProtection: 0.3,
        edgePreservation: 0.66,
      ),
    ),
  ];

  static StylePack? byDisplayName(String name) {
    for (final p in corePacks) {
      if (p.displayName == name) return p;
    }
    for (final p in architectPacks) {
      if (p.displayName == name) return p;
    }
    // Legacy quick labels → closest pack
    switch (name) {
      case 'Viral':
        return corePacks.firstWhere((e) => e.id == 'clean_influencer');
      case 'Natural':
      case 'Fix My Photo':
        return corePacks.firstWhere((e) => e.id == 'natural_premium');
      case 'Cinematic':
        return corePacks.firstWhere((e) => e.id == 'cinematic_soft');
      case 'Cyber Neon':
        return corePacks.firstWhere((e) => e.id == 'neon_night_city');
      case 'Color Splash':
        return corePacks.firstWhere((e) => e.id == 'golden_hour_rich');
      default:
        return null;
    }
  }

  static List<String> get coreStyleDisplayNames =>
      corePacks.map((e) => e.displayName).toList(growable: false);

  static List<String> get architectStyleDisplayNames =>
      architectPacks.map((e) => e.displayName).toList(growable: false);
}
