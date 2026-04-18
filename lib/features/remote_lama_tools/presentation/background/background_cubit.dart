import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/core/background/bg_job_models.dart';
import 'package:untitled2/core/background/operation_tracker.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/domain/failures/lama_failure.dart';
import 'package:untitled2/features/remote_lama_tools/domain/usecases/lama_usecases.dart';

enum BackgroundToolStage {
  initial,
  ready,
  submitting,
  processing,
  success,
  failure
}

class BackgroundToolState extends Equatable {
  final BackgroundToolStage stage;
  final Uint8List? imageBytes;
  final Uint8List? resultBytes;
  final LamaJobStatus? jobStatus;
  final String? message;
  final bool isRetryable;
  final int edgeRadius;

  const BackgroundToolState({
    required this.stage,
    this.imageBytes,
    this.resultBytes,
    this.jobStatus,
    this.message,
    this.isRetryable = false,
    this.edgeRadius = 4,
  });

  const BackgroundToolState.initial()
      : this(stage: BackgroundToolStage.initial);

  BackgroundToolState copyWith({
    BackgroundToolStage? stage,
    Uint8List? imageBytes,
    bool clearImage = false,
    Uint8List? resultBytes,
    bool clearResult = false,
    LamaJobStatus? jobStatus,
    bool clearStatus = false,
    String? message,
    bool clearMessage = false,
    bool? isRetryable,
    int? edgeRadius,
  }) {
    return BackgroundToolState(
      stage: stage ?? this.stage,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      resultBytes: clearResult ? null : (resultBytes ?? this.resultBytes),
      jobStatus: clearStatus ? null : (jobStatus ?? this.jobStatus),
      message: clearMessage ? null : (message ?? this.message),
      isRetryable: isRetryable ?? this.isRetryable,
      edgeRadius: edgeRadius ?? this.edgeRadius,
    );
  }

  bool get hasImage => imageBytes != null;
  bool get hasResult => resultBytes != null;
  bool get isBusy =>
      stage == BackgroundToolStage.submitting ||
      stage == BackgroundToolStage.processing;

  @override
  List<Object?> get props => [
        stage,
        imageBytes,
        resultBytes,
        jobStatus,
        message,
        isRetryable,
        edgeRadius,
      ];
}

class BackgroundCubit extends Cubit<BackgroundToolState> {
  final SubmitJobUseCase _submitJobUseCase;
  final PollJobStatusUseCase _pollJobStatusUseCase;
  final GetJobResultUseCase _getJobResultUseCase;
  StreamSubscription<LamaJobStatus>? _pollingSubscription;
  Uint8List? _lastMaskBytes;
  final OperationTracker _tracker = OperationTracker();
  String? _localJobId;

  BackgroundCubit({
    required SubmitJobUseCase submitJobUseCase,
    required PollJobStatusUseCase pollJobStatusUseCase,
    required GetJobResultUseCase getJobResultUseCase,
  })  : _submitJobUseCase = submitJobUseCase,
        _pollJobStatusUseCase = pollJobStatusUseCase,
        _getJobResultUseCase = getJobResultUseCase,
        super(const BackgroundToolState.initial());

  void setImage(Uint8List bytes) {
    _lastMaskBytes = null;
    emit(
      BackgroundToolState(
        stage: BackgroundToolStage.ready,
        imageBytes: bytes,
      ),
    );
  }

  void updateEdgeRadius(int radius) {
    emit(state.copyWith(edgeRadius: radius, clearMessage: true));
  }

  Future<void> submit(Uint8List maskBytes) async {
    if (!state.hasImage || state.isBusy) {
      return;
    }

    _lastMaskBytes = maskBytes;
    emit(
      state.copyWith(
        stage: BackgroundToolStage.submitting,
        clearResult: true,
        clearStatus: true,
        clearMessage: true,
        isRetryable: false,
      ),
    );

    try {
      _localJobId = await _tracker.createForegroundJob(
        type: BgJobType.background,
        sourceBytes: state.imageBytes!,
        maskBytes: maskBytes,
        metadata: {'tool': 'background_cleanup', 'edgeRadius': state.edgeRadius},
        sourcePrefix: 'background_source',
        maskPrefix: 'background_mask',
      );
      final options = CleanEdgesOptions(
        imageBytes: state.imageBytes!,
        imageName: 'background_source.png',
        maskBytes: maskBytes,
        maskName: 'background_mask.png',
        edgeRadius: state.edgeRadius,
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
          stage: state.hasImage
              ? BackgroundToolStage.ready
              : BackgroundToolStage.initial,
          message: 'Mask the background boundary again before retrying.',
          isRetryable: false,
        ),
      );
      return;
    }
    await submit(_lastMaskBytes!);
  }

  void editAgain() {
    if (!state.hasImage) {
      emit(const BackgroundToolState.initial());
      return;
    }
    emit(
      state.copyWith(
        stage: BackgroundToolStage.ready,
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
    emit(const BackgroundToolState.initial());
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
            stage: BackgroundToolStage.processing,
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
              stage: BackgroundToolStage.failure,
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
          stage: BackgroundToolStage.success,
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
        stage: BackgroundToolStage.failure,
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
