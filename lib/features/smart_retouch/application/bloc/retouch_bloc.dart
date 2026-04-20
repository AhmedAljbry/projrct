import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/retouch_operation.dart';
import '../../infrastructure/engine/retouch_image_service.dart';
import 'retouch_event.dart';
import 'retouch_state.dart';

class RetouchBloc extends Bloc<RetouchEvent, RetouchState> {
  RetouchBloc() : super(const RetouchState()) {
    on<LoadImageEvent>(_onLoadImage);
    on<ChangeModeEvent>(_onChangeMode);
    on<UpdateBrushSettingsEvent>(_onUpdateBrushSettings);
    on<SetSourceAnchorEvent>(_onSetSourceAnchor);
    on<SetCloneOffsetEvent>(_onSetCloneOffset);
    on<ApplyOperationEvent>(_onApplyOperation);
    on<UndoEvent>(_onUndo);
    on<RedoEvent>(_onRedo);
    on<ClearHistoryEvent>(_onClearHistory);
  }

  Future<void> _onLoadImage(
    LoadImageEvent event,
    Emitter<RetouchState> emit,
  ) async {
    emit(state.copyWith(status: RetouchStatus.loading));

    final byteData =
        await event.image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      emit(state.copyWith(
        status: RetouchStatus.error,
        errorMessage: 'Failed to read image bytes.',
      ));
      return;
    }

    final bytes = byteData.buffer.asUint8List();

    emit(state.copyWith(
      status: RetouchStatus.ready,
      originalImage: event.image,
      originalImageBytes: bytes,
      currentImageBytes: bytes,
      currentImage: event.image,
      operations: [],
      redoStack: [],
    ));
  }

  void _onChangeMode(ChangeModeEvent event, Emitter<RetouchState> emit) {
    emit(state.copyWith(
      activeMode: event.mode,
      activeSourceAnchor: null,
      resetCloneOffset: true,
      resetLastStroke: true,
    ));
  }

  void _onUpdateBrushSettings(
    UpdateBrushSettingsEvent event,
    Emitter<RetouchState> emit,
  ) {
    emit(state.copyWith(activeBrushSettings: event.settings));
  }

  void _onSetSourceAnchor(
    SetSourceAnchorEvent event,
    Emitter<RetouchState> emit,
  ) {
    emit(state.copyWith(
      activeSourceAnchor: event.anchor,
      resetCloneOffset: true,
      resetLastStroke: true,
    ));
  }

  void _onSetCloneOffset(
    SetCloneOffsetEvent event,
    Emitter<RetouchState> emit,
  ) {
    emit(state.copyWith(
      activeCloneOffset: event.offset,
      resetCloneOffset: event.offset == null,
    ));
  }

  Future<void> _onApplyOperation(
    ApplyOperationEvent event,
    Emitter<RetouchState> emit,
  ) async {
    final Uint8List? sourceImageBytes = state.originalImageBytes;
    final Uint8List? baseTargetBytes =
        state.currentImageBytes ?? state.originalImageBytes;
    final updatedOps = List.of(state.operations)..add(event.operation);

    emit(state.copyWith(
      status: RetouchStatus.processing,
      operations: updatedOps,
      redoStack: [],
      lastStrokeEnd: _extractTargetEnd(event.operation),
      lastSourceEnd: _extractSourceEnd(event.operation),
    ));

    if (sourceImageBytes != null && baseTargetBytes != null) {
      final resultBytes =
          await RetouchImageService.renderSingleOperationPreview(
        sourceImageBytes: sourceImageBytes,
        currentImageBytes: baseTargetBytes,
        operation: event.operation,
      );

      if (resultBytes != null) {
        final codec = await ui.instantiateImageCodec(resultBytes);
        final frame = await codec.getNextFrame();
        emit(state.copyWith(
          status: RetouchStatus.ready,
          currentImage: frame.image,
          currentImageBytes: resultBytes,
          lastStrokeEnd: _extractTargetEnd(event.operation),
          lastSourceEnd: _extractSourceEnd(event.operation),
        ));
        return;
      }
    }

    await _renderAndEmit(updatedOps, emit);
  }

  Future<void> _onUndo(UndoEvent event, Emitter<RetouchState> emit) async {
    if (state.operations.isEmpty) return;

    final updatedOps = List.of(state.operations);
    final lastOp = updatedOps.removeLast();
    final updatedRedo = List.of(state.redoStack)..add(lastOp);

    emit(state.copyWith(
      status: RetouchStatus.ready,
      operations: updatedOps,
      redoStack: updatedRedo,
    ));
    await _renderAndEmit(updatedOps, emit);
  }

  Future<void> _onRedo(RedoEvent event, Emitter<RetouchState> emit) async {
    if (state.redoStack.isEmpty) return;

    final updatedRedo = List.of(state.redoStack);
    final opToRestore = updatedRedo.removeLast();
    final updatedOps = List.of(state.operations)..add(opToRestore);

    emit(state.copyWith(
      status: RetouchStatus.ready,
      operations: updatedOps,
      redoStack: updatedRedo,
    ));
    await _renderAndEmit(updatedOps, emit);
  }

  void _onClearHistory(ClearHistoryEvent event, Emitter<RetouchState> emit) {
    emit(state.copyWith(
      operations: [],
      redoStack: [],
      currentImage: state.originalImage,
      currentImageBytes: state.originalImageBytes,
      resetLastStroke: true,
    ));
  }

  Future<void> _renderAndEmit(
    List<RetouchOperation> operations,
    Emitter<RetouchState> emit,
  ) async {
    if (state.originalImageBytes == null) return;

    final resultBytes = await RetouchImageService.renderOperations(
      originalImageBytes: state.originalImageBytes!,
      operations: operations,
    );

    if (resultBytes != null) {
      final codec = await ui.instantiateImageCodec(resultBytes);
      final frame = await codec.getNextFrame();
      emit(state.copyWith(
        status: RetouchStatus.ready,
        currentImage: frame.image,
        currentImageBytes: resultBytes,
        lastStrokeEnd: _findLastTargetEnd(operations),
        lastSourceEnd: _findLastSourceEnd(operations),
      ));
    }
  }

  Offset? _extractTargetEnd(RetouchOperation operation) {
    if (operation is StrokeOperation && operation.path.isNotEmpty) {
      return operation.path.last;
    }
    if (operation is EraseOperation && operation.path.isNotEmpty) {
      return operation.path.last;
    }
    return null;
  }

  Offset? _extractSourceEnd(RetouchOperation operation) {
    if (operation is StrokeOperation &&
        operation.path.isNotEmpty &&
        operation.sourceAnchor != null) {
      return operation.sourceAnchor! +
          (operation.path.last - operation.path.first);
    }
    return null;
  }

  Offset? _findLastTargetEnd(List<RetouchOperation> operations) {
    for (final op in operations.reversed) {
      final end = _extractTargetEnd(op);
      if (end != null) return end;
    }
    return null;
  }

  Offset? _findLastSourceEnd(List<RetouchOperation> operations) {
    for (final op in operations.reversed) {
      final end = _extractSourceEnd(op);
      if (end != null) return end;
    }
    return null;
  }
}
