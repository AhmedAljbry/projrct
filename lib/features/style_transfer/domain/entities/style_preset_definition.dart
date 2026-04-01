import 'package:untitled2/features/style_transfer/domain/entities/local_rules.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';

/// Describes a built-in preset as a reusable product artifact rather than just
/// a raw style profile. The registry uses this metadata to drive scene-aware
/// routing, default strength, and safe fallback behavior.
class StylePresetDefinition {
  const StylePresetDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.profile,
    required this.adaptiveRule,
    required this.maskPolicy,
    required this.supportedScenes,
    required this.featured,
    required this.naturalMode,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final StyleProfile profile;
  final StylePresetAdaptiveRule adaptiveRule;
  final LocalRules maskPolicy;
  final List<String> supportedScenes;
  final bool featured;
  final bool naturalMode;

  bool supportsScene(String sceneType) {
    return supportedScenes.isEmpty || supportedScenes.contains(sceneType);
  }
}

/// Encodes how aggressively a preset should respond to scene mismatches.
class StylePresetAdaptiveRule {
  const StylePresetAdaptiveRule({
    required this.defaultStrength,
    required this.safeFallbackStrength,
    required this.mismatchDamping,
    required this.hslDamping,
    required this.curveDamping,
    required this.detailRecoveryBoost,
  });

  final double defaultStrength;
  final double safeFallbackStrength;
  final double mismatchDamping;
  final double hslDamping;
  final double curveDamping;
  final double detailRecoveryBoost;
}
