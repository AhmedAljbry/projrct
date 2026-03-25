import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:meta/meta.dart';
import 'package:untitled2/vv/blemish_operation.dart';
import 'package:untitled2/vv/brush_settings.dart';


/// Processing status of the blemish engine.
enum ProcessingStatus {
  idle,
  processingPreview,
  processingFinal,
  exporting,
  error,
}

/// Represents whether we're in before/after compare mode.
enum CompareMode { edited, original }

/// The full immutable UI state for the blemish remover feature.
@immutable
class BlemishState {
  // ─── Source image ────────────────────────────────────────────────────────────
  final ui.Image? sourceImage;
  final int imageWidth;
  final int imageHeight;

  // ─── Brush ───────────────────────────────────────────────────────────────────
  final BrushSettings brushSettings;

  // ─── Canvas transform ────────────────────────────────────────────────────────
  final double canvasScale;
  final Offset canvasTranslation;

  // ─── Operations ──────────────────────────────────────────────────────────────
  /// Committed operations in application order.
  final List<BlemishOperation> operations;

  // ─── In-progress stroke ──────────────────────────────────────────────────────
  /// Touch points of the stroke currently being drawn (not yet committed).
  final List<Offset> activeStrokePoints;

  // ─── Preview state ───────────────────────────────────────────────────────────
  /// Latest preview pixels rendered by the engine (for display overlay).
  final Uint8List? previewPixels;

  // ─── Processing ──────────────────────────────────────────────────────────────
  final ProcessingStatus processingStatus;
  final double exportProgress;

  // ─── Compare mode ────────────────────────────────────────────────────────────
  final CompareMode compareMode;

  // ─── Error ───────────────────────────────────────────────────────────────────
  final String? errorMessage;

  // ─── Session ─────────────────────────────────────────────────────────────────
  final bool hasUnsavedChanges;

  const BlemishState({
    this.sourceImage,
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.brushSettings = const BrushSettings(),
    this.canvasScale = 1.0,
    this.canvasTranslation = Offset.zero,
    this.operations = const [],
    this.activeStrokePoints = const [],
    this.previewPixels,
    this.processingStatus = ProcessingStatus.idle,
    this.exportProgress = 0.0,
    this.compareMode = CompareMode.edited,
    this.errorMessage,
    this.hasUnsavedChanges = false,
  });

  bool get isProcessing =>
      processingStatus == ProcessingStatus.processingPreview ||
      processingStatus == ProcessingStatus.processingFinal ||
      processingStatus == ProcessingStatus.exporting;

  bool get hasOperations => operations.isNotEmpty;

  bool get showingOriginal => compareMode == CompareMode.original;

  BlemishState copyWith({
    ui.Image? sourceImage,
    int? imageWidth,
    int? imageHeight,
    BrushSettings? brushSettings,
    double? canvasScale,
    Offset? canvasTranslation,
    List<BlemishOperation>? operations,
    List<Offset>? activeStrokePoints,
    Uint8List? previewPixels,
    ProcessingStatus? processingStatus,
    double? exportProgress,
    CompareMode? compareMode,
    String? errorMessage,
    bool? hasUnsavedChanges,
    bool clearError = false,
    bool clearPreview = false,
  }) {
    return BlemishState(
      sourceImage: sourceImage ?? this.sourceImage,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      brushSettings: brushSettings ?? this.brushSettings,
      canvasScale: canvasScale ?? this.canvasScale,
      canvasTranslation: canvasTranslation ?? this.canvasTranslation,
      operations: operations ?? this.operations,
      activeStrokePoints: activeStrokePoints ?? this.activeStrokePoints,
      previewPixels: clearPreview ? null : (previewPixels ?? this.previewPixels),
      processingStatus: processingStatus ?? this.processingStatus,
      exportProgress: exportProgress ?? this.exportProgress,
      compareMode: compareMode ?? this.compareMode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }

  @override
  String toString() => 'BlemishState(ops=${operations.length}, '
      'status=$processingStatus, scale=$canvasScale)';
}
