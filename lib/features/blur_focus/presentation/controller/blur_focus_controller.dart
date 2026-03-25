import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/features/blur_focus/data/repositories/blur_focus_repository.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_focus_operation.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_mode.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_settings.dart';
import 'package:untitled2/features/blur_focus/domain/models/focus_geometry.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';
import 'package:untitled2/features/blur_focus/integration/mappers/blur_focus_operation_mapper.dart';
import 'package:untitled2/features/blur_focus/presentation/controller/blur_focus_state.dart';

enum _PerformanceProfile { low, balanced, high }

const int _kMaxUndoDepth = 20;

class BlurFocusController extends Cubit<BlurFocusState> {
  BlurFocusController({
    required this.repository,
    required this.mapper,
  }) : super(BlurFocusState());

  final BlurFocusRepository repository;
  final BlurFocusOperationMapper mapper;

  Uint8List? _originalBytes;
  int _renderTicket = 0;
  Timer? _idleRenderDebounce;
  _PerformanceProfile _profile = _PerformanceProfile.balanced;

  Future<void> initialize(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null) {
      emit(state.copyWith(
        status: BlurFocusStatus.error,
        errorMessage: 'Failed to read image bytes.',
      ));
      return;
    }

    _originalBytes = bytes;
    _profile = _resolveProfile(image.width, image.height);

    final initialOperation = BlurFocusOperation.initial().copyWith(
      settings: const BlurSettings().copyWith(
        mode: BlurMode.smart,
        blurAmount: switch (_profile) {
          _PerformanceProfile.low => 14.0,
          _PerformanceProfile.balanced => 17.0,
          _PerformanceProfile.high => 20.0,
        },
        transitionAmount: 0.34,
        subjectProtection: 0.94,
        edgeRefinement: 0.78,
        focusBoost: 0.12,
        depthFalloff: 0.88,
        smartSettings: const SmartBlurSettings(
          protectFace: true,
          protectHands: false,
          antiHalo: 0.72,
          holeFill: 0.62,
          contourCleanup: 0.68,
          falloffStrength: 0.84,
        ),
      ),
    );

    emit(state.copyWith(
      status: BlurFocusStatus.ready,
      originalImage: image,
      previewImage: image,
      operation: initialOperation,
      undoStack: const [],
      redoStack: const [],
      hintMessage: _buildInitialHint(),
    ));

    await _scheduleRender(BlurQuality.previewTrack, immediate: true);

