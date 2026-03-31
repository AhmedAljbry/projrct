import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/usecases/retouch_mask_assist_usecases.dart';

part 'expand_mask_assist_state.dart';

class ExpandMaskAssistCubit extends Cubit<ExpandMaskAssistState> {
  ExpandMaskAssistCubit({
    required GenerateMaskSuggestionUseCase generateMaskSuggestionUseCase,
    required BuildMaskPreviewUseCase buildMaskPreviewUseCase,
    required ApplyMaskBrushStrokeUseCase applyMaskBrushStrokeUseCase,
    required TransformMaskUseCase transformMaskUseCase,
    required ExportProcessingMaskUseCase exportProcessingMaskUseCase,
  })  : _generateMaskSuggestionUseCase = generateMaskSuggestionUseCase,
        _buildMaskPreviewUseCase = buildMaskPreviewUseCase,
        _applyMaskBrushStrokeUseCase = applyMaskBrushStrokeUseCase,
        _transformMaskUseCase = transformMaskUseCase,
        _exportProcessingMaskUseCase = exportProcessingMaskUseCase,
        super(const ExpandMaskAssistState());

  final GenerateMaskSuggestionUseCase _generateMaskSuggestionUseCase;
  final BuildMaskPreviewUseCase _buildMaskPreviewUseCase;
  final ApplyMaskBrushStrokeUseCase _applyMaskBrushStrokeUseCase;
  final TransformMaskUseCase _transformMaskUseCase;
  final ExportProcessingMaskUseCase _exportProcessingMaskUseCase;

  final List<_MaskSnapshot> _undoStack = <_MaskSnapshot>[];
  final List<_MaskSnapshot> _redoStack = <_MaskSnapshot>[];

  void setCreationMode(MaskCreationMode mode) {
    emit(state.copyWith(creationMode: mode, clearErrorMessage: true));
  }

  void setEditMode(MaskEditMode mode) {
    emit(state.copyWith(editMode: mode));
  }

  Future<void> setImage(Uint8List imageBytes, {bool resetMode = false}) async {
    _undoStack.clear();
    _redoStack.clear();
    emit(
      state.copyWith(
        sourceImageBytes: imageBytes,
        creationMode: resetMode ? MaskCreationMode.manual : state.creationMode,
        generationStatus: MaskGenerationStatus.idle,
        clearErrorMessage: true,
        clearMaskData: true,
        expansionLevel: 0,
        feather: resetMode ? 2 : state.feather,
        previewVisible: true,
        canUndo: false,
        canRedo: false,
      ),
    );
  }

  Future<void> generateSuggestion() async {
    if (state.sourceImageBytes == null) {
      return;
    }
    emit(state.copyWith(
        generationStatus: MaskGenerationStatus.generating,
        clearErrorMessage: true));
    try {
      final result = await _generateMaskSuggestionUseCase(
        MaskSuggestionRequest(
          imageBytes: state.sourceImageBytes!,
          toolType: RetouchToolType.expand,
        ),
      );
      final preview = await _buildMaskPreviewUseCase(
        alphaMask: result.alphaMask,
        width: result.width,
        height: result.height,
        feather: state.feather,
      );
      _undoStack
        ..clear()
        ..add(_MaskSnapshot(
            Uint8List.fromList(result.alphaMask), state.feather, 0));
      _redoStack.clear();
      emit(
        state.copyWith(
          maskAlpha: result.alphaMask,
          maskWidth: result.width,
          maskHeight: result.height,
          maskPreviewPng: preview,
          generationStatus: MaskGenerationStatus.ready,
          source: result.source,
          expansionLevel: 0,
          canUndo: false,
          canRedo: false,
        ),
      );
    } catch (error) {
      emit(state.copyWith(
          generationStatus: MaskGenerationStatus.failure,
          errorMessage: error.toString()));
    }
  }

  Future<void> retrySuggestion() async => generateSuggestion();

