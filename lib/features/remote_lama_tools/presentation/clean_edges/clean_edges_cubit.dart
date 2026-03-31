import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  StreamSubscription? _pollingSubscription;

  CleanEdgesCubit({
    required SubmitJobUseCase submitJobUseCase,
    required PollJobStatusUseCase pollJobStatusUseCase,
    required GetJobResultUseCase getJobResultUseCase,
  })  : _submitJobUseCase = submitJobUseCase,
        _pollJobStatusUseCase = pollJobStatusUseCase,
        _getJobResultUseCase = getJobResultUseCase,
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

  Future<void> submitJob(Uint8List maskBytes) async {
    final currentState = state;
    if (currentState is! CleanEdgesReady) return;

    emit(CleanEdgesSubmitting());
    try {
      final options = CleanEdgesOptions(
        imageBytes: currentState.imageBytes,
        imageName: 'clean_source.png',
        maskBytes: maskBytes,
        maskName: 'clean_mask.png',
        edgeRadius: currentState.edgeRadius,
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
        emit(CleanEdgesProcessing(status));
        if (status.isCompleted) {
          _fetchResult(status.jobId);
        } else if (status.isFailed) {
          emit(CleanEdgesFailure(message: status.error ?? 'Job failed mysteriously.'));
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
      if (!isClosed) emit(CleanEdgesSuccess(resultBytes));
    } catch (e) {
      if (!isClosed) emit(CleanEdgesFailure(message: 'Failed fetching result: $e', isRetryable: true));
    }
  }

  void _handleError(Object e) {
    if (e is LamaRateLimitFailure || e is LamaServerBusyFailure) {
      emit(CleanEdgesFailure(message: (e as dynamic).message, isRetryable: true));
    } else {
      emit(CleanEdgesFailure(message: e.toString()));
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
