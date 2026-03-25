import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/entities/blur_mode.dart';
import '../../domain/entities/blur_operation.dart';
import '../../domain/repositories/blur_repository.dart';
import '../datasources/bp_segmentation_datasource.dart';
import '../rendering/bp_isolate_renderer.dart';

/// Concrete implementation of [BlurRepository].
class BpBlurRepositoryImpl implements BlurRepository {
  BpBlurRepositoryImpl({
    required this.renderer,
    required this.segmentation,
  });

  final BpIsolateRenderer renderer;
  final BpSegmentationDatasource segmentation;

  Map<String, dynamic>? _subjectMaskCache;
  Map<String, dynamic>? _textMaskCache;

  @override
  Future<ui.Image?> renderPreview({
    required Uint8List imageBytes,
    required BlurOperation operation,
    required BpRenderQuality quality,
  }) async {
    // Only attempt segmentation for smart mode
    Map<String, dynamic>? mask;
    if (operation.settings.mode == BlurPhotoMode.smart) {
      mask = _subjectMaskCache;
    } else if (operation.settings.mode == BlurPhotoMode.text) {
      mask = _textMaskCache;
    }

    return renderer.render(
      imageBytes: imageBytes,
      operation: operation,
      quality: quality,
      maskJson: mask,
    );
  }

  @override
  Future<Uint8List?> renderExport({
    required Uint8List imageBytes,
    required BlurOperation operation,
  }) async {
    Map<String, dynamic>? mask;
    if (operation.settings.mode == BlurPhotoMode.smart) {
      mask = _subjectMaskCache;
    } else if (operation.settings.mode == BlurPhotoMode.text) {
      mask = _textMaskCache;
    }
    return renderer.export(
      imageBytes: imageBytes,
      operation: operation,
      maskJson: mask,
    );
  }

  @override
  Future<Map<String, dynamic>?> detectSubject({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    final result = await segmentation.detectSubject(
      imageBytes: imageBytes,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    if (result != null && result['usedFallback'] != true) {
      _subjectMaskCache = result;
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>?> detectTextRegions({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    final result = await segmentation.detectTextRegions(
      imageBytes: imageBytes,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    if (result != null) {
      _textMaskCache = result;
    }
    return result;
  }

  @override
  Future<void> dispose() async {
    await segmentation.dispose();
    _subjectMaskCache = null;
    _textMaskCache = null;
  }
}
