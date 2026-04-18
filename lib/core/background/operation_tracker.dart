import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'package:untitled2/core/background/bg_job_models.dart';
import 'package:untitled2/core/background/bg_job_repository.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';

class OperationTracker {
  OperationTracker({
    BgJobRepository? repository,
  }) : _repository = repository ?? BgJobRepository();

  final BgJobRepository _repository;

  Future<String> createForegroundJob({
    required BgJobType type,
    required Uint8List sourceBytes,
    Uint8List? maskBytes,
    Map<String, dynamic> metadata = const {},
    String sourcePrefix = 'op_source',
    String maskPrefix = 'op_mask',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final localJobId = DateTime.now().microsecondsSinceEpoch.toString();
    final sourcePath = '${tempDir.path}\\${sourcePrefix}_$localJobId.png';
    String? maskPath;

    await File(sourcePath).writeAsBytes(sourceBytes);
    if (maskBytes != null) {
      maskPath = '${tempDir.path}\\${maskPrefix}_$localJobId.png';
      await File(maskPath).writeAsBytes(maskBytes);
    }

    await _repository.enqueueJob(
      jobId: localJobId,
      toolType: type,
      sourceImagePath: sourcePath,
      maskImagePath: maskPath,
      metadata: metadata,
    );

    await _repository.patchJob(
      localJobId,
      status: JobStatus.uploading,
      progress: 3,
      metadata: metadata,
    );

    return localJobId;
  }

  Future<void> bindRemoteJob(
    String localJobId, {
    required String remoteJobId,
    required bool queued,
    int? queuePosition,
    String? message,
  }) async {
    final job = await _repository.getJob(localJobId);
    final metadata = <String, dynamic>{
      ...?job?.metadata,
      'remoteJobId': remoteJobId,
      if (message != null && message.isNotEmpty) 'message': message,
    };
    await _repository.patchJob(
      localJobId,
      status: queued ? JobStatus.queued : JobStatus.processing,
      queuePosition: queuePosition ?? job?.queuePosition,
      progress: queued ? 0 : 10,
      errorMessage: message,
      metadata: metadata,
    );
  }

  Future<void> updateFromRemoteStatus(
    String localJobId,
    LamaJobStatus status,
  ) async {
    final mappedStatus = switch (status.status) {
      'queued' || 'pending' => JobStatus.queued,
      'processing' || 'running' => JobStatus.processing,
      'completed' => JobStatus.completed,
      'failed' => JobStatus.failed,
      'cancelled' => JobStatus.cancelled,
      _ => JobStatus.processing,
    };
    final job = await _repository.getJob(localJobId);
    final queuePosition = status.message.contains('#')
        ? job?.queuePosition
        : job?.queuePosition;
    await _repository.patchJob(
      localJobId,
      status: mappedStatus,
      progress: status.progress.clamp(0, 100),
      errorMessage: status.error ?? status.message,
      queuePosition: queuePosition,
    );
  }

  Future<void> completeJob(
    String localJobId,
    Uint8List resultBytes,
  ) async {
    final job = await _repository.getJob(localJobId);
    if (job == null) {
      return;
    }
    final outputPath = '${File(job.sourceImagePath).parent.path}\\out_$localJobId.png';
    await File(outputPath).writeAsBytes(resultBytes);
    await _repository.patchJob(
      localJobId,
      status: JobStatus.completed,
      progress: 100,
      outputImagePath: outputPath,
      errorMessage: '',
    );
  }

  Future<void> failJob(String localJobId, String message) {
    return _repository.patchJob(
      localJobId,
      status: JobStatus.failed,
      errorMessage: message,
    );
  }

  Future<void> cancelJob(String localJobId) {
    return _repository.patchJob(
      localJobId,
      status: JobStatus.cancelled,
      isCancelled: true,
    );
  }
}
