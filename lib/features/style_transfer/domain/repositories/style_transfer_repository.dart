import 'dart:typed_data';

import 'package:untitled2/features/scene_analysis/domain/entities/scene_analysis_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_settings.dart';

abstract class StyleTransferRepository {
  Future<StyleProfile> extractStyle({
    required Uint8List referenceBytes,
    String? name,
  });

  Future<SceneAnalysisResult> analyzeScene(Uint8List imageBytes);

  Future<StyleTransferResult> applyStyle({
    required Uint8List targetBytes,
    required StyleProfile styleProfile,
    required StyleTransferSettings settings,
    Uint8List? referenceBytes,
    SceneAnalysisResult? targetAnalysis,
    bool highQuality = false,
  });
}
