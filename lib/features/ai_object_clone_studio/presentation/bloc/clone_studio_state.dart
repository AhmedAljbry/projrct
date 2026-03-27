import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/clone_entities.dart';

enum CloneStudioMode {
  select,
  place,
}

const Object _unsetActiveLayerId = Object();

abstract class CloneStudioEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadImageEvent extends CloneStudioEvent {
  final Uint8List image;
  LoadImageEvent(this.image);

  @override
  List<Object?> get props => [image];
}

class SelectObjectEvent extends CloneStudioEvent {
  final List<Offset> points;
  SelectObjectEvent(this.points);

  @override
  List<Object?> get props => [points];
}

class SetModeEvent extends CloneStudioEvent {
  final CloneStudioMode mode;
  SetModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

class ConfirmSelectionEvent extends CloneStudioEvent {}

class UpdateLayerTransformEvent extends CloneStudioEvent {
  final String id;
  final TransformState transform;
  UpdateLayerTransformEvent(this.id, this.transform);

  @override
  List<Object?> get props => [id, transform];
}

class UpdateLayerHarmonizationEvent extends CloneStudioEvent {
  final String id;
  final HarmonizationSettings harmonization;
  UpdateLayerHarmonizationEvent(this.id, this.harmonization);

  @override
  List<Object?> get props => [id, harmonization];
}

class DeleteLayerEvent extends CloneStudioEvent {
  final String id;
  DeleteLayerEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UndoEvent extends CloneStudioEvent {}

class RedoEvent extends CloneStudioEvent {}

class CloneStudioState extends Equatable {
  final Uint8List? baseImage;
  final CloneStudioMode mode;
  final List<EditLayer> layers;
  final String? activeLayerId;
  final bool isLoading;
  final String? errorMessage;
  final List<EditLayer> history;
  final int historyIndex;

  const CloneStudioState({
    this.baseImage,
    this.mode = CloneStudioMode.select,
    this.layers = const [],
    this.activeLayerId,
    this.isLoading = false,
    this.errorMessage,
    this.history = const [],
    this.historyIndex = -1,
  });

  CloneStudioState copyWith({
    Uint8List? baseImage,
    CloneStudioMode? mode,
    List<EditLayer>? layers,
    Object? activeLayerId = _unsetActiveLayerId,
    bool? isLoading,
    String? errorMessage,
    List<EditLayer>? history,
    int? historyIndex,
  }) {
    return CloneStudioState(
      baseImage: baseImage ?? this.baseImage,
      mode: mode ?? this.mode,
      layers: layers ?? this.layers,
      activeLayerId: identical(activeLayerId, _unsetActiveLayerId)
          ? this.activeLayerId
          : activeLayerId as String?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
    );
  }

  @override
  List<Object?> get props => [
        baseImage,
        mode,
        layers,
        activeLayerId,
        isLoading,
        errorMessage,
        history,
        historyIndex,
      ];
}
