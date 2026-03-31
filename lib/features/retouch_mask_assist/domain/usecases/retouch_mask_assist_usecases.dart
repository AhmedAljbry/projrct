import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/repositories/retouch_mask_assist_repository.dart';

class GenerateMaskSuggestionUseCase {
  final RetouchMaskAssistRepository repository;

  GenerateMaskSuggestionUseCase(this.repository);

  Future<MaskSuggestionResult> call(MaskSuggestionRequest request) {
    return repository.generateSuggestion(request);
  }
}

class BuildMaskPreviewUseCase {
  final RetouchMaskAssistRepository repository;

  BuildMaskPreviewUseCase(this.repository);

  Future<Uint8List> call({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required double feather,
  }) {
    return repository.buildPreviewPng(
      alphaMask: alphaMask,
      width: width,
      height: height,
      feather: feather,
    );
  }
}

class ApplyMaskBrushStrokeUseCase {
  final RetouchMaskAssistRepository repository;

  ApplyMaskBrushStrokeUseCase(this.repository);

  Future<Uint8List> call({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required List<Offset> imagePoints,
    required double brushRadius,
    required MaskEditMode editMode,
  }) {
    return repository.applyBrushStroke(
      alphaMask: alphaMask,
      width: width,
      height: height,
      imagePoints: imagePoints,
      brushRadius: brushRadius,
      editMode: editMode,
    );
  }
}

class TransformMaskUseCase {
  final RetouchMaskAssistRepository repository;

  TransformMaskUseCase(this.repository);

  Future<Uint8List> call({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required MaskTransformAction action,
    int radius = 4,
  }) {
    return repository.transformMask(
      alphaMask: alphaMask,
      width: width,
      height: height,
      action: action,
      radius: radius,
    );
  }
}

class ExportProcessingMaskUseCase {
  final RetouchMaskAssistRepository repository;

  ExportProcessingMaskUseCase(this.repository);

  Future<Uint8List> call({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required double feather,
  }) {
    return repository.exportBinaryMaskPng(
      alphaMask: alphaMask,
      width: width,
      height: height,
      feather: feather,
    );
  }
}
