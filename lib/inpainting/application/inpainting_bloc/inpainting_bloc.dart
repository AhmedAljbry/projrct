import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/core/background/bg_job_models.dart';
import 'package:untitled2/core/background/operation_tracker.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';

import '../../data/inpainting_repository.dart';
import '../../domain/inpainting_failure.dart';
import '../../domain/inpainting_status.dart';
import 'inpainting_event.dart';
import 'inpainting_state.dart';

class InpaintingBloc extends Bloc<InpaintingEvent, InpaintingState> {
  InpaintingBloc({required this.repo}) : super(InpaintingState.idle()) {
    on<InpaintingPrepare>(_onPrepare);
    on<InpaintingPreparationFailed>(_onPreparationFailed);
    on<InpaintingStart>(_onStart);
    on<InpaintingCancel>(_onCancel);
    on<InpaintingReset>(_onReset);
  }

  final InpaintingRepository repo;
  final OperationTracker _tracker = OperationTracker();

  bool _cancelled = false;
  String? _localJobId;
  Uint8List? _lastImageBytes;
  Uint8List? _lastMaskBytes;

  void _log(String message) {
    debugPrint('[InpaintingBloc] $message');
  }

  Future<void> _onPrepare(
    InpaintingPrepare event,
    Emitter<InpaintingState> emit,
  ) async {
    _log('Preparation started');
    _cancelled = false;
    emit(InpaintingState(
      status: InpaintingStatus.preparing,
      startedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      serverStage: 'preparing',
      serverMessage: event.message ?? 'Preparing image and mask',
    ));
  }

  Future<void> _onPreparationFailed(
    InpaintingPreparationFailed event,
    Emitter<InpaintingState> emit,
  ) async {
    _log('Preparation failed: ${event.message}');
    emit(state.copyWith(
      status: InpaintingStatus.failed,
      failure: const InpaintingFailure(
        code: 'prepare_failed',
        messageKey: 'failed',
      ),
      serverStage: 'preparing',
      serverMessage: event.message,
      lastUpdatedAt: DateTime.now(),
    ));
  }

  Future<void> _onReset(
    InpaintingReset event,
    Emitter<InpaintingState> emit,
  ) async {
    _log('Reset requested for local jobId=${state.jobId ?? "none"}');
    _cancelled = false;
    _localJobId = null;
    emit(InpaintingState.idle());
  }

  Future<void> _onCancel(
    InpaintingCancel event,
    Emitter<InpaintingState> emit,
  ) async {
    _log('Cancel requested for local jobId=${state.jobId ?? "none"}');
    _cancelled = true;

    final jobId = state.jobId;
    if (jobId != null) {
      await repo.cancelJob(jobId);
    }
    if (_localJobId != null) {
      await _tracker.cancelJob(_localJobId!);
    }

    emit(state.copyWith(
      status: InpaintingStatus.cancelled,
      failure: const InpaintingFailure(
        code: 'cancelled',
        messageKey: 'cancelled',
      ),
      serverStage: 'cancelled',
      serverMessage: null,
      serverProgress: null,
      lastUpdatedAt: DateTime.now(),
    ));
  }

  Future<void> _onStart(
    InpaintingStart event,
    Emitter<InpaintingState> emit,
  ) async {
    _log(
      'Start requested: image=${event.imageBytes.length} bytes, mask=${event.maskBytes.length} bytes',
    );
    _cancelled = false;
    _lastImageBytes = event.imageBytes;
    _lastMaskBytes = event.maskBytes;

    emit(InpaintingState(
      status: InpaintingStatus.uploading,
      startedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      serverMessage: 'Preparing files',
    ));

    try {
      _localJobId = await _tracker.createForegroundJob(
        type: BgJobType.magic,
        sourceBytes: event.imageBytes,
        maskBytes: event.maskBytes,
        metadata: {'tool': 'magic_inpainting'},
        sourcePrefix: 'magic_source',
        maskPrefix: 'magic_mask',
      );
      final submitResponse = await repo.submitJob(
        image: event.imageBytes,
        mask: event.maskBytes,
      );
      final jobId = submitResponse.jobId;
      final queuedByServer =
          (submitResponse.position ?? 0) > 0 ||
          (submitResponse.message?.toLowerCase().contains('busy') ?? false);

      _log(
        'Server accepted jobId=$jobId queued=$queuedByServer position=${submitResponse.position ?? 0} message=${submitResponse.message ?? "-"}',
      );
      await _tracker.bindRemoteJob(
        _localJobId!,
        remoteJobId: jobId,
        queued: queuedByServer,
        queuePosition: submitResponse.position,
        message: submitResponse.message,
      );

      emit(state.copyWith(
        status: queuedByServer
            ? InpaintingStatus.queued
            : InpaintingStatus.processing,
        jobId: jobId,
        queuePosition: submitResponse.position,
        serverProgress: queuedByServer ? 0 : 5,
        serverStage: queuedByServer ? 'queued' : 'processing',
        serverMessage: submitResponse.message,
        lastUpdatedAt: DateTime.now(),
        clearFailure: true,
      ));

      await _monitorServerJob(jobId, event.imageBytes, emit);
    } catch (e) {
      _log('Start failed for local inpainting flow: $e');
      if (_cancelled) {
        return;
      }

      final failure = e is InpaintingFailure
          ? e
          : const InpaintingFailure(code: 'unknown', messageKey: 'failed');

      emit(state.copyWith(
        status: InpaintingStatus.failed,
        failure: failure,
        serverStage: 'failed',
        serverProgress: null,
        serverMessage: e.toString(),
        lastUpdatedAt: DateTime.now(),
      ));
    }
  }

