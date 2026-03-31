import 'package:shared_preferences/shared_preferences.dart';

import 'package:untitled2/features/presets/domain/repositories/style_preset_repository.dart';
import 'package:untitled2/features/style_transfer/data/models/style_profile_codec.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';

class SharedPrefsStylePresetRepository implements StylePresetRepository {
  SharedPrefsStylePresetRepository({StyleProfileCodec? codec})
      : _codec = codec ?? const StyleProfileCodec();

  static const String _storageKey = 'style_transfer_presets_v1';

  final StyleProfileCodec _codec;

  @override
  Future<List<StyleProfile>> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    return _codec.decodeList(prefs.getString(_storageKey));
  }

  @override
  Future<void> savePreset(StyleProfile preset) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _codec.decodeList(prefs.getString(_storageKey)).toList();
    final index = existing.indexWhere((item) => item.id == preset.id);
    if (index >= 0) {
      existing[index] = preset;
    } else {
      existing.insert(0, preset);
    }
    await prefs.setString(_storageKey, _codec.encodeList(existing));
  }

  @override
  Future<void> deletePreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _codec
        .decodeList(prefs.getString(_storageKey))
        .where((item) => item.id != id)
        .toList(growable: false);
    await prefs.setString(_storageKey, _codec.encodeList(existing));
  }
}
