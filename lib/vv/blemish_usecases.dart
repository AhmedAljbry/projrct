import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:untitled2/vv/blemish_operation.dart';
import 'package:untitled2/vv/blemish_removal_engine.dart';
import 'package:untitled2/vv/brush_settings.dart';
import 'package:untitled2/vv/mask_data.dart';
import 'package:untitled2/vv/mask_generation_service.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Use Case: Apply a single blemish operation
// ─────────────────────────────────────────────────────────────────────────────

class ApplyBlemishOperationUseCase {
  final BlemishRemovalEngine engine;

  const ApplyBlemishOperationUseCase(this.engine);

  Future<EngineResult> call({
    required Uint8List imagePixels,
    required int imageWidth,
    required int imageHeight,
    required BlemishOperation operation,
    EngineQualityMode mode = EngineQualityMode.preview,
  }) {
    return engine.heal(
      imagePixels: imagePixels,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      operation: operation,
      mode: mode,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Use Case: Generate mask from brush stroke
// ─────────────────────────────────────────────────────────────────────────────

class GenerateBrushMaskUseCase {
  final MaskGenerationService maskService;

  const GenerateBrushMaskUseCase(this.maskService);

  MaskData call({
    required List<Offset> strokePoints,
    required BrushSettings brush,
    required int imageWidth,
    required int imageHeight,
  }) {
    return maskService.generateStrokeMask(
      strokePoints: strokePoints,
      brush: brush,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Use Case: Export final image with all operations applied
// ─────────────────────────────────────────────────────────────────────────────

class ExportBlemishResultUseCase {
  final BlemishRemovalEngine engine;

  const ExportBlemishResultUseCase(this.engine);

  Future<Uint8List> call({
    required Uint8List imagePixels,
    required int imageWidth,
    required int imageHeight,
    required List<BlemishOperation> operations,
    void Function(int, int)? onProgress,
  }) {
    return engine.applyAll(
      imagePixels: imagePixels,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      operations: operations,
      mode: EngineQualityMode.finalQuality,
      onProgress: onProgress,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Use Case: Build a BlemishOperation from raw stroke data
// ─────────────────────────────────────────────────────────────────────────────

class BuildBlemishOperationUseCase {
  final MaskGenerationService maskService;

  const BuildBlemishOperationUseCase(this.maskService);

  BlemishOperation call({
    required List<Offset> strokePoints,
    required BrushSettings brushSettings,
    required StrokeType strokeType,
    required int imageWidth,
    required int imageHeight,
    required String operationId,
  }) {
    final mask = maskService.generateStrokeMask(
      strokePoints: strokePoints,
      brush: brushSettings,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );

    return BlemishOperation(
      id: operationId,
      createdAt: DateTime.now(),
      brushSettings: brushSettings,
      strokePoints: strokePoints,
      strokeType: strokeType,
      mask: mask,
    );
  }
}
