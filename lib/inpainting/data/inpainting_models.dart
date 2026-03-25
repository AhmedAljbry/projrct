/// Response from POST /submit-job
class SubmitJobResponse {
  final String jobId;
  final int? position;   // queue position (null = starts immediately)
  final String? message; // localised message from server

  const SubmitJobResponse({
    required this.jobId,
    this.position,
    this.message,
  });
}

/// Response from GET /status/{jobId}
class JobStatusResponse {
  /// Coarse status: queued | processing | completed | failed | cancelled
  final String status;

  /// Fine-grained stage from backend
  final String stage;

  /// Progress 0–100
  final int progress;

  /// Localised human-readable message from server
  final String message;

  /// Queue position — only present when status == 'queued'
  final int? position;

  const JobStatusResponse({
    required this.status,
    required this.stage,
    required this.progress,
    required this.message,
    this.position,
  });

  bool get isQueued    => status == 'queued';
  bool get isProcessing=> status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed    => status == 'failed';
  bool get isCancelled => status == 'cancelled';
}
