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
import 'package:untitled2/vv/patch_blender.dart';

import 'blemish_state.dart';

class BlemishCubit extends Cubit<BlemishState> {
  final EngineIsolateWorker _worker;
  final MaskGenerationService _maskService;
  final BrushInteractionService _brushInteraction;
  final HistoryService _history;
  final ExportService _exportService;
  final PatchBlender _instantBlender = PatchBlender();

  Uint8List? _sourcePixels;
  Uint8List? _previewPixelsCache;
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

  Future<void> loadImage(ui.Image image) async {
    if (!_workerStarted) {
      await _worker.start();
      _workerStarted = true;
    }

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    _sourcePixels = byteData?.buffer.asUint8List();
    _previewPixelsCache = null;

    emit(state.copyWith(
      sourceImage: image,
      imageWidth: image.width,
      imageHeight: image.height,
      operations: const [],
      clearPreview: true,
    ));
  }

  void setBrushRadius(double radius) => emit(state.copyWith(
      brushSettings: state.brushSettings.copyWith(radius: radius)));

  void setBrushSoftness(double softness) => emit(state.copyWith(
      brushSettings: state.brushSettings.copyWith(softness: softness)));

  void setBrushStrength(double strength) => emit(state.copyWith(
      brushSettings: state.brushSettings.copyWith(strength: strength)));

  void setBrushSettings(BrushSettings settings) =>
      emit(state.copyWith(brushSettings: settings));

  void clearError() => emit(state.copyWith(clearError: true));

  void updateCanvasTransform({double? scale, Offset? translation}) {
    emit(state.copyWith(
      canvasScale: scale ?? state.canvasScale,
      canvasTranslation: translation ?? state.canvasTranslation,
    ));
  }

  void onStrokeBegin(Offset canvasPoint) {
    if (state.sourceImage == null || state.isProcessing) return;
    final imagePoint = _toImageSpace(canvasPoint);
    _brushInteraction.beginStroke(imagePoint);
    emit(state.copyWith(
      activeStrokePoints: [imagePoint],
      clearError: true,
    ));
  }

  void onStrokeUpdate(Offset canvasPoint) {
    if (state.sourceImage == null || state.isProcessing) return;
    final imagePoint = _toImageSpace(canvasPoint);
    final added = _brushInteraction.continueStroke(imagePoint);
    if (added) {
      emit(state.copyWith(
        activeStrokePoints: List<Offset>.from(_brushInteraction.currentStroke),
      ));
    }
  }

  Future<void> onSpotHeal(Offset canvasPoint) async {
    if (state.sourceImage == null || state.isProcessing) return;
    final imagePoint = _toImageSpace(canvasPoint);

    emit(state.copyWith(
      activeStrokePoints: [imagePoint],
      clearError: true,
    ));

    await _commitStroke(
      [imagePoint],
      StrokeType.spotHeal,
      preferInstantPreview: true,
    );

    if (!isClosed) {
      emit(state.copyWith(activeStrokePoints: const []));
    }
  }

  Future<void> onStrokeEnd() async {
    if (state.sourceImage == null || state.isProcessing) return;
    final strokePoints = _brushInteraction.endStroke();
    if (strokePoints.isEmpty) return;

    emit(state.copyWith(
      activeStrokePoints: const [],
      processingStatus: ProcessingStatus.processingPreview,
    ));

    await _commitStroke(strokePoints, StrokeType.dragHeal);
  }

  void cancelActiveStroke() {
    _brushInteraction.cancelStroke();
    emit(state.copyWith(activeStrokePoints: const []));
  }

  Future<void> undo() async {
    final undone = _history.undo();
    if (undone == null) return;
    emit(state.copyWith(
      operations: _history.operations,
      hasUnsavedChanges: _history.canUndo,
    ));
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

  void reset() {
    _history.clear();
    _brushInteraction.cancelStroke();
    _previewPixelsCache = null;
    emit(state.copyWith(
      operations: const [],
      activeStrokePoints: const [],
      clearPreview: true,
      processingStatus: ProcessingStatus.idle,
      hasUnsavedChanges: false,
    ));
  }

  void setCompareMode(CompareMode mode) =>
      emit(state.copyWith(compareMode: mode));

  void toggleCompare() {
    final next = state.compareMode == CompareMode.edited
        ? CompareMode.original
        : CompareMode.edited;
    setCompareMode(next);
  }

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
      }

