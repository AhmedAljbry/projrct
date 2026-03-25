import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:untitled2/features/blur_focus/data/engines/blur_commit_renderer.dart';
import 'package:untitled2/features/blur_focus/data/engines/blur_preview_renderer.dart';
import 'package:untitled2/features/blur_focus/data/processors/blur_rendering_isolate.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_focus_operation.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_mode.dart';

class IsolateBlurRenderer implements BlurPreviewRenderer, BlurCommitRenderer {
  const IsolateBlurRenderer();

  @override
  Future<Uint8List?> renderFinal({
    required Uint8List originalImageBytes,
    required BlurFocusOperation operation,
  }) async {
    final result = await compute(renderBlurFocus, {
      'bytes': originalImageBytes,
      'settings': operation.settings.toJson(),
      'segmentation': operation.segmentation?.toJson(),
      'manualStrokes': operation.manualStrokes.map((stroke) => stroke.toJson()).toList(),
      'quality': BlurQuality.export.name,
    });
    return result == null ? null : result['bytes'] as Uint8List;
  }

  @override
  Future<Uint8List?> renderPreview({
    required Uint8List originalImageBytes,
    required BlurFocusOperation operation,
    required BlurQuality quality,
  }) async {
    final result = await compute(renderBlurFocus, {
      'bytes': originalImageBytes,
      'settings': operation.settings.toJson(),
      'segmentation': operation.segmentation?.toJson(),
      'manualStrokes': operation.manualStrokes.map((stroke) => stroke.toJson()).toList(),
      'quality': quality.name,
    });
    return result == null ? null : result['bytes'] as Uint8List;
  }

  static Future<ui.Image?> decodeUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
