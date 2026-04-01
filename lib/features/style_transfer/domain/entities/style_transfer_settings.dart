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
    required this.naturalMode,
    required this.cinematicGlow,
    required this.depthIllusion,
    required this.faceRefinement,
    required this.fallbackEnabled,
    required this.luminancePreservation,
    required this.detailRecovery,
    required this.analysisMaxDimension,
    required this.previewMaxDimension,
    required this.exportMaxDimension,
    required this.previewJpegQuality,
    required this.exportJpegQuality,
    required this.glowBoost,
    required this.detailBoost,
    required this.watermarkEnabled,
    required this.watermarkText,
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
      naturalMode: true,
      cinematicGlow: true,
      depthIllusion: true,
      faceRefinement: true,
      fallbackEnabled: true,
      luminancePreservation: 0.84,
      detailRecovery: 0.30,
      analysisMaxDimension: 288,
      previewMaxDimension: 960,
      exportMaxDimension: 2560,
      previewJpegQuality: 89,
      exportJpegQuality: 95,
      glowBoost: 0.35,
      detailBoost: 0.28,
      watermarkEnabled: false,
      watermarkText: 'AI Style Transfer Studio',
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
  final bool naturalMode;
  final bool cinematicGlow;
  final bool depthIllusion;
  final bool faceRefinement;
  final bool fallbackEnabled;
  final double luminancePreservation;
  final double detailRecovery;
  final int analysisMaxDimension;
  final int previewMaxDimension;
  final int exportMaxDimension;
  final int previewJpegQuality;
  final int exportJpegQuality;
  final double glowBoost;
  final double detailBoost;
  final bool watermarkEnabled;
  final String watermarkText;
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
    bool? naturalMode,
    bool? cinematicGlow,
    bool? depthIllusion,
    bool? faceRefinement,
    bool? fallbackEnabled,
    double? luminancePreservation,
    double? detailRecovery,
    int? analysisMaxDimension,
    int? previewMaxDimension,
    int? exportMaxDimension,
    int? previewJpegQuality,
    int? exportJpegQuality,
    double? glowBoost,
    double? detailBoost,
    bool? watermarkEnabled,
    String? watermarkText,
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
      naturalMode: naturalMode ?? this.naturalMode,
      cinematicGlow: cinematicGlow ?? this.cinematicGlow,
      depthIllusion: depthIllusion ?? this.depthIllusion,
      faceRefinement: faceRefinement ?? this.faceRefinement,
      fallbackEnabled: fallbackEnabled ?? this.fallbackEnabled,
      luminancePreservation:
          luminancePreservation ?? this.luminancePreservation,
      detailRecovery: detailRecovery ?? this.detailRecovery,
      analysisMaxDimension: analysisMaxDimension ?? this.analysisMaxDimension,
      previewMaxDimension: previewMaxDimension ?? this.previewMaxDimension,
      exportMaxDimension: exportMaxDimension ?? this.exportMaxDimension,
      previewJpegQuality: previewJpegQuality ?? this.previewJpegQuality,
      exportJpegQuality: exportJpegQuality ?? this.exportJpegQuality,
      glowBoost: glowBoost ?? this.glowBoost,
      detailBoost: detailBoost ?? this.detailBoost,
      watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
      watermarkText: watermarkText ?? this.watermarkText,
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
      'naturalMode': naturalMode,
      'cinematicGlow': cinematicGlow,
      'depthIllusion': depthIllusion,
      'faceRefinement': faceRefinement,
      'fallbackEnabled': fallbackEnabled,
      'luminancePreservation': luminancePreservation,
      'detailRecovery': detailRecovery,
      'analysisMaxDimension': analysisMaxDimension,
      'previewMaxDimension': previewMaxDimension,
      'exportMaxDimension': exportMaxDimension,
      'previewJpegQuality': previewJpegQuality,
      'exportJpegQuality': exportJpegQuality,
      'glowBoost': glowBoost,
      'detailBoost': detailBoost,
      'watermarkEnabled': watermarkEnabled,
      'watermarkText': watermarkText,
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
      naturalMode: map['naturalMode'] as bool? ?? true,
      cinematicGlow: map['cinematicGlow'] as bool? ?? true,
      depthIllusion: map['depthIllusion'] as bool? ?? true,
      faceRefinement: map['faceRefinement'] as bool? ?? true,
      fallbackEnabled: map['fallbackEnabled'] as bool? ?? true,
      luminancePreservation: _asDouble(map['luminancePreservation'], 0.84),
      detailRecovery: _asDouble(map['detailRecovery'], 0.30),
      analysisMaxDimension:
          (map['analysisMaxDimension'] as num?)?.toInt() ?? 288,
      previewMaxDimension: (map['previewMaxDimension'] as num?)?.toInt() ?? 960,
      exportMaxDimension: (map['exportMaxDimension'] as num?)?.toInt() ?? 2560,
      previewJpegQuality: (map['previewJpegQuality'] as num?)?.toInt() ?? 89,
      exportJpegQuality: (map['exportJpegQuality'] as num?)?.toInt() ?? 95,
      glowBoost: _asDouble(map['glowBoost'], 0.35),
      detailBoost: _asDouble(map['detailBoost'], 0.28),
      watermarkEnabled: map['watermarkEnabled'] as bool? ?? false,
      watermarkText:
          map['watermarkText']?.toString() ?? 'AI Style Transfer Studio',
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
