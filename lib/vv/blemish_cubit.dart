import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/vv/blemish_operation.dart';
import 'package:untitled2/vv/blemish_removal_engine.dart';
import 'package:untitled2/vv/brush_interaction_service.dart';
import 'package:untitled2/vv/brush_settings.dart';
import 'package:untitled2/vv/engine_isolate_worker.dart';
import 'package:untitled2/vv/export_service.dart';
import 'package:untitled2/vv/history_service.dart';
import 'package:untitled2/vv/mask_data.dart';
import 'package:untitled2/vv/mask_generation_service.dart';

import 'blemish_state.dart';

/// Central Cubit managing all blemish remover interactions.
///
/// Responsibilities:
///  - Load source image and initialise engine worker
///  - Handle brush touch events → mask generation → engine heal → state update
///  - Manage undo/redo via [HistoryService]
///  - Trigger compare-mode toggle
///  - Dispatch export via [ExportService]
///  - Clean up on close
class BlemishCubit extends Cubit<BlemishState> {
  final EngineIsolateWorker _worker;
  final MaskGenerationService _maskService;
  final BrushInteractionService _brushInteraction;
  final HistoryService _history;
  final ExportService _exportService;

  /// Debounce timer for preview-quality healing after stroke end.
  Timer? _previewDebounce;

  /// Pixel buffer of the source image (kept in memory for engine calls).
  Uint8List? _sourcePixels;

  bool _workerStarted = false;

  BlemishCubit({
    EngineIsolateWorker? worker,
    MaskGenerationService? maskService,
    BrushInteractionService? brushInteraction,
    HistoryService? history,
    ExportService? exportService,
  })  : _worker = worker ?? EngineIsolateWorker(),
        _maskService = maskService ?? MaskGenerationService(),
        _brushInteraction = brushInteraction ?? BrushInteractionService(),
        _history = history ?? HistoryService(),
        _exportService = exportService ?? ExportService(EngineIsolateWorker()),
        super(const BlemishState()) {
    _history.addListener(_onHistoryChanged);
  }

  // ─── Initialisation ──────────────────────────────────────────────────────────

  /// Load the source image and start the engine worker.
  Future<void> loadImage(ui.Image image) async {
    if (!_workerStarted) {
      await _worker.start();
      _workerStarted = true;
    }

    // Decode source image to raw RGBA for engine calls.
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    _sourcePixels = byteData?.buffer.asUint8List();

    emit(state.copyWith(
      sourceImage: image,
      imageWidth: image.width,
      imageHeight: image.height,
      operations: const [],
      clearPreview: true,
    ));
  }

  // ─── Brush settings ──────────────────────────────────────────────────────────

  void setBrushRadius(double radius) =>
      emit(state.copyWith(brushSettings: state.brushSettings.copyWith(radius: radius)));

  void setBrushSoftness(double softness) =>
      emit(state.copyWith(brushSettings: state.brushSettings.copyWith(softness: softness)));

  void setBrushStrength(double strength) =>
      emit(state.copyWith(brushSettings: state.brushSettings.copyWith(strength: strength)));

  void setBrushSettings(BrushSettings settings) =>
      emit(state.copyWith(brushSettings: settings));

  // ─── Canvas transform ────────────────────────────────────────────────────────

  void updateCanvasTransform({double? scale, Offset? translation}) {
    emit(state.copyWith(
      canvasScale: scale ?? state.canvasScale,
      canvasTranslation: translation ?? state.canvasTranslation,
    ));
  }

  // ─── Stroke handling ─────────────────────────────────────────────────────────

  /// Called when the user begins touching the canvas.
  void onStrokeBegin(Offset canvasPoint) {
    if (state.sourceImage == null) return;
    final imagePoint = _toImageSpace(canvasPoint);
    _brushInteraction.beginStroke(imagePoint);
    emit(state.copyWith(
      activeStrokePoints: [imagePoint],
      clearError: true,
    ));
  }

