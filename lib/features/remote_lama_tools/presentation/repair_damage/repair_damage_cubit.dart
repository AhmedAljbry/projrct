import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      final options = RepairDamageOptions(
        imageBytes: currentState.imageBytes,
        imageName: 'repair_source.png',
        maskBytes: maskBytes,
        maskName: 'repair_mask.png',
      );
      final jobId = await _submitJobUseCase.execute(options);
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
      if (!isClosed) {
        emit(RepairDamageSuccess(resultBytes));
      }
    } catch (e) {
      if (!isClosed) {
        emit(RepairDamageFailure(
            message: 'Failed fetching result: $e', isRetryable: true));
      }
    }
  }

  void _handleError(Object e) {
    if (e is LamaRateLimitFailure || e is LamaServerBusyFailure) {
      emit(RepairDamageFailure(
          message: (e as dynamic).message, isRetryable: true));
    } else {
      emit(RepairDamageFailure(message: e.toString()));
    }
  }

  void reset() {
    _pollingSubscription?.cancel();
    emit(RepairDamageInitial());
  }

  @override
  Future<void> close() {
    _pollingSubscription?.cancel();
    return super.close();
  }
}
