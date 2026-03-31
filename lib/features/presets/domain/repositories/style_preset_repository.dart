import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';

abstract class StylePresetRepository {
  Future<List<StyleProfile>> loadPresets();

  Future<void> savePreset(StyleProfile preset);

  Future<void> deletePreset(String id);
}