  /// Called for each subsequent touch move.
  void onStrokeUpdate(Offset canvasPoint) {
    if (state.sourceImage == null) return;
    final imagePoint = _toImageSpace(canvasPoint);
    final added = _brushInteraction.continueStroke(imagePoint);
    if (added) {
      emit(state.copyWith(
        activeStrokePoints: List<Offset>.from(_brushInteraction.currentStroke),
      ));
    }
  }

  /// Called when the user lifts their finger/pointer.
  Future<void> onStrokeEnd() async {
    if (state.sourceImage == null) return;
    final strokePoints = _brushInteraction.endStroke();
    if (strokePoints.isEmpty) return;

    emit(state.copyWith(
      activeStrokePoints: const [],
      processingStatus: ProcessingStatus.processingPreview,
    ));

    await _commitStroke(strokePoints, StrokeType.dragHeal);
  }

  /// Cancel the stroke in progress (e.g., two-finger gesture started).
  void cancelActiveStroke() {
    _brushInteraction.cancelStroke();
    emit(state.copyWith(activeStrokePoints: const []));
  }

  // ─── Undo / Redo ─────────────────────────────────────────────────────────────

  Future<void> undo() async {
    final undone = _history.undo();
    if (undone == null) return;
    emit(state.copyWith(
      operations: _history.operations,
      hasUnsavedChanges: _history.canUndo,
    ));
    // Recompute preview from scratch after undo.
    await _recomputePreview();
  }

  Future<void> redo() async {
    final redone = _history.redo();
    if (redone == null) return;
    emit(state.copyWith(
      operations: _history.operations,
      hasUnsavedChanges: true,
    ));
    await _recomputePreview();
  }

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  // ─── Reset ───────────────────────────────────────────────────────────────────

  void reset() {
    _history.clear();
    _brushInteraction.cancelStroke();
    emit(state.copyWith(
      operations: const [],
      activeStrokePoints: const [],
      clearPreview: true,
      processingStatus: ProcessingStatus.idle,
      hasUnsavedChanges: false,
    ));
  }

  // ─── Compare mode ────────────────────────────────────────────────────────────

  void setCompareMode(CompareMode mode) => emit(state.copyWith(compareMode: mode));

  void toggleCompare() {
    final next = state.compareMode == CompareMode.edited
        ? CompareMode.original
        : CompareMode.edited;
    setCompareMode(next);
  }

  // ─── Export ──────────────────────────────────────────────────────────────────

