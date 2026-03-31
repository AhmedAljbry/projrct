import 'package:untitled2/features/style_transfer/domain/entities/curve_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/detail_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/hsl_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/local_rules.dart';
import 'package:untitled2/features/style_transfer/domain/entities/tone_profile.dart';

class StyleTransferSettings {
  const StyleTransferSettings({
    required this.strength,
    required this.sceneFit,
    required this.exposureLock,
    required this.cinematicGlow,
    required this.depthIllusion,
    required this.faceRefinement,
    required this.previewMaxDimension,
    required this.exportMaxDimension,
    required this.glowBoost,
    required this.detailBoost,
    required this.toneAdjustment,
    required this.hslAdjustment,
    required this.curveAdjustment,
    required this.detailAdjustment,
    required this.localOverrides,
  });

  factory StyleTransferSettings.defaults() {
    return StyleTransferSettings(
      strength: 0.82,
      sceneFit: true,
      exposureLock: true,
      cinematicGlow: true,
      depthIllusion: true,
      faceRefinement: true,
      previewMaxDimension: 1280,
      exportMaxDimension: 2400,
      glowBoost: 0.35,
      detailBoost: 0.28,
      toneAdjustment: const ToneProfile.neutral(),
      hslAdjustment: const HslProfile.zero(),
      curveAdjustment: CurveProfile.zeroDelta(),
      detailAdjustment: const DetailProfile.neutral(),
      localOverrides: const LocalRules.enabled(),
    );
  }

  final double strength;
  final bool sceneFit;
  final bool exposureLock;
  final bool cinematicGlow;
  final bool depthIllusion;
  final bool faceRefinement;
  final int previewMaxDimension;
  final int exportMaxDimension;
  final double glowBoost;
  final double detailBoost;
  final ToneProfile toneAdjustment;
  final HslProfile hslAdjustment;
  final CurveProfile curveAdjustment;
  final DetailProfile detailAdjustment;
  final LocalRules localOverrides;

  bool get skinProtect => localOverrides.skinProtect;

  StyleTransferSettings copyWith({
    double? strength,
    bool? sceneFit,
    bool? exposureLock,
    bool? cinematicGlow,
    bool? depthIllusion,
    bool? faceRefinement,
    int? previewMaxDimension,
    int? exportMaxDimension,
    double? glowBoost,
    double? detailBoost,
    ToneProfile? toneAdjustment,
    HslProfile? hslAdjustment,
    CurveProfile? curveAdjustment,
    DetailProfile? detailAdjustment,
    LocalRules? localOverrides,
  }) {
    return StyleTransferSettings(
      strength: strength ?? this.strength,
      sceneFit: sceneFit ?? this.sceneFit,
      exposureLock: exposureLock ?? this.exposureLock,
      cinematicGlow: cinematicGlow ?? this.cinematicGlow,
      depthIllusion: depthIllusion ?? this.depthIllusion,
      faceRefinement: faceRefinement ?? this.faceRefinement,
      previewMaxDimension: previewMaxDimension ?? this.previewMaxDimension,
      exportMaxDimension: exportMaxDimension ?? this.exportMaxDimension,
      glowBoost: glowBoost ?? this.glowBoost,
      detailBoost: detailBoost ?? this.detailBoost,
      toneAdjustment: toneAdjustment ?? this.toneAdjustment,
      hslAdjustment: hslAdjustment ?? this.hslAdjustment,
      curveAdjustment: curveAdjustment ?? this.curveAdjustment,
      detailAdjustment: detailAdjustment ?? this.detailAdjustment,
      localOverrides: localOverrides ?? this.localOverrides,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'strength': strength,
      'sceneFit': sceneFit,
      'exposureLock': exposureLock,
      'cinematicGlow': cinematicGlow,
      'depthIllusion': depthIllusion,
      'faceRefinement': faceRefinement,
      'previewMaxDimension': previewMaxDimension,
      'exportMaxDimension': exportMaxDimension,
      'glowBoost': glowBoost,
      'detailBoost': detailBoost,
      'toneAdjustment': toneAdjustment.toMap(),
      'hslAdjustment': hslAdjustment.toMap(),
      'curveAdjustment': curveAdjustment.toMap(),
      'detailAdjustment': detailAdjustment.toMap(),
      'localOverrides': localOverrides.toMap(),
    };
  }

  factory StyleTransferSettings.fromMap(Map<String, dynamic> map) {
    return StyleTransferSettings(
      strength: _asDouble(map['strength'], 0.82),
      sceneFit: map['sceneFit'] as bool? ?? true,
      exposureLock: map['exposureLock'] as bool? ?? true,
      cinematicGlow: map['cinematicGlow'] as bool? ?? true,
      depthIllusion: map['depthIllusion'] as bool? ?? true,
      faceRefinement: map['faceRefinement'] as bool? ?? true,
      previewMaxDimension:
          (map['previewMaxDimension'] as num?)?.toInt() ?? 1280,
      exportMaxDimension: (map['exportMaxDimension'] as num?)?.toInt() ?? 2400,
      glowBoost: _asDouble(map['glowBoost'], 0.35),
      detailBoost: _asDouble(map['detailBoost'], 0.28),
      toneAdjustment: ToneProfile.fromMap(
        (map['toneAdjustment'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      hslAdjustment: HslProfile.fromMap(
        (map['hslAdjustment'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      curveAdjustment: CurveProfile.fromMap(
        (map['curveAdjustment'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      detailAdjustment: DetailProfile.fromMap(
        (map['detailAdjustment'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      localOverrides: LocalRules.fromMap(
        (map['localOverrides'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
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
