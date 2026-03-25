import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';

import '../domain/models/af_blur_mode.dart';
import '../domain/models/af_blur_operation.dart';

enum AfEditorStatus { loading, ready, processing, exporting, error }

/// Immutable state snapshot for the blur focus editor Cubit.
class AfBlurState extends Equatable {
  AfBlurState({
    this.status = AfEditorStatus.loading,
    this.originalImage,
    this.previewImage,
    AfBlurOperation? operation,
    this.undoStack = const [],
    this.redoStack = const [],
    this.showOriginalPreview = false,
    this.showMaskOverlay = false,
    this.refineMaskMode = false,
    this.segmentationInProgress = false,
    this.brushAdd = true,
    this.hintMessage,
    this.errorMessage,
  }) : operation = operation ?? AfBlurOperation.initial();

  final AfEditorStatus status;
  final ui.Image? originalImage;
  final ui.Image? previewImage;
  final AfBlurOperation operation;
  final List<AfBlurOperation> undoStack;
  final List<AfBlurOperation> redoStack;
  final bool showOriginalPreview;
  final bool showMaskOverlay;
  final bool refineMaskMode;
  final bool segmentationInProgress;
  final bool brushAdd;
  final String? hintMessage;
  final String? errorMessage;

  AfBlurState copyWith({
    AfEditorStatus? status,
    ui.Image? originalImage,
    ui.Image? previewImage,
    AfBlurOperation? operation,
    List<AfBlurOperation>? undoStack,
    List<AfBlurOperation>? redoStack,
    bool? showOriginalPreview,
    bool? showMaskOverlay,
    bool? refineMaskMode,
    bool? segmentationInProgress,
    bool? brushAdd,
    String? hintMessage,
    bool clearHint = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AfBlurState(
      status: status ?? this.status,
      originalImage: originalImage ?? this.originalImage,
      previewImage: previewImage ?? this.previewImage,
      operation: operation ?? this.operation,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      showOriginalPreview: showOriginalPreview ?? this.showOriginalPreview,
      showMaskOverlay: showMaskOverlay ?? this.showMaskOverlay,
      refineMaskMode: refineMaskMode ?? this.refineMaskMode,
      segmentationInProgress:
          segmentationInProgress ?? this.segmentationInProgress,
      brushAdd: brushAdd ?? this.brushAdd,
      hintMessage: clearHint ? null : (hintMessage ?? this.hintMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  bool get hasSegmentation => operation.maskData != null;
  AfBlurMode get activeMode => operation.settings.mode;

  @override
  List<Object?> get props => [
        status,
        originalImage,
        previewImage,
        operation,
        undoStack,
        redoStack,
        showOriginalPreview,
        showMaskOverlay,
        refineMaskMode,
        segmentationInProgress,
        brushAdd,
        hintMessage,
        errorMessage,
      ];
}
