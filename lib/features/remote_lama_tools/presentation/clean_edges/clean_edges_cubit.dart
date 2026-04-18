import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/core/background/bg_job_models.dart';
import 'package:untitled2/core/background/operation_tracker.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/domain/failures/lama_failure.dart';
import 'package:untitled2/features/remote_lama_tools/domain/usecases/lama_usecases.dart';

abstract class CleanEdgesState {}

class CleanEdgesInitial extends CleanEdgesState {}

class CleanEdgesReady extends CleanEdgesState {
  final Uint8List imageBytes;
  final int edgeRadius;

  CleanEdgesReady({
    required this.imageBytes,
    this.edgeRadius = 4,
  });

  CleanEdgesReady copyWith({
    Uint8List? imageBytes,
    int? edgeRadius,
  }) {
    return CleanEdgesReady(
      imageBytes: imageBytes ?? this.imageBytes,
      edgeRadius: edgeRadius ?? this.edgeRadius,
    );
  }
}

class CleanEdgesSubmitting extends CleanEdgesState {}

class CleanEdgesProcessing extends CleanEdgesState {
  final LamaJobStatus status;
  CleanEdgesProcessing(this.status);
}

class CleanEdgesSuccess extends CleanEdgesState {
  final Uint8List resultBytes;
  CleanEdgesSuccess(this.resultBytes);
}

class CleanEdgesFailure extends CleanEdgesState {
  final String message;
  final bool isRetryable;
  CleanEdgesFailure({required this.message, this.isRetryable = false});
}

class CleanEdgesCubit extends Cubit<CleanEdgesState> {
  final SubmitJobUseCase _submitJobUseCase;
  final PollJobStatusUseCase _pollJobStatusUseCase;
  final GetJobResultUseCase _getJobResultUseCase;
  final OperationTracker _operationTracker;

  StreamSubscription<LamaJobStatus>? _pollingSubscription;

  CleanEdgesCubit({
    required SubmitJobUseCase submitJobUseCase,
    required PollJobStatusUseCase pollJobStatusUseCase,
    required GetJobResultUseCase getJobResultUseCase,
    OperationTracker? operationTracker,
  })  : _submitJobUseCase = submitJobUseCase,
        _pollJobStatusUseCase = pollJobStatusUseCase,
        _getJobResultUseCase = getJobResultUseCase,
        _operationTracker = operationTracker ?? OperationTracker(),
        super(CleanEdgesInitial());

  void setImage(Uint8List bytes) {
    emit(CleanEdgesReady(imageBytes: bytes));
  }

  void updateRadius(int radius) {
    final currentState = state;
    if (currentState is CleanEdgesReady) {
      emit(currentState.copyWith(edgeRadius: radius));
    }
  }

  Future<String?> submitJob(Uint8List maskBytes) async {
    final currentState = state;
    if (currentState is! CleanEdgesReady) {
      return null;
    }

    emit(CleanEdgesSubmitting());

    String? localJobId;
    try {
      localJobId = await _operationTracker.createForegroundJob(
        type: BgJobType.cleanEdges,
        sourceBytes: currentState.imageBytes,
        maskBytes: maskBytes,
        metadata: {'edgeRadius': currentState.edgeRadius},
        sourcePrefix: 'clean_source',
        maskPrefix: 'clean_mask',
      );

      final remoteJobId = await _submitJobUseCase.execute(
        CleanEdgesOptions(
          imageBytes: currentState.imageBytes,
          imageName: 'clean_edges.png',
          maskBytes: maskBytes,
          maskName: 'clean_edges_mask.png',
          edgeRadius: currentState.edgeRadius,
        ),
      );

      await _operationTracker.bindRemoteJob(
        localJobId,
        remoteJobId: remoteJobId,
        queued: true,
        message: 'Queued on API',
      );

      final queuedStatus = LamaJobStatus(
        jobId: remoteJobId,
        status: 'queued',
        progress: 0,
        message: 'Queued on API',
      );
      emit(CleanEdgesProcessing(queuedStatus));
      _pollJob(remoteJobId, localJobId);
      return localJobId;
    } catch (e) {
      await _failJob(localJobId, e);
      return null;
    }
  }

  void _pollJob(String remoteJobId, String localJobId) {
    _pollingSubscription?.cancel();
    _pollingSubscription = _pollJobStatusUseCase.execute(remoteJobId).listen(
      (status) async {
        if (isClosed) {
          return;
        }

        await _operationTracker.updateFromRemoteStatus(localJobId, status);
        emit(CleanEdgesProcessing(status));

        if (status.isCompleted) {
          await _fetchResult(localJobId, status.jobId);
        } else if (status.isFailed) {
          await _operationTracker.failJob(
            localJobId,
            status.error ?? 'Clean edges request failed.',
          );
          emit(
            CleanEdgesFailure(
              message: status.error ?? 'Clean edges request failed.',
              isRetryable: true,
            ),
          );
        }
      },
      onError: (e) async {
        if (!isClosed) {
          await _failJob(localJobId, e);
        }
      },
    );
  }

  Future<void> _fetchResult(String localJobId, String remoteJobId) async {
    try {
      final resultBytes = await _getJobResultUseCase.execute(remoteJobId);
      await _operationTracker.completeJob(localJobId, resultBytes);
      if (!isClosed) {
        emit(CleanEdgesSuccess(resultBytes));
      }
    } catch (e) {
      await _failJob(localJobId, 'Failed fetching result: $e');
    }
  }

  Future<void> _failJob(String? localJobId, Object error) async {
    if (localJobId != null) {
      await _operationTracker.failJob(localJobId, error.toString());
    }
    if (!isClosed) {
      _handleError(error);
    }
  }

  void _handleError(Object e) {
    if (e is LamaRateLimitFailure || e is LamaServerBusyFailure) {
      emit(CleanEdgesFailure(message: (e as dynamic).message, isRetryable: true));
    } else {
      emit(CleanEdgesFailure(message: e.toString(), isRetryable: true));
    }
  }

  void reset() {
    _pollingSubscription?.cancel();
    emit(CleanEdgesInitial());
  }

  @override
  Future<void> close() {
    _pollingSubscription?.cancel();
    return super.close();
  }
}
