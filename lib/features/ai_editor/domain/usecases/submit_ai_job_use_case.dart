import 'package:untitled2/features/ai_editor/domain/entities/ai_job_entity.dart';
import 'package:untitled2/features/ai_editor/domain/repositories/ai_processing_repository.dart';

class SubmitAiJobUseCase {
  final AiProcessingRepository repository;

  const SubmitAiJobUseCase(this.repository);

  Future<AiJobEntity> call(SubmitAiJobParams params) {
    return repository.submitJob(params);
  }
}
