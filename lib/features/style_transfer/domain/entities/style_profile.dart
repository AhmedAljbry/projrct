import 'package:untitled2/features/style_transfer/domain/entities/color_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/curve_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/detail_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/hsl_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/local_rules.dart';
import 'package:untitled2/features/style_transfer/domain/entities/tone_profile.dart';

class StyleProfile {
  const StyleProfile({
    required this.id,
    required this.name,
    required this.confidence,
    required this.sceneType,
    required this.tone,
    required this.color,
    required this.hsl,
    required this.curves,
    required this.detail,
    required this.local,
  });

  final String id;
  final String name;
  final double confidence;
  final String sceneType;
  final ToneProfile tone;
  final ColorProfile color;
  final HslProfile hsl;
  final CurveProfile curves;
  final DetailProfile detail;
  final LocalRules local;

  StyleProfile copyWith({
    String? id,
    String? name,
    double? confidence,
    String? sceneType,
    ToneProfile? tone,
    ColorProfile? color,
    HslProfile? hsl,
    CurveProfile? curves,
    DetailProfile? detail,
    LocalRules? local,
  }) {
    return StyleProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      confidence: confidence ?? this.confidence,
      sceneType: sceneType ?? this.sceneType,
      tone: tone ?? this.tone,
      color: color ?? this.color,
      hsl: hsl ?? this.hsl,
      curves: curves ?? this.curves,
      detail: detail ?? this.detail,
      local: local ?? this.local,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'confidence': confidence,
      'sceneType': sceneType,
      'tone': tone.toMap(),
      'color': color.toMap(),
      'hsl': hsl.toMap(),
      'curves': curves.toMap(),
      'detail': detail.toMap(),
      'local': local.toMap(),
    };
  }

  factory StyleProfile.fromMap(Map<String, dynamic> map) {
    return StyleProfile(
      id: map['id']?.toString() ?? 'style-profile',
      name: map['name']?.toString() ?? 'Style Profile',
      confidence: _asDouble(map['confidence']),
      sceneType: map['sceneType']?.toString() ?? 'editorial',
      tone: ToneProfile.fromMap(
        (map['tone'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      color: ColorProfile.fromMap(
        (map['color'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      hsl: HslProfile.fromMap(
        (map['hsl'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      curves: CurveProfile.fromMap(
        (map['curves'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      detail: DetailProfile.fromMap(
        (map['detail'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      local: LocalRules.fromMap(
        (map['local'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
    );
  }
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}
