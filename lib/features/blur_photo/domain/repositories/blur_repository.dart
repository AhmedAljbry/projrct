import 'dart:typed_data';
import 'dart:ui' as ui;

import '../entities/blur_mode.dart';
import '../entities/blur_operation.dart';

/// Abstract contract for the blur rendering + segmentation pipeline.
/// Implementations live in data/repositories.
abstract class BlurRepository {
  /// Renders a preview frame at the requested [quality].
  /// Returns a [ui.Image] or null if rendering failed.
  Future<ui.Image?> renderPreview({
    required Uint8List imageBytes,
    required BlurOperation operation,
    required BpRenderQuality quality,
  });

  /// Renders and encodes a full-quality PNG for export/save.
  Future<Uint8List?> renderExport({
    required Uint8List imageBytes,
    required BlurOperation operation,
  });

  /// Attempts AI subject segmentation on the provided image bytes.
  /// Returns a confidence-mask map or null on failure.
  Future<Map<String, dynamic>?> detectSubject({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  });

  /// Attempts OCR-based text region detection on the provided image bytes.
  Future<Map<String, dynamic>?> detectTextRegions({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  });

  /// Releases any background resources held by this repository.
  Future<void> dispose();
}
