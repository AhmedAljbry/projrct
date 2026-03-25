import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repository/af_blur_repository.dart';
import '../domain/models/af_blur_mode.dart';
import '../domain/models/af_blur_operation.dart';
import '../domain/models/af_blur_settings.dart';
import '../domain/models/af_focus_geometry.dart';
import '../domain/models/af_mask_data.dart';
import 'af_blur_state.dart';

const _kMaxUndo = 20;

enum _DeviceProfile { low, balanced, high }

class AfBlurController extends Cubit<AfBlurState> {
  AfBlurController({required this.repository}) : super(AfBlurState());

  final AfBlurRepository repository;

  Uint8List? _originalBytes;
  int _ticket = 0;
  Timer? _debounce;
  _DeviceProfile _profile = _DeviceProfile.balanced;

  Future<void> initialize(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data?.buffer.asUint8List();
    if (isClosed) {
      return;
    }
    if (bytes == null) {
      emit(state.copyWith(
        status: AfEditorStatus.error,
        errorMessage: 'Could not read image data.',
      ));
      return;
    }

    _originalBytes = bytes;
    _profile = _resolveProfile(image.width, image.height);

    emit(state.copyWith(
      status: AfEditorStatus.ready,
      originalImage: image,
      previewImage: image,
      operation: AfBlurOperation.initial().copyWith(
        settings: _defaultSettings(),
      ),
      undoStack: const [],
      redoStack: const [],
      hintMessage:
          'Smart mode starts first and detects the full person automatically.',
      clearError: true,
    ));

    await _render(AfRenderQuality.track);
    unawaited(_bootstrapSmartDetection());
  }

