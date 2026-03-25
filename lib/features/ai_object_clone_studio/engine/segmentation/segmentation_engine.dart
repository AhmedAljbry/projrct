import 'dart:typed_data';

import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';

import '../../domain/entities/clone_entities.dart';

class SegmentationEngine {
  final SubjectSegmenter _segmenter = SubjectSegmenter(
    options: SubjectSegmenterOptions(
      enableForegroundBitmap: false,
      enableForegroundConfidenceMask: true,
      enableMultipleSubjects: SubjectResultOptions(
        enableConfidenceMask: false,
        enableSubjectBitmap: false,
      ),
    ),
  );

  Future<MaskData?> autoDetectSubject(Uint8List imageBytes) async {
    try {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<MaskData> refineMask(MaskData mask, {double feather = 0.0}) async {
    return mask;
  }

  Future<void> dispose() => _segmenter.close();
}
