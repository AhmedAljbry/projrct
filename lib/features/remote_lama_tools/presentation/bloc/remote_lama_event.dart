import 'package:equatable/equatable.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';

abstract class RemoteLamaEvent extends Equatable {
  const RemoteLamaEvent();

  @override
  List<Object?> get props => [];
}

class SubmitLamaJobEvent extends RemoteLamaEvent {
  final LamaOptions options;

  const SubmitLamaJobEvent(this.options);

  @override
  List<Object?> get props => [options];
}

class PollJobStatusEvent extends RemoteLamaEvent {
  final String jobId;

  const PollJobStatusEvent(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

class FetchJobResultEvent extends RemoteLamaEvent {
  final String jobId;

  const FetchJobResultEvent(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

class ResetLamaStateEvent extends RemoteLamaEvent {}
