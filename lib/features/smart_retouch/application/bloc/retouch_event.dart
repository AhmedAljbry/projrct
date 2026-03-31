import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/models/brush_settings.dart';
import '../../domain/models/retouch_mode.dart';
import '../../domain/models/retouch_operation.dart';

abstract class RetouchEvent extends Equatable {
  const RetouchEvent();

  @override
  List<Object?> get props => [];
}

class LoadImageEvent extends RetouchEvent {
  final ui.Image image;
  const LoadImageEvent(this.image);

  @override
  List<Object?> get props => [image];
}

class ChangeModeEvent extends RetouchEvent {
  final RetouchMode mode;
  const ChangeModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

class UpdateBrushSettingsEvent extends RetouchEvent {
  final BrushSettings settings;
  const UpdateBrushSettingsEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SetSourceAnchorEvent extends RetouchEvent {
  final Offset? anchor;
  const SetSourceAnchorEvent(this.anchor);

  @override
  List<Object?> get props => [anchor];
}

class SetCloneOffsetEvent extends RetouchEvent {
  final Offset? offset;
  const SetCloneOffsetEvent(this.offset);

  @override
  List<Object?> get props => [offset];
}

class PreviewOperationEvent extends RetouchEvent {
  final RetouchOperation operation;

  const PreviewOperationEvent({required this.operation});

  @override
  List<Object?> get props => [operation];
}

class ApplyOperationEvent extends RetouchEvent {
  final RetouchOperation operation;
  final bool useCurrentImageAsResult;

  const ApplyOperationEvent({
    required this.operation,
    this.useCurrentImageAsResult = false,
  });

  @override
  List<Object?> get props => [operation, useCurrentImageAsResult];
}

class UndoEvent extends RetouchEvent {}

class RedoEvent extends RetouchEvent {}

class ClearHistoryEvent extends RetouchEvent {}

class ExportRequestedEvent extends RetouchEvent {}
