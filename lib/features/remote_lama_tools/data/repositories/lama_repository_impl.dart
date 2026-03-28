import 'dart:typed_data';

import 'package:untitled2/features/remote_lama_tools/data/datasources/lama_remote_data_source.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/domain/repositories/lama_repository.dart';

class LamaRepositoryImpl implements LamaRepository {
  final LamaRemoteDataSource remoteDataSource;

  LamaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<LamaServerHealth> checkHealth() {
    return remoteDataSource.checkHealth();
  }

  @override
  Future<LamaCapabilities> getCapabilities() {
    return remoteDataSource.getCapabilities();
  }

  @override
  Future<String> submitJob(LamaOptions options) {
    return remoteDataSource.submitJob(options);
  }

  @override
  Future<LamaJobStatus> getJobStatus(String jobId) {
    return remoteDataSource.getJobStatus(jobId);
  }

  @override
  Future<Uint8List> getJobResult(String jobId) {
    return remoteDataSource.getJobResult(jobId);
  }
}
