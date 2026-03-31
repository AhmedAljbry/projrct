import 'dart:typed_data';

import 'package:untitled2/features/scene_analysis/domain/entities/scene_analysis_result.dart';
import 'package:untitled2/features/style_transfer/data/services/style_transfer_pipeline.dart';
import 'package:untitled2/features/style_transfer/data/services/style_transfer_processing_cache.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_settings.dart';
import 'package:untitled2/features/style_transfer/domain/repositories/style_transfer_repository.dart';

class StyleTransferRepositoryImpl implements StyleTransferRepository {
  StyleTransferRepositoryImpl({
    StyleTransferPipeline? pipeline,
    StyleTransferProcessingCache? cache,
  })  : _pipeline = pipeline ?? const StyleTransferPipeline(),
        _cache = cache ?? StyleTransferProcessingCache();

  final StyleTransferPipeline _pipeline;
  final StyleTransferProcessingCache _cache;

  @override
  Future<StyleProfile> extractStyle({
    required Uint8List referenceBytes,
    String? name,
  }) async {
    final cached = _cache.readStyle(referenceBytes);
    if (cached != null) {
      return cached;
    }
    final profile = await _pipeline.extractStyle(
        referenceBytes: referenceBytes, name: name);
    _cache.writeStyle(referenceBytes, profile);
    return profile;
  }

  @override
  Future<SceneAnalysisResult> analyzeScene(Uint8List imageBytes) async {
    final cached = _cache.readScene(imageBytes);
    if (cached != null) {
      return cached;
    }
    final analysis = await _pipeline.analyzeScene(imageBytes);
    _cache.writeScene(imageBytes, analysis);
    return analysis;
  }

  @override
  Future<StyleTransferResult> applyStyle({
    required Uint8List targetBytes,
    required StyleProfile styleProfile,
    required StyleTransferSettings settings,
    Uint8List? referenceBytes,
    SceneAnalysisResult? targetAnalysis,
    bool highQuality = false,
  }) async {
    if (!highQuality) {
      final cached = _cache.readPreview(
        targetBytes: targetBytes,
        styleProfile: styleProfile,
        settings: settings,
      );
      if (cached != null) {
        return cached.copyWith(usedCachedPreview: true);
      }
    }

    final result = await _pipeline.applyStyle(
      targetBytes: targetBytes,
      styleProfile: styleProfile,
      settings: settings,
      referenceBytes: referenceBytes,
      highQuality: highQuality,
    );
    if (!highQuality) {
      _cache.writePreview(
        targetBytes: targetBytes,
        styleProfile: styleProfile,
        settings: settings,
        result: result,
      );
    }
    return result;
  }
}
