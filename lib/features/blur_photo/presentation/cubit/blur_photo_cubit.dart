import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/blur_mode.dart';
import '../../domain/entities/blur_operation.dart';
import '../../domain/entities/blur_settings.dart';
import '../../domain/entities/blur_style.dart';
import '../../domain/entities/circle_params.dart';
import '../../domain/entities/line_params.dart';
import '../../domain/repositories/blur_repository.dart';
import 'blur_photo_state.dart';

const _kMaxUndo = 24;

class BlurPhotoCubit extends Cubit<BlurPhotoState> {
  BlurPhotoCubit({required this.repository}) : super(BlurPhotoState());

  final BlurRepository repository;

  Uint8List? _originalBytes;
  int _ticket = 0;
  Timer? _debounce;
  bool _renderInFlight = false;
  BpRenderQuality? _queuedQuality;
  bool _queuedImmediate = false;

  Future<void> initialize(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data?.buffer.asUint8List();
    if (isClosed) return;

    if (bytes == null) {
      emit(state.copyWith(
        status: BpEditorStatus.error,
        errorMessage: 'Could not read image data.',
      ));
      return;
    }

    _originalBytes = bytes;

    final op = BlurOperation.initial();
    emit(state.copyWith(
      status: BpEditorStatus.ready,
      originalImage: image,
      previewImage: image,
      operation: op,
      undoStack: const [],
      redoStack: const [],
      hintMessage:
          'Full blur is active. Use the small buttons below to switch modes.',
      clearError: true,
    ));

    await _render(BpRenderQuality.track);
  }

  Future<void> setMode(BlurPhotoMode mode) async {
    _commitSettings(state.settings.copyWith(mode: mode), push: false);
    emit(state.copyWith(
      hintMessage: switch (mode) {
        BlurPhotoMode.full => 'Blur is applied to the whole image.',
        BlurPhotoMode.text =>
          'Text blur finds text blocks and blurs only them.',
        BlurPhotoMode.smart => 'Smart mode blurs the background automatically.',
        BlurPhotoMode.circle =>
          'Drag the shape to move it and resize it with the side handles.',
        BlurPhotoMode.line =>
          'Move the line above the subject to keep that side sharp and blur the rest.',
      },
    ));
    await _scheduleRender(BpRenderQuality.track, immediate: true);

    if (mode == BlurPhotoMode.smart && !state.segmentationInProgress) {
      unawaited(detectSubject());
    }
    if (mode == BlurPhotoMode.text && !state.textDetectionInProgress) {
      unawaited(detectTextRegions());
    }
  }

  Future<void> updateStyle(BlurPhotoStyle style) async {
    _commitSettings(state.settings.copyWith(style: style), push: true);
    emit(state.copyWith(
      hintMessage: switch (style) {
        BlurPhotoStyle.soft => 'Soft blur gives a natural background result.',
        BlurPhotoStyle.frost => 'Frost adds a brighter glass-like blur.',
        BlurPhotoStyle.motion => 'Motion creates a stronger directional feel.',
        BlurPhotoStyle.crystal => 'Crystal keeps the focused area cleaner.',
        BlurPhotoStyle.spotlight => 'Spotlight darkens the outer blur softly.',
      },
    ));
    await _scheduleRender(BpRenderQuality.previewIdle, immediate: true);
  }

  void updateIntensity(double value) {
    _commitSettings(
      state.settings.copyWith(blurIntensity: value.clamp(2.0, 30.0)),
      push: false,
    );
    _scheduleRender(BpRenderQuality.track);
  }

  void onIntensityDragEnd(double value) {
    _commitSettings(
      state.settings.copyWith(blurIntensity: value.clamp(2.0, 30.0)),
      push: true,
    );
    _scheduleRender(BpRenderQuality.previewIdle, immediate: true);
  }

  void updateCircle(CircleBlurParams params, {bool trackOnly = false}) {
    _commitSettings(state.settings.copyWith(circle: params), push: false);
    _scheduleRender(
      trackOnly ? BpRenderQuality.track : BpRenderQuality.previewIdle,
      immediate: !trackOnly,
    );
  }

  void commitCircleInteractionEnd(CircleBlurParams params) {
    _commitSettings(state.settings.copyWith(circle: params), push: true);
    _scheduleRender(BpRenderQuality.previewIdle, immediate: true);
  }

  void updateLine(LineBlurParams params, {bool trackOnly = false}) {
    _commitSettings(state.settings.copyWith(line: params), push: false);
    _scheduleRender(
      trackOnly ? BpRenderQuality.track : BpRenderQuality.previewIdle,
      immediate: !trackOnly,
    );
  }

  void commitLineInteractionEnd(LineBlurParams params) {
    _commitSettings(state.settings.copyWith(line: params), push: true);
    _scheduleRender(BpRenderQuality.previewIdle, immediate: true);
  }

  Future<void> detectSubject() async {
    if (_originalBytes == null || state.originalImage == null || isClosed) {
      return;
    }

    emit(state.copyWith(
      segmentationInProgress: true,
      hintMessage: 'Detecting subject...',
      clearError: true,
    ));

    try {
      final result = await repository.detectSubject(
        imageBytes: _originalBytes!,
        imageWidth: state.originalImage!.width,
        imageHeight: state.originalImage!.height,
      );

      if (isClosed) return;
      emit(state.copyWith(
        segmentationInProgress: false,
        hintMessage: result == null || result['usedFallback'] == true
            ? 'Smart blur could not isolate the subject. A safe fallback was used.'
            : 'Subject detected. Blur applied to background.',
        clearError: true,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        segmentationInProgress: false,
        hintMessage: 'Smart blur failed, so the preview stayed safe.',
        errorMessage: 'Smart mode is not available for this image right now.',
      ));
    }

    await _scheduleRender(BpRenderQuality.previewIdle, immediate: true);
  }

