import 'dart:io';

import 'package:untitled2/features/ai_editor/domain/entities/ai_job_entity.dart';

enum AiEditorTool { heal, clean, erase }

class SubmitAiJobParams {
  final File imageFile;
  final File maskFile;
  final AiEditorTool tool;
  final int? healRadius;
  final int? edgeRadius;
  final int? backgroundRadius;
  final String priority;

  const SubmitAiJobParams({
    required this.imageFile,
    required this.maskFile,
    required this.tool,
    this.healRadius,
    this.edgeRadius,
    this.backgroundRadius,
    this.priority = 'normal',
  });
}

abstract class AiProcessingRepository {
  Future<AiJobEntity> submitJob(SubmitAiJobParams params);
  Future<AiJobEntity> getJobStatus(String jobId);
  Future<AiJobEntity> getJobResult(String jobId);
  Future<void> persistActiveJob({
    required AiJobEntity job,
    required AiEditorTool tool,
    required File sourceImage,
    required File maskImage,
  });
  Future<StoredAiJob?> getStoredActiveJob();
  Future<void> clearStoredJob();
}

class StoredAiJob {
  final AiJobEntity job;
  final AiEditorTool tool;
  final String sourceImagePath;
  final String maskImagePath;

  const StoredAiJob({
    required this.job,
    required this.tool,
    required this.sourceImagePath,
    required this.maskImagePath,
  });
}
