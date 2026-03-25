import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as im;

import 'package:untitled2/features/blur_focus/data/engines/mlkit_subject_segmentation_engine.dart';

/// Builds a grayscale PNG mask (R channel = alpha weight) for the creative pipeline.
/// On non-Android or ML failure, returns `null` so the pipeline keeps geometric masks.
Future<Uint8List?> buildMlSubjectMaskPng(Uint8List imageBytes) async {
  if (kIsWeb) return null;
  if (defaultTargetPlatform != TargetPlatform.android) return null;

  final decoded = im.decodeImage(imageBytes);
  if (decoded == null) return null;

  final w = decoded.width;
  final h = decoded.height;
  if (w < 8 || h < 8) return null;

  final engine = MlKitSubjectSegmentationEngine();
  try {
    final r = await engine.detectSubject(
      imageBytes: imageBytes,
      imageWidth: w,
      imageHeight: h,
    );
    await engine.dispose();

    final n = r.width * r.height;
    if (r.confidenceMask.length != n || n < 1) {
      return null;
    }

    final out = im.Image(width: r.width, height: r.height);
    for (var y = 0; y < r.height; y++) {
      for (var x = 0; x < r.width; x++) {
        final v = (r.confidenceMask[y * r.width + x] * 255).round().clamp(0, 255);
        out.setPixelRgb(x, y, v, v, v);
      }
    }
    return Uint8List.fromList(im.encodePng(out, level: 3));
  } catch (_) {
    try {
      await engine.dispose();
    } catch (_) {}
    return null;
  }
}
