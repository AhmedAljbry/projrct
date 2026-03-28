import 'dart:typed_data';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/domain/repositories/lama_repository.dart';

class CheckHealthUseCase {
  final LamaRepository repository;
  CheckHealthUseCase(this.repository);

  Future<LamaServerHealth> execute() => repository.checkHealth();
}

class GetCapabilitiesUseCase {
  final LamaRepository repository;
  GetCapabilitiesUseCase(this.repository);

  Future<LamaCapabilities> execute() => repository.getCapabilities();
}

class SubmitJobUseCase {
  final LamaRepository repository;
  SubmitJobUseCase(this.repository);

  Future<String> execute(LamaOptions options) => repository.submitJob(options);
}

class PollJobStatusUseCase {
  final LamaRepository repository;
  PollJobStatusUseCase(this.repository);

  Stream<LamaJobStatus> execute(String jobId, {Duration pollInterval = const Duration(seconds: 2)}) async* {
    while (true) {
      final status = await repository.getJobStatus(jobId);
      yield status;
      if (status.isCompleted || status.isFailed) {
        break;
      }
      await Future.delayed(pollInterval);
    }
  }
}

class GetJobResultUseCase {
  final LamaRepository repository;
  GetJobResultUseCase(this.repository);

  Future<Uint8List> execute(String jobId) => repository.getJobResult(jobId);
}
