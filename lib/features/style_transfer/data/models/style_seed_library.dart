import 'package:untitled2/features/style_transfer/data/models/style_preset_registry.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';

/// Backwards-compatible facade that exposes built-in preset profiles to the
/// existing screens while the richer preset registry powers the new UI.
class StyleSeedLibrary {
  const StyleSeedLibrary._();

  static List<StyleProfile> get trendingStyles =>
      StylePresetRegistry.featuredPresets
          .map((preset) => preset.profile)
          .toList(growable: false);

  static Map<String, List<StyleProfile>> get categorizedStyles =>
      StylePresetRegistry.categorizedPresets.map(
        (category, presets) => MapEntry<String, List<StyleProfile>>(
          category,
          presets.map((preset) => preset.profile).toList(growable: false),
        ),
      );
}
