import 'dart:convert';

/// Defines the mode of operation for the Lama API task.
/// All modes from the Python API are implemented here.
enum LamaTaskMode {
  healRegion,
  repairDamage,
  expandCanvas,
  cleanEdges,
}

extension LamaTaskModeExtension on LamaTaskMode {
  /// Converts the enum to the string value expected by the API.
  String get value {
    switch (this) {
      case LamaTaskMode.healRegion:
        return 'heal_region';
      case LamaTaskMode.repairDamage:
        return 'repair_damage';
      case LamaTaskMode.expandCanvas:
        return 'expand_canvas';
      case LamaTaskMode.cleanEdges:
        return 'clean_edges';
    }
  }
}

/// Represents the status of a job submitted to the Lama Server.
class LamaJobStatus {
  final String jobId;
  final String status;
  final int progress;
  final String message;
  final String? error;
  final int? position;

  LamaJobStatus({
    required this.jobId,
    required this.status,
    required this.progress,
    required this.message,
    this.error,
    this.position,
  });

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing';
  bool get isQueued => status == 'queued';

  factory LamaJobStatus.fromJson(Map<String, dynamic> json) {
    return LamaJobStatus(
      jobId: json['job_id'] ?? '',
      status: json['status'] ?? 'unknown',
      progress: json['progress'] ?? 0,
      message: json['message'] ?? '',
      error: json['error'],
      position: json['position'],
    );
  }
}

/// Options to configure exactly how the canvas should be expanded
/// for the `expand_canvas` feature.
class ExpandOptions {
  final int left;
  final int top;
  final int right;
  final int bottom;
  
  /// The anchor point for the original image inside the new expanded canvas.
  /// Allowed values: center, top_left, top_right, bottom_left, bottom_right, left, right, top, bottom
  final String anchor;

  const ExpandOptions({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.anchor = 'center',
  });
}
