import 'package:untitled2/features/ai_editor/domain/entities/ai_job_entity.dart';
import 'package:untitled2/features/ai_editor/domain/repositories/ai_processing_repository.dart';

class GetJobResultUseCase {
  final AiProcessingRepository repository;

  const GetJobResultUseCase(this.repository);

  Future<AiJobEntity> call(String jobId) {
    return repository.getJobResult(jobId);
  }
}
