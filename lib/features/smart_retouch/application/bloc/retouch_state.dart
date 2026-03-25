import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:equatable/equatable.dart';
import 'package:flutter/gestures.dart';
import '../../domain/models/brush_settings.dart';
import '../../domain/models/retouch_mode.dart';
import '../../domain/models/retouch_operation.dart';

enum RetouchStatus { initial, loading, ready, processing, error, saving }

class RetouchState extends Equatable {
  final RetouchStatus status;
  final ui.Image? originalImage;
  final Uint8List? originalImageBytes;
  final Uint8List? currentImageBytes;
  final ui.Image? currentImage;

  final RetouchMode activeMode;
  final BrushSettings activeBrushSettings;

  final List<RetouchOperation> operations;
  final List<RetouchOperation> redoStack;

  final bool isMasksVisible;
  final Offset? activeSourceAnchor;
  final Offset? activeCloneOffset;
  final Offset? lastStrokeEnd;
  final Offset? lastSourceEnd;

  final String? errorMessage;

  const RetouchState({
    this.status = RetouchStatus.initial,
    this.originalImage,
    this.originalImageBytes,
    this.currentImageBytes,
    this.currentImage,
    this.activeMode = RetouchMode.clone,
    this.activeBrushSettings = const BrushSettings(),
    this.operations = const [],
    this.redoStack = const [],
    this.isMasksVisible = false,
    this.activeSourceAnchor,
    this.activeCloneOffset,
    this.lastStrokeEnd,
    this.lastSourceEnd,
    this.errorMessage,
  });

  RetouchState copyWith({
    RetouchStatus? status,
    ui.Image? originalImage,
    Uint8List? originalImageBytes,
    Uint8List? currentImageBytes,
    ui.Image? currentImage,
    RetouchMode? activeMode,
    BrushSettings? activeBrushSettings,
    List<RetouchOperation>? operations,
    List<RetouchOperation>? redoStack,
    bool? isMasksVisible,
    Offset? activeSourceAnchor,
    Offset? activeCloneOffset,
    Offset? lastStrokeEnd,
    Offset? lastSourceEnd,
    String? errorMessage,
    bool resetCloneOffset = false,
    bool resetLastStroke = false,
  }) {
    return RetouchState(
      status: status ?? this.status,
      originalImage: originalImage ?? this.originalImage,
      originalImageBytes: originalImageBytes ?? this.originalImageBytes,
      currentImageBytes: currentImageBytes ?? this.currentImageBytes,
      currentImage: currentImage ?? this.currentImage,
      activeMode: activeMode ?? this.activeMode,
      activeBrushSettings: activeBrushSettings ?? this.activeBrushSettings,
      operations: operations ?? this.operations,
      redoStack: redoStack ?? this.redoStack,
      isMasksVisible: isMasksVisible ?? this.isMasksVisible,
      activeSourceAnchor: activeSourceAnchor ?? this.activeSourceAnchor,
      activeCloneOffset: resetCloneOffset
          ? null
          : (activeCloneOffset ?? this.activeCloneOffset),
      lastStrokeEnd:
          resetLastStroke ? null : (lastStrokeEnd ?? this.lastStrokeEnd),
      lastSourceEnd:
          resetLastStroke ? null : (lastSourceEnd ?? this.lastSourceEnd),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get canUndo => operations.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  @override
  List<Object?> get props => [
        status,
        originalImage,
        originalImageBytes,
        currentImageBytes,
        currentImage,
        activeMode,
        activeBrushSettings,
        operations,
        redoStack,
        isMasksVisible,
        activeSourceAnchor,
        activeCloneOffset,
        lastStrokeEnd,
        lastSourceEnd,
        errorMessage,
      ];
}