  /// Apply all operations at final quality and return PNG bytes.
  Future<Uint8List?> exportImage({
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    if (state.sourceImage == null) return null;

    emit(state.copyWith(
      processingStatus: ProcessingStatus.exporting,
      exportProgress: 0.0,
    ));

    final result = await _exportService.export(
      sourceImage: state.sourceImage!,
      operations: _history.operations,
      onProgress: (progress) {
        if (!isClosed) {
          emit(state.copyWith(exportProgress: progress));
        }
      },
    );

    if (!isClosed) {
      if (result.isSuccess) {
        emit(state.copyWith(
          processingStatus: ProcessingStatus.idle,
          exportProgress: 1.0,
          hasUnsavedChanges: false,
        ));
        return result.pngBytes;
      } else {
        emit(state.copyWith(
          processingStatus: ProcessingStatus.error,
          errorMessage: result.errorMessage,
        ));
        return null;
      }
    }
    return null;
  }

  // ─── Private ─────────────────────────────────────────────────────────────────

  Future<void> _commitStroke(List<Offset> strokePoints, StrokeType strokeType) async {
    if (_sourcePixels == null) return;

    try {
      // 1. Generate mask.
      final mask = _maskService.generateStrokeMask(
        strokePoints: strokePoints,
        brush: state.brushSettings,
        imageWidth: state.imageWidth,
        imageHeight: state.imageHeight,
      );

      if (mask.bounds.isEmpty) {
        emit(state.copyWith(processingStatus: ProcessingStatus.idle));
        return;
      }

      // 2. Build immutable operation.
      final operation = BlemishOperation(
        id: _generateOperationId(),
        createdAt: DateTime.now(),
        brushSettings: state.brushSettings,
        strokePoints: strokePoints,
        strokeType: strokeType,
        mask: mask,
      );

      // 3. Run preview-quality healing on the worker isolate.
      // We feed the accumulated preview (or original if first op) into the engine.
      final inputPixels = await _buildCurrentPixels(EngineQualityMode.preview);

      final result = await _worker.heal(
        imagePixels: inputPixels,
        imageWidth: state.imageWidth,
        imageHeight: state.imageHeight,
        operation: operation,
        mode: EngineQualityMode.preview,
      );

      if (result.isSuccess) {
        // 4. Write healed region into a working copy for preview display.
        final previewPixels = Uint8List.fromList(inputPixels);
        _writeRegion(previewPixels, result.healed!.bounds, result.healed!.healedPixels);

        // 5. Commit to history.
        _history.commit(operation.copyWith(isProcessed: true));

        if (!isClosed) {
          emit(state.copyWith(
            operations: _history.operations,
            previewPixels: previewPixels,
            processingStatus: ProcessingStatus.idle,
            hasUnsavedChanges: true,
          ));
        }
      } else {
        debugPrint('[BlemishCubit] Heal failed: ${result.error}');
        if (!isClosed) {
          emit(state.copyWith(
            processingStatus: ProcessingStatus.error,
            errorMessage: 'Healing failed: ${result.error?.message}',
          ));
        }
      }
    } catch (e, stack) {
      debugPrint('[BlemishCubit] _commitStroke error: $e\n$stack');
      if (!isClosed) {
        emit(state.copyWith(
          processingStatus: ProcessingStatus.error,
          errorMessage: 'Unexpected error: $e',
        ));
      }
    }
  }

  /// Recompute preview by replaying all operations on the original image.
  Future<void> _recomputePreview() async {
    if (_sourcePixels == null) return;
    if (_history.operations.isEmpty) {
      emit(state.copyWith(clearPreview: true, processingStatus: ProcessingStatus.idle));
      return;
    }

    emit(state.copyWith(processingStatus: ProcessingStatus.processingPreview));

    try {
      final resultPixels = await _worker.applyAll(
        imagePixels: _sourcePixels!,
        imageWidth: state.imageWidth,
        imageHeight: state.imageHeight,
        operations: _history.operations,
        mode: EngineQualityMode.preview,
      );

      if (!isClosed) {
        emit(state.copyWith(
          previewPixels: resultPixels,
          processingStatus: ProcessingStatus.idle,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          processingStatus: ProcessingStatus.error,
          errorMessage: 'Preview rebuild failed: $e',
        ));
      }
    }
  }

  /// Build the current pixel state by starting from original + applying all
  /// committed operations up to this point.
  Future<Uint8List> _buildCurrentPixels(EngineQualityMode mode) async {
    if (_history.operations.isEmpty) return Uint8List.fromList(_sourcePixels!);
    return _worker.applyAll(
      imagePixels: _sourcePixels!,
      imageWidth: state.imageWidth,
      imageHeight: state.imageHeight,
      operations: _history.operations,
      mode: mode,
    );
  }

  void _writeRegion(Uint8List buffer, MaskBounds bounds, Uint8List regionPixels) {
    final w = bounds.width;
    for (int dy = 0; dy < bounds.height; dy++) {
      final sy = bounds.top + dy;
      final dstOffset = (sy * state.imageWidth + bounds.left) * 4;
      final srcOffset = dy * w * 4;
      buffer.setRange(dstOffset, dstOffset + w * 4, regionPixels, srcOffset);
    }
  }

  void _onHistoryChanged() {
    // Sync undo/redo availability into state when history notifies.
    // (State already updated by undo()/redo() calls.)
  }

  Offset _toImageSpace(Offset canvasPoint) {
    return BrushInteractionService.canvasToImage(
      canvasPoint,
      scale: state.canvasScale,
      translation: state.canvasTranslation,
      imageWidth: state.imageWidth,
      imageHeight: state.imageHeight,
    );
  }

  int _opCounter = 0;
  String _generateOperationId() =>
      'op_${++_opCounter}_${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<void> close() async {
    _previewDebounce?.cancel();
    _history.removeListener(_onHistoryChanged);
    await _worker.dispose();
    return super.close();
  }
}
