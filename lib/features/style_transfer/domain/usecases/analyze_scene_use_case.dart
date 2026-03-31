import 'dart:typed_data';

import 'package:untitled2/features/scene_analysis/domain/entities/scene_analysis_result.dart';
import 'package:untitled2/features/style_transfer/domain/repositories/style_transfer_repository.dart';

class AnalyzeSceneUseCase {
  const AnalyzeSceneUseCase(this._repository);

  final StyleTransferRepository _repository;

  Future<SceneAnalysisResult> call(Uint8List imageBytes) {
    return _repository.analyzeScene(imageBytes);
  }
}
