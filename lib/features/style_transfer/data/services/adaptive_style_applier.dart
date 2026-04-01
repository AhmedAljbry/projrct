import 'dart:math' as math;

import 'package:untitled2/features/scene_analysis/domain/entities/scene_analysis_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/color_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/curve_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/detail_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/hsl_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/local_rules.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_preset_definition.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_settings.dart';
import 'package:untitled2/features/style_transfer/domain/entities/tone_profile.dart';

/// Applies scene-aware routing before the heavy renderer runs so that presets
/// stay realistic even when the user mixes them with very different images.
class AdaptiveStyleApplier {
  const AdaptiveStyleApplier();

  AdaptiveStyleApplication apply({
    required StyleProfile baseProfile,
    required StyleTransferSettings settings,
    SceneAnalysisResult? analysis,
    StylePresetDefinition? preset,
  }) {
    final sceneType = analysis?.scene.sceneType ?? baseProfile.sceneType;
    final rule = preset?.adaptiveRule;
    final supportsScene = preset?.supportsScene(sceneType) ?? true;
    final sceneMismatch = _sceneMismatch(
      baseScene: baseProfile.sceneType,
      targetScene: sceneType,
      supportsScene: supportsScene,
    );
    final sceneScale = _sceneScale(sceneType);
    var effectiveStrength = settings.strength;
    if (rule != null) {
      effectiveStrength = math.min(effectiveStrength, rule.defaultStrength);
      if (sceneMismatch > 0.35) {
        effectiveStrength = math.min(
          effectiveStrength,
          rule.safeFallbackStrength,
        );
      }
    }
    final naturalMode = settings.naturalMode || (preset?.naturalMode ?? false);
    if (naturalMode) {
      effectiveStrength *= 0.94;
    }
    effectiveStrength *= sceneScale.strengthScale;
    effectiveStrength = effectiveStrength.clamp(0.32, 0.92).toDouble();

    final hslScale = (1 -
            ((rule?.hslDamping ?? 0.24) *
                (sceneMismatch + (naturalMode ? 0.18 : 0))))
        .clamp(0.45, 1.0)
        .toDouble();
    final curveScale = (1 -
            ((rule?.curveDamping ?? 0.22) *
                (sceneMismatch + (naturalMode ? 0.14 : 0))))
        .clamp(0.48, 1.0)
        .toDouble();
    final toneScale =
        (1 - ((rule?.mismatchDamping ?? 0.18) * sceneMismatch)).clamp(0.6, 1.0);

    final profile = _routeProfile(
      baseProfile,
      sceneType: sceneType,
      sceneScale: sceneScale,
      toneScale: toneScale.toDouble(),
      hslScale: hslScale,
      curveScale: curveScale,
      naturalMode: naturalMode,
    );
    final mergedRules = _mergeRules(
      settings.localOverrides,
      preset?.maskPolicy ?? baseProfile.local,
      sceneType: sceneType,
      analysis: analysis,
    );
    final tunedSettings = settings.copyWith(
      strength: effectiveStrength,
      naturalMode: naturalMode,
      localOverrides: mergedRules,
      glowBoost: _sceneGlow(sceneType, settings.glowBoost, naturalMode),
      detailBoost: _sceneDetailBoost(
        sceneType,
        settings.detailBoost,
        (rule?.detailRecoveryBoost ?? 0.18),
      ),
      detailRecovery: _sceneDetailRecovery(
        settings.detailRecovery,
        sceneType,
        naturalMode,
      ),
      luminancePreservation: _sceneLuminancePreservation(
        settings.luminancePreservation,
        sceneType,
        naturalMode,
      ),
    );

    final notes = <String>[];
    if (!supportsScene && preset != null) {
      notes.add('${preset.name} softened itself for this $sceneType scene.');
    }
    if (sceneType == 'wildlife') {
      notes.add('Wildlife detail protection is preserving fur and warm tones.');
    } else if (sceneType == 'portrait') {
      notes.add('Portrait protection is preserving skin and face luminance.');
    } else if (naturalMode) {
      notes.add('Natural mode is prioritizing realism and luminance safety.');
    }

    return AdaptiveStyleApplication(
      profile: profile,
      settings: tunedSettings,
      notes: notes,
      sceneType: sceneType,
    );
  }
}

class AdaptiveStyleApplication {
  const AdaptiveStyleApplication({
    required this.profile,
    required this.settings,
    required this.notes,
    required this.sceneType,
  });

  final StyleProfile profile;
  final StyleTransferSettings settings;
  final List<String> notes;
  final String sceneType;
}

class _SceneScale {
  const _SceneScale({
    required this.strengthScale,
    required this.toneBias,
    required this.colorBias,
    required this.detailBias,
    required this.glowBias,
  });

  final double strengthScale;
  final double toneBias;
  final double colorBias;
  final double detailBias;
  final double glowBias;
}

