import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';

import '../../domain/entities/blur_mode.dart';
import '../../domain/entities/blur_operation.dart';
import '../../domain/entities/blur_settings.dart';

/// Editor status lifecycle.
enum BpEditorStatus { loading, ready, processing, exporting, error }

/// Complete immutable state snapshot for [BlurPhotoCubit].
class BlurPhotoState extends Equatable {
  BlurPhotoState({
    this.status = BpEditorStatus.loading,
    this.originalImage,
    this.previewImage,
    BlurOperation? operation,
    this.undoStack = const [],
    this.redoStack = const [],
    this.segmentationInProgress = false,
    this.textDetectionInProgress = false,
    this.showOriginal = false,
    this.hintMessage,
    this.errorMessage,
  }) : operation = operation ?? BlurOperation.initial();

  final BpEditorStatus status;
  final ui.Image? originalImage;
  final ui.Image? previewImage;
  final BlurOperation operation;

  /// Undo stack — most recent at end.
  final List<BlurOperation> undoStack;
  final List<BlurOperation> redoStack;

  final bool segmentationInProgress;
  final bool textDetectionInProgress;
  final bool showOriginal;
  final String? hintMessage;
  final String? errorMessage;

  // ── Convenience getters ────────────────────────────────────────────────────
  BlurPhotoMode get activeMode => operation.settings.mode;
  BlurPhotoSettings get settings => operation.settings;
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  bool get isBusy =>
      status == BpEditorStatus.processing ||
      status == BpEditorStatus.exporting ||
      segmentationInProgress ||
      textDetectionInProgress;

  BlurPhotoState copyWith({
    BpEditorStatus? status,
    ui.Image? originalImage,
    ui.Image? previewImage,
    BlurOperation? operation,
    List<BlurOperation>? undoStack,
    List<BlurOperation>? redoStack,
    bool? segmentationInProgress,
    bool? textDetectionInProgress,
    bool? showOriginal,
    String? hintMessage,
    bool clearHint = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BlurPhotoState(
      status: status ?? this.status,
      originalImage: originalImage ?? this.originalImage,
      previewImage: previewImage ?? this.previewImage,
      operation: operation ?? this.operation,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      segmentationInProgress:
          segmentationInProgress ?? this.segmentationInProgress,
      textDetectionInProgress:
          textDetectionInProgress ?? this.textDetectionInProgress,
      showOriginal: showOriginal ?? this.showOriginal,
      hintMessage: clearHint ? null : (hintMessage ?? this.hintMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        originalImage,
        previewImage,
        operation,
        undoStack,
        redoStack,
        segmentationInProgress,
        textDetectionInProgress,
        showOriginal,
        hintMessage,
        errorMessage,
      ];
}
