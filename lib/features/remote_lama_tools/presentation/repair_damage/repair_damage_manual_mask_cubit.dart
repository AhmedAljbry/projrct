import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;

import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/usecases/retouch_mask_assist_usecases.dart';

part 'repair_damage_manual_mask_state.dart';

class RepairDamageManualMaskCubit extends Cubit<RepairDamageManualMaskState> {
  RepairDamageManualMaskCubit({
    required BuildMaskPreviewUseCase buildMaskPreviewUseCase,
    required ApplyMaskBrushStrokeUseCase applyMaskBrushStrokeUseCase,
    required TransformMaskUseCase transformMaskUseCase,
    required ExportProcessingMaskUseCase exportProcessingMaskUseCase,
  })  : _buildMaskPreviewUseCase = buildMaskPreviewUseCase,
        _applyMaskBrushStrokeUseCase = applyMaskBrushStrokeUseCase,
        _transformMaskUseCase = transformMaskUseCase,
        _exportProcessingMaskUseCase = exportProcessingMaskUseCase,
        super(const RepairDamageManualMaskState());

  final BuildMaskPreviewUseCase _buildMaskPreviewUseCase;
  final ApplyMaskBrushStrokeUseCase _applyMaskBrushStrokeUseCase;
  final TransformMaskUseCase _transformMaskUseCase;
  final ExportProcessingMaskUseCase _exportProcessingMaskUseCase;

  final List<_ManualMaskSnapshot> _undoStack = <_ManualMaskSnapshot>[];
  final List<_ManualMaskSnapshot> _redoStack = <_ManualMaskSnapshot>[];

  Future<void> setImage(Uint8List imageBytes) async {
    final dimensions = await compute(_decodeImageDimensionsTask, imageBytes);
    if (dimensions.$1 <= 0 || dimensions.$2 <= 0) {
      reset();
      return;
    }

    final blankMask = Uint8List(dimensions.$1 * dimensions.$2);
    final snapshot = _ManualMaskSnapshot(
      alphaMask: blankMask,
      feather: state.feather,
      expansionLevel: 0,
    );

    _undoStack
      ..clear()
      ..add(snapshot);
    _redoStack.clear();

    emit(
      state.copyWith(
        sourceImageBytes: imageBytes,
        imageWidth: dimensions.$1,
        imageHeight: dimensions.$2,
        maskAlpha: blankMask,
        maskPreviewPng: null,
        expansionLevel: 0,
        canUndo: false,
        canRedo: false,
        hasMaskContent: false,
      ),
    );
  }

  void setEditMode(MaskEditMode mode) {
    emit(state.copyWith(editMode: mode));
  }

  Future<void> commitStroke({
    required List<Offset> imagePoints,
    required double brushRadius,
  }) async {
    if (!state.isReady || state.maskAlpha == null || imagePoints.isEmpty) {
      return;
    }

    final updated = await _applyMaskBrushStrokeUseCase(
      alphaMask: state.maskAlpha!,
      width: state.imageWidth,
      height: state.imageHeight,
      imagePoints: imagePoints,
      brushRadius: brushRadius,
      editMode: state.editMode,
    );

    await _emitMask(
      updated,
      feather: state.feather,
      expansionLevel: state.expansionLevel,
      appendHistory: true,
    );
  }

  Future<void> updateFeather(double feather) async {
    if (!state.isReady || state.maskAlpha == null) {
      emit(state.copyWith(feather: feather));
      return;
    }

    if (!state.hasMaskContent) {
      if (_undoStack.isNotEmpty) {
        _undoStack[_undoStack.length - 1] = _undoStack.last.copyWith(
          feather: feather,
        );
      }
      emit(
        state.copyWith(
          feather: feather,
          maskPreviewPng: null,
        ),
      );
      return;
    }

    final preview = await _buildMaskPreviewUseCase(
      alphaMask: state.maskAlpha!,
      width: state.imageWidth,
      height: state.imageHeight,
      feather: feather,
    );

    if (_undoStack.isNotEmpty) {
      _undoStack[_undoStack.length - 1] = _undoStack.last.copyWith(
        feather: feather,
      );
    }

    emit(
      state.copyWith(
        feather: feather,
        maskPreviewPng: preview,
      ),
    );
  }