  Future<void> retryLastSubmission() async {
    final imageBytes = _lastImageBytes;
    final maskBytes = _lastMaskBytes;
    if (imageBytes == null || maskBytes == null) {
      return;
    }

    add(InpaintingStart(imageBytes: imageBytes, maskBytes: maskBytes));
  }

  Future<void> _monitorServerJob(
    String jobId,
    Uint8List sentImageBytes,
    Emitter<InpaintingState> emit,
  ) async {
    const pollInterval = Duration(seconds: 2);
    const maxWait = Duration(minutes: 15);
    final startedAt = DateTime.now();

    while (!_cancelled) {
      if (DateTime.now().difference(startedAt) > maxWait) {
        _log('Monitor timed out for server jobId=$jobId');
        emit(state.copyWith(
          status: InpaintingStatus.timeout,
          failure: const InpaintingFailure(code: 'timeout', messageKey: 'timeout'),
          lastUpdatedAt: DateTime.now(),
        ));
        return;
      }

      final job = await repo.getStatus(jobId);
      if (_localJobId != null) {
        await _tracker.updateFromRemoteStatus(
          _localJobId!,
          LamaJobStatus(
            jobId: jobId,
            status: job.status,
            progress: job.progress,
            message: job.message,
          ),
        );
      }
      final nextStatus = switch (job.status) {
        'queued' => InpaintingStatus.queued,
        'processing' => InpaintingStatus.processing,
        'completed' => InpaintingStatus.downloading,
        'failed' => InpaintingStatus.failed,
        'cancelled' => InpaintingStatus.cancelled,
        _ => InpaintingStatus.processing,
      };

      emit(state.copyWith(
        status: nextStatus,
        jobId: jobId,
        queuePosition: job.position,
        serverProgress: job.progress,
        serverStage: job.stage,
        serverMessage: job.message,
        pollCount: state.pollCount + 1,
        lastUpdatedAt: DateTime.now(),
        clearFailure: true,
      ));

      _log(
        'Monitor update jobId=$jobId status=${job.status} stage=${job.stage} progress=${job.progress}% queue=${job.position ?? 0} message=${job.message}',
      );

      if (job.isCompleted) {
        emit(state.copyWith(
          status: InpaintingStatus.downloading,
          serverProgress: 100,
          serverStage: job.stage,
          serverMessage: job.message,
          lastUpdatedAt: DateTime.now(),
          clearFailure: true,
        ));
        _log('Downloading result for server jobId=$jobId');
        final resultBytes = await repo.downloadResult(
          jobId,
          sentImageBytes: sentImageBytes,
        );
        if (_localJobId != null) {
          await _tracker.completeJob(_localJobId!, resultBytes);
        }
        _log('Download complete for server jobId=$jobId (${resultBytes.length} bytes)');
        emit(state.copyWith(
          status: InpaintingStatus.success,
          result: resultBytes,
          serverProgress: 100,
          serverStage: 'result_ready',
          serverMessage: 'Result downloaded successfully',
          lastUpdatedAt: DateTime.now(),
          clearFailure: true,
        ));
        return;
      }

      if (job.isFailed) {
        _log('Server job failed jobId=$jobId message=${job.message}');
        if (_localJobId != null) {
          await _tracker.failJob(_localJobId!, job.message);
        }
        emit(state.copyWith(
          status: InpaintingStatus.failed,
          failure: const InpaintingFailure(
            code: 'background_failed',
            messageKey: 'failed',
          ),
          serverStage: 'failed',
          serverProgress: null,
          serverMessage: job.message,
          lastUpdatedAt: DateTime.now(),
        ));
        return;
      }

      if (job.isCancelled) {
        _log('Server job cancelled jobId=$jobId');
        if (_localJobId != null) {
          await _tracker.cancelJob(_localJobId!);
        }
        emit(state.copyWith(
          status: InpaintingStatus.cancelled,
          failure: const InpaintingFailure(
            code: 'cancelled',
            messageKey: 'cancelled',
          ),
          serverStage: 'cancelled',
          serverProgress: null,
          serverMessage: null,
          lastUpdatedAt: DateTime.now(),
        ));
        return;
      }

      await Future.delayed(pollInterval);
    }
  }
}
