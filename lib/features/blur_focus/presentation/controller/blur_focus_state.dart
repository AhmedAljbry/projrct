import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_focus_operation.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_mode.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';

enum BlurFocusStatus { loading, ready, processing, exporting, error }

class BlurFocusState extends Equatable {
  BlurFocusState({
    this.status = BlurFocusStatus.loading,
    this.originalImage,
    this.previewImage,
    BlurFocusOperation? operation,
    this.undoStack = const [],
    this.redoStack = const [],
    this.showOriginalPreview = false,
    this.showMaskPreview = false,
    this.refineMaskMode = false,
    this.segmentationInProgress = false,
    this.manualBlendMode = ManualMaskBlendMode.include,
    this.hintMessage,
    this.errorMessage,
    DateTime? lastInteractionAt,
  })  : operation = operation ?? BlurFocusOperation.initial(),
        lastInteractionAt = lastInteractionAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final BlurFocusStatus status;
  final ui.Image? originalImage;
  final ui.Image? previewImage;
  final BlurFocusOperation operation;
  final List<BlurFocusOperation> undoStack;
  final List<BlurFocusOperation> redoStack;
  final bool showOriginalPreview;
  final bool showMaskPreview;
  final bool refineMaskMode;
  final bool segmentationInProgress;
  final ManualMaskBlendMode manualBlendMode;
  final String? hintMessage;
  final String? errorMessage;
  final DateTime lastInteractionAt;

  BlurFocusState copyWith({
    BlurFocusStatus? status,
    ui.Image? originalImage,
    ui.Image? previewImage,
    BlurFocusOperation? operation,
    List<BlurFocusOperation>? undoStack,
    List<BlurFocusOperation>? redoStack,
    bool? showOriginalPreview,
    bool? showMaskPreview,
    bool? refineMaskMode,
    bool? segmentationInProgress,
    ManualMaskBlendMode? manualBlendMode,
    String? hintMessage,
    bool clearHint = false,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastInteractionAt,
  }) {
    return BlurFocusState(
      status: status ?? this.status,
      originalImage: originalImage ?? this.originalImage,
      previewImage: previewImage ?? this.previewImage,
      operation: operation ?? this.operation,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      showOriginalPreview: showOriginalPreview ?? this.showOriginalPreview,
      showMaskPreview: showMaskPreview ?? this.showMaskPreview,
      refineMaskMode: refineMaskMode ?? this.refineMaskMode,
      segmentationInProgress: segmentationInProgress ?? this.segmentationInProgress,
      manualBlendMode: manualBlendMode ?? this.manualBlendMode,
      hintMessage: clearHint ? null : (hintMessage ?? this.hintMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
    );
  }

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  bool get hasSegmentation => operation.segmentation != null;
  BlurMode get activeMode => operation.settings.mode;

  @override
  List<Object?> get props => [
        status,
        originalImage,
        previewImage,
        operation,
        undoStack,
        redoStack,
        showOriginalPreview,
        showMaskPreview,
        refineMaskMode,
        segmentationInProgress,
        manualBlendMode,
        hintMessage,
        errorMessage,
        lastInteractionAt,
      ];
}