_SceneScale _sceneScale(String sceneType) {
  switch (sceneType) {
    case 'portrait':
      return const _SceneScale(
        strengthScale: 0.94,
        toneBias: 0.94,
        colorBias: 0.92,
        detailBias: 0.86,
        glowBias: 0.82,
      );
    case 'wildlife':
      return const _SceneScale(
        strengthScale: 0.90,
        toneBias: 0.92,
        colorBias: 0.88,
        detailBias: 1.12,
        glowBias: 0.72,
      );
    case 'night':
      return const _SceneScale(
        strengthScale: 0.96,
        toneBias: 1.02,
        colorBias: 0.94,
        detailBias: 1.02,
        glowBias: 1.04,
      );
    case 'product':
      return const _SceneScale(
        strengthScale: 0.90,
        toneBias: 0.94,
        colorBias: 0.90,
        detailBias: 1.00,
        glowBias: 0.70,
      );
    case 'architecture':
      return const _SceneScale(
        strengthScale: 0.92,
        toneBias: 0.96,
        colorBias: 0.88,
        detailBias: 1.04,
        glowBias: 0.78,
      );
    case 'landscape':
      return const _SceneScale(
        strengthScale: 0.96,
        toneBias: 0.98,
        colorBias: 1.00,
        detailBias: 1.04,
        glowBias: 0.88,
      );
    default:
      return const _SceneScale(
        strengthScale: 1.0,
        toneBias: 1.0,
        colorBias: 1.0,
        detailBias: 1.0,
        glowBias: 1.0,
      );
  }
}

double _sceneMismatch({
  required String baseScene,
  required String targetScene,
  required bool supportsScene,
}) {
  if (baseScene == targetScene) {
    return 0;
  }
  if (supportsScene) {
    return 0.22;
  }
  if ((baseScene == 'portrait' && targetScene == 'editorial') ||
      (baseScene == 'editorial' && targetScene == 'portrait')) {
    return 0.32;
  }
  return 0.54;
}

StyleProfile _routeProfile(
  StyleProfile profile, {
  required String sceneType,
  required _SceneScale sceneScale,
  required double toneScale,
  required double hslScale,
  required double curveScale,
  required bool naturalMode,
}) {
  final sceneColorScale =
      naturalMode ? sceneScale.colorBias * 0.94 : sceneScale.colorBias;
  final detailScale =
      naturalMode ? sceneScale.detailBias * 0.94 : sceneScale.detailBias;
  return profile.copyWith(
    tone:
        _scaleTone(profile.tone, toneScale * sceneScale.toneBias, naturalMode),
    color: _routeColor(profile.color, sceneType, sceneColorScale, naturalMode),
    hsl: _scaleHsl(profile.hsl, hslScale, sceneType),
    curves: _scaleCurves(profile.curves, curveScale),
    detail: _routeDetail(profile.detail, sceneType, detailScale, naturalMode),
    local: _routeLocal(profile.local, sceneType),
  );
}

ToneProfile _scaleTone(ToneProfile tone, double scale, bool naturalMode) {
  final fadeScale = naturalMode ? scale * 0.88 : scale;
  return tone.copyWith(
    exposure: tone.exposure * scale,
    contrast: tone.contrast * scale,
    highlights: tone.highlights * (scale * 0.96),
    shadows: tone.shadows * scale,
    blacks: tone.blacks * (scale * 0.92),
    whites: tone.whites * (scale * 0.92),
    fade: (tone.fade * fadeScale).clamp(0.0, 0.18).toDouble(),
  );
}

ColorProfile _routeColor(
  ColorProfile color,
  String sceneType,
  double scale,
  bool naturalMode,
) {
  var temperature = color.temperature * scale;
  var tint = color.tint * scale;
  var saturation = color.saturation * scale;
  var vibrance = color.vibrance * scale;
  if (sceneType == 'wildlife') {
    temperature *= 0.78;
    saturation *= 0.78;
    vibrance *= 0.84;
  } else if (sceneType == 'architecture') {
    temperature *= 0.72;
    tint *= 0.72;
  } else if (sceneType == 'product') {
    vibrance *= 0.84;
  }
  if (naturalMode) {
    saturation *= 0.9;
    vibrance *= 0.9;
  }
  return color.copyWith(
    temperature: temperature,
    tint: tint,
    saturation: saturation,
    vibrance: vibrance,
  );
}

HslProfile _scaleHsl(HslProfile hsl, double scale, String sceneType) {
  HslChannel tune(String name, HslChannel channel) {
    var hue = channel.h * scale;
    var saturation = channel.s * scale;
    var luminance = channel.l * scale;
    if (sceneType == 'wildlife' && (name == 'orange' || name == 'yellow')) {
      hue *= 0.76;
      saturation *= 0.72;
      luminance *= 0.78;
    }
    if (sceneType == 'portrait' && (name == 'orange' || name == 'red')) {
      saturation *= 0.84;
      luminance *= 0.88;
    }
    if (sceneType == 'architecture' && (name == 'blue' || name == 'aqua')) {
      saturation *= 0.9;
    }
    return channel.copyWith(h: hue, s: saturation, l: luminance);
  }

  return HslProfile(
    red: tune('red', hsl.red),
    orange: tune('orange', hsl.orange),
    yellow: tune('yellow', hsl.yellow),
    green: tune('green', hsl.green),
    aqua: tune('aqua', hsl.aqua),
    blue: tune('blue', hsl.blue),
    purple: tune('purple', hsl.purple),
    magenta: tune('magenta', hsl.magenta),
  );
}