    if (_shouldAutoRunSegmentation(image.width, image.height)) {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 320), () async {
          if (isClosed || state.operation.settings.mode != BlurMode.smart) {
            return;
          }
          await redetectSubject(isInitial: true);
          if (!isClosed) {
            await _scheduleRender(BlurQuality.previewIdle, immediate: true);
          }
        }),
      );
    }
  }

  _PerformanceProfile _resolveProfile(int width, int height) {
    final megapixels = (width * height) / 1000000.0;
    final cores = Platform.numberOfProcessors;
    if (cores <= 8 || megapixels >= 6.0) {
      return _PerformanceProfile.low;
    }
    if (cores <= 10 || megapixels >= 3.5) {
      return _PerformanceProfile.balanced;
    }
    return _PerformanceProfile.high;
  }

  bool _shouldAutoRunSegmentation(int width, int height) {
    return true;
  }

  String _buildInitialHint() => switch (_profile) {
        _PerformanceProfile.high =>
          'High-performance mode active. Smart AI starts with stronger blur quality.',
        _PerformanceProfile.balanced =>
          'Balanced mode active. Smart blur is tuned for clear subject edges and smooth background blur.',
        _PerformanceProfile.low =>
          'Performance mode active. Smart blur stays enabled with lighter previews for smoother editing.',
      };

  Future<void> redetectSubject({bool isInitial = false}) async {
    if (_originalBytes == null || state.originalImage == null) {
      return;
    }
    emit(state.copyWith(segmentationInProgress: true, clearError: true));
    final segmentation = await repository.detectSubject(
      imageBytes: _originalBytes!,
      imageWidth: state.originalImage!.width,
      imageHeight: state.originalImage!.height,
      forceRefresh: !isInitial,
    );
    if (isClosed) {
      return;
    }
    var operation = mapper.attachSegmentation(state.operation, segmentation);
    operation = repository.refineOperation(operation);
    final hint = segmentation.usedFallback
        ? 'No confident subject found. Circle or Line may suit this photo better.'
        : 'Subject detected. Smart mode is protecting the subject and face region.';
    emit(state.copyWith(
      operation: operation,
      segmentationInProgress: false,
      hintMessage: hint,
      clearError: true,
    ));
  }

  void updateSettings(BlurSettings settings, {bool trackInteraction = true}) {
    var operation = mapper.updateSettings(state.operation, settings);
    if (!trackInteraction && operation.segmentation != null) {
      operation = repository.refineOperation(operation);
    }
    _commitOperation(
      operation,
      addToHistory: false,
      lastInteraction:
          trackInteraction ? DateTime.now() : state.lastInteractionAt,
    );
    _scheduleRender(
      trackInteraction ? BlurQuality.previewTrack : BlurQuality.previewIdle,
    );
  }

  void setMode(BlurMode mode) {
    updateSettings(
      state.operation.settings.copyWith(mode: mode),
      trackInteraction: false,
    );
    final hint = switch (mode) {
      BlurMode.smart =>
        'Smart mode keeps the subject sharp and pushes the background to a stronger blur.',
      BlurMode.circle =>
        'Drag to reposition, pinch to scale, and rotate for elliptical focus.',
      BlurMode.line =>
        'Drag to move the focus strip, rotate to tilt, and pinch to adjust width.',
    };
    emit(state.copyWith(hintMessage: hint));
  }

  void toggleMaskPreview() =>
      emit(state.copyWith(showMaskPreview: !state.showMaskPreview));

  void toggleRefineMask() =>
      emit(state.copyWith(refineMaskMode: !state.refineMaskMode));

  void setManualBlendMode(ManualMaskBlendMode mode) =>
      emit(state.copyWith(manualBlendMode: mode));

  void showOriginal(bool show) =>
      emit(state.copyWith(showOriginalPreview: show));

  void addManualStroke(List<ManualMaskPoint> points) {
    if (points.isEmpty) {
      return;
    }
    final stroke = ManualMaskStroke(
      blendMode: state.manualBlendMode,
      radius: state.operation.settings.manualBrushRadius,
      hardness: state.operation.settings.manualBrushHardness,
      points: points,
    );
    var operation = mapper.appendStroke(state.operation, stroke);
    if (operation.segmentation != null) {
      operation = repository.refineOperation(operation);
    }
    _commitOperation(operation, addToHistory: true);
    _scheduleRender(BlurQuality.previewIdle, immediate: true);
  }

  void resetCurrentMode() {
    final resetSettings = state.operation.settings.copyWith(
      blurAmount: switch (_profile) {
        _PerformanceProfile.low => 12.0,
        _PerformanceProfile.balanced => 15.0,
        _PerformanceProfile.high => 18.0,
      },
      transitionAmount: 0.34,
      subjectProtection: 0.94,
      edgeRefinement: 0.78,
      focusBoost: _profile == _PerformanceProfile.low ? 0.08 : 0.12,
      invertMask: false,
      depthFalloff: 0.88,
      previewExposure: 0.0,
      circleSettings: const CircleFocusSettings(),
      lineSettings: const LineFocusSettings(),
      smartSettings: const SmartBlurSettings(
        protectFace: true,
        protectHands: false,
        antiHalo: 0.72,
        holeFill: 0.62,
        contourCleanup: 0.68,
        falloffStrength: 0.84,
      ),
      manualBrushRadius: const BlurSettings().manualBrushRadius,
      manualBrushHardness: const BlurSettings().manualBrushHardness,
    );
    updateSettings(resetSettings, trackInteraction: false);
    emit(state.copyWith(hintMessage: 'Current mode controls were reset.'));
  }

  Future<void> undo() async {
    if (!state.canUndo) {
      return;
    }
    final updatedUndo = List<BlurFocusOperation>.from(state.undoStack);
    final previous = updatedUndo.removeLast();
    final updatedRedo = List<BlurFocusOperation>.from(state.redoStack)
      ..add(state.operation);
    emit(state.copyWith(
      operation: previous,
      undoStack: updatedUndo,
      redoStack: updatedRedo,
    ));
    await _scheduleRender(BlurQuality.previewIdle, immediate: true);
  }

  Future<void> redo() async {
    if (!state.canRedo) {
      return;
    }
    final updatedRedo = List<BlurFocusOperation>.from(state.redoStack);
    final restored = updatedRedo.removeLast();
    final updatedUndo = List<BlurFocusOperation>.from(state.undoStack)
      ..add(state.operation);
    emit(state.copyWith(
      operation: restored,
      undoStack: updatedUndo,
      redoStack: updatedRedo,
    ));
    await _scheduleRender(BlurQuality.previewIdle, immediate: true);
  }

  Future<Uint8List?> exportFinal() async {
    if (_originalBytes == null) {
      return null;
    }
    emit(state.copyWith(status: BlurFocusStatus.exporting));
    final bytes = await repository.renderFinal(
      imageBytes: _originalBytes!,
      operation: state.operation,
    );
    emit(state.copyWith(status: BlurFocusStatus.ready));
    return bytes;
  }

  Duration get _trackDebounce => switch (_profile) {
        _PerformanceProfile.low => const Duration(milliseconds: 380),
        _PerformanceProfile.balanced => const Duration(milliseconds: 240),
        _PerformanceProfile.high => const Duration(milliseconds: 140),
      };

  Duration get _idleDebounce => switch (_profile) {
        _PerformanceProfile.low => const Duration(milliseconds: 340),
        _PerformanceProfile.balanced => const Duration(milliseconds: 200),
        _PerformanceProfile.high => const Duration(milliseconds: 120),
      };

  Future<void> _scheduleRender(
    BlurQuality quality, {
    bool immediate = false,
  }) async {
    _idleRenderDebounce?.cancel();
    if (immediate || quality == BlurQuality.previewTrack) {
      await _render(quality);
      if (quality == BlurQuality.previewTrack) {
        _idleRenderDebounce = Timer(_trackDebounce, () {
          _render(BlurQuality.previewIdle);
        });
      }
      return;
    }
    _idleRenderDebounce = Timer(_idleDebounce, () {
      _render(quality);
    });
  }

  Future<void> _render(BlurQuality quality) async {
    if (_originalBytes == null || state.originalImage == null) {
      return;
    }
    final ticket = ++_renderTicket;
    if (quality != BlurQuality.previewTrack) {
      emit(state.copyWith(
        status: BlurFocusStatus.processing,
        clearError: true,
      ));
    }
    final preview = await repository.renderPreview(
      imageBytes: _originalBytes!,
      operation: state.operation,
      quality: quality,
    );
    if (ticket != _renderTicket || isClosed) {
      return;
    }
    emit(state.copyWith(
      status: BlurFocusStatus.ready,
      previewImage: preview ?? state.previewImage ?? state.originalImage,
    ));
  }

  void _commitOperation(
    BlurFocusOperation operation, {
    required bool addToHistory,
    String? hintMessage,
    DateTime? lastInteraction,
  }) {
    List<BlurFocusOperation> undoStack = state.undoStack;
    if (addToHistory) {
      final expanded = List<BlurFocusOperation>.from(state.undoStack)
        ..add(state.operation);
      undoStack = expanded.length > _kMaxUndoDepth
          ? expanded.sublist(expanded.length - _kMaxUndoDepth)
          : expanded;
    }
    emit(state.copyWith(
      operation: operation,
      undoStack: undoStack,
      redoStack: addToHistory ? const [] : state.redoStack,
      hintMessage: hintMessage,
      lastInteractionAt: lastInteraction ?? state.lastInteractionAt,
      clearError: true,
    ));
  }

  @override
  Future<void> close() async {
    _idleRenderDebounce?.cancel();
    await repository.dispose();
    return super.close();
  }
}
