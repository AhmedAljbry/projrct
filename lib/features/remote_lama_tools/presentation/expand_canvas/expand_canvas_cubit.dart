import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/domain/failures/lama_failure.dart';
import 'package:untitled2/features/remote_lama_tools/domain/usecases/lama_usecases.dart';

abstract class ExpandCanvasState {}

class ExpandCanvasInitial extends ExpandCanvasState {}

class ExpandCanvasReady extends ExpandCanvasState {
  final Uint8List imageBytes;
  final int left;
  final int top;
  final int right;
  final int bottom;

  ExpandCanvasReady({
    required this.imageBytes,
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  ExpandCanvasReady copyWith({
    Uint8List? imageBytes,
    int? left,
    int? top,
    int? right,
    int? bottom,
  }) {
    return ExpandCanvasReady(
      imageBytes: imageBytes ?? this.imageBytes,
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }
}

class ExpandCanvasSubmitting extends ExpandCanvasState {}

class ExpandCanvasProcessing extends ExpandCanvasState {
  final LamaJobStatus status;
  ExpandCanvasProcessing(this.status);
}

class ExpandCanvasSuccess extends ExpandCanvasState {
  final Uint8List resultBytes;
  ExpandCanvasSuccess(this.resultBytes);
}

class ExpandCanvasFailure extends ExpandCanvasState {
  final String message;
  final bool isRetryable;
  ExpandCanvasFailure({required this.message, this.isRetryable = false});
}

class ExpandCanvasCubit extends Cubit<ExpandCanvasState> {
  final SubmitJobUseCase _submitJobUseCase;
  final PollJobStatusUseCase _pollJobStatusUseCase;
  final GetJobResultUseCase _getJobResultUseCase;
  StreamSubscription? _pollingSubscription;

  ExpandCanvasCubit({
    required SubmitJobUseCase submitJobUseCase,
    required PollJobStatusUseCase pollJobStatusUseCase,
    required GetJobResultUseCase getJobResultUseCase,
  })  : _submitJobUseCase = submitJobUseCase,
        _pollJobStatusUseCase = pollJobStatusUseCase,
        _getJobResultUseCase = getJobResultUseCase,
        super(ExpandCanvasInitial());

  void setImage(Uint8List bytes) {
    emit(ExpandCanvasReady(imageBytes: bytes));
  }

  void updatePadding({int? left, int? top, int? right, int? bottom}) {
    final currentState = state;
    if (currentState is ExpandCanvasReady) {
      emit(currentState.copyWith(
          left: left, top: top, right: right, bottom: bottom));
    }
  }

  Future<void> submitJob([Uint8List? maskBytes]) async {
    final currentState = state;
    if (currentState is! ExpandCanvasReady) return;

    if (currentState.left == 0 &&
        currentState.top == 0 &&
        currentState.right == 0 &&
        currentState.bottom == 0) {
      emit(ExpandCanvasFailure(
          message: 'Select expansion values greater than 0',
          isRetryable: true));
      emit(currentState);
      return;
    }

    emit(ExpandCanvasSubmitting());
    try {
      final options = ExpandCanvasOptions(
        imageBytes: currentState.imageBytes,
        imageName: 'expand_source.png',
        maskBytes: maskBytes,
        maskName: maskBytes == null ? null : 'expand_mask.png',
        left: currentState.left,
        top: currentState.top,
        right: currentState.right,
        bottom: currentState.bottom,
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
        emit(ExpandCanvasProcessing(status));
        if (status.isCompleted) {
          _fetchResult(status.jobId);
        } else if (status.isFailed) {
          emit(ExpandCanvasFailure(
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
        emit(ExpandCanvasSuccess(resultBytes));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ExpandCanvasFailure(
            message: 'Failed fetching result: $e', isRetryable: true));
      }
    }
  }

  void _handleError(Object e) {
    if (e is LamaRateLimitFailure || e is LamaServerBusyFailure) {
      emit(ExpandCanvasFailure(
          message: (e as dynamic).message, isRetryable: true));
    } else {
      emit(ExpandCanvasFailure(message: e.toString()));
    }
  }

  void reset() {
    _pollingSubscription?.cancel();
    emit(ExpandCanvasInitial());
  }

  @override
  Future<void> close() {
    _pollingSubscription?.cancel();
    return super.close();
  }
}
