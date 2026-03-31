import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';

abstract class RetouchMaskAssistRepository {
  Future<MaskSuggestionResult> generateSuggestion(
      MaskSuggestionRequest request);

  Future<Uint8List> buildPreviewPng({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required double feather,
  });

  Future<Uint8List> applyBrushStroke({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required List<Offset> imagePoints,
    required double brushRadius,
    required MaskEditMode editMode,
  });

  Future<Uint8List> transformMask({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required MaskTransformAction action,
    int radius = 4,
  });

  Future<Uint8List> exportBinaryMaskPng({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required double feather,
  });

  Future<void> dispose();
}