  void togglePreview(bool value) {
    emit(state.copyWith(previewVisible: value));
  }

  Future<void> transformMask(MaskTransformAction action) async {
    if (!state.isReady || state.maskAlpha == null) {
      return;
    }

    final updated = await _transformMaskUseCase(
      alphaMask: state.maskAlpha!,
      width: state.imageWidth,
      height: state.imageHeight,
      action: action,
      radius: 4,
    );

    final nextExpansion = switch (action) {
      MaskTransformAction.expand => state.expansionLevel + 1,
      MaskTransformAction.contract => state.expansionLevel - 1,
      MaskTransformAction.clear => 0,
    };

    await _emitMask(
      updated,
      feather: state.feather,
      expansionLevel: nextExpansion,
      appendHistory: true,
    );
  }

  Future<void> clearMask() async {
    await transformMask(MaskTransformAction.clear);
  }

  Future<void> undo() async {
    if (_undoStack.length <= 1) {
      return;
    }

    final current = _undoStack.removeLast();
    _redoStack.add(current);
    final previous = _undoStack.last;

    await _emitMask(
      previous.alphaMask,
      feather: previous.feather,
      expansionLevel: previous.expansionLevel,
      appendHistory: false,
    );
  }

  Future<void> redo() async {
    if (_redoStack.isEmpty) {
      return;
    }

    final snapshot = _redoStack.removeLast();
    _undoStack.add(snapshot);

    await _emitMask(
      snapshot.alphaMask,
      feather: snapshot.feather,
      expansionLevel: snapshot.expansionLevel,
      appendHistory: false,
    );
  }

  Future<Uint8List?> exportMaskPng() async {
    if (!state.isReady || state.maskAlpha == null || !state.hasMaskContent) {
      return null;
    }

    return _exportProcessingMaskUseCase(
      alphaMask: state.maskAlpha!,
      width: state.imageWidth,
      height: state.imageHeight,
      feather: state.feather,
    );
  }

  void reset() {
    _undoStack.clear();
    _redoStack.clear();
    emit(const RepairDamageManualMaskState());
  }

  Future<void> _emitMask(
    Uint8List alphaMask, {
    required double feather,
    required int expansionLevel,
    required bool appendHistory,
  }) async {
    final copiedAlpha = Uint8List.fromList(alphaMask);
    final hasMaskContent = copiedAlpha.any((value) => value > 0);
    Uint8List? preview;

    if (hasMaskContent) {
      preview = await _buildMaskPreviewUseCase(
        alphaMask: copiedAlpha,
        width: state.imageWidth,
        height: state.imageHeight,
        feather: feather,
      );
    }

    if (appendHistory) {
      _undoStack.add(
        _ManualMaskSnapshot(
          alphaMask: copiedAlpha,
          feather: feather,
          expansionLevel: expansionLevel,
        ),
      );
      _redoStack.clear();
    }

    emit(
      state.copyWith(
        maskAlpha: copiedAlpha,
        maskPreviewPng: preview,
        feather: feather,
        expansionLevel: expansionLevel,
        canUndo: _undoStack.length > 1,
        canRedo: _redoStack.isNotEmpty,
        hasMaskContent: hasMaskContent,
      ),
    );
  }
}

class _ManualMaskSnapshot {
  const _ManualMaskSnapshot({
    required this.alphaMask,
    required this.feather,
    required this.expansionLevel,
  });

  final Uint8List alphaMask;
  final double feather;
  final int expansionLevel;

  _ManualMaskSnapshot copyWith({
    Uint8List? alphaMask,
    double? feather,
    int? expansionLevel,
  }) {
    return _ManualMaskSnapshot(
      alphaMask: alphaMask ?? this.alphaMask,
      feather: feather ?? this.feather,
      expansionLevel: expansionLevel ?? this.expansionLevel,
    );
  }
}

(int, int) _decodeImageDimensionsTask(Uint8List imageBytes) {
  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) {
    return (0, 0);
  }
  return (decoded.width, decoded.height);
}
