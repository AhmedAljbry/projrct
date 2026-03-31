import 'dart:typed_data';

import 'package:untitled2/features/scene_analysis/domain/entities/scene_analysis_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_settings.dart';
import 'package:untitled2/features/style_transfer/domain/repositories/style_transfer_repository.dart';

class ApplyStyleUseCase {
  const ApplyStyleUseCase(this._repository);

  final StyleTransferRepository _repository;

  Future<StyleTransferResult> call({
    required Uint8List targetBytes,
    required StyleProfile styleProfile,
    required StyleTransferSettings settings,
    Uint8List? referenceBytes,
    SceneAnalysisResult? targetAnalysis,
    bool highQuality = false,
  }) {
    return _repository.applyStyle(
      targetBytes: targetBytes,
      styleProfile: styleProfile,
      settings: settings,
      referenceBytes: referenceBytes,
      targetAnalysis: targetAnalysis,
      highQuality: highQuality,
    );
  }
}
