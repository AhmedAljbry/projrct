import 'dart:typed_data';

import 'package:untitled2/features/blur_focus/domain/models/blur_focus_operation.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_mode.dart';

abstract class BlurPreviewRenderer {
  Future<Uint8List?> renderPreview({
    required Uint8List originalImageBytes,
    required BlurFocusOperation operation,
    required BlurQuality quality,
  });
}
