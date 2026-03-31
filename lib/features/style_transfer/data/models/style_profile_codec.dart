import 'dart:convert';

import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';

class StyleProfileCodec {
  const StyleProfileCodec();

  String encode(StyleProfile profile) {
    return jsonEncode(profile.toMap());
  }

  StyleProfile decode(String source) {
    return StyleProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  String encodeList(List<StyleProfile> profiles) {
    return jsonEncode(profiles.map((profile) => profile.toMap()).toList());
  }

  List<StyleProfile> decodeList(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const <StyleProfile>[];
    }
    final decoded = jsonDecode(source);
    if (decoded is! List<dynamic>) {
      return const <StyleProfile>[];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(StyleProfile.fromMap)
        .toList(growable: false);
  }
}
