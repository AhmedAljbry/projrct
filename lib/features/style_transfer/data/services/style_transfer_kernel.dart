import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'package:untitled2/features/enhancement/data/viral_enhancement_engine.dart';
import 'package:untitled2/features/face_protection/data/face_protection_engine.dart';
import 'package:untitled2/features/scene_analysis/data/scene_analysis_engine.dart';
import 'package:untitled2/features/style_transfer/data/services/adaptive_mapping_engine.dart';
import 'package:untitled2/features/style_transfer/data/services/style_extraction_engine.dart';

class StyleTransferKernel {
  const StyleTransferKernel();

  Map<String, dynamic> extractStyle(Map<String, dynamic> payload) {
    final referenceBytes = _toBytes(payload['bytes']);
    final image = _decode(referenceBytes);
    final analysis = _normalizeAnalysis(
      const SceneAnalysisEngine().analyze(
        image,
        maxDimension: _asInt(payload['analysisMaxDimension'], 320),
      ),
    );
    return const StyleExtractionEngine().extract(
      stats: analysis['statistics'] as Map<String, dynamic>,
      scene: analysis['scene'] as Map<String, dynamic>,
      name: payload['name']?.toString() ?? 'Reference Style',
      id: 'style-${_fastHash(referenceBytes)}',
    );
  }

  Map<String, dynamic> analyzeScene(Map<String, dynamic> payload) {
    final bytes = _toBytes(payload['bytes']);
    final image = _decode(bytes);
    final analysis = const SceneAnalysisEngine().analyze(
      image,
      maxDimension: _asInt(payload['analysisMaxDimension'], 320),
    );
    return _normalizeAnalysis(analysis);
  }