  Future<void> detectTextRegions() async {
    if (_originalBytes == null || state.originalImage == null || isClosed) {
      return;
    }

    emit(state.copyWith(
      textDetectionInProgress: true,
      hintMessage: 'Scanning text...',
      clearError: true,
    ));

    final result = await repository.detectTextRegions(
      imageBytes: _originalBytes!,
      imageWidth: state.originalImage!.width,
      imageHeight: state.originalImage!.height,
    );

    if (isClosed) return;

    final count = ((result?['regions'] as List?) ?? const []).length;
    emit(state.copyWith(
      textDetectionInProgress: false,
      hintMessage: count > 0
          ? 'Text detected and blurred.'
          : 'No text found. Increase intensity or switch mode.',
      clearError: true,
    ));

    await _scheduleRender(BpRenderQuality.previewIdle, immediate: true);
  }

  void showOriginal(bool show) => emit(state.copyWith(showOriginal: show));

  Future<void> undo() async {
    if (!state.canUndo) return;
    final undo = List<BlurOperation>.from(state.undoStack);
    final prev = undo.removeLast();
    final redo = List<BlurOperation>.from(state.redoStack)
      ..add(state.operation);
    emit(state.copyWith(operation: prev, undoStack: undo, redoStack: redo));
    await _scheduleRender(BpRenderQuality.previewIdle, immediate: true);
  }

  Future<void> redo() async {
    if (!state.canRedo) return;
    final redo = List<BlurOperation>.from(state.redoStack);
    final next = redo.removeLast();
    final undo = List<BlurOperation>.from(state.undoStack)
      ..add(state.operation);
    emit(state.copyWith(operation: next, undoStack: undo, redoStack: redo));
    await _scheduleRender(BpRenderQuality.previewIdle, immediate: true);
  }

  Future<Uint8List?> exportFinal() async {
    if (_originalBytes == null || isClosed) return null;
    emit(state.copyWith(status: BpEditorStatus.exporting, clearError: true));
    final bytes = await repository.renderExport(
      imageBytes: _originalBytes!,
      operation: state.operation,
    );
    if (!isClosed) emit(state.copyWith(status: BpEditorStatus.ready));
    return bytes;
  }

  void _commitSettings(BlurPhotoSettings settings, {required bool push}) {
    final nextOp = state.operation.copyWith(
      settings: settings,
      id: state.operation.id + 1,
    );
    List<BlurOperation> undo = state.undoStack;
    if (push) {
      final expanded = List<BlurOperation>.from(state.undoStack)
        ..add(state.operation);
      undo = expanded.length > _kMaxUndo
          ? expanded.sublist(expanded.length - _kMaxUndo)
          : expanded;
    }
    emit(state.copyWith(
      operation: nextOp,
      undoStack: undo,
      redoStack: push ? const [] : state.redoStack,
      clearError: true,
    ));
  }

  Future<void> _scheduleRender(
    BpRenderQuality quality, {
    bool immediate = false,
  }) async {
    _debounce?.cancel();
    if (_renderInFlight) {
      _queueRender(quality, immediate: immediate);
      return;
    }

    if (immediate || quality == BpRenderQuality.track) {
      unawaited(_render(quality));
      if (quality == BpRenderQuality.track) {
        _debounce = Timer(
          const Duration(milliseconds: 48),
          () => _scheduleRender(BpRenderQuality.previewIdle),
        );
      }
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 60),
      () => _scheduleRender(quality, immediate: true),
    );
  }

  Future<void> _render(BpRenderQuality quality) async {
    if (_originalBytes == null || state.originalImage == null || isClosed) {
      return;
    }
    _renderInFlight = true;
    try {
      final ticket = ++_ticket;
      if (quality != BpRenderQuality.track) {
        emit(
          state.copyWith(status: BpEditorStatus.processing, clearError: true),
        );
      }

      final preview = await repository.renderPreview(
        imageBytes: _originalBytes!,
        operation: state.operation,
        quality: quality,
      );

      if (isClosed || ticket != _ticket) return;

      emit(state.copyWith(
        status: BpEditorStatus.ready,
        previewImage: preview ?? state.previewImage ?? state.originalImage,
      ));
    } finally {
      _renderInFlight = false;
      await _flushQueuedRender();
    }
  }

  void _queueRender(BpRenderQuality quality, {required bool immediate}) {
    final current = _queuedQuality;
    if (current == null || quality.index > current.index) {
      _queuedQuality = quality;
    } else if (quality == BpRenderQuality.track) {
      _queuedQuality = quality;
    }
    _queuedImmediate =
        _queuedImmediate || immediate || quality == BpRenderQuality.track;
  }

  Future<void> _flushQueuedRender() async {
    if (!_renderInFlight && _queuedQuality != null) {
      final quality = _queuedQuality!;
      final immediate = _queuedImmediate;
      _queuedQuality = null;
      _queuedImmediate = false;
      await _scheduleRender(quality, immediate: immediate);
    }
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await repository.dispose();
    return super.close();
  }
}
