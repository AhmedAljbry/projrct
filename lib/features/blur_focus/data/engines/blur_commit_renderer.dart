import 'dart:typed_data';

import 'package:untitled2/features/blur_focus/domain/models/blur_focus_operation.dart';

abstract class BlurCommitRenderer {
  Future<Uint8List?> renderFinal({
    required Uint8List originalImageBytes,
    required BlurFocusOperation operation,
  });
}
