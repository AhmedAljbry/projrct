import 'package:untitled2/features/presets/domain/repositories/style_preset_repository.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';

class SavePresetUseCase {
  const SavePresetUseCase(this._repository);

  final StylePresetRepository _repository;

  Future<void> call(StyleProfile preset) {
    return _repository.savePreset(preset);
  }
}