CurveProfile _scaleCurves(CurveProfile curves, double scale) {
  List<double> scaleCurve(List<double> curve) {
    if (curve.isEmpty) {
      return const <double>[0, 0.25, 0.5, 0.75, 1];
    }
    return List<double>.generate(curve.length, (index) {
      final identity = curve.length == 1 ? 0.0 : index / (curve.length - 1);
      return (identity + ((curve[index] - identity) * scale))
          .clamp(0.0, 1.0)
          .toDouble();
    });
  }

  return curves.copyWith(
    master: scaleCurve(curves.master),
    red: scaleCurve(curves.red),
    green: scaleCurve(curves.green),
    blue: scaleCurve(curves.blue),
  );
}

DetailProfile _routeDetail(
  DetailProfile detail,
  String sceneType,
  double scale,
  bool naturalMode,
) {
  var sharpness = detail.sharpness * scale;
  var clarity = detail.clarity * scale;
  var texture = detail.texture * scale;
  var grain = detail.grain * scale;
  var vignette = detail.vignette * scale;
  var bloom = detail.bloom * scale;

  if (sceneType == 'portrait') {
    sharpness *= 0.84;
    clarity *= 0.82;
    texture *= 0.78;
    bloom *= 0.88;
  } else if (sceneType == 'wildlife') {
    sharpness *= 1.08;
    texture *= 1.18;
    clarity *= 1.06;
    bloom *= 0.72;
  } else if (sceneType == 'product') {
    bloom *= 0.68;
    vignette *= 0.74;
  }

  if (naturalMode) {
    clarity *= 0.92;
    bloom *= 0.78;
    grain *= 0.9;
  }

  return detail.copyWith(
    sharpness: sharpness.clamp(0.0, 1.0).toDouble(),
    clarity: clarity.clamp(0.0, 1.0).toDouble(),
    texture: texture.clamp(0.0, 1.0).toDouble(),
    grain: grain.clamp(0.0, 1.0).toDouble(),
    vignette: vignette.clamp(0.0, 1.0).toDouble(),
    bloom: bloom.clamp(0.0, 1.0).toDouble(),
  );
}

LocalRules _routeLocal(LocalRules local, String sceneType) {
  if (sceneType == 'portrait') {
    return local.copyWith(skinProtect: true, faceExposureGuard: true);
  }
  if (sceneType == 'wildlife') {
    return local.copyWith(backgroundAdjust: true);
  }
  if (sceneType == 'product') {
    return local.copyWith(skyAdjust: false);
  }
  return local;
}

LocalRules _mergeRules(
  LocalRules current,
  LocalRules presetRules, {
  required String sceneType,
  SceneAnalysisResult? analysis,
}) {
  final merged = LocalRules(
    skinProtect: current.skinProtect || presetRules.skinProtect,
    faceExposureGuard:
        current.faceExposureGuard || presetRules.faceExposureGuard,
    skyAdjust: current.skyAdjust || presetRules.skyAdjust,
    backgroundAdjust: current.backgroundAdjust || presetRules.backgroundAdjust,
  );
  if (sceneType == 'portrait' || (analysis?.scene.faceCount ?? 0) > 0) {
    return merged.copyWith(skinProtect: true, faceExposureGuard: true);
  }
  return merged;
}

double _sceneGlow(String sceneType, double current, bool naturalMode) {
  if (sceneType == 'night') {
    return naturalMode ? current * 0.92 : current;
  }
  if (sceneType == 'portrait' || sceneType == 'product') {
    return current * 0.82;
  }
  return current * (naturalMode ? 0.9 : 1.0);
}

double _sceneDetailBoost(String sceneType, double current, double ruleBoost) {
  if (sceneType == 'wildlife' || sceneType == 'architecture') {
    return (current + (ruleBoost * 0.35)).clamp(0.0, 0.6).toDouble();
  }
  if (sceneType == 'portrait') {
    return (current + (ruleBoost * 0.1)).clamp(0.0, 0.5).toDouble();
  }
  return (current + (ruleBoost * 0.2)).clamp(0.0, 0.6).toDouble();
}

double _sceneDetailRecovery(
  double current,
  String sceneType,
  bool naturalMode,
) {
  var value = current;
  if (sceneType == 'wildlife' || sceneType == 'architecture') {
    value += 0.08;
  } else if (sceneType == 'portrait') {
    value += 0.03;
  }
  if (naturalMode) {
    value += 0.04;
  }
  return value.clamp(0.0, 1.0).toDouble();
}

double _sceneLuminancePreservation(
  double current,
  String sceneType,
  bool naturalMode,
) {
  var value = current;
  if (sceneType == 'portrait' || sceneType == 'wildlife') {
    value += 0.06;
  } else if (sceneType == 'product' || sceneType == 'architecture') {
    value += 0.04;
  }
  if (naturalMode) {
    value += 0.04;
  }
  return value.clamp(0.0, 1.0).toDouble();
}
