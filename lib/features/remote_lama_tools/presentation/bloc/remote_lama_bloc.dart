import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/features/remote_lama_tools/domain/failures/lama_failure.dart';
import 'package:untitled2/features/remote_lama_tools/domain/usecases/lama_usecases.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/bloc/remote_lama_event.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/bloc/remote_lama_state.dart';

class RemoteLamaBloc extends Bloc<RemoteLamaEvent, RemoteLamaState> {
  final SubmitJobUseCase _submitJobUseCase;
  final PollJobStatusUseCase _pollJobStatusUseCase;
  final GetJobResultUseCase _getJobResultUseCase;

  StreamSubscription? _pollingSubscription;

  RemoteLamaBloc({
    required SubmitJobUseCase submitJobUseCase,
    required PollJobStatusUseCase pollJobStatusUseCase,
    required GetJobResultUseCase getJobResultUseCase,
  })  : _submitJobUseCase = submitJobUseCase,
        _pollJobStatusUseCase = pollJobStatusUseCase,
        _getJobResultUseCase = getJobResultUseCase,
        super(RemoteLamaInitial()) {
    on<SubmitLamaJobEvent>(_onSubmitJob);
    on<PollJobStatusEvent>(_onPollJobStatus);
    on<FetchJobResultEvent>(_onFetchJobResult);
    on<ResetLamaStateEvent>(_onResetState);
  }

  Future<void> _onSubmitJob(SubmitLamaJobEvent event, Emitter<RemoteLamaState> emit) async {
    emit(RemoteLamaSubmitting());
    try {
      final jobId = await _submitJobUseCase.execute(event.options);
      add(PollJobStatusEvent(jobId));
    } catch (e) {
      if (e is LamaRateLimitFailure || e is LamaServerBusyFailure) {
        emit(RemoteLamaFailureState(message: (e as dynamic).message, isRetryable: true));
      } else {
        emit(RemoteLamaFailureState(message: e.toString()));
      }
    }
  }

  Future<void> _onPollJobStatus(PollJobStatusEvent event, Emitter<RemoteLamaState> emit) async {
    await _pollingSubscription?.cancel();

    final completer = Completer<void>();

    _pollingSubscription = _pollJobStatusUseCase.execute(event.jobId).listen(
      (status) {
        emit(RemoteLamaProcessing(status));
        if (status.isCompleted) {
          add(FetchJobResultEvent(status.jobId));
          completer.complete();
        } else if (status.isFailed) {
          emit(RemoteLamaFailureState(message: status.error ?? 'Job failed mysteriously.'));
          completer.complete();
        }
      },
      onError: (e) {
        emit(RemoteLamaFailureState(message: e.toString(), isRetryable: true));
        completer.complete();
      },
    );

    // Keep the handler alive until polling concludes
    await completer.future;
  }

  Future<void> _onFetchJobResult(FetchJobResultEvent event, Emitter<RemoteLamaState> emit) async {
    try {
      final resultBytes = await _getJobResultUseCase.execute(event.jobId);
      emit(RemoteLamaSuccess(resultBytes));
    } catch (e) {
      emit(RemoteLamaFailureState(message: 'Failed fetching result: ${e.toString()}', isRetryable: true));
    }
  }

  void _onResetState(ResetLamaStateEvent event, Emitter<RemoteLamaState> emit) {
    _pollingSubscription?.cancel();
    emit(RemoteLamaInitial());
  }

  @override
  Future<void> close() {
    _pollingSubscription?.cancel();
    return super.close();
  }
}
