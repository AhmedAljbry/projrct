import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/domain/failures/lama_failure.dart';

abstract class RemoteLamaState extends Equatable {
  const RemoteLamaState();

  @override
  List<Object?> get props => [];
}

class RemoteLamaInitial extends RemoteLamaState {}

class RemoteLamaSubmitting extends RemoteLamaState {}

class RemoteLamaProcessing extends RemoteLamaState {
  final LamaJobStatus jobStatus;

  const RemoteLamaProcessing(this.jobStatus);

  @override
  List<Object?> get props => [jobStatus.jobId, jobStatus.progress, jobStatus.status];
}

class RemoteLamaSuccess extends RemoteLamaState {
  final Uint8List resultBytes;

  const RemoteLamaSuccess(this.resultBytes);

  @override
  List<Object?> get props => [resultBytes];
}

class RemoteLamaFailureState extends RemoteLamaState {
  final String message;
  final bool isRetryable;

  const RemoteLamaFailureState({required this.message, this.isRetryable = false});

  @override
  List<Object?> get props => [message, isRetryable];
}
