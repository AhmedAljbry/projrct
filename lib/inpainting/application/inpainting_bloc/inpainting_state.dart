import 'dart:typed_data';
import '../../domain/inpainting_status.dart';
import '../../domain/inpainting_failure.dart';

class InpaintingState {
  final InpaintingStatus status;
  final InpaintingFailure? failure;
  final Uint8List? result;

  // ✅ Server-backed fields
  final String? jobId;
  final int? queuePosition;      // /submit-job + /status (when queued)
  final int? serverProgress;     // 0..100 from API
  final String? serverStage;     // queued|processing|saving|completed|failed...
  final String? serverMessage;   // message from API (already i18n from backend)

  // measurable
  final int pollCount;
  final DateTime? startedAt;
  final DateTime? lastUpdatedAt;

  const InpaintingState({
    required this.status,
    this.failure,
    this.result,
    this.jobId,
    this.queuePosition,
    this.serverProgress,
    this.serverStage,
    this.serverMessage,
    this.pollCount = 0,
    this.startedAt,
    this.lastUpdatedAt,
  });

  factory InpaintingState.idle() => const InpaintingState(status: InpaintingStatus.idle);

  InpaintingState copyWith({
    InpaintingStatus? status,
    InpaintingFailure? failure,
    Uint8List? result,
    String? jobId,
    int? queuePosition,
    int? serverProgress,
    String? serverStage,
    String? serverMessage,
    int? pollCount,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
    bool clearFailure = false,
  }) {
    return InpaintingState(
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
      result: result ?? this.result,
      jobId: jobId ?? this.jobId,
      queuePosition: queuePosition ?? this.queuePosition,
      serverProgress: serverProgress ?? this.serverProgress,
      serverStage: serverStage ?? this.serverStage,
      serverMessage: serverMessage ?? this.serverMessage,
      pollCount: pollCount ?? this.pollCount,
      startedAt: startedAt ?? this.startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}