import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:untitled2/features/blur_focus/data/engines/blur_commit_renderer.dart';
import 'package:untitled2/features/blur_focus/data/engines/blur_preview_renderer.dart';
import 'package:untitled2/features/blur_focus/data/engines/focus_mask_refinement_engine.dart';
import 'package:untitled2/features/blur_focus/data/engines/subject_segmentation_engine.dart';
import 'package:untitled2/features/blur_focus/data/processors/isolate_blur_renderer.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_focus_operation.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_mode.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';

class BlurFocusRepository {
  BlurFocusRepository({
    required this.segmentationEngine,
    required this.refinementEngine,
    required this.previewRenderer,
    required this.commitRenderer,
  });

  final SubjectSegmentationEngine segmentationEngine;
  final FocusMaskRefinementEngine refinementEngine;
  final BlurPreviewRenderer previewRenderer;
  final BlurCommitRenderer commitRenderer;

  SegmentationResultData? _cachedSegmentation;

  Future<SegmentationResultData> detectSubject({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedSegmentation != null) {
      return _cachedSegmentation!;
    }
    final detection = await segmentationEngine.detectSubject(
      imageBytes: imageBytes,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    _cachedSegmentation = detection;
    return detection;
  }

  BlurFocusOperation refineOperation(BlurFocusOperation operation) {
    if (operation.segmentation == null) {
      return operation;
    }
    final refinedSegmentation = refinementEngine.refine(
      segmentation: operation.segmentation!,
      settings: operation.settings,
      manualStrokes: operation.manualStrokes,
    );
    return operation.copyWith(segmentation: refinedSegmentation);
  }

  Future<ui.Image?> renderPreview({
    required Uint8List imageBytes,
    required BlurFocusOperation operation,
    required BlurQuality quality,
  }) async {
    final bytes = await previewRenderer.renderPreview(
      originalImageBytes: imageBytes,
      operation: operation,
      quality: quality,
    );
    if (bytes == null) {
      return null;
    }
    return IsolateBlurRenderer.decodeUiImage(bytes);
  }

  Future<Uint8List?> renderFinal({
    required Uint8List imageBytes,
    required BlurFocusOperation operation,
  }) {
    return commitRenderer.renderFinal(
      originalImageBytes: imageBytes,
      operation: operation,
    );
  }

  Future<void> dispose() => segmentationEngine.dispose();
}
