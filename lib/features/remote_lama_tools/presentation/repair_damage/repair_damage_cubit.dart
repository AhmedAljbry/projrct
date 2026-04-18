import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/core/background/bg_job_models.dart';
import 'package:untitled2/core/background/operation_tracker.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/domain/failures/lama_failure.dart';
import 'package:untitled2/features/remote_lama_tools/domain/usecases/lama_usecases.dart';

abstract class RepairDamageState {}

class RepairDamageInitial extends RepairDamageState {}

class RepairDamageReady extends RepairDamageState {
  final Uint8List imageBytes;
  RepairDamageReady({required this.imageBytes});
}

class RepairDamageSubmitting extends RepairDamageState {}

class RepairDamageProcessing extends RepairDamageState {
  final LamaJobStatus status;
  RepairDamageProcessing(this.status);
}

class RepairDamageSuccess extends RepairDamageState {
  final Uint8List resultBytes;
  RepairDamageSuccess(this.resultBytes);
}

class RepairDamageFailure extends RepairDamageState {
  final String message;
  final bool isRetryable;
  RepairDamageFailure({required this.message, this.isRetryable = false});
}

class RepairDamageCubit extends Cubit<RepairDamageState> {
  final SubmitJobUseCase _submitJobUseCase;
  final PollJobStatusUseCase _pollJobStatusUseCase;
  final GetJobResultUseCase _getJobResultUseCase;
  StreamSubscription? _pollingSubscription;
  final OperationTracker _tracker = OperationTracker();
  String? _localJobId;

  RepairDamageCubit({
    required SubmitJobUseCase submitJobUseCase,
    required PollJobStatusUseCase pollJobStatusUseCase,
    required GetJobResultUseCase getJobResultUseCase,
  })  : _submitJobUseCase = submitJobUseCase,
        _pollJobStatusUseCase = pollJobStatusUseCase,
        _getJobResultUseCase = getJobResultUseCase,
        super(RepairDamageInitial());

  void setImage(Uint8List bytes) {
    emit(RepairDamageReady(imageBytes: bytes));
  }

  Future<void> submitJob(Uint8List maskBytes) async {
    final currentState = state;
    if (currentState is! RepairDamageReady) return;

    emit(RepairDamageSubmitting());
    try {
      _localJobId = await _tracker.createForegroundJob(
        type: BgJobType.repairDamage,
        sourceBytes: currentState.imageBytes,
        maskBytes: maskBytes,
        metadata: {'tool': 'repair_damage'},
        sourcePrefix: 'repair_source',
        maskPrefix: 'repair_mask',
      );
      final options = RepairDamageOptions(
        imageBytes: currentState.imageBytes,
        imageName: 'repair_source.png',
        maskBytes: maskBytes,
        maskName: 'repair_mask.png',
      );
      final jobId = await _submitJobUseCase.execute(options);
      await _tracker.bindRemoteJob(
        _localJobId!,
        remoteJobId: jobId,
        queued: false,
      );
      _pollJob(jobId);
    } catch (e) {
      _handleError(e);
    }
  }

  void _pollJob(String jobId) {
    _pollingSubscription?.cancel();
    _pollingSubscription = _pollJobStatusUseCase.execute(jobId).listen(
      (status) {
        if (isClosed) return;
        if (_localJobId != null) {
          _tracker.updateFromRemoteStatus(_localJobId!, status);
        }
        emit(RepairDamageProcessing(status));
        if (status.isCompleted) {
          _fetchResult(status.jobId);
        } else if (status.isFailed) {
          emit(RepairDamageFailure(
              message: status.error ?? 'Job failed mysteriously.'));
        }
      },
      onError: (e) {
        if (!isClosed) _handleError(e);
      },
    );
  }

  Future<void> _fetchResult(String jobId) async {
    try {
      final resultBytes = await _getJobResultUseCase.execute(jobId);
      if (_localJobId != null) {
        await _tracker.completeJob(_localJobId!, resultBytes);
      }
      if (!isClosed) {
        emit(RepairDamageSuccess(resultBytes));
      }
    } catch (e) {
      if (_localJobId != null) {
        await _tracker.failJob(_localJobId!, 'Failed fetching result: $e');
      }
      if (!isClosed) {
        emit(RepairDamageFailure(
            message: 'Failed fetching result: $e', isRetryable: true));
      }
    }
  }

  void _handleError(Object e) {
    if (_localJobId != null) {
      _tracker.failJob(_localJobId!, e.toString());
    }
    if (e is LamaRateLimitFailure || e is LamaServerBusyFailure) {
      emit(RepairDamageFailure(
          message: (e as dynamic).message, isRetryable: true));
    } else {
      emit(RepairDamageFailure(message: e.toString()));
    }
  }

  void reset() {
    _pollingSubscription?.cancel();
    _localJobId = null;
    emit(RepairDamageInitial());
  }

  @override
  Future<void> close() {
    _pollingSubscription?.cancel();
    return super.close();
  }
}
