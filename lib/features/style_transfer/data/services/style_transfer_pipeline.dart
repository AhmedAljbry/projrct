import 'dart:isolate';
import 'package:flutter/foundation.dart';

import 'package:untitled2/features/face_protection/domain/entities/style_safety_report.dart';
import 'package:untitled2/features/scene_analysis/domain/entities/scene_analysis_result.dart';
import 'package:untitled2/features/style_transfer/data/services/style_transfer_isolate.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_settings.dart';

class StyleTransferPipeline {
  const StyleTransferPipeline();

  Future<StyleProfile> extractStyle({
    required Uint8List referenceBytes,
    String? name,
  }) async {
    final result = await compute<Map<String, dynamic>, Map<String, dynamic>>(
      extractStyleWorker,
      <String, dynamic>{
        'bytes': _transfer(referenceBytes),
        'name': name,
      },
    );
    return StyleProfile.fromMap(result);
  }

  Future<SceneAnalysisResult> analyzeScene(Uint8List imageBytes) async {
    final result = await compute<Map<String, dynamic>, Map<String, dynamic>>(
      analyzeSceneWorker,
      <String, dynamic>{'bytes': _transfer(imageBytes)},
    );
    return SceneAnalysisResult.fromMap(result);
  }

  Future<StyleTransferResult> applyStyle({
    required Uint8List targetBytes,
    required StyleProfile styleProfile,
    required StyleTransferSettings settings,
    Uint8List? referenceBytes,
    SceneAnalysisResult? targetAnalysis,
    bool highQuality = false,
  }) async {
    try {
      return await _runApplyStyle(
        targetBytes: targetBytes,
        styleProfile: styleProfile,
        settings: settings,
        referenceBytes: referenceBytes,
        targetAnalysis: targetAnalysis,
        highQuality: highQuality,
        fallbackMode: false,
      );
    } catch (_) {
      if (!settings.fallbackEnabled) {
        rethrow;
      }
      return _runApplyStyle(
        targetBytes: targetBytes,
        styleProfile: styleProfile,
        settings: settings,
        referenceBytes: referenceBytes,
        targetAnalysis: targetAnalysis,
        highQuality: highQuality,
        fallbackMode: true,
      );
    }
  }

  Future<StyleTransferResult> _runApplyStyle({
    required Uint8List targetBytes,
    required StyleProfile styleProfile,
    required StyleTransferSettings settings,
    Uint8List? referenceBytes,
    SceneAnalysisResult? targetAnalysis,
    required bool highQuality,
    required bool fallbackMode,
  }) async {
    final result = await compute<Map<String, dynamic>, Map<String, dynamic>>(
      applyStyleWorker,
      <String, dynamic>{
        'targetBytes': _transfer(targetBytes),
        'styleProfile': styleProfile.toMap(),
        'settings': settings.toMap(),
        'referenceBytes':
            referenceBytes == null ? null : _transfer(referenceBytes),
        'targetAnalysis': targetAnalysis?.toMap(),
        'highQuality': highQuality,
        'fallbackMode': fallbackMode,
      },
    );
    return StyleTransferResult(
      previewBytes: _toBytes(result['previewBytes']),
      exportBytes: result['exportBytes'] == null
          ? null
          : _toBytes(result['exportBytes']),
      appliedProfile: StyleProfile.fromMap(
          result['appliedProfile'] as Map<String, dynamic>),
      sceneAnalysis: SceneAnalysisResult.fromMap(
          result['sceneAnalysis'] as Map<String, dynamic>),
      safetyReport: StyleSafetyReport.fromMap(
          result['safetyReport'] as Map<String, dynamic>),
      compatibility: (result['compatibility'] as num).toDouble(),
      appliedStrength: (result['appliedStrength'] as num).toDouble(),
      previewRenderMs: (result['previewRenderMs'] as num).toInt(),
      exportRenderMs: (result['exportRenderMs'] as num).toInt(),
      exportReady: result['exportReady'] as bool? ?? false,
      warnings: (result['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      viralScore: (result['viralScore'] as num).toDouble(),
      usedCachedPreview: false,
      usedCachedAnalysis:
          result['usedCachedAnalysis'] as bool? ?? targetAnalysis != null,
      usedFallback: result['usedFallback'] as bool? ?? fallbackMode,
      watermarkApplied: result['watermarkApplied'] as bool? ?? false,
    );
  }
}

Uint8List _toBytes(dynamic value) {
  if (value is TransferableTypedData) {
    return value.materialize().asUint8List();
  }
  if (value is Uint8List) {
    return value;
  }
  if (value is List<int>) {
    return Uint8List.fromList(value);
  }
  if (value is List<dynamic>) {
    return Uint8List.fromList(
        value.map((item) => (item as num).toInt()).toList(growable: false));
  }
  return Uint8List(0);
}

TransferableTypedData _transfer(Uint8List bytes) {
  return TransferableTypedData.fromList(<Uint8List>[bytes]);
}
