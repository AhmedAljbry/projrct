import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/core/background/bg_job_models.dart';
import 'package:untitled2/core/background/operation_tracker.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/domain/failures/lama_failure.dart';
import 'package:untitled2/features/remote_lama_tools/domain/usecases/lama_usecases.dart';

abstract class HealRegionState {}

class HealRegionInitial extends HealRegionState {}

class HealRegionReady extends HealRegionState {
  final Uint8List imageBytes;
  final int healRadius;

  HealRegionReady({
    required this.imageBytes,
    this.healRadius = 0,
  });

  HealRegionReady copyWith({
    Uint8List? imageBytes,
    int? healRadius,
  }) {
    return HealRegionReady(
      imageBytes: imageBytes ?? this.imageBytes,
      healRadius: healRadius ?? this.healRadius,
    );
  }
}

class HealRegionSubmitting extends HealRegionState {}

class HealRegionProcessing extends HealRegionState {
  final LamaJobStatus status;
  HealRegionProcessing(this.status);
}

class HealRegionSuccess extends HealRegionState {
  final Uint8List resultBytes;
  HealRegionSuccess(this.resultBytes);
}

class HealRegionFailure extends HealRegionState {
  final String message;
  final bool isRetryable;
  HealRegionFailure({required this.message, this.isRetryable = false});
}

class HealRegionCubit extends Cubit<HealRegionState> {
  final SubmitJobUseCase _submitJobUseCase;
  final PollJobStatusUseCase _pollJobStatusUseCase;
  final GetJobResultUseCase _getJobResultUseCase;
  final OperationTracker _operationTracker;

  StreamSubscription<LamaJobStatus>? _pollingSubscription;

  HealRegionCubit({
    required SubmitJobUseCase submitJobUseCase,
    required PollJobStatusUseCase pollJobStatusUseCase,
    required GetJobResultUseCase getJobResultUseCase,
    OperationTracker? operationTracker,
  })  : _submitJobUseCase = submitJobUseCase,
        _pollJobStatusUseCase = pollJobStatusUseCase,
        _getJobResultUseCase = getJobResultUseCase,
        _operationTracker = operationTracker ?? OperationTracker(),
        super(HealRegionInitial());

  void setImage(Uint8List bytes) {
    emit(HealRegionReady(imageBytes: bytes));
  }

  void updateRadius(int radius) {
    final currentState = state;
    if (currentState is HealRegionReady) {
      emit(currentState.copyWith(healRadius: radius));
    }
  }

  Future<String?> submitJob(Uint8List maskBytes) async {
    final currentState = state;
    if (currentState is! HealRegionReady) {
      return null;
    }

    emit(HealRegionSubmitting());

    try {
      final localJobId = await _operationTracker.createForegroundJob(
        type: BgJobType.heal,
        sourceBytes: currentState.imageBytes,
        maskBytes: maskBytes,
        metadata: {'healRadius': currentState.healRadius},
        sourcePrefix: 'heal_source',
        maskPrefix: 'heal_mask',
      );
      unawaited(_submitRemoteJob(
        localJobId: localJobId,
        imageBytes: currentState.imageBytes,
        maskBytes: maskBytes,
        healRadius: currentState.healRadius,
      ));
      return localJobId;
    } catch (e) {
      await _failJob(null, e);
      return null;
    }
  }

  Future<void> _submitRemoteJob({
    required String localJobId,
    required Uint8List imageBytes,
    required Uint8List maskBytes,
    required int healRadius,
  }) async {
    try {
      final remoteJobId = await _submitJobUseCase.execute(
        HealRegionOptions(
          imageBytes: imageBytes,
          imageName: 'heal_region.png',
          maskBytes: maskBytes,
          maskName: 'heal_region_mask.png',
          healRadius: healRadius,
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
      if (!isClosed) {
        emit(HealRegionProcessing(queuedStatus));
      }
      _pollJob(remoteJobId, localJobId);
    } catch (e) {
      await _failJob(localJobId, e);
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
        emit(HealRegionProcessing(status));

        if (status.isCompleted) {
          await _fetchResult(localJobId, status.jobId);
        } else if (status.isFailed) {
          await _operationTracker.failJob(
            localJobId,
            status.error ?? 'Heal request failed.',
          );
          emit(
            HealRegionFailure(
              message: status.error ?? 'Heal request failed.',
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
        emit(HealRegionSuccess(resultBytes));
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
      emit(HealRegionFailure(
          message: (e as dynamic).message, isRetryable: true));
    } else {
      emit(HealRegionFailure(message: e.toString(), isRetryable: true));
    }
  }

  void reset() {
    _pollingSubscription?.cancel();
    emit(HealRegionInitial());
  }

  @override
  Future<void> close() {
    _pollingSubscription?.cancel();
    return super.close();
  }
}