  Future<void> _bootstrapSmartDetection() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (isClosed || state.activeMode != AfBlurMode.smart) {
      return;
    }
    await redetectSubject(isInitial: true);
  }

  AfBlurSettings _defaultSettings() {
    return AfBlurSettings(
      mode: AfBlurMode.smart,
      blurAmount: switch (_profile) {
        _DeviceProfile.low => 13.0,
        _DeviceProfile.balanced => 16.0,
        _DeviceProfile.high => 19.0,
      },
      transitionAmount: 0.34,
      subjectProtection: 0.95,
      edgeRefinement: 0.82,
      focusBoost: _profile == _DeviceProfile.low ? 0.06 : 0.10,
      depthFalloff: 0.90,
      circleSettings: const AfCircleSettings(),
      lineSettings: const AfLineSettings(),
      smartSettings: const AfSmartSettings(
        protectFace: true,
        protectHands: false,
        antiHalo: 0.72,
        holeFill: 0.62,
      ),
    );
  }

  void updateSettings(AfBlurSettings settings, {bool trackInteraction = true}) {
    var op = state.operation.copyWith(settings: settings);
    if (!trackInteraction && op.maskData != null) {
      op = repository.refineOperation(op);
    }
    _commitOp(op, push: false);
    _scheduleRender(
      trackInteraction ? AfRenderQuality.track : AfRenderQuality.previewIdle,
    );
  }

  Future<void> setMode(AfBlurMode mode) async {
    updateSettings(
      state.operation.settings.copyWith(mode: mode),
      trackInteraction: false,
    );

    emit(state.copyWith(
      hintMessage: switch (mode) {
        AfBlurMode.smart => 'Smart mode targets the detected person only.',
        AfBlurMode.circle => 'Circle mode uses a manual elliptical focus area.',
        AfBlurMode.line => 'Line mode uses a manual tilt-shift focus strip.',
      },
    ));

    if (mode == AfBlurMode.smart &&
        !state.segmentationInProgress &&
        (state.operation.maskData == null ||
            state.operation.maskData!.usedFallback)) {
      await redetectSubject();
    }
  }

  Future<void> redetectSubject({bool isInitial = false}) async {
    if (_originalBytes == null || state.originalImage == null || isClosed) {
      return;
    }

    emit(state.copyWith(
      segmentationInProgress: true,
      hintMessage: 'Detecting the full person for Smart mode...',
      clearError: true,
    ));

    final mask = await repository.detectSubject(
      imageBytes: _originalBytes!,
      imageWidth: state.originalImage!.width,
      imageHeight: state.originalImage!.height,
      forceRefresh: !isInitial,
    );
    if (isClosed) {
      return;
    }

    var op = state.operation.copyWith(maskData: mask);
    op = repository.refineOperation(op);

    emit(state.copyWith(
      operation: op,
      segmentationInProgress: false,
      hintMessage: mask.usedFallback
          ? 'Smart mode could not isolate a person in this image.'
          : 'Person detected. Smart mode is now using the full body mask.',
      clearError: true,
    ));

    await _scheduleRender(AfRenderQuality.previewIdle, immediate: true);
  }

  void addManualStroke(List<AfStrokePoint> points) {
    if (points.isEmpty) {
      return;
    }

    final stroke = AfManualStroke(
      points: points,
      radius: state.operation.settings.brushRadius,
      hardness: state.operation.settings.brushHardness,
      add: state.brushAdd,
    );

    var op = state.operation.copyWith(
      manualStrokes: [...state.operation.manualStrokes, stroke],
    );
    if (op.maskData != null) {
      op = repository.refineOperation(op);
    }
    _commitOp(op, push: true);
    _scheduleRender(AfRenderQuality.previewIdle, immediate: true);
  }

  void toggleMaskOverlay() {
    emit(state.copyWith(showMaskOverlay: !state.showMaskOverlay));
  }

  void toggleRefineMask() {
    emit(state.copyWith(refineMaskMode: !state.refineMaskMode));
  }

  void setBrushMode(bool add) {
    emit(state.copyWith(brushAdd: add));
  }

  void showOriginal(bool show) {
    emit(state.copyWith(showOriginalPreview: show));
  }

  void resetMode() {
    final currentMode = state.activeMode;
    updateSettings(
      _defaultSettings().copyWith(
        mode: currentMode,
        circleSettings: const AfCircleSettings(),
        lineSettings: const AfLineSettings(),
      ),
      trackInteraction: false,
    );
    emit(state.copyWith(hintMessage: 'Current mode controls have been reset.'));
  }

  Future<void> undo() async {
    if (!state.canUndo) {
      return;
    }
    final undo = List<AfBlurOperation>.from(state.undoStack);
    final prev = undo.removeLast();
    final redo = List<AfBlurOperation>.from(state.redoStack)
      ..add(state.operation);
    emit(state.copyWith(operation: prev, undoStack: undo, redoStack: redo));
    await _scheduleRender(AfRenderQuality.previewIdle, immediate: true);
  }

  Future<void> redo() async {
    if (!state.canRedo) {
      return;
    }
    final redo = List<AfBlurOperation>.from(state.redoStack);
    final next = redo.removeLast();
    final undo = List<AfBlurOperation>.from(state.undoStack)
      ..add(state.operation);
    emit(state.copyWith(operation: next, undoStack: undo, redoStack: redo));
    await _scheduleRender(AfRenderQuality.previewIdle, immediate: true);
  }

  Future<Uint8List?> exportFinal() async {
    if (_originalBytes == null || isClosed) {
      return null;
    }
    emit(state.copyWith(status: AfEditorStatus.exporting, clearError: true));
    final bytes = await repository.renderExport(
      imageBytes: _originalBytes!,
      op: state.operation,
    );
    if (!isClosed) {
      emit(state.copyWith(status: AfEditorStatus.ready));
    }
    return bytes;
  }

  Duration get _trackDebounce => switch (_profile) {
        _DeviceProfile.low => const Duration(milliseconds: 360),
        _DeviceProfile.balanced => const Duration(milliseconds: 220),
        _DeviceProfile.high => const Duration(milliseconds: 140),
      };

  Duration get _idleDebounce => switch (_profile) {
        _DeviceProfile.low => const Duration(milliseconds: 300),
        _DeviceProfile.balanced => const Duration(milliseconds: 180),
        _DeviceProfile.high => const Duration(milliseconds: 110),
      };

  Future<void> _scheduleRender(AfRenderQuality quality,
      {bool immediate = false}) async {
    _debounce?.cancel();
    if (immediate || quality == AfRenderQuality.track) {
      await _render(quality);
      if (quality == AfRenderQuality.track) {
        _debounce =
            Timer(_trackDebounce, () => _render(AfRenderQuality.previewIdle));
      }
      return;
    }
    _debounce = Timer(_idleDebounce, () => _render(quality));
  }

  Future<void> _render(AfRenderQuality quality) async {
    if (_originalBytes == null || state.originalImage == null || isClosed) {
      return;
    }
    final ticket = ++_ticket;
    if (quality != AfRenderQuality.track) {
      emit(state.copyWith(status: AfEditorStatus.processing, clearError: true));
    }

    final preview = await repository.renderPreview(
      imageBytes: _originalBytes!,
      op: state.operation,
      quality: quality,
    );
    if (isClosed || ticket != _ticket) {
      return;
    }

    emit(state.copyWith(
      status: AfEditorStatus.ready,
      previewImage: preview ?? state.previewImage ?? state.originalImage,
    ));
  }

  void _commitOp(AfBlurOperation op, {required bool push}) {
    List<AfBlurOperation> undo = state.undoStack;
    if (push) {
      final expanded = List<AfBlurOperation>.from(state.undoStack)
        ..add(state.operation);
      undo = expanded.length > _kMaxUndo
          ? expanded.sublist(expanded.length - _kMaxUndo)
          : expanded;
    }
    emit(state.copyWith(
      operation: op,
      undoStack: undo,
      redoStack: push ? const [] : state.redoStack,
      clearError: true,
    ));
  }

  _DeviceProfile _resolveProfile(int width, int height) {
    final megapixels = (width * height) / 1000000.0;
    final cores = Platform.numberOfProcessors;
    if (cores <= 8 || megapixels >= 6.0) {
      return _DeviceProfile.low;
    }
    if (cores <= 10 || megapixels >= 3.5) {
      return _DeviceProfile.balanced;
    }
    return _DeviceProfile.high;
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await repository.dispose();
    return super.close();
  }
}
