import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/entities/blur_mode.dart';
import '../../domain/entities/blur_operation.dart';
import 'bp_blur_isolate.dart';

/// Spawns a background isolate and converts the result into a [ui.Image].
class BpIsolateRenderer {
  const BpIsolateRenderer();

  Future<ui.Image?> render({
    required Uint8List imageBytes,
    required BlurOperation operation,
    required BpRenderQuality quality,
    Map<String, dynamic>? maskJson,
  }) async {
    try {
      final args = {
        'bytes': imageBytes,
        'settings': operation.settings.toJson(),
        'mask': maskJson,
        'quality': quality.name,
      };

      final result = await Isolate.run(() => bpRenderBlur(args));
      if (result == null) return null;

      final resultBytes = result['bytes'] as Uint8List;
      final codec = await ui.instantiateImageCodec(resultBytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> export({
    required Uint8List imageBytes,
    required BlurOperation operation,
    Map<String, dynamic>? maskJson,
  }) async {
    try {
      final args = {
        'bytes': imageBytes,
        'settings': operation.settings.toJson(),
        'mask': maskJson,
        'quality': BpRenderQuality.export.name,
      };
      final result = await Isolate.run(() => bpRenderBlur(args));
      return result?['bytes'] as Uint8List?;
    } catch (_) {
      return null;
    }
  }
}
