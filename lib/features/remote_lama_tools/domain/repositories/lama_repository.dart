import 'dart:typed_data';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';

abstract class LamaRepository {
  Future<LamaServerHealth> checkHealth();
  Future<LamaCapabilities> getCapabilities();
  Future<String> submitJob(LamaOptions options);
  Future<LamaJobStatus> getJobStatus(String jobId);
  Future<Uint8List> getJobResult(String jobId);
}
