import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/core/background/bg_job_models.dart';
import 'package:untitled2/core/background/operation_tracker.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/domain/failures/lama_failure.dart';
import 'package:untitled2/features/remote_lama_tools/domain/usecases/lama_usecases.dart';

enum DescratchStage { initial, ready, submitting, processing, success, failure }

class DescratchState extends Equatable {
  final DescratchStage stage;
  final Uint8List? imageBytes;
  final Uint8List? resultBytes;
  final LamaJobStatus? jobStatus;
  final String? message;
  final bool isRetryable;

  const DescratchState({
    required this.stage,
    this.imageBytes,
    this.resultBytes,
    this.jobStatus,
    this.message,
    this.isRetryable = false,
  });

  const DescratchState.initial() : this(stage: DescratchStage.initial);

  DescratchState copyWith({
    DescratchStage? stage,
    Uint8List? imageBytes,
    bool clearImage = false,
    Uint8List? resultBytes,
    bool clearResult = false,
    LamaJobStatus? jobStatus,
    bool clearStatus = false,
    String? message,
    bool clearMessage = false,
    bool? isRetryable,
  }) {
    return DescratchState(
      stage: stage ?? this.stage,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      resultBytes: clearResult ? null : (resultBytes ?? this.resultBytes),
      jobStatus: clearStatus ? null : (jobStatus ?? this.jobStatus),
      message: clearMessage ? null : (message ?? this.message),
      isRetryable: isRetryable ?? this.isRetryable,
    );
  }

  bool get hasImage => imageBytes != null;
  bool get hasResult => resultBytes != null;
  bool get isBusy =>
      stage == DescratchStage.submitting || stage == DescratchStage.processing;

  @override
  List<Object?> get props =>
      [stage, imageBytes, resultBytes, jobStatus, message, isRetryable];
}

class DescratchCubit extends Cubit<DescratchState> {
  final SubmitJobUseCase _submitJobUseCase;
  final PollJobStatusUseCase _pollJobStatusUseCase;
  final GetJobResultUseCase _getJobResultUseCase;
  StreamSubscription<LamaJobStatus>? _pollingSubscription;
  Uint8List? _lastMaskBytes;
  final OperationTracker _tracker = OperationTracker();
  String? _localJobId;

  DescratchCubit({
    required SubmitJobUseCase submitJobUseCase,
    required PollJobStatusUseCase pollJobStatusUseCase,
    required GetJobResultUseCase getJobResultUseCase,
  })  : _submitJobUseCase = submitJobUseCase,
        _pollJobStatusUseCase = pollJobStatusUseCase,
        _getJobResultUseCase = getJobResultUseCase,
        super(const DescratchState.initial());

  void setImage(Uint8List bytes) {
    _lastMaskBytes = null;
    emit(
      DescratchState(
        stage: DescratchStage.ready,
        imageBytes: bytes,
      ),
    );
  }

  Future<void> submit(Uint8List maskBytes) async {
    if (!state.hasImage || state.isBusy) {
      return;
    }

    _lastMaskBytes = maskBytes;
    emit(
      state.copyWith(
        stage: DescratchStage.submitting,
        clearResult: true,
        clearStatus: true,
        clearMessage: true,
        isRetryable: false,
      ),
    );

    try {
      _localJobId = await _tracker.createForegroundJob(
        type: BgJobType.descratch,
        sourceBytes: state.imageBytes!,
        maskBytes: maskBytes,
        metadata: {'tool': 'descratch_restore'},
        sourcePrefix: 'descratch_source',
        maskPrefix: 'descratch_mask',
      );
      final options = RepairDamageOptions(
        imageBytes: state.imageBytes!,
        imageName: 'descratch_source.png',
        maskBytes: maskBytes,
        maskName: 'descratch_mask.png',
      );
      final jobId = await _submitJobUseCase.execute(options);
      await _tracker.bindRemoteJob(
        _localJobId!,
        remoteJobId: jobId,
        queued: false,
      );
      _startPolling(jobId);
    } catch (error) {
      _emitFailure(error);
    }
  }

  Future<void> retryLastSubmission() async {
    if (_lastMaskBytes == null) {
      emit(
        state.copyWith(
          stage: state.hasImage ? DescratchStage.ready : DescratchStage.initial,
          message: 'Select the scratched region again before retrying.',
          isRetryable: false,
        ),
      );
      return;
    }
    await submit(_lastMaskBytes!);
  }

  void editAgain() {
    if (!state.hasImage) {
      emit(const DescratchState.initial());
      return;
    }
    emit(
      state.copyWith(
        stage: DescratchStage.ready,
        clearResult: true,
        clearStatus: true,
        clearMessage: true,
        isRetryable: false,
      ),
    );
  }

  void reset() {
    _pollingSubscription?.cancel();
    _lastMaskBytes = null;
    _localJobId = null;
    emit(const DescratchState.initial());
  }

  void _startPolling(String jobId) {
    _pollingSubscription?.cancel();
    _pollingSubscription = _pollJobStatusUseCase.execute(jobId).listen(
      (status) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            stage: DescratchStage.processing,
            jobStatus: status,
            clearMessage: true,
            isRetryable: false,
          ),
        );
        if (_localJobId != null) {
          _tracker.updateFromRemoteStatus(_localJobId!, status);
        }
        if (status.isCompleted) {
          _fetchResult(status.jobId);
        } else if (status.isFailed) {
          emit(
            state.copyWith(
              stage: DescratchStage.failure,
              message: status.error ?? status.message,
              isRetryable: true,
            ),
          );
        }
      },
      onError: _emitFailure,
    );
  }

  Future<void> _fetchResult(String jobId) async {
    try {
      final resultBytes = await _getJobResultUseCase.execute(jobId);
      if (_localJobId != null) {
        await _tracker.completeJob(_localJobId!, resultBytes);
      }
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          stage: DescratchStage.success,
          resultBytes: resultBytes,
          clearStatus: true,
          clearMessage: true,
          isRetryable: false,
        ),
      );
    } catch (error) {
      _emitFailure(error);
    }
  }

  void _emitFailure(Object error) {
    if (_localJobId != null) {
      _tracker.failJob(_localJobId!, error.toString());
    }
    final isRetryable = error is LamaRateLimitFailure ||
        error is LamaServerBusyFailure ||
        error is LamaApiFailure;
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        stage: DescratchStage.failure,
        message: error.toString(),
        isRetryable: isRetryable,
      ),
    );
  }

  @override
  Future<void> close() {
    _pollingSubscription?.cancel();
    return super.close();
  }
}