  Future<void> commitStroke(
      {required List<Offset> imagePoints, required double brushRadius}) async {
    if (state.maskAlpha == null || imagePoints.isEmpty) {
      return;
    }
    final updated = await _applyMaskBrushStrokeUseCase(
      alphaMask: state.maskAlpha!,
      width: state.maskWidth,
      height: state.maskHeight,
      imagePoints: imagePoints,
      brushRadius: brushRadius,
      editMode: state.editMode,
    );
    await _emitMask(updated,
        feather: state.feather,
        expansionLevel: state.expansionLevel,
        appendHistory: true);
  }

  Future<void> updateFeather(double feather) async {
    if (state.maskAlpha == null) {
      emit(state.copyWith(feather: feather));
      return;
    }
    final preview = await _buildMaskPreviewUseCase(
      alphaMask: state.maskAlpha!,
      width: state.maskWidth,
      height: state.maskHeight,
      feather: feather,
    );
    if (_undoStack.isNotEmpty) {
      _undoStack[_undoStack.length - 1] = _MaskSnapshot(
          Uint8List.fromList(state.maskAlpha!), feather, state.expansionLevel);
    }
    emit(state.copyWith(feather: feather, maskPreviewPng: preview));
  }

  void togglePreview(bool value) {
    emit(state.copyWith(previewVisible: value));
  }

  Future<void> transformMask(MaskTransformAction action) async {
    if (state.maskAlpha == null) {
      return;
    }
    final updated = await _transformMaskUseCase(
      alphaMask: state.maskAlpha!,
      width: state.maskWidth,
      height: state.maskHeight,
      action: action,
      radius: 4,
    );
    final nextExpansion = switch (action) {
      MaskTransformAction.expand => state.expansionLevel + 1,
      MaskTransformAction.contract => state.expansionLevel - 1,
      MaskTransformAction.clear => 0,
    };
    await _emitMask(updated,
        feather: state.feather,
        expansionLevel: nextExpansion,
        appendHistory: true);
  }

  Future<void> clearMask() async => transformMask(MaskTransformAction.clear);

  Future<void> undo() async {
    if (_undoStack.length <= 1) {
      return;
    }
    final current = _undoStack.removeLast();
    _redoStack.add(current);
    final previous = _undoStack.last;
    await _emitMask(previous.alphaMask,
        feather: previous.feather,
        expansionLevel: previous.expansionLevel,
        appendHistory: false);
  }

  Future<void> redo() async {
    if (_redoStack.isEmpty) {
      return;
    }
    final snapshot = _redoStack.removeLast();
    _undoStack.add(snapshot);
    await _emitMask(snapshot.alphaMask,
        feather: snapshot.feather,
        expansionLevel: snapshot.expansionLevel,
        appendHistory: false);
  }

  Future<Uint8List?> exportMaskPng() async {
    if (state.maskAlpha == null) {
      return null;
    }
    return _exportProcessingMaskUseCase(
      alphaMask: state.maskAlpha!,
      width: state.maskWidth,
      height: state.maskHeight,
      feather: state.feather,
    );
  }

  Future<void> _emitMask(Uint8List alphaMask,
      {required double feather,
      required int expansionLevel,
      required bool appendHistory}) async {
    final preview = await _buildMaskPreviewUseCase(
      alphaMask: alphaMask,
      width: state.maskWidth,
      height: state.maskHeight,
      feather: feather,
    );
    if (appendHistory) {
      _undoStack.add(_MaskSnapshot(
          Uint8List.fromList(alphaMask), feather, expansionLevel));
      _redoStack.clear();
    }
    emit(state.copyWith(
      maskAlpha: Uint8List.fromList(alphaMask),
      maskPreviewPng: preview,
      feather: feather,
      expansionLevel: expansionLevel,
      generationStatus: MaskGenerationStatus.ready,
      canUndo: _undoStack.length > 1,
      canRedo: _redoStack.isNotEmpty,
    ));
  }
}

class _MaskSnapshot {
  final Uint8List alphaMask;
  final double feather;
  final int expansionLevel;

  _MaskSnapshot(this.alphaMask, this.feather, this.expansionLevel);
}
