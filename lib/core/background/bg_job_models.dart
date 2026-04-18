import 'dart:convert';
import 'package:equatable/equatable.dart';

enum JobStatus {
  pending,
  queued,
  preparing,
  uploading,
  processing,
  retryWaiting,
  completed,
  failed,
  cancelled
}

enum BgJobType {
  magic,
  heal,
  cleanEdges,
  repairDamage,
  descratch,
  background,
  expandCanvas,
}

class BackgroundJob extends Equatable {
  final String jobId;
  final BgJobType toolType;
  final String sourceImagePath;
  final String? maskImagePath;
  final String? outputImagePath;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  final JobStatus status;
  final int progress;
  
  final int retryCount;
  final int maxRetries;
  final String? errorMessage;
  
  final int queuePosition;
  final bool isCancelled;
  final Map<String, dynamic> metadata;

  const BackgroundJob({
    required this.jobId,
    required this.toolType,
    required this.sourceImagePath,
    this.maskImagePath,
    this.outputImagePath,
    required this.createdAt,
    required this.updatedAt,
    this.status = JobStatus.pending,
    this.progress = 0,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.errorMessage,
    this.queuePosition = 0,
    this.isCancelled = false,
    this.metadata = const {},
  });

  BackgroundJob copyWith({
    String? jobId,
    BgJobType? toolType,
    String? sourceImagePath,
    String? maskImagePath,
    String? outputImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    JobStatus? status,
    int? progress,
    int? retryCount,
    int? maxRetries,
    String? errorMessage,
    int? queuePosition,
    bool? isCancelled,
    Map<String, dynamic>? metadata,
  }) {
    return BackgroundJob(
      jobId: jobId ?? this.jobId,
      toolType: toolType ?? this.toolType,
      sourceImagePath: sourceImagePath ?? this.sourceImagePath,
      maskImagePath: maskImagePath ?? this.maskImagePath,
      outputImagePath: outputImagePath ?? this.outputImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      errorMessage: errorMessage ?? this.errorMessage,
      queuePosition: queuePosition ?? this.queuePosition,
      isCancelled: isCancelled ?? this.isCancelled,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'toolType': toolType.name,
      'sourceImagePath': sourceImagePath,
      'maskImagePath': maskImagePath,
      'outputImagePath': outputImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'progress': progress,
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'errorMessage': errorMessage,
      'queuePosition': queuePosition,
      'isCancelled': isCancelled,
      'metadata': jsonEncode(metadata),
    };
  }

  factory BackgroundJob.fromMap(Map<String, dynamic> map) {
    return BackgroundJob(
      jobId: map['jobId'] ?? '',
      toolType: BgJobType.values.firstWhere(
        (e) => e.name == map['toolType'],
        orElse: () => BgJobType.magic,
      ),
      sourceImagePath: map['sourceImagePath'] ?? '',
      maskImagePath: map['maskImagePath'],
      outputImagePath: map['outputImagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      status: JobStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JobStatus.pending,
      ),
      progress: map['progress']?.toInt() ?? 0,
      retryCount: map['retryCount']?.toInt() ?? 0,
      maxRetries: map['maxRetries']?.toInt() ?? 3,
      errorMessage: map['errorMessage'],
      queuePosition: map['queuePosition']?.toInt() ?? 0,
      isCancelled: map['isCancelled'] ?? false,
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : {},
    );
  }

  String toJson() => json.encode(toMap());

  factory BackgroundJob.fromJson(String source) => BackgroundJob.fromMap(json.decode(source));

  @override
  List<Object?> get props => [
        jobId,
        toolType,
        sourceImagePath,
        maskImagePath,
        outputImagePath,
        createdAt,
        updatedAt,
        status,
        progress,
        retryCount,
        maxRetries,
        errorMessage,
        queuePosition,
        isCancelled,
        metadata,
      ];
}
