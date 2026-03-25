import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../domain/models/af_blur_mode.dart';
import '../../domain/models/af_blur_operation.dart';
import '../../domain/services/af_blur_renderer.dart';
import 'af_blur_isolate.dart';

/// Wraps [afRenderBlur] in a Flutter `compute()` call so rendering
/// always happens off the main thread.
class AfIsolateRenderer implements AfBlurRenderer {
  const AfIsolateRenderer();

  @override
  Future<Uint8List?> renderPreview({
    required Uint8List imageBytes,
    required AfBlurOperation operation,
    required AfRenderQuality quality,
  }) async {
    final result = await compute(afRenderBlur, {
      'bytes': imageBytes,
      'settings': operation.settings.toJson(),
      'mask': operation.maskData?.toJson(),
      'strokes': operation.manualStrokes.map((s) => s.toJson()).toList(),
      'quality': quality.name,
    });
    return result == null ? null : result['bytes'] as Uint8List;
  }

  @override
  Future<Uint8List?> renderExport({
    required Uint8List imageBytes,
    required AfBlurOperation operation,
  }) async {
    final result = await compute(afRenderBlur, {
      'bytes': imageBytes,
      'settings': operation.settings.toJson(),
      'mask': operation.maskData?.toJson(),
      'strokes': operation.manualStrokes.map((s) => s.toJson()).toList(),
      'quality': AfRenderQuality.export.name,
    });
    return result == null ? null : result['bytes'] as Uint8List;
  }

  /// Decode raw bytes to a [ui.Image] for display on the canvas.
  static Future<ui.Image?> toUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