      emit(state.copyWith(
        processingStatus: ProcessingStatus.error,
        errorMessage: result.errorMessage,
      ));
    }
    return null;
  }

  Future<void> _commitStroke(
    List<Offset> strokePoints,
    StrokeType strokeType, {
    bool preferInstantPreview = false,
  }) async {
    if (_sourcePixels == null || state.isProcessing) return;

    try {
      final tunedBrush = state.brushSettings.normalizedForHealing(
        imageWidth: state.imageWidth,
        imageHeight: state.imageHeight,
      );
      final mask = _maskService.generateStrokeMask(
        strokePoints: strokePoints,
        brush: tunedBrush,
        imageWidth: state.imageWidth,
        imageHeight: state.imageHeight,
      );

      if (mask.bounds.isEmpty) {
        emit(state.copyWith(processingStatus: ProcessingStatus.idle));
        return;
      }

      final operation = BlemishOperation(
        id: _generateOperationId(),
        createdAt: DateTime.now(),
        brushSettings: tunedBrush,
        strokePoints: strokePoints,
        strokeType: strokeType,
        mask: mask,
      );

      if (preferInstantPreview && strokeType == StrokeType.spotHeal) {
        final previewSeed =
            Uint8List.fromList(_previewPixelsCache ?? _sourcePixels!);
        final baselinePixels = Uint8List.fromList(previewSeed);
        final instantApplied = _applyInstantSpotPreview(
          previewSeed,
          operation,
        );

        if (instantApplied) {
          _previewPixelsCache = previewSeed;
          _history.commit(operation.copyWith(isProcessed: true));

          if (!isClosed) {
            emit(state.copyWith(
              operations: _history.operations,
              previewPixels: _previewPixelsCache,
              processingStatus: ProcessingStatus.idle,
              hasUnsavedChanges: true,
            ));
          }

          unawaited(_refineSpotPreview(
            operation: operation,
            baselinePixels: baselinePixels,
            historyCount: _history.undoCount,
          ));
          return;
        }
      }

      final inputPixels =
          Uint8List.fromList(_previewPixelsCache ?? _sourcePixels!);
      final result = await _worker.heal(
        imagePixels: inputPixels,
        imageWidth: state.imageWidth,
        imageHeight: state.imageHeight,
        operation: operation,
        mode: EngineQualityMode.preview,
      );

      if (result.isSuccess) {
        _writeRegion(
            inputPixels, result.healed!.bounds, result.healed!.healedPixels);
        _previewPixelsCache = inputPixels;
        _history.commit(operation.copyWith(isProcessed: true));

        if (!isClosed) {
          emit(state.copyWith(
            operations: _history.operations,
            previewPixels: _previewPixelsCache,
            processingStatus: ProcessingStatus.idle,
            hasUnsavedChanges: true,
          ));
        }
        return;
      }

      debugPrint('[BlemishCubit] Heal failed: ${result.error}');
      if (!isClosed) {
        emit(state.copyWith(
          processingStatus: ProcessingStatus.error,
          errorMessage: 'Healing failed: ${result.error?.message}',
        ));
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

  Future<void> _refineSpotPreview({
    required BlemishOperation operation,
    required Uint8List baselinePixels,
    required int historyCount,
  }) async {
    try {
      final result = await _worker.heal(
        imagePixels: baselinePixels,
        imageWidth: state.imageWidth,
        imageHeight: state.imageHeight,
        operation: operation,
        mode: EngineQualityMode.preview,
      );

      if (result.isFailure || isClosed) {
        return;
      }

      final isStillLatest = _history.undoCount == historyCount &&
          _history.lastOperation?.id == operation.id;
      if (!isStillLatest || _previewPixelsCache == null) {
        return;
      }

      final refinedPixels = Uint8List.fromList(_previewPixelsCache!);
      _writeRegion(
          refinedPixels, result.healed!.bounds, result.healed!.healedPixels);
      _previewPixelsCache = refinedPixels;

      emit(state.copyWith(
        previewPixels: _previewPixelsCache,
        processingStatus: ProcessingStatus.idle,
      ));
    } catch (e, stack) {
      debugPrint('[BlemishCubit] _refineSpotPreview error: $e\n$stack');
    }
  }

  bool _applyInstantSpotPreview(Uint8List pixels, BlemishOperation operation) {
    final targetBounds = operation.mask.computeTightBounds().clampTo(
          state.imageWidth,
          state.imageHeight,
        );
    if (targetBounds.isEmpty) {
      return false;
    }

    final sourceBounds = _pickInstantSourceBounds(targetBounds);
    if (sourceBounds == null) {
      return false;
    }

    final sourcePatch = _extractRegion(pixels, sourceBounds);
    _instantBlender.blend(
      outputPixels: pixels,
      imageWidth: state.imageWidth,
      imageHeight: state.imageHeight,
      sourcePatch: sourcePatch,
      patchWidth: targetBounds.width,
      patchHeight: targetBounds.height,
      sourceAnchorX: sourceBounds.left,
      sourceAnchorY: sourceBounds.top,
      targetBounds: targetBounds,
      mask: operation.mask,
      strength: (operation.brushSettings.strength * 0.92).clamp(0.48, 0.88),
    );
    return true;
  }

  MaskBounds? _pickInstantSourceBounds(MaskBounds targetBounds) {
    final patchW = targetBounds.width;
    final patchH = targetBounds.height;
    if (patchW <= 0 || patchH <= 0) {
      return null;
    }

    final gap = patchW <= 18 ? 2 : 4;
    final candidates = <MaskBounds>[
      MaskBounds(
        left: targetBounds.right + gap,
        top: targetBounds.top,
        right: targetBounds.right + gap + patchW,
        bottom: targetBounds.top + patchH,
      ),
      MaskBounds(
        left: targetBounds.left - gap - patchW,
        top: targetBounds.top,
        right: targetBounds.left - gap,
        bottom: targetBounds.top + patchH,
      ),
      MaskBounds(
        left: targetBounds.left,
        top: targetBounds.bottom + gap,
        right: targetBounds.left + patchW,
        bottom: targetBounds.bottom + gap + patchH,
      ),
      MaskBounds(
        left: targetBounds.left,
        top: targetBounds.top - gap - patchH,
        right: targetBounds.left + patchW,
        bottom: targetBounds.top - gap,
      ),
    ];

    MaskBounds? bestBounds;
    double bestScore = double.infinity;

    for (final candidate in candidates) {
      final clamped = candidate.clampTo(state.imageWidth, state.imageHeight);
      if (clamped.width != patchW || clamped.height != patchH) {
        continue;
      }
      if (_boundsOverlap(targetBounds, clamped, margin: 1)) {
        continue;
      }

      final score = _estimatePatchDifference(targetBounds, clamped);
      if (score < bestScore) {
        bestScore = score;
        bestBounds = clamped;
      }
    }

    return bestBounds;
  }

  double _estimatePatchDifference(MaskBounds target, MaskBounds source) {
    final pixels = _previewPixelsCache ?? _sourcePixels;
    if (pixels == null) {
      return double.infinity;
    }

    double targetLuma = 0;
    double sourceLuma = 0;
    int count = 0;

    for (int dy = 0; dy < target.height; dy++) {
      final targetY = target.top + dy;
      final sourceY = source.top + dy;
      for (int dx = 0; dx < target.width; dx++) {
        final targetX = target.left + dx;
        final sourceX = source.left + dx;

        final targetIdx = (targetY * state.imageWidth + targetX) * 4;
        final sourceIdx = (sourceY * state.imageWidth + sourceX) * 4;
        targetLuma += _lumaAt(pixels, targetIdx);
        sourceLuma += _lumaAt(pixels, sourceIdx);
        count++;
      }
    }

    if (count == 0) {
      return double.infinity;
    }

    return (targetLuma - sourceLuma).abs() / count;
  }

  double _lumaAt(Uint8List pixels, int offset) {
    return (pixels[offset] * 0.299) +
        (pixels[offset + 1] * 0.587) +
        (pixels[offset + 2] * 0.114);
  }

  bool _boundsOverlap(MaskBounds a, MaskBounds b, {required int margin}) {
    return a.left < b.right + margin &&
        a.top < b.bottom + margin &&
        a.right > b.left - margin &&
        a.bottom > b.top - margin;
  }

  Uint8List _extractRegion(Uint8List pixels, MaskBounds bounds) {
    final w = bounds.width;
    final h = bounds.height;
    final buffer = Uint8List(w * h * 4);

    for (int dy = 0; dy < h; dy++) {
      final sy = bounds.top + dy;
      final srcOffset = (sy * state.imageWidth + bounds.left) * 4;
      final dstOffset = dy * w * 4;
      buffer.setRange(dstOffset, dstOffset + w * 4, pixels, srcOffset);
    }

    return buffer;
  }

  Future<void> _recomputePreview() async {
    if (_sourcePixels == null || state.isProcessing) return;
    if (_history.operations.isEmpty) {
      _previewPixelsCache = null;
      emit(state.copyWith(
        clearPreview: true,
        processingStatus: ProcessingStatus.idle,
      ));
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

      _previewPixelsCache = resultPixels;
      if (!isClosed) {
        emit(state.copyWith(
          previewPixels: _previewPixelsCache,
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

  void _writeRegion(
      Uint8List buffer, MaskBounds bounds, Uint8List regionPixels) {
    final w = bounds.width;
    for (int dy = 0; dy < bounds.height; dy++) {
      final sy = bounds.top + dy;
      final dstOffset = (sy * state.imageWidth + bounds.left) * 4;
      final srcOffset = dy * w * 4;
      buffer.setRange(dstOffset, dstOffset + w * 4, regionPixels, srcOffset);
    }
  }

  void _onHistoryChanged() {}

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
    _history.removeListener(_onHistoryChanged);
    await _worker.dispose();
    return super.close();
  }
}
