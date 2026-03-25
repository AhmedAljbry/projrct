import 'dart:typed_data';

import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';

abstract class SubjectSegmentationEngine {
  Future<SegmentationResultData> detectSubject({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  });

  Future<void> dispose() async {}
}
