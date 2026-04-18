import 'package:equatable/equatable.dart';

class AiJobEntity extends Equatable {
  final String jobId;
  final String status;
  final double progress;
  final String? resultUrl;
  final String? error;

  const AiJobEntity({
    required this.jobId,
    required this.status,
    required this.progress,
    this.resultUrl,
    this.error,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';

  @override
  List<Object?> get props => [jobId, status, progress, resultUrl, error];
}
