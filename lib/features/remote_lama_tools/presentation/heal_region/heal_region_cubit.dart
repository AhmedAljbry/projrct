import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  StreamSubscription? _pollingSubscription;

  HealRegionCubit({
    required SubmitJobUseCase submitJobUseCase,
    required PollJobStatusUseCase pollJobStatusUseCase,
    required GetJobResultUseCase getJobResultUseCase,
  })  : _submitJobUseCase = submitJobUseCase,
        _pollJobStatusUseCase = pollJobStatusUseCase,
        _getJobResultUseCase = getJobResultUseCase,
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

  Future<void> submitJob(Uint8List maskBytes) async {
    final currentState = state;
    if (currentState is! HealRegionReady) return;

    emit(HealRegionSubmitting());
    try {
      final options = HealRegionOptions(
        imageBytes: currentState.imageBytes,
        imageName: 'heal_source.png',
        maskBytes: maskBytes,
        maskName: 'heal_mask.png',
        healRadius: currentState.healRadius,
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
        emit(HealRegionProcessing(status));
        if (status.isCompleted) {
          _fetchResult(status.jobId);
        } else if (status.isFailed) {
          emit(HealRegionFailure(message: status.error ?? 'Job failed mysteriously.'));
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
      if (!isClosed) emit(HealRegionSuccess(resultBytes));
    } catch (e) {
      if (!isClosed) emit(HealRegionFailure(message: 'Failed fetching result: $e', isRetryable: true));
    }
  }

  void _handleError(Object e) {
    if (e is LamaRateLimitFailure || e is LamaServerBusyFailure) {
      emit(HealRegionFailure(message: (e as dynamic).message, isRetryable: true));
    } else {
      emit(HealRegionFailure(message: e.toString()));
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