  Map<String, dynamic> applyStyle(Map<String, dynamic> payload) {
    final settings = Map<String, dynamic>.from(
      payload['settings'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
    final sourceProfile = Map<String, dynamic>.from(
      payload['styleProfile'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );
    final highQuality = _bool(payload['highQuality'], false);
    final fallbackMode = _bool(payload['fallbackMode'], false);
    final targetBytes = _toBytes(payload['targetBytes']);
    final referenceBytes = _toBytes(payload['referenceBytes']);
    final analysisMaxDimension = _asInt(settings['analysisMaxDimension'], 288);
    final previewMaxDimension = _previewDimension(settings, fallbackMode);
    final exportMaxDimension = _exportDimension(settings, fallbackMode);
    final previewQuality = _jpegQuality(
      settings['previewJpegQuality'],
      fallbackMode ? 82 : 89,
    );
    final exportQuality = _jpegQuality(
      settings['exportJpegQuality'],
      fallbackMode ? 90 : 95,
    );
    final seed = _fastHash(targetBytes) ^ _fastHash(referenceBytes);

    final originalImage = _decode(targetBytes);
    final providedAnalysis =
        _normalizedAnalysisFromPayload(payload['targetAnalysis']);
    final targetAnalysis = providedAnalysis ??
        _normalizeAnalysis(
          const SceneAnalysisEngine().analyze(
            originalImage,
            maxDimension: analysisMaxDimension,
          ),
        );
    final usedCachedAnalysis = providedAnalysis != null;

    final mapped = const AdaptiveMappingEngine().mapProfile(
      sourceProfile: sourceProfile,
      targetStats: targetAnalysis['statistics'] as Map<String, dynamic>,
      scene: targetAnalysis['scene'] as Map<String, dynamic>,
      settings: settings,
    );

    final stabilized = _stabilizeMappedProfile(
      Map<String, dynamic>.from(
        mapped['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      compatibility: _asDouble(mapped['compatibility'], 0.52),
      sceneFit: _bool(settings['sceneFit'], true),
      naturalMode: _bool(settings['naturalMode'], true),
      sceneType: (targetAnalysis['scene'] as Map<String, dynamic>)['sceneType']
              ?.toString() ??
          'editorial',
      faceCount: ((targetAnalysis['scene'] as Map<String, dynamic>)['faceCount']
                  as num?)
              ?.toInt() ??
          0,
      fallbackMode: fallbackMode,
    );
    final compatibility = _asDouble(mapped['compatibility'], 0.52);
    final appliedStrength = (_asDouble(mapped['appliedStrength'], 0.72) *
            _asDouble(stabilized['strengthScale'], 1))
        .clamp(0.22, 0.96)
        .toDouble();
    final stabilizedProfile = Map<String, dynamic>.from(
      stabilized['profile'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );
    stabilizedProfile['confidence'] = compatibility;

    final enhancement = const ViralEnhancementEngine().build(
      profile: stabilizedProfile,
      scene: targetAnalysis['scene'] as Map<String, dynamic>,
      settings: settings,
    );
    final tunedEnhancement = _tuneEnhancementRecipe(
      enhancement,
      compatibility: compatibility,
      fallbackMode: fallbackMode,
      naturalMode: _bool(settings['naturalMode'], true),
    );

    final previewWatch = Stopwatch()..start();
    final previewSource = _resizeDown(originalImage, previewMaxDimension);
    final previewImage = _renderStyledImage(
      source: previewSource,
      analysis: targetAnalysis,
      profile: stabilizedProfile,
      settings: settings,
      enhancement: tunedEnhancement,
      compatibility: compatibility,
      appliedStrength: appliedStrength,
      fallbackMode: fallbackMode,
      seed: seed,
    );
    final watermarkApplied =
        _applyWatermarkIfNeeded(previewImage, settings: settings);
    final previewBytes = img.encodeJpg(previewImage, quality: previewQuality);
    previewWatch.stop();

    Uint8List? exportBytes;
    var exportRenderMs = 0;
    if (highQuality) {
      final exportWatch = Stopwatch()..start();
      final exportSource = _resizeDown(originalImage, exportMaxDimension);
      final exportImage = _renderStyledImage(
        source: exportSource,
        analysis: targetAnalysis,
        profile: stabilizedProfile,
        settings: settings,
        enhancement: tunedEnhancement,
        compatibility: compatibility,
        appliedStrength: appliedStrength,
        fallbackMode: fallbackMode,
        seed: seed ^ 0x9E3779B9,
      );
      _applyWatermarkIfNeeded(exportImage, settings: settings);
      exportBytes = img.encodeJpg(exportImage, quality: exportQuality);
      exportWatch.stop();
      exportRenderMs = exportWatch.elapsedMilliseconds;
    }

    final processedStats = _normalizeAnalysis(
      const SceneAnalysisEngine().analyze(
        previewImage,
        maxDimension: math.min(240, analysisMaxDimension),
      ),
    );

    final safetyReport = const FaceProtectionEngine().buildReport(
      originalStats: targetAnalysis['statistics'] as Map<String, dynamic>,
      processedStats: processedStats['statistics'] as Map<String, dynamic>,
      scene: targetAnalysis['scene'] as Map<String, dynamic>,
      settings: settings,
    );

    final warnings = _buildWarnings(
      compatibility: compatibility,
      safetyReport: safetyReport,
      fallbackMode: fallbackMode,
      watermarkApplied: watermarkApplied,
      targetStats: targetAnalysis['statistics'] as Map<String, dynamic>,
      processedStats: processedStats['statistics'] as Map<String, dynamic>,
    );
    final viralScore = (_asDouble(mapped['viralScore'], 0.62) +
            (_asDouble(tunedEnhancement['colorPop']) * 0.16) +
            (_asDouble(tunedEnhancement['toneCurveStrength']) * 0.12))
        .clamp(0.0, 0.99)
        .toDouble();

    return <String, dynamic>{
      'previewBytes': TransferableTypedData.fromList(<Uint8List>[previewBytes]),
      'exportBytes': exportBytes == null
          ? null
          : TransferableTypedData.fromList(<Uint8List>[exportBytes]),
      'appliedProfile': stabilizedProfile,
      'sceneAnalysis': targetAnalysis,
      'safetyReport': safetyReport,
      'compatibility': compatibility,
      'appliedStrength': appliedStrength,
      'previewRenderMs': previewWatch.elapsedMilliseconds,
      'exportRenderMs': exportRenderMs,
      'exportReady': highQuality && exportBytes != null,
      'warnings': warnings,
      'viralScore': viralScore,
      'usedCachedAnalysis': usedCachedAnalysis,
      'usedFallback': fallbackMode,
      'watermarkApplied': watermarkApplied,
    };
  }
}

Map<String, dynamic> _normalizeAnalysis(Map<String, dynamic> raw) {
  if (raw.containsKey('scene') && raw.containsKey('statistics')) {
    return <String, dynamic>{
      'scene': Map<String, dynamic>.from(
        raw['scene'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      'faces': List<dynamic>.from(
          raw['faces'] as List<dynamic>? ?? const <dynamic>[]),
      'skinMask': Map<String, dynamic>.from(
        raw['skinMask'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      'neutralMask': Map<String, dynamic>.from(
        raw['neutralMask'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      'hairMask': Map<String, dynamic>.from(
        raw['hairMask'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      'backgroundMask': Map<String, dynamic>.from(
        raw['backgroundMask'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      'skyMask': Map<String, dynamic>.from(
        raw['skyMask'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      'foregroundMask': Map<String, dynamic>.from(
        raw['foregroundMask'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      'statistics': Map<String, dynamic>.from(
        raw['statistics'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    };
  }

  final analysis = Map<String, dynamic>.from(
    raw['analysis'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  );
  return <String, dynamic>{
    ...analysis,
    'statistics': Map<String, dynamic>.from(
      raw['stats'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    ),
  };
}

Map<String, dynamic>? _normalizedAnalysisFromPayload(dynamic value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }
  return _normalizeAnalysis(value);
}

Map<String, dynamic> _stabilizeMappedProfile(
  Map<String, dynamic> source, {
  required double compatibility,
  required bool sceneFit,
  required bool naturalMode,
  required String sceneType,
  required int faceCount,
  required bool fallbackMode,
}) {
  var strengthScale = fallbackMode ? 0.86 : 1.0;
  if (sceneFit) {
    strengthScale *= (0.78 + (compatibility * 0.22));
  }
  if (naturalMode) {
    strengthScale *= 0.92;
  }
  if (faceCount > 0) {
    strengthScale *= 0.96;
  }
  if (sceneType == 'wildlife' || sceneType == 'product') {
    strengthScale *= 0.94;
  }
  strengthScale = strengthScale.clamp(0.68, 1.0).toDouble();

  final profile = Map<String, dynamic>.from(source);
  profile['tone'] = _scaleSignedMap(
    profile['tone'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    keys: const <String>[
      'exposure',
      'contrast',
      'highlights',
      'shadows',
      'blacks',
      'whites',
    ],
    unsignedKeys: const <String>['fade'],
    scale: strengthScale,
  );
  profile['color'] = _scaleSignedMap(
    profile['color'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    keys: const <String>['temperature', 'tint', 'saturation', 'vibrance'],
    preserve: const <String>['palette'],
    scale: strengthScale,
  );
  profile['detail'] = _scaleUnsignedMap(
    profile['detail'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    keys: const <String>[
      'sharpness',
      'clarity',
      'texture',
      'grain',
      'vignette',
      'bloom',
    ],
    scale: (sceneType == 'wildlife' ? 0.82 : 0.74) + (strengthScale * 0.22),
  );
  profile['hsl'] = _scaleHslProfile(
    profile['hsl'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    strengthScale,
  );
  profile['curves'] = _blendCurvesToIdentity(
    profile['curves'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    strengthScale,
  );
  return <String, dynamic>{
    'profile': profile,
    'strengthScale': strengthScale,
  };
}

Map<String, dynamic> _scaleSignedMap(
  Map<String, dynamic> source, {
  required List<String> keys,
  List<String> unsignedKeys = const <String>[],
  List<String> preserve = const <String>[],
  required double scale,
}) {
  final output = Map<String, dynamic>.from(source);
  for (final key in keys) {
    output[key] = _asDouble(output[key]) * scale;
  }
  for (final key in unsignedKeys) {
    output[key] = _clamp01(_asDouble(output[key]) * scale);
  }
  for (final key in preserve) {
    output[key] = source[key];
  }
  return output;
}

Map<String, dynamic> _scaleUnsignedMap(
  Map<String, dynamic> source, {
  required List<String> keys,
  required double scale,
}) {
  final output = Map<String, dynamic>.from(source);
  for (final key in keys) {
    output[key] = _clamp01(_asDouble(output[key]) * scale);
  }
  return output;
}

Map<String, dynamic> _scaleHslProfile(
  Map<String, dynamic> source,
  double scale,
) {
  final output = <String, dynamic>{};
  for (final entry in source.entries) {
    final channel = Map<String, dynamic>.from(
      entry.value as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
    output[entry.key] = <String, dynamic>{
      'h': _asDouble(channel['h']) * scale,
      's': _asDouble(channel['s']) * scale,
      'l': _asDouble(channel['l']) * scale,
    };
  }
  return output;
}

Map<String, dynamic> _blendCurvesToIdentity(
  Map<String, dynamic> source,
  double scale,
) {
  List<double> blendCurve(String key) {
    final curve = _curveFromDynamic(source[key]);
    if (curve.isEmpty) {
      return const <double>[0, 0.25, 0.5, 0.75, 1];
    }
    return List<double>.generate(curve.length, (index) {
      final identity = curve.length == 1 ? 0.0 : index / (curve.length - 1);
      return _mix(identity, curve[index], scale);
    });
  }

  return <String, dynamic>{
    'master': blendCurve('master'),
    'red': blendCurve('red'),
    'green': blendCurve('green'),
    'blue': blendCurve('blue'),
  };
}

Map<String, dynamic> _tuneEnhancementRecipe(
  Map<String, dynamic> recipe, {
  required double compatibility,
  required bool fallbackMode,
  required bool naturalMode,
}) {
  final multiplier =
      (fallbackMode ? 0.78 : 1.0) * (0.8 + (compatibility * 0.2));
  final naturalMultiplier = naturalMode ? 0.88 : 1.0;
  return <String, dynamic>{
    ...recipe,
    'bloomStrength': _clamp01(
      _asDouble(recipe['bloomStrength']) * multiplier * naturalMultiplier,
    ),
    'microContrast': _clamp01(
      _asDouble(recipe['microContrast']) * multiplier * naturalMultiplier,
    ),
    'glow': _clamp01(
      _asDouble(recipe['glow']) * multiplier * naturalMultiplier,
    ),
    'depthLift': _clamp01(_asDouble(recipe['depthLift']) * multiplier),
    'faceLift': _clamp01(_asDouble(recipe['faceLift']) * multiplier),
    'highlightRollOff': _clamp01(
      _asDouble(recipe['highlightRollOff']) * (1.05 - compatibility * 0.1),
    ),
    'colorPop': _clamp01(
      _asDouble(recipe['colorPop']) * multiplier * naturalMultiplier,
    ),
    'toneCurveStrength':
        _clamp01(_asDouble(recipe['toneCurveStrength']) * multiplier),
    'vignette': _clamp01(_asDouble(recipe['vignette']) * multiplier),
  };
}

img.Image _renderStyledImage({
  required img.Image source,
  required Map<String, dynamic> analysis,
  required Map<String, dynamic> profile,
  required Map<String, dynamic> settings,
  required Map<String, dynamic> enhancement,
  required double compatibility,
  required double appliedStrength,
  required bool fallbackMode,
  required int seed,
}) {
  final image = img.Image.from(source);
  // Style color is reconstructed first, then texture and tonal safety are
  // restored from the original frame to keep the result natural.
  _applyPixelTransfer(
    image,
    original: source,
    analysis: analysis,
    profile: profile,
    settings: settings,
    enhancement: enhancement,
    compatibility: compatibility,
    appliedStrength: appliedStrength,
  );
  _applyMicroContrast(
    image,
    analysis: analysis,
    strength: _asDouble(enhancement['microContrast']),
  );
  _applyDetailRecovery(
    image,
    original: source,
    analysis: analysis,
    strength: (_asDouble(settings['detailRecovery'], 0.3) +
            (_asDouble(enhancement['microContrast']) * 0.22))
        .clamp(0.0, 1.0)
        .toDouble(),
    naturalMode: _bool(settings['naturalMode'], true),
  );
  if (!fallbackMode) {
    _applyBloom(
      image,
      strength: _asDouble(enhancement['bloomStrength']),
      glow: _asDouble(enhancement['glow']),
    );
  }
  _applyVignette(
    image,
    analysis: analysis,
    strength: _asDouble(enhancement['vignette']),
    depthLift: _asDouble(enhancement['depthLift']),
  );
  _applyGrain(
    image,
    analysis: analysis,
    amount: _asDouble(
      (profile['detail'] as Map<String, dynamic>? ??
          const <String, dynamic>{})['grain'],
    ),
    seed: seed,
  );
  _applySafetyPass(
    image,
    original: source,
    analysis: analysis,
    settings: settings,
  );
  return image;
}

// Luminance is tone-mapped separately from chroma styling so the transfer can
// feel premium without flattening the original lighting structure.
void _applyPixelTransfer(
  img.Image image, {
  required img.Image original,
  required Map<String, dynamic> analysis,
  required Map<String, dynamic> profile,
  required Map<String, dynamic> settings,
  required Map<String, dynamic> enhancement,
  required double compatibility,
  required double appliedStrength,
}) {
  final scene = Map<String, dynamic>.from(
    analysis['scene'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  );
  final stats = Map<String, dynamic>.from(
    analysis['statistics'] as Map<String, dynamic>? ??
        const <String, dynamic>{},
  );
  final tone = Map<String, dynamic>.from(
    profile['tone'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  );
  final color = Map<String, dynamic>.from(
    profile['color'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  );
  final curves = Map<String, dynamic>.from(
    profile['curves'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  );
  final hslProfile = Map<String, dynamic>.from(
    profile['hsl'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  );
  final local = Map<String, dynamic>.from(
    profile['local'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  );
  final masterCurve = _curveFromDynamic(curves['master']);
  final redCurve = _curveFromDynamic(curves['red']);
  final greenCurve = _curveFromDynamic(curves['green']);
  final blueCurve = _curveFromDynamic(curves['blue']);
  final skinProtect = _bool(
          (settings['localOverrides'] as Map<String, dynamic>?)?['skinProtect'],
          true) &&
      _bool(local['skinProtect'], true);
  final naturalMode = _bool(settings['naturalMode'], true);
  final luminancePreservation =
      _asDouble(settings['luminancePreservation'], 0.84);
  final faceGuard = _bool(local['faceExposureGuard'], true);
  final neutralLimit =
      _asDouble(stats['neutralLikelihood']) > 0.16 ? 0.62 : 0.48;
  final highlightCeiling =
      (0.95 - ((1 - _asDouble(stats['highlightHeadroom'], 1)) * 0.05))
          .clamp(0.88, 0.97)
          .toDouble();
  final shadowFloor =
      (0.02 + ((1 - _asDouble(stats['shadowHeadroom'], 1)) * 0.025))
          .clamp(0.02, 0.08)
          .toDouble();

  for (var y = 0; y < image.height; y++) {
    final ny = image.height <= 1 ? 0.0 : y / (image.height - 1);
    for (var x = 0; x < image.width; x++) {
      final nx = image.width <= 1 ? 0.0 : x / (image.width - 1);
      final pixel = image.getPixel(x, y);
      final originalPixel = original.getPixel(x, y);
      final originalR = originalPixel.r.toInt();
      final originalG = originalPixel.g.toInt();
      final originalB = originalPixel.b.toInt();
      final originalRf = originalR / 255.0;
      final originalGf = originalG / 255.0;
      final originalBf = originalB / 255.0;
      final originalLuminance =
          _luminanceDouble(originalRf, originalGf, originalBf);
      final skinMask = _maskValue(analysis['skinMask'], nx, ny);
      final neutralMask = _maskValue(analysis['neutralMask'], nx, ny);
      final skyMask = _maskValue(analysis['skyMask'], nx, ny);
      final backgroundMask = _maskValue(analysis['backgroundMask'], nx, ny);
      final foregroundMask = _maskValue(analysis['foregroundMask'], nx, ny);
      final faceWeight = _faceWeight(analysis['faces'], nx, ny);
      final protectWeight = ((skinProtect ? skinMask * 0.58 : 0.0) +
              (neutralMask * neutralLimit) +
              (faceWeight * 0.22))
          .clamp(0.0, 0.88)
          .toDouble();
      final localStrength = (appliedStrength *
              (1 - protectWeight * 0.72) *
              (1 + (skyMask * 0.08) + (foregroundMask * 0.04)))
          .clamp(0.08, 1.0)
          .toDouble();

      final hsl = _rgbToHsl(originalR, originalG, originalB);
      var hue = hsl[0];
      var saturation = hsl[1];
      var lightness = hsl[2];

      final hueAdjustment = _channelDelta(hslProfile, hue, axis: 'h');
      final saturationAdjustment = _channelDelta(hslProfile, hue, axis: 's');
      final lightnessAdjustment = _channelDelta(hslProfile, hue, axis: 'l');
      final neutralProtection = 1 - (neutralMask * 0.85);
      final skinProtection = 1 - (skinMask * 0.55);

      hue = (hue +
              (hueAdjustment *
                  localStrength *
                  neutralProtection *
                  skinProtection))
          .remainder(360);
      if (hue < 0) {
        hue += 360;
      }

      final vibranceLift = _asDouble(color['vibrance']) *
          (1 - saturation) *
          0.42 *
          localStrength;
      final saturationCap =
          naturalMode ? (scene['sceneType'] == 'wildlife' ? 0.72 : 0.78) : 0.88;
      final compatibilitySaturationScale = 0.82 + (compatibility * 0.18);
      saturation = _clamp01(
        saturation +
            ((_asDouble(color['saturation']) * 0.36) +
                    (saturationAdjustment * 0.34) +
                    vibranceLift +
                    (_asDouble(enhancement['colorPop']) *
                        (0.26 + (foregroundMask * 0.2))) +
                    (_bool(local['skyAdjust'], true) ? skyMask * 0.05 : 0)) *
                neutralProtection *
                skinProtection,
      );
      saturation = math
          .min(saturation * compatibilitySaturationScale, saturationCap)
          .toDouble();

      lightness = _clamp01(
          lightness + (_asDouble(tone['exposure']) * 0.42 * localStrength));
      lightness = _clamp01(((lightness - 0.5) *
              (1 + (_asDouble(tone['contrast']) * 0.92 * localStrength))) +
          0.5);
      if (lightness > 0.52) {
        lightness += _asDouble(tone['highlights']) * 0.16 * (1 - lightness);
        lightness +=
            _asDouble(tone['whites']) * 0.08 * ((lightness - 0.52) / 0.48);
      } else {
        lightness += _asDouble(tone['shadows']) * 0.2 * (0.52 - lightness);
        lightness -=
            _asDouble(tone['blacks']) * 0.08 * ((0.52 - lightness) / 0.52);
      }
      lightness += lightnessAdjustment * 0.22 * localStrength;
      if (faceGuard && faceWeight > 0.02) {
        lightness = _clamp01(
          lightness + (_asDouble(enhancement['faceLift']) * faceWeight * 0.06),
        );
      }
      if (_bool(local['backgroundAdjust'], true) && backgroundMask > 0.05) {
        lightness = _clamp01(
          lightness -
              (_asDouble(enhancement['depthLift']) * backgroundMask * 0.05),
        );
      }
      lightness = _applyCinematicCurve(
        lightness,
        toneCurveStrength: _asDouble(enhancement['toneCurveStrength']),
        fade: _asDouble(tone['fade']),
        highlightRollOff: _asDouble(enhancement['highlightRollOff']),
      );
      final mappedLuminance = _toneMapLuminance(
        baseLuminance: originalLuminance,
        tone: tone,
        enhancement: enhancement,
        sceneType: scene['sceneType']?.toString() ?? 'editorial',
        protectWeight: protectWeight,
        naturalMode: naturalMode,
        luminancePreservation: luminancePreservation,
      );

      final rgb = _hslToRgb(hue, saturation, lightness);
      var rf = rgb[0];
      var gf = rgb[1];
      var bf = rgb[2];

      final temperatureShift = _asDouble(color['temperature']) *
          0.12 *
          localStrength *
          neutralProtection;
      final tintShift =
          _asDouble(color['tint']) * 0.08 * localStrength * neutralProtection;
      rf = _clamp01(rf + temperatureShift + (tintShift * 0.5));
      gf = _clamp01(gf + tintShift - (temperatureShift * 0.2));
      bf = _clamp01(bf - temperatureShift - (tintShift * 0.35));
      final preCurveLuminance = _luminanceDouble(rf, gf, bf);
      final preCurveScale =
          mappedLuminance / math.max(preCurveLuminance, 0.001);
      rf = _clamp01(rf * preCurveScale);
      gf = _clamp01(gf * preCurveScale);
      bf = _clamp01(bf * preCurveScale);

      rf = _curveApply(_curveApply(rf, masterCurve), redCurve);
      gf = _curveApply(_curveApply(gf, masterCurve), greenCurve);
      bf = _curveApply(_curveApply(bf, masterCurve), blueCurve);
      final styledLuminance = _luminanceDouble(rf, gf, bf);
      final luminanceScale = mappedLuminance / math.max(styledLuminance, 0.001);
      rf = _clamp01(rf * luminanceScale);
      gf = _clamp01(gf * luminanceScale);
      bf = _clamp01(bf * luminanceScale);

      final outputLuminance = _luminanceDouble(rf, gf, bf);
      if (outputLuminance > highlightCeiling) {
        final compression =
            highlightCeiling / math.max(outputLuminance, 0.0001);
        rf = _mix(originalRf, rf * compression, 0.86);
        gf = _mix(originalGf, gf * compression, 0.86);
        bf = _mix(originalBf, bf * compression, 0.86);
      } else if (outputLuminance < shadowFloor) {
        final lift = shadowFloor - outputLuminance;
        rf = _clamp01(rf + (lift * 0.7));
        gf = _clamp01(gf + (lift * 0.68));
        bf = _clamp01(bf + (lift * 0.66));
      }

      final preserveBlend = (protectWeight * 0.62) + (faceWeight * 0.1);
      if (preserveBlend > 0.01) {
        rf = _mix(rf, originalRf, preserveBlend);
        gf = _mix(gf, originalGf, preserveBlend);
        bf = _mix(bf, originalBf, preserveBlend);
      }

      image.setPixelRgba(
        x,
        y,
        (rf * 255).round().clamp(0, 255),
        (gf * 255).round().clamp(0, 255),
        (bf * 255).round().clamp(0, 255),
        pixel.a.toInt(),
      );
    }
  }
}

double _toneMapLuminance({
  required double baseLuminance,
  required Map<String, dynamic> tone,
  required Map<String, dynamic> enhancement,
  required String sceneType,
  required double protectWeight,
  required bool naturalMode,
  required double luminancePreservation,
}) {
  var value = baseLuminance;
  value = _clamp01(value + (_asDouble(tone['exposure']) * 0.18));
  value = _clamp01(
    ((value - 0.5) * (1 + (_asDouble(tone['contrast']) * 0.52))) + 0.5,
  );
  if (value < 0.5) {
    value += _asDouble(tone['shadows']) * 0.14 * (0.5 - value);
    value -= _asDouble(tone['blacks']) * 0.10 * ((0.5 - value) / 0.5);
  } else {
    value += _asDouble(tone['whites']) * 0.08 * ((value - 0.5) / 0.5);
    value += _asDouble(tone['highlights']) * 0.16 * (1 - value);
  }
  final blackPoint =
      (0.01 + (_asDouble(tone['blacks']) * 0.05)).clamp(0.0, 0.08).toDouble();
  final whitePoint = (0.995 - (_asDouble(tone['whites']) * 0.04))
      .clamp(0.88, 0.995)
      .toDouble();
  value = ((value - blackPoint) / math.max(whitePoint - blackPoint, 0.1))
      .clamp(0.0, 1.0)
      .toDouble();
  value = _applyCinematicCurve(
    value,
    toneCurveStrength: _asDouble(enhancement['toneCurveStrength']),
    fade: _asDouble(tone['fade']).clamp(0.0, naturalMode ? 0.12 : 0.18),
    highlightRollOff: _asDouble(enhancement['highlightRollOff']),
  );
  if (sceneType == 'night') {
    value = _mix(value, baseLuminance, 0.16);
  } else if (sceneType == 'portrait' || sceneType == 'wildlife') {
    value = _mix(value, baseLuminance, 0.24);
  }
  final preserveBlend = (luminancePreservation + (protectWeight * 0.18))
      .clamp(0.0, 0.96)
      .toDouble();
  return _mix(value, baseLuminance, preserveBlend);
}

// Restores fine texture from the original frame after global styling so the
// result keeps hair, fur, and edge detail without introducing halos.
void _applyDetailRecovery(
  img.Image image, {
  required img.Image original,
  required Map<String, dynamic> analysis,
  required double strength,
  required bool naturalMode,
}) {
  if (strength < 0.04 || image.width < 3 || image.height < 3) {
    return;
  }
  final amount = (naturalMode ? strength * 0.26 : strength * 0.22)
      .clamp(0.0, 0.36)
      .toDouble();
  for (var y = 1; y < image.height - 1; y++) {
    final ny = image.height <= 1 ? 0.0 : y / (image.height - 1);
    for (var x = 1; x < image.width - 1; x++) {
      final nx = image.width <= 1 ? 0.0 : x / (image.width - 1);
      final skinMask = _maskValue(analysis['skinMask'], nx, ny);
      final neutralMask = _maskValue(analysis['neutralMask'], nx, ny);
      final faceWeight = _faceWeight(analysis['faces'], nx, ny);
      final recoveryWeight =
          (1 - ((skinMask * 0.46) + (neutralMask * 0.18) + (faceWeight * 0.18)))
              .clamp(0.28, 1.0)
              .toDouble();
      final originalPixel = original.getPixel(x, y);
      final currentPixel = image.getPixel(x, y);
      final originalLuminance = _luminance(
        originalPixel.r.toInt(),
        originalPixel.g.toInt(),
        originalPixel.b.toInt(),
      );
      final currentLuminance = _luminance(
        currentPixel.r.toInt(),
        currentPixel.g.toInt(),
        currentPixel.b.toInt(),
      );
      final neighborLuminance =
          (_luminanceFromPixel(original.getPixel(x - 1, y)) +
                  _luminanceFromPixel(original.getPixel(x + 1, y)) +
                  _luminanceFromPixel(original.getPixel(x, y - 1)) +
                  _luminanceFromPixel(original.getPixel(x, y + 1))) /
              4;
      final edgeDelta = (originalLuminance - neighborLuminance) * amount;
      final clarityDelta =
          (originalLuminance - currentLuminance) * amount * recoveryWeight;
      final factor = (1 + edgeDelta + clarityDelta).clamp(0.9, 1.12).toDouble();
      image.setPixelRgba(
        x,
        y,
        (currentPixel.r * factor).round().clamp(0, 255),
        (currentPixel.g * factor).round().clamp(0, 255),
        (currentPixel.b * factor).round().clamp(0, 255),
        currentPixel.a.toInt(),
      );
    }
  }
}

// Final guardrail pass that prevents washed highlights, muddy shadows, and
// unstable neutral colors after enhancement effects are layered in.
void _applySafetyPass(
  img.Image image, {
  required img.Image original,
  required Map<String, dynamic> analysis,
  required Map<String, dynamic> settings,
}) {
  final naturalMode = _bool(settings['naturalMode'], true);
  for (var y = 0; y < image.height; y++) {
    final ny = image.height <= 1 ? 0.0 : y / (image.height - 1);
    for (var x = 0; x < image.width; x++) {
      final nx = image.width <= 1 ? 0.0 : x / (image.width - 1);
      final current = image.getPixel(x, y);
      final base = original.getPixel(x, y);
      final skinMask = _maskValue(analysis['skinMask'], nx, ny);
      final neutralMask = _maskValue(analysis['neutralMask'], nx, ny);
      final faceWeight = _faceWeight(analysis['faces'], nx, ny);
      final protect = (neutralMask * 0.62) +
          (skinMask * 0.32) +
          (faceWeight * 0.18) +
          (naturalMode ? 0.08 : 0.0);

      final currentLum = _luminanceFromPixel(current);
      final baseLum = _luminanceFromPixel(base);
      final currentHsl = _rgbToHsl(
        current.r.toInt(),
        current.g.toInt(),
        current.b.toInt(),
      );
      final baseHsl = _rgbToHsl(base.r.toInt(), base.g.toInt(), base.b.toInt());

      var blendBack = 0.0;
      if (currentLum > baseLum + 0.18) {
        blendBack += 0.28 + protect;
      } else if (currentLum < baseLum - 0.16) {
        blendBack += 0.24 + protect;
      }
      if (currentHsl[1] < (baseHsl[1] * 0.55) && baseHsl[1] > 0.14) {
        blendBack += 0.16;
      }
      if (currentHsl[1] > baseHsl[1] + 0.24) {
        blendBack += 0.12;
      }
      final channelDrift = math.max(
        (current.r - base.r).abs().toDouble() / 255.0,
        math.max(
          (current.g - base.g).abs().toDouble() / 255.0,
          (current.b - base.b).abs().toDouble() / 255.0,
        ),
      );
      if (channelDrift > 0.22 && protect > 0.16) {
        blendBack += 0.18;
      }
      blendBack = blendBack.clamp(0.0, 0.78);
      if (blendBack <= 0.01) {
        continue;
      }
      image.setPixelRgba(
        x,
        y,
        _mixInt(current.r.toInt(), base.r.toInt(), blendBack),
        _mixInt(current.g.toInt(), base.g.toInt(), blendBack),
        _mixInt(current.b.toInt(), base.b.toInt(), blendBack),
        current.a.toInt(),
      );
    }
  }
}

void _applyMicroContrast(
  img.Image image, {
  required Map<String, dynamic> analysis,
  required double strength,
}) {
  if (strength < 0.02 || image.width < 3 || image.height < 3) {
    return;
  }
  final source = img.Image.from(image);
  final amount = strength * 0.36;
  for (var y = 1; y < image.height - 1; y++) {
    final ny = image.height <= 1 ? 0.0 : y / (image.height - 1);
    for (var x = 1; x < image.width - 1; x++) {
      final nx = image.width <= 1 ? 0.0 : x / (image.width - 1);
      final protect = (_maskValue(analysis['skinMask'], nx, ny) * 0.55) +
          (_faceWeight(analysis['faces'], nx, ny) * 0.25);
      final pixel = source.getPixel(x, y);
      final neighbors = <img.Pixel>[
        source.getPixel(x - 1, y),
        source.getPixel(x + 1, y),
        source.getPixel(x, y - 1),
        source.getPixel(x, y + 1),
      ];
      final localAverage = neighbors
              .map((entry) =>
                  _luminance(entry.r.toInt(), entry.g.toInt(), entry.b.toInt()))
              .reduce((a, b) => a + b) /
          neighbors.length;
      final baseLuminance =
          _luminance(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
      final delta = (baseLuminance - localAverage) * amount * (1 - protect);
      final scale = (1 + delta).clamp(0.8, 1.18).toDouble();
      image.setPixelRgba(
        x,
        y,
        (pixel.r * scale).round().clamp(0, 255),
        (pixel.g * scale).round().clamp(0, 255),
        (pixel.b * scale).round().clamp(0, 255),
        pixel.a.toInt(),
      );
    }
  }
}

void _applyBloom(
  img.Image image, {
  required double strength,
  required double glow,
}) {
  final effectiveStrength = (strength * 0.24) + (glow * 0.12);
  if (effectiveStrength < 0.02) {
    return;
  }
  final highlights = img.Image.from(image);
  for (var y = 0; y < highlights.height; y++) {
    for (var x = 0; x < highlights.width; x++) {
      final pixel = highlights.getPixel(x, y);
      final luminance =
          _luminance(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
      final weight = ((luminance - 0.64) / 0.36).clamp(0.0, 1.0).toDouble();
      highlights.setPixelRgba(
        x,
        y,
        (pixel.r * weight).round().clamp(0, 255),
        (pixel.g * weight).round().clamp(0, 255),
        (pixel.b * weight).round().clamp(0, 255),
        (255 * weight).round().clamp(0, 255),
      );
    }
  }
  img.gaussianBlur(
    highlights,
    radius: math.max(1, (1 + (effectiveStrength * 10)).round()),
  );
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final base = image.getPixel(x, y);
      final bloom = highlights.getPixel(x, y);
      final blend = (bloom.a / 255.0) * effectiveStrength;
      image.setPixelRgba(
        x,
        y,
        _mixInt(base.r.toInt(), bloom.r.toInt(), blend),
        _mixInt(base.g.toInt(), bloom.g.toInt(), blend),
        _mixInt(base.b.toInt(), bloom.b.toInt(), blend),
        base.a.toInt(),
      );
    }
  }
}

void _applyVignette(
  img.Image image, {
  required Map<String, dynamic> analysis,
  required double strength,
  required double depthLift,
}) {
  if (strength < 0.02 && depthLift < 0.02) {
    return;
  }
  final vignetteStrength = (strength * 0.28) + (depthLift * 0.12);
  for (var y = 0; y < image.height; y++) {
    final ny = image.height <= 1 ? 0.0 : y / (image.height - 1);
    for (var x = 0; x < image.width; x++) {
      final nx = image.width <= 1 ? 0.0 : x / (image.width - 1);
      final dx = nx - 0.5;
      final dy = ny - 0.48;
      final radius = math.sqrt((dx * dx) + (dy * dy));
      final edgeWeight = ((radius - 0.32) / 0.4).clamp(0.0, 1.0).toDouble();
      final subjectProtection =
          (_maskValue(analysis['foregroundMask'], nx, ny) * 0.26) +
              (_faceWeight(analysis['faces'], nx, ny) * 0.3);
      final darken = vignetteStrength * edgeWeight * (1 - subjectProtection);
      if (darken < 0.01) {
        continue;
      }
      final pixel = image.getPixel(x, y);
      final factor = (1 - darken).clamp(0.72, 1.0).toDouble();
      image.setPixelRgba(
        x,
        y,
        (pixel.r * factor).round().clamp(0, 255),
        (pixel.g * factor).round().clamp(0, 255),
        (pixel.b * factor).round().clamp(0, 255),
        pixel.a.toInt(),
      );
    }
  }
}

void _applyGrain(
  img.Image image, {
  required Map<String, dynamic> analysis,
  required double amount,
  required int seed,
}) {
  final effectiveAmount = amount * 0.06;
  if (effectiveAmount < 0.004) {
    return;
  }
  for (var y = 0; y < image.height; y++) {
    final ny = image.height <= 1 ? 0.0 : y / (image.height - 1);
    for (var x = 0; x < image.width; x++) {
      final nx = image.width <= 1 ? 0.0 : x / (image.width - 1);
      final protect = (_maskValue(analysis['skinMask'], nx, ny) * 0.42) +
          (_faceWeight(analysis['faces'], nx, ny) * 0.24);
      final noise =
          ((((x * 73856093) ^ (y * 19349663) ^ seed) & 255) / 255.0) - 0.5;
      final pixel = image.getPixel(x, y);
      final luminance =
          _luminance(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
      final tonalWeight = 1 - ((luminance - 0.5).abs() * 1.3).clamp(0.0, 0.9);
      final delta = noise * effectiveAmount * tonalWeight * (1 - protect);
      image.setPixelRgba(
        x,
        y,
        ((pixel.r / 255.0 + delta) * 255).round().clamp(0, 255),
        ((pixel.g / 255.0 + delta) * 255).round().clamp(0, 255),
        ((pixel.b / 255.0 + delta) * 255).round().clamp(0, 255),
        pixel.a.toInt(),
      );
    }
  }
}

bool _applyWatermarkIfNeeded(
  img.Image image, {
  required Map<String, dynamic> settings,
}) {
  if (!_bool(settings['watermarkEnabled'], false)) {
    return false;
  }
  var label = settings['watermarkText']?.toString().trim() ?? '';
  if (label.isEmpty) {
    label = 'AI Style Transfer Studio';
  }
  if (label.length > 28) {
    label = '${label.substring(0, 28)}...';
  }
  final font = img.arial24;
  var textWidth = 0;
  for (final codePoint in label.runes) {
    textWidth += font.characterXAdvance(String.fromCharCode(codePoint));
  }
  final textHeight = font.lineHeight;
  final padding = math.max(12, image.width ~/ 60);
  final boxWidth =
      math.min(image.width - (padding * 2), textWidth + (padding * 2));
  final boxHeight =
      math.min(image.height - (padding * 2), textHeight + padding);
  final boxX1 = image.width - boxWidth - padding;
  final boxY1 = image.height - boxHeight - padding;
  final boxX2 = image.width - padding;
  final boxY2 = image.height - padding;
  img.fillRect(
    image,
    x1: boxX1,
    y1: boxY1,
    x2: boxX2,
    y2: boxY2,
    color: img.ColorRgba8(0, 0, 0, 150),
    radius: 10,
  );
  img.drawString(
    image,
    label,
    font: font,
    x: boxX1 + padding,
    y: boxY1 + ((boxHeight - textHeight) ~/ 2),
    color: img.ColorRgba8(255, 255, 255, 232),
  );
  return true;
}

List<String> _buildWarnings({
  required double compatibility,
  required Map<String, dynamic> safetyReport,
  required bool fallbackMode,
  required bool watermarkApplied,
  required Map<String, dynamic> targetStats,
  required Map<String, dynamic> processedStats,
}) {
  final warnings = <String>[];
  if (compatibility < 0.56) {
    warnings
        .add('Style strength was softened to fit this scene more naturally.');
  }
  if (_asDouble(safetyReport['clipRisk']) > 0.22) {
    warnings.add('Highlight protection reduced aggressive brightening.');
  }
  if (_asDouble(processedStats['darkPixelRatio']) >
      _asDouble(targetStats['darkPixelRatio']) + 0.05) {
    warnings.add('Shadow guard lifted deeper blacks to avoid crushing detail.');
  }
  if (fallbackMode) {
    warnings.add('Safe-mode rendering kept processing stable on this device.');
  }
  if (watermarkApplied) {
    warnings.add('Export watermark is enabled.');
  }
  return warnings;
}

double _maskValue(dynamic maskData, double nx, double ny) {
  if (maskData is! Map<String, dynamic>) {
    return 0;
  }
  final width = (maskData['width'] as num?)?.toInt() ?? 0;
  final height = (maskData['height'] as num?)?.toInt() ?? 0;
  if (width == 0 || height == 0) {
    return 0;
  }
  final values = _toBytes(maskData['values']);
  if (values.isEmpty) {
    return 0;
  }
  final x = (nx.clamp(0.0, 1.0) * (width - 1)).round();
  final y = (ny.clamp(0.0, 1.0) * (height - 1)).round();
  final index = y * width + x;
  if (index < 0 || index >= values.length) {
    return 0;
  }
  return values[index] / 255.0;
}

double _faceWeight(dynamic facesData, double nx, double ny) {
  if (facesData is! List<dynamic>) {
    return 0;
  }
  var best = 0.0;
  for (final entry in facesData) {
    if (entry is! Map<String, dynamic>) {
      continue;
    }
    final left = _asDouble(entry['left']);
    final top = _asDouble(entry['top']);
    final width = _asDouble(entry['width']);
    final height = _asDouble(entry['height']);
    final right = left + width;
    final bottom = top + height;
    if (nx < left || nx > right || ny < top || ny > bottom) {
      continue;
    }
    final dx = ((nx - (left + width / 2)).abs() / math.max(width / 2, 0.001));
    final dy = ((ny - (top + height / 2)).abs() / math.max(height / 2, 0.001));
    final radial = math.sqrt((dx * dx) + (dy * dy));
    best = math.max(best, (1 - radial).clamp(0.0, 1.0).toDouble());
  }
  return best;
}

double _channelDelta(
  Map<String, dynamic> profile,
  double hue, {
  required String axis,
}) {
  const centers = <String, double>{
    'red': 0,
    'orange': 32,
    'yellow': 58,
    'green': 118,
    'aqua': 178,
    'blue': 226,
    'purple': 278,
    'magenta': 320,
  };
  var total = 0.0;
  for (final entry in centers.entries) {
    final channel = Map<String, dynamic>.from(
      profile[entry.key] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
    final delta = _asDouble(channel[axis]);
    final distance = _circularDistance(hue, entry.value);
    final weight = (1 - (distance / 50)).clamp(0.0, 1.0).toDouble();
    total += delta * weight;
  }
  return total;
}

double _applyCinematicCurve(
  double luminance, {
  required double toneCurveStrength,
  required double fade,
  required double highlightRollOff,
}) {
  var value = _clamp01(luminance);
  final toe = toneCurveStrength * 0.16;
  final shoulder = toneCurveStrength * 0.24;
  if (value < 0.5) {
    value = _mix(value, value * value, toe);
  } else {
    final inverse = 1 - value;
    value = 1 - _mix(inverse, inverse * inverse, shoulder);
  }
  if (value > 0.72) {
    final compressed = 0.72 + ((value - 0.72) * (1 - highlightRollOff));
    value = _mix(value, compressed, 0.9);
  }
  if (fade > 0) {
    value = _mix(value, 0.06 + (value * 0.94), fade * 0.22);
  }
  return _clamp01(value);
}

img.Image _resizeDown(img.Image image, int maxDimension) {
  final maxSide = math.max(image.width, image.height);
  if (maxSide <= maxDimension) {
    return img.Image.from(image);
  }
  if (image.width >= image.height) {
    return img.copyResize(image, width: maxDimension);
  }
  return img.copyResize(image, height: maxDimension);
}

img.Image _decode(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw StateError('Unable to decode image bytes.');
  }
  return img.bakeOrientation(image);
}

Uint8List _toBytes(dynamic value) {
  if (value == null) {
    return Uint8List(0);
  }
  if (value is TransferableTypedData) {
    return value.materialize().asUint8List();
  }
  if (value is Uint8List) {
    return value;
  }
  if (value is ByteBuffer) {
    return value.asUint8List();
  }
  if (value is List<int>) {
    return Uint8List.fromList(value);
  }
  if (value is List<dynamic>) {
    return Uint8List.fromList(
      value.map((item) => (item as num).toInt()).toList(growable: false),
    );
  }
  return Uint8List(0);
}

List<double> _curveFromDynamic(dynamic value) {
  return (value as List<dynamic>? ?? const <dynamic>[])
      .map((entry) => (entry as num).toDouble())
      .toList(growable: false);
}

int _fastHash(Uint8List bytes) {
  var hash = 0x811C9DC5;
  for (final value in bytes) {
    hash ^= value;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}

int _previewDimension(Map<String, dynamic> settings, bool fallbackMode) {
  final configured = _asInt(settings['previewMaxDimension'], 960);
  return fallbackMode ? math.min(configured, 720) : configured;
}

int _exportDimension(Map<String, dynamic> settings, bool fallbackMode) {
  final configured = _asInt(settings['exportMaxDimension'], 2560);
  return fallbackMode ? math.min(configured, 1800) : configured;
}

int _jpegQuality(dynamic value, int fallback) {
  return _asInt(value, fallback).clamp(60, 100);
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

bool _bool(dynamic value, bool fallback) {
  if (value is bool) {
    return value;
  }
  return fallback;
}

double _clamp01(double value) {
  return value.clamp(0.0, 1.0).toDouble();
}

double _mix(double a, double b, double t) {
  return a + ((b - a) * t.clamp(0.0, 1.0));
}

int _mixInt(int a, int b, double t) {
  return _mix(a.toDouble(), b.toDouble(), t).round().clamp(0, 255);
}

double _curveApply(double value, List<double> curve) {
  if (curve.isEmpty) {
    return _clamp01(value);
  }
  if (curve.length == 1) {
    return _clamp01(curve.first);
  }
  final clamped = value.clamp(0.0, 1.0).toDouble();
  final scaled = clamped * (curve.length - 1);
  final index = scaled.floor().clamp(0, curve.length - 2);
  final t = scaled - index;
  return _mix(curve[index], curve[index + 1], t).clamp(0.0, 1.0).toDouble();
}

double _luminance(int r, int g, int b) {
  return ((0.299 * r) + (0.587 * g) + (0.114 * b)) / 255.0;
}

double _luminanceFromPixel(img.Pixel pixel) {
  return _luminance(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
}

double _luminanceDouble(double r, double g, double b) {
  return (0.299 * r) + (0.587 * g) + (0.114 * b);
}

double _circularDistance(double a, double b) {
  final delta = (a - b).abs();
  return math.min(delta, 360 - delta).toDouble();
}

List<double> _rgbToHsl(int r, int g, int b) {
  final rd = r / 255.0;
  final gd = g / 255.0;
  final bd = b / 255.0;
  final maxValue = math.max(rd, math.max(gd, bd));
  final minValue = math.min(rd, math.min(gd, bd));
  final delta = maxValue - minValue;
  final lightness = (maxValue + minValue) / 2;

  double hue = 0;
  double saturation = 0;
  if (delta != 0) {
    saturation = delta / (1 - (2 * lightness - 1).abs());
    if (maxValue == rd) {
      hue = 60 * (((gd - bd) / delta) % 6);
    } else if (maxValue == gd) {
      hue = 60 * (((bd - rd) / delta) + 2);
    } else {
      hue = 60 * (((rd - gd) / delta) + 4);
    }
  }
  if (hue < 0) {
    hue += 360;
  }
  return <double>[hue, saturation.isNaN ? 0 : saturation, lightness];
}

List<double> _hslToRgb(double hue, double saturation, double lightness) {
  final c = (1 - (2 * lightness - 1).abs()) * saturation;
  final x = c * (1 - (((hue / 60) % 2) - 1).abs());
  final m = lightness - (c / 2);
  double r = 0;
  double g = 0;
  double b = 0;

  if (hue < 60) {
    r = c;
    g = x;
  } else if (hue < 120) {
    r = x;
    g = c;
  } else if (hue < 180) {
    g = c;
    b = x;
  } else if (hue < 240) {
    g = x;
    b = c;
  } else if (hue < 300) {
    r = x;
    b = c;
  } else {
    r = c;
    b = x;
  }

  return <double>[
    (r + m).clamp(0.0, 1.0).toDouble(),
    (g + m).clamp(0.0, 1.0).toDouble(),
    (b + m).clamp(0.0, 1.0).toDouble(),
  ];
}
