/*
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:lama/core/ml/adaptive_style_applier.dart';
import 'package:lama/core/color/color_statistics.dart';
import 'package:lama/core/imaging/image_decode.dart';
import 'package:lama/core/imaging/protection_mask_bundle.dart';
import 'package:lama/core/ml/local_color_transfer_engine.dart';
import 'package:lama/core/ml/style_blend_engine.dart';
import 'package:lama/core/rendering/style_transfer_renderer.dart';
import 'package:lama/core/utils/value_utils.dart';
import 'package:lama/features/enhancement/data/services/viral_enhancement_service.dart';
import 'package:lama/features/local_color_transfer/domain/entities/local_color_transfer_result.dart';
import 'package:lama/features/scene_analysis/domain/entities/scene_analysis.dart';
import 'package:lama/features/smart_masks/data/services/smart_mask_service.dart';
import 'package:lama/features/smart_masks/domain/entities/smart_mask_result.dart';
import 'package:lama/features/style_transfer/domain/entities/color_profile.dart';
import 'package:lama/features/style_transfer/domain/entities/compatibility_score.dart';
import 'package:lama/features/style_transfer/domain/entities/curve_profile.dart';
import 'package:lama/features/style_transfer/domain/entities/detail_profile.dart';
import 'package:lama/features/style_transfer/domain/entities/hsl_profile.dart';
import 'package:lama/features/style_transfer/domain/entities/local_rules.dart';
import 'package:lama/features/style_transfer/domain/entities/processing_diagnostics.dart';
import 'package:lama/features/style_transfer/domain/entities/style_behavior.dart';
import 'package:lama/features/style_transfer/domain/entities/style_profile.dart';
import 'package:lama/features/style_transfer/domain/entities/style_transfer_request.dart';
import 'package:lama/features/style_transfer/domain/entities/style_transfer_settings.dart';
import 'package:lama/features/style_transfer/domain/entities/tone_profile.dart';

Map<String, dynamic> extractStyleProfileCompute(Map<String, dynamic> payload) {
  final bytes = Uint8List.fromList(
    ((payload['bytes'] ?? <int>[]) as List)
        .map((value) => (value as num).toInt())
        .toList(),
  );
  final name = payload['name']?.toString() ?? 'Extracted Style';
  final image = decodeEditableImage(bytes);
  final stats = analyzeColorStatistics(image);
  final profile = buildStyleProfileFromStatistics(
    stats: stats,
    name: name,
  );
  return <String, dynamic>{
    'profile': profile.toMap(),
    'statistics': stats.toMap(),
  };
}

Map<String, dynamic> applyStyleTransferCompute(Map<String, dynamic> payload) {
  final request = StyleTransferRequest.fromMap(payload);
  try {
    return _apply(request, usedFallback: false);
  } catch (_) {
    if (!request.settings.allowFallback) {
      rethrow;
    }
    return _apply(request, usedFallback: true);
  }
}

Map<String, dynamic> _apply(
  StyleTransferRequest request, {
  required bool usedFallback,
}) {
  final targetBytes = Uint8List.fromList(request.targetBytes);
  final image = decodeEditableImage(targetBytes);
  final targetStats = request.targetStatistics ?? analyzeColorStatistics(image);
  final protectionMask = request.protectionMask ?? buildProtectionMaskBundle(image);
  final smartMaskResult = request.smartMaskResult ??
      _buildSmartMaskResult(
        image: image,
        scene: request.sceneAnalysis,
        protectionMask: protectionMask,
      );
  final sourceProfile = request.styleBlendProfile == null
      ? request.styleProfile
      : const StyleBlendEngine().blend(request.styleBlendProfile!);
  final decision = const AdaptiveStyleApplier().evaluate(
    profile: sourceProfile,
    scene: request.sceneAnalysis,
    targetStats: targetStats,
    settings: request.settings,
  );
  final mappedProfile = buildMappedStyleProfile(
    sourceProfile: sourceProfile,
    targetStats: targetStats,
    scene: request.sceneAnalysis,
    settings: request.settings,
    decision: decision,
    usedFallback: usedFallback,
  );
  final enhancement = const ViralEnhancementService().build(
    profile: mappedProfile,
    scene: request.sceneAnalysis,
    settings: request.settings,
  );
  final rendered = renderStyleTransfer(
    image: image,
    profile: mappedProfile,
    settings: request.settings,
    scene: request.sceneAnalysis,
    enhancement: enhancement,
    renderMode: request.renderMode,
    appliedStrength: decision.appliedStrength,
    safeModeTriggered: decision.safeModeTriggered,
    usedFallback: usedFallback,
    protectionMask: protectionMask,
    smartMaskResult: smartMaskResult,
  );
  final localTransfer = _applyLocalTransferIfNeeded(
    request: request,
    targetBytes: targetBytes,
    previewBytes: rendered.previewBytes,
    exportBytes: rendered.exportBytes,
    targetMasks: smartMaskResult,
  );
  final diagnostics = ProcessingDiagnostics(
    compatibility: CompatibilityScore(
      value: decision.compatibility,
      reasons: _buildCompatibilityReasons(
        decision: decision,
        scene: request.sceneAnalysis,
        sourceProfile: sourceProfile,
      ),
    ),
    sceneRoute: decision.sceneRoute,
    moodTags: _buildMoodTags(
      profile: mappedProfile,
      scene: request.sceneAnalysis,
      decision: decision,
    ),
    suggestedMode: _buildSuggestedMode(
      scene: request.sceneAnalysis,
      decision: decision,
      request: request,
    ),
    localTransfer: localTransfer.result,
  );

  final warnings = <String>[
    ...decision.warnings,
    ...rendered.warnings,
    ...localTransfer.result.warnings,
    if (decision.safeModeTriggered)
      'Adaptive safe mode softened the transfer to preserve realism.',
    if (decision.compatibility < 0.5)
      'Reference and target are weakly matched, so the engine reduced style pressure.',
    if (usedFallback) 'Fallback renderer was used to keep the process stable.',
  ];

  return <String, dynamic>{
    'previewBytes': localTransfer.previewBytes,
    'exportBytes': localTransfer.exportBytes,
    'appliedProfile': mappedProfile.toMap(),
    'sceneAnalysis': request.sceneAnalysis.toMap(),
    'safetyReport': rendered.safetyReport.toMap(),
    'compatibilityScore': decision.compatibility,
    'appliedStrength': decision.appliedStrength,
    'previewRenderMs': rendered.previewRenderMs,
    'exportRenderMs': rendered.exportRenderMs,
    'usedFallback': rendered.usedFallback,
    'exportReady': request.renderMode != StyleTransferRenderMode.preview,
    'previewCacheHit': false,
    'histogramCacheHit': request.targetStatistics != null,
    'maskCacheHit': request.protectionMask != null,
    'renderMode': request.renderMode.name,
    'warnings': warnings,
    'smartMaskResult': smartMaskResult.toMap(),
    'diagnostics': diagnostics.toMap(),
    'targetStatistics': targetStats.toMap(),
    'protectionMask': protectionMask.toMap(),
  };
}

class _LocalTransferApplication {
  const _LocalTransferApplication({
    required this.previewBytes,
    required this.exportBytes,
    required this.result,
  });

  final Uint8List previewBytes;
  final Uint8List? exportBytes;
  final LocalColorTransferResult result;
}

_LocalTransferApplication _applyLocalTransferIfNeeded({
  required StyleTransferRequest request,
  required Uint8List targetBytes,
  required Uint8List previewBytes,
  required Uint8List? exportBytes,
  required SmartMaskResult targetMasks,
}) {
  final transferRequest = request.settings.localColorTransfer;
  if (!transferRequest.enabled) {
    return _LocalTransferApplication(
      previewBytes: previewBytes,
      exportBytes: exportBytes,
      result: const LocalColorTransferResult(
        applied: false,
        compatibility: 1.0,
        warnings: <String>[],
      ),
    );
  }

  final useReference =
      transferRequest.useReferenceImage && request.referenceBytes != null;
  final sourceBytes = useReference
      ? Uint8List.fromList(request.referenceBytes!)
      : targetBytes;
  final sourceImage = decodeEditableImage(sourceBytes);
  final sourceStats = analyzeColorStatistics(sourceImage);
  final sourceScene = useReference
      ? _sceneAnalysisFromStatistics(sourceStats)
      : request.sceneAnalysis;
  final sourceMasks = _buildSmartMaskResult(
    image: sourceImage,
    scene: sourceScene,
    protectionMask: buildProtectionMaskBundle(sourceImage),
  );
  final engine = const LocalColorTransferEngine();
  final previewCanvas = decodeEditableImage(previewBytes);
  final previewResult = engine.apply(
    canvas: previewCanvas,
    sourceImage: sourceImage,
    request: transferRequest,
    sourceMasks: sourceMasks,
    targetMasks: targetMasks,
  );

  Uint8List? exportOutput;
  LocalColorTransferResult aggregate = previewResult;
  if (exportBytes != null) {
    final exportCanvas = decodeEditableImage(exportBytes);
    final exportResult = engine.apply(
      canvas: exportCanvas,
      sourceImage: sourceImage,
      request: transferRequest,
      sourceMasks: sourceMasks,
      targetMasks: targetMasks,
    );
    exportOutput = Uint8List.fromList(img.encodePng(exportCanvas));
    aggregate = LocalColorTransferResult(
      applied: previewResult.applied || exportResult.applied,
      compatibility:
          (previewResult.compatibility + exportResult.compatibility) / 2,
      warnings: <String>{
        ...previewResult.warnings,
        ...exportResult.warnings,
      }.toList(),
    );
  }

  return _LocalTransferApplication(
    previewBytes: Uint8List.fromList(img.encodeJpg(previewCanvas, quality: 90)),
    exportBytes: exportOutput ?? exportBytes,
    result: aggregate,
  );
}

SmartMaskResult _buildSmartMaskResult({
  required img.Image image,
  required SceneAnalysis scene,
  required ProtectionMaskBundle protectionMask,
}) {
  return const SmartMaskService().build(
    image: image,
    scene: scene,
    protectionMask: protectionMask,
  );
}

SceneAnalysis _sceneAnalysisFromStatistics(ColorStatistics stats) {
  final inferredType = inferReferenceSceneType(stats);
  return SceneAnalysis(
    sceneType: inferredType,
    faceCount: inferredType == 'portrait' ? 1 : 0,
    hasSkin: stats.skinLikelihood > 0.045,
    hasHair: stats.skinLikelihood > 0.028,
    hasSky: stats.skyLikelihood > 0.05 || inferredType == 'landscape',
    hasForegroundSubject:
        inferredType == 'portrait' || inferredType == 'wildlife',
    averageBrightness: stats.averageLuminance,
    contrast: stats.contrast,
    saturation: stats.averageSaturation,
    warmth: stats.temperature,
    segmentationConfidence: 0.56,
  );
}

List<String> _buildCompatibilityReasons({
  required AdaptiveStyleDecision decision,
  required SceneAnalysis scene,
  required StyleProfile sourceProfile,
}) {
  return <String>[
    'Scene routed as ${decision.sceneRoute.replaceAll('_', ' ')}.',
    if (sourceProfile.sceneType == scene.sceneType)
      'Reference and target scenes align closely.'
    else
      'Reference scene (${sourceProfile.sceneType}) was adapted to ${scene.sceneType}.',
    if (decision.safeModeTriggered)
      'Safe mode limited aggressive tone and color shifts.',
    if (decision.appliedStrength < sourceProfile.behavior.baseStrength)
      'Strength was reduced to preserve realism.',
  ];
}

List<String> _buildMoodTags({
  required StyleProfile profile,
  required SceneAnalysis scene,
  required AdaptiveStyleDecision decision,
}) {
  return <String>{
    profile.sceneType,
    scene.sceneType,
    if (profile.behavior.naturalMode) 'natural',
    if (scene.sceneType == 'night') 'moody',
    if (scene.sceneType == 'architecture') 'architectural',
    if (profile.color.temperature > 0.08) 'warm',
    if (profile.color.temperature < -0.08) 'cool',
    if (profile.detail.bloom > 0.3) 'cinematic glow',
    if (decision.safeModeTriggered) 'protected',
  }.where((value) => value.isNotEmpty).toList();
}

String _buildSuggestedMode({
  required SceneAnalysis scene,
  required AdaptiveStyleDecision decision,
  required StyleTransferRequest request,
}) {
  if (request.settings.operatingMode.name == 'architect' ||
      scene.sceneType == 'architecture') {
    return 'architect';
  }
  if (request.settings.experienceMode.name == 'pro' ||
      request.styleBlendProfile != null ||
      request.settings.localColorTransfer.enabled) {
    return 'pro';
  }
  return decision.safeModeTriggered ? 'simple_safe' : 'simple';
}

double computeAdaptiveStrength({
  required double requestedStrength,
  required double compatibility,
  required SceneAnalysis scene,
  required ColorStatistics targetStats,
  required bool adaptiveStrengthEnabled,
}) {
  if (!adaptiveStrengthEnabled) {
    return requestedStrength.clamp(0.2, 1.0);
  }

  var multiplier = 0.72 + (compatibility * 0.42);
  if (scene.faceCount > 0) {
    multiplier -= 0.08;
  }
  if (targetStats.averageSaturation > 0.58) {
    multiplier -= 0.06;
  }
  if (targetStats.contrast > 0.32) {
    multiplier -= 0.05;
  }
  if (scene.sceneType == 'moody') {
    multiplier += 0.03;
  }
  return (requestedStrength * multiplier).clamp(0.28, 0.92);
}

StyleProfile buildStyleProfileFromStatistics({
  required ColorStatistics stats,
  required String name,
}) {
  final tone = ToneProfile(
    exposure: clampSigned((stats.averageLuminance - 0.5) * 0.55, min: -0.24, max: 0.24),
    contrast: clampSigned((stats.contrast - 0.2) * 2.1, min: -0.22, max: 0.34),
    highlights: clampSigned((0.2 - stats.brightPixelRatio) * 0.45, min: -0.18, max: 0.18),
    shadows: clampSigned((stats.darkPixelRatio - 0.16) * 0.45, min: -0.16, max: 0.18),
    blacks: clampSigned((stats.darkPixelRatio - 0.2) * 0.25, min: -0.12, max: 0.12),
    whites: clampSigned((stats.brightPixelRatio - 0.18) * 0.25, min: -0.12, max: 0.14),
    fade: clampUnit((0.24 - stats.contrast) * 0.75),
  );
  final color = ColorProfile(
    temperature: clampSigned(stats.temperature * 0.75, min: -0.28, max: 0.28),
    tint: clampSigned(_paletteTint(stats.palette), min: -0.18, max: 0.18),
    saturation: clampSigned((stats.averageSaturation - 0.34) * 0.9, min: -0.2, max: 0.26),
    vibrance: clampSigned(
      ((stats.averageSaturation - 0.24) * 0.55) + (stats.edgeEnergy * 0.2),
      min: -0.06,
      max: 0.32,
    ),
    palette: stats.palette,
  );
  final detail = DetailProfile(
    sharpness: clampUnit(stats.edgeEnergy * 1.2),
    clarity: clampUnit((stats.edgeEnergy - 0.08) * 1.6),
    texture: clampUnit((stats.contrast * 1.6) + (stats.edgeEnergy * 0.6)),
    grain: clampUnit((stats.darkPixelRatio - 0.12) * 0.5),
    vignette: clampUnit(stats.darkPixelRatio * 0.7),
    bloom: clampUnit(stats.brightPixelRatio * 0.8),
  );
  final sceneType = inferReferenceSceneType(stats);
  return StyleProfile(
    id: 'style-${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
    name: name.replaceAll(RegExp(r'\.[A-Za-z0-9]+$'), ''),
    confidence: (0.54 + (stats.contrast * 0.55) + (stats.averageSaturation * 0.16))
        .clamp(0.0, 0.99),
    sceneType: sceneType,
    tone: tone,
    color: color,
    hsl: buildHslProfile(
      palette: stats.palette,
      temperature: color.temperature,
      saturation: color.saturation,
    ),
    curves: buildCurveProfile(tone: tone, color: color),
    detail: detail,
    local: LocalRules(
      skinProtect: stats.skinLikelihood > 0.035,
      faceExposureGuard: stats.skinLikelihood > 0.035,
      skyAdjust: stats.skyLikelihood > 0.05,
      backgroundAdjust: true,
    ),
    behavior: StyleBehavior.adaptive(sceneType: sceneType),
  );
}

String inferReferenceSceneType(ColorStatistics stats) {
  if (stats.skinLikelihood > 0.05) {
    return 'portrait';
  }
  if (stats.averageLuminance < 0.34 &&
      (stats.darkPixelRatio > 0.42 || stats.brightPixelRatio > 0.08)) {
    return 'night';
  }
  if (stats.warmOrganicLikelihood > 0.12 &&
      stats.edgeEnergy > 0.18 &&
      stats.averageSaturation >= 0.18 &&
      stats.averageSaturation <= 0.46) {
    return 'wildlife';
  }
  if (stats.neutralLikelihood > 0.22 &&
      stats.averageLuminance > 0.48 &&
      stats.edgeEnergy < 0.2) {
    return 'product';
  }
  if (stats.edgeEnergy > 0.22 &&
      stats.averageSaturation < 0.3 &&
      stats.neutralLikelihood > 0.16) {
    return 'architecture';
  }
  if (stats.skyLikelihood > 0.06 && stats.averageLuminance > 0.58) {
    return 'landscape';
  }
  return 'editorial';
}

double computeStyleCompatibility({
  required StyleProfile profile,
  required SceneAnalysis scene,
  required ColorStatistics targetStats,
}) {
  var score = 0.46;
  if (profile.sceneType == scene.sceneType) {
    score += 0.2;
  } else if ((profile.sceneType == 'portrait' && scene.faceCount > 0) ||
      (profile.sceneType == 'landscape' && scene.hasSky)) {
    score += 0.12;
  }

  final contrastAffinity =
      1 - (profile.tone.contrast - ((targetStats.contrast - 0.2) * 1.8)).abs();
  final saturationAffinity = 1 -
      (profile.color.saturation - ((targetStats.averageSaturation - 0.34) * 1.2)).abs();
  final brightnessAffinity =
      1 - (profile.tone.exposure - ((targetStats.averageLuminance - 0.5) * 0.6)).abs();
  final histogramAffinity = 1 -
      _meanHistogramDistance(
        targetStats.luminanceHistogram,
        targetStats.saturationHistogram,
      );

  score += clampUnit(contrastAffinity) * 0.12;
  score += clampUnit(saturationAffinity) * 0.12;
  score += clampUnit(brightnessAffinity) * 0.1;
  score += clampUnit(histogramAffinity) * 0.08;
  if (scene.faceCount > 0 && profile.local.skinProtect) {
    score += 0.05;
  }
  return score.clamp(0.0, 0.99);
}

StyleProfile buildMappedStyleProfile({
  required StyleProfile sourceProfile,
  required ColorStatistics targetStats,
  required SceneAnalysis scene,
  required StyleTransferSettings settings,
  required AdaptiveStyleDecision decision,
  required bool usedFallback,
}) {
  final behavior = sourceProfile.behavior;
  final mapping = settings.sceneFit ? (0.68 + (decision.compatibility * 0.28)) : 1.0;
  final strength = decision.appliedStrength * mapping;
  final toneStrength = strength * decision.toneScale;
  final colorStrength = strength * decision.colorScale;
  final exposureBalance = (0.5 - targetStats.averageLuminance) * 0.16;
  final contrastBalance = (0.24 - targetStats.contrast) * 0.28;
  final safeBlend = decision.safeModeTriggered ? 0.84 : 1.0;
  final fallbackBlend = usedFallback ? 0.78 : 1.0;
  final naturalBlend = behavior.naturalMode ? 0.86 : 1.0;
  final routeToneBoost = switch (decision.sceneRoute) {
    'portrait_protect' => 0.94,
    'wildlife_detail' => 0.98,
    'night_balance' => 1.02,
    'product_clean' => 0.92,
    'architecture_dynamic' => 1.04,
    'landscape_depth' => 1.0,
    _ => 1.0,
  };
  final routeDetailBoost = switch (decision.sceneRoute) {
    'portrait_protect' => 0.96,
    'wildlife_detail' => 1.08,
    'night_balance' => 1.0,
    'product_clean' => 0.98,
    'architecture_dynamic' => 1.02,
    'landscape_depth' => 1.02,
    _ => 1.0,
  };

  final tone = sourceProfile.tone.copyWith(
    exposure: clampSigned(
      ((sourceProfile.tone.exposure * toneStrength) + exposureBalance) *
          safeBlend *
          routeToneBoost,
      min: -0.34,
      max: 0.34,
    ),
    contrast: clampSigned(
      ((sourceProfile.tone.contrast * toneStrength * naturalBlend) + contrastBalance) *
          fallbackBlend *
          routeToneBoost,
      min: -0.28,
      max: 0.38,
    ),
    highlights: clampSigned(
      sourceProfile.tone.highlights * toneStrength * safeBlend * naturalBlend,
      min: -0.2,
      max: 0.18,
    ),
    shadows: clampSigned(
      sourceProfile.tone.shadows * toneStrength * safeBlend,
      min: -0.18,
      max: 0.22,
    ),
    blacks: clampSigned(
      sourceProfile.tone.blacks * toneStrength * safeBlend,
      min: -0.14,
      max: 0.16,
    ),
    whites: clampSigned(
      sourceProfile.tone.whites * toneStrength * fallbackBlend,
      min: -0.14,
      max: 0.18,
    ),
    fade: clampUnit(sourceProfile.tone.fade * (0.68 + (0.24 * strength))),
  );

  final color = sourceProfile.color.copyWith(
    temperature: clampSigned(
      ((sourceProfile.color.temperature * colorStrength) - (scene.warmth * 0.08)) *
          safeBlend,
      min: -0.24,
      max: 0.24,
    ),
    tint: clampSigned(
      sourceProfile.color.tint * colorStrength * safeBlend,
      min: -0.16,
      max: 0.16,
    ),
    saturation: clampSigned(
      ((sourceProfile.color.saturation * colorStrength * safeBlend * naturalBlend) +
              ((0.36 - targetStats.averageSaturation) * 0.12)) *
          fallbackBlend,
      min: -0.16,
      max: 0.24,
    ),
    vibrance: clampSigned(
      (sourceProfile.color.vibrance * (0.62 + (decision.compatibility * 0.28)) * naturalBlend) +
          (settings.glowBoost * 0.04),
      min: -0.04,
      max: 0.34,
    ),
  );

  final detail = sourceProfile.detail.copyWith(
    sharpness: clampUnit(
      sourceProfile.detail.sharpness * (0.68 + strength * 0.24) * decision.detailScale,
    ),
    clarity: clampUnit(
      ((sourceProfile.detail.clarity * (0.58 + decision.compatibility * 0.32)) +
              ((scene.contrast < 0.18) ? 0.04 : 0)) *
          fallbackBlend *
          routeDetailBoost,
    ),
    texture: clampUnit(
      sourceProfile.detail.texture *
          (0.6 + strength * 0.28) *
          decision.detailScale *
          routeDetailBoost,
    ),
    grain: clampUnit(sourceProfile.detail.grain * (scene.averageBrightness < 0.4 ? 0.9 : 0.58)),
    vignette: clampUnit(sourceProfile.detail.vignette * (scene.hasForegroundSubject ? 0.94 : 0.68)),
    bloom: clampUnit(sourceProfile.detail.bloom + (settings.glowBoost * 0.16)),
  );

  final local = sourceProfile.local.copyWith(
    skinProtect: settings.skinProtect || sourceProfile.local.skinProtect,
    faceExposureGuard: scene.faceCount > 0 || sourceProfile.local.faceExposureGuard,
    skyAdjust: scene.hasSky && sourceProfile.local.skyAdjust,
    backgroundAdjust: true,
  );

  return sourceProfile.copyWith(
    confidence: decision.compatibility,
    tone: tone,
    color: color,
    hsl: _scaleHslProfile(
      sourceProfile.hsl,
      decision.hslScale * strength,
    ),
    detail: detail,
    curves: buildCurveProfile(
      tone: tone,
      color: color,
      baseCurves: sourceProfile.curves,
      aggression: decision.curveScale * strength,
    ),
    local: local,
  );
}

HslProfile buildHslProfile({
  required List<Color> palette,
  required double temperature,
  required double saturation,
}) {
  final avgHue = palette.isEmpty
      ? 200.0
      : palette.map((color) => HSLColor.fromColor(color).hue).reduce((a, b) => a + b) /
          palette.length;
  final coolBias = avgHue > 180 ? 1.0 : -1.0;
  return HslProfile(
    red: HslChannel(h: 0, s: saturation * 0.05, l: 0),
    orange: HslChannel(h: temperature * 4, s: saturation * 0.08, l: temperature * 0.02),
    yellow: HslChannel(h: temperature * 3, s: saturation * 0.04, l: 0.01),
    green: HslChannel(h: 0, s: -0.02, l: 0),
    aqua: HslChannel(h: coolBias * -2, s: saturation * 0.03, l: 0.01),
    blue: HslChannel(h: temperature * -5, s: saturation * 0.08, l: coolBias * 0.02),
    purple: HslChannel(h: coolBias * -2, s: saturation * 0.04, l: 0),
    magenta: HslChannel(h: temperature * 2, s: saturation * 0.05, l: 0.01),
  );
}

CurveProfile buildCurveProfile({
  required ToneProfile tone,
  required ColorProfile color,
  CurveProfile? baseCurves,
  double aggression = 1.0,
}) {
  final master = <double>[
    0,
    clampUnit(0.25 + (tone.shadows * 0.16) - (tone.fade * 0.08)),
    clampUnit(0.5 + (tone.exposure * 0.2) + (tone.contrast * 0.05)),
    clampUnit(0.75 + (tone.highlights * 0.08) + (tone.whites * 0.06)),
    1,
  ];
  final generated = CurveProfile(
    master: master,
    red: <double>[
      0,
      clampUnit(master[1] + (color.temperature * 0.05)),
      clampUnit(master[2] + (color.temperature * 0.08)),
      clampUnit(master[3] + (color.temperature * 0.05)),
      1,
    ],
    green: <double>[
      0,
      clampUnit(master[1] + (color.tint * 0.04)),
      master[2],
      clampUnit(master[3] + (color.tint * 0.04)),
      1,
    ],
    blue: <double>[
      0,
      clampUnit(master[1] - (color.temperature * 0.05)),
      clampUnit(master[2] - (color.temperature * 0.08)),
      clampUnit(master[3] - (color.temperature * 0.05)),
      1,
    ],
  );
  if (baseCurves == null) {
    return generated;
  }
  final blend = clampUnit(aggression);
  return CurveProfile(
    master: _blendCurve(baseCurves.master, generated.master, blend),
    red: _blendCurve(baseCurves.red, generated.red, blend),
    green: _blendCurve(baseCurves.green, generated.green, blend),
    blue: _blendCurve(baseCurves.blue, generated.blue, blend),
  );
}

double _paletteTint(List<Color> palette) {
  if (palette.isEmpty) {
    return 0;
  }
  final avg = palette
          .map((color) => color.g - ((color.r + color.b) / 2))
          .reduce((a, b) => a + b) /
      palette.length;
  return avg * 0.6;
}

HslProfile _scaleHslProfile(HslProfile profile, double scale) {
  final blend = clampUnit(scale);
  HslChannel blendChannel(HslChannel channel) => HslChannel(
        h: channel.h * blend,
        s: channel.s * blend,
        l: channel.l * blend,
      );

  return HslProfile(
    red: blendChannel(profile.red),
    orange: blendChannel(profile.orange),
    yellow: blendChannel(profile.yellow),
    green: blendChannel(profile.green),
    aqua: blendChannel(profile.aqua),
    blue: blendChannel(profile.blue),
    purple: blendChannel(profile.purple),
    magenta: blendChannel(profile.magenta),
  );
}

List<double> _blendCurve(List<double> base, List<double> generated, double blend) {
  final length = math.min(base.length, generated.length);
  return List<double>.generate(
    length,
    (index) => lerpDoubleSafe(base[index], generated[index], blend),
  );
}

double _meanHistogramDistance(List<double> a, List<double> b) {
  if (a.isEmpty || b.isEmpty) {
    return 0.4;
  }
  final shared = math.min(a.length, b.length);
  var distance = 0.0;
  for (var index = 0; index < shared; index++) {
    distance += (a[index] - b[index]).abs();
  }
  return (distance / shared).clamp(0.0, 1.0);
}
*/
