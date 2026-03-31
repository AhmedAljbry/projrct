import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:untitled2/features/ai_object_clone_studio/engine/segmentation/segmentation_engine.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/repositories/retouch_mask_assist_repository.dart';

class RetouchMaskAssistRepositoryImpl implements RetouchMaskAssistRepository {
  RetouchMaskAssistRepositoryImpl({SegmentationEngine? segmentationEngine})
      : _segmentationEngine = segmentationEngine ?? SegmentationEngine();

  final SegmentationEngine _segmentationEngine;

  @override
  Future<MaskSuggestionResult> generateSuggestion(
    MaskSuggestionRequest request,
  ) async {
    final maskData = await _segmentationEngine.autoDetectSubject(
      request.imageBytes,
    );
    if (maskData == null) {
      final decoded = img.decodeImage(request.imageBytes);
      final width = decoded?.width ?? 512;
      final height = decoded?.height ?? 512;
      final fallback = await compute(_buildFallbackAlphaMask, {
        'width': width,
        'height': height,
      });
      return MaskSuggestionResult(
        alphaMask: fallback,
        width: width,
        height: height,
        source: MaskSuggestionSource.fallbackHeuristic,
      );
    }

    return MaskSuggestionResult(
      alphaMask: maskData.bytes,
      width: maskData.width,
      height: maskData.height,
      source: MaskSuggestionSource.mlKitSubjectSegmentation,
    );
  }

  @override
  Future<Uint8List> buildPreviewPng({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required double feather,
  }) {
    return compute(_buildPreviewPngTask, {
      'alphaMask': alphaMask,
      'width': width,
      'height': height,
      'feather': feather,
    });
  }

  @override
  Future<Uint8List> applyBrushStroke({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required List<Offset> imagePoints,
    required double brushRadius,
    required MaskEditMode editMode,
  }) {
    return compute(_applyBrushStrokeTask, {
      'alphaMask': alphaMask,
      'width': width,
      'height': height,
      'points':
          imagePoints.map((point) => <double>[point.dx, point.dy]).toList(),
      'brushRadius': brushRadius,
      'editMode': editMode.name,
    });
  }

  @override
  Future<Uint8List> transformMask({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required MaskTransformAction action,
    int radius = 4,
  }) {
    return compute(_transformMaskTask, {
      'alphaMask': alphaMask,
      'width': width,
      'height': height,
      'action': action.name,
      'radius': radius,
    });
  }

  @override
  Future<Uint8List> exportBinaryMaskPng({
    required Uint8List alphaMask,
    required int width,
    required int height,
    required double feather,
  }) {
    return compute(_exportBinaryMaskTask, {
      'alphaMask': alphaMask,
      'width': width,
      'height': height,
      'feather': feather,
    });
  }

  @override
  Future<void> dispose() => _segmentationEngine.dispose();
}

Uint8List _buildFallbackAlphaMask(Map<String, dynamic> args) {
  final width = args['width'] as int;
  final height = args['height'] as int;
  final bytes = Uint8List(width * height);
  final centerX = width * 0.5;
  final centerY = height * 0.48;
  final radiusX = width * 0.22;
  final radiusY = height * 0.3;

  for (var y = 0; y < height; y++) {
    final dy = (y - centerY) / radiusY;
    for (var x = 0; x < width; x++) {
      final dx = (x - centerX) / radiusX;
      final distance = math.sqrt((dx * dx) + (dy * dy));
      final value = ((1 - distance).clamp(0.0, 1.0) * 255).round();
      bytes[(y * width) + x] = value;
    }
  }
  return bytes;
}

Uint8List _buildPreviewPngTask(Map<String, dynamic> args) {
  final alphaMask = Uint8List.fromList(args['alphaMask'] as Uint8List);
  final width = args['width'] as int;
  final height = args['height'] as int;
  final feather = (args['feather'] as num).toDouble();
  final image = img.Image(width: width, height: height, numChannels: 4);

  final processedAlpha = feather > 0
      ? _blurAlphaMask(alphaMask, width, height, feather.round().clamp(1, 12))
      : alphaMask;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = processedAlpha[(y * width) + x];
      image.setPixelRgba(x, y, 255, 104, 84, alpha.clamp(0, 190));
    }
  }

  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _applyBrushStrokeTask(Map<String, dynamic> args) {
  final alphaMask = Uint8List.fromList(args['alphaMask'] as Uint8List);
  final width = args['width'] as int;
  final height = args['height'] as int;
  final points = (args['points'] as List)
      .map((item) => Offset((item as List)[0] as double, item[1] as double))
      .toList();
  final brushRadius = (args['brushRadius'] as num).toDouble();
  final editMode = args['editMode'] as String;

  for (final point in points) {
    _paintCircle(
      alphaMask,
      width,
      height,
      point,
      brushRadius,
      editMode == MaskEditMode.add.name,
    );
  }

  return alphaMask;
}

void _paintCircle(
  Uint8List mask,
  int width,
  int height,
  Offset center,
  double radius,
  bool addMode,
) {
  final r = radius.ceil();
  final left = (center.dx - r).floor().clamp(0, width - 1);
  final right = (center.dx + r).ceil().clamp(0, width - 1);
  final top = (center.dy - r).floor().clamp(0, height - 1);
  final bottom = (center.dy + r).ceil().clamp(0, height - 1);
  final radiusSq = radius * radius;

  for (var y = top; y <= bottom; y++) {
    for (var x = left; x <= right; x++) {
      final dx = x - center.dx;
      final dy = y - center.dy;
      if ((dx * dx) + (dy * dy) <= radiusSq) {
        mask[(y * width) + x] = addMode ? 255 : 0;
      }
    }
  }
}

Uint8List _transformMaskTask(Map<String, dynamic> args) {
  final alphaMask = Uint8List.fromList(args['alphaMask'] as Uint8List);
  final width = args['width'] as int;
  final height = args['height'] as int;
  final action = args['action'] as String;
  final radius = args['radius'] as int;

  if (action == MaskTransformAction.clear.name) {
    return Uint8List(width * height);
  }

  var source = alphaMask;
  for (var i = 0; i < math.max(1, radius ~/ 2); i++) {
    source = action == MaskTransformAction.expand.name
        ? _dilate(source, width, height)
        : _erode(source, width, height);
  }
  return source;
}

Uint8List _dilate(Uint8List source, int width, int height) {
  final result = Uint8List.fromList(source);
  for (var y = 1; y < height - 1; y++) {
    for (var x = 1; x < width - 1; x++) {
      final index = (y * width) + x;
      var maxValue = source[index];
      for (var ky = -1; ky <= 1; ky++) {
        for (var kx = -1; kx <= 1; kx++) {
          final neighbor = source[((y + ky) * width) + (x + kx)];
          if (neighbor > maxValue) {
            maxValue = neighbor;
          }
        }
      }
      result[index] = maxValue;
    }
  }
  return result;
}

Uint8List _erode(Uint8List source, int width, int height) {
  final result = Uint8List.fromList(source);
  for (var y = 1; y < height - 1; y++) {
    for (var x = 1; x < width - 1; x++) {
      final index = (y * width) + x;
      var minValue = source[index];
      for (var ky = -1; ky <= 1; ky++) {
        for (var kx = -1; kx <= 1; kx++) {
          final neighbor = source[((y + ky) * width) + (x + kx)];
          if (neighbor < minValue) {
            minValue = neighbor;
          }
        }
      }
      result[index] = minValue;
    }
  }
  return result;
}

Uint8List _blurAlphaMask(
    Uint8List alphaMask, int width, int height, int radius) {
  final image = img.Image(width: width, height: height, numChannels: 1);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = alphaMask[(y * width) + x];
      image.setPixelRgba(x, y, alpha, alpha, alpha, 255);
    }
  }
  final blurred = img.gaussianBlur(image, radius: radius);
  final result = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      result[(y * width) + x] = blurred.getPixel(x, y).r.toInt().clamp(0, 255);
    }
  }
  return result;
}

Uint8List _exportBinaryMaskTask(Map<String, dynamic> args) {
  final alphaMask = Uint8List.fromList(args['alphaMask'] as Uint8List);
  final width = args['width'] as int;
  final height = args['height'] as int;
  final feather = (args['feather'] as num).toDouble();
  final processedAlpha = feather > 0
      ? _blurAlphaMask(alphaMask, width, height, feather.round().clamp(1, 12))
      : alphaMask;
  final image = img.Image(width: width, height: height, numChannels: 4);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = processedAlpha[(y * width) + x] >= 56 ? 255 : 0;
      image.setPixelRgba(x, y, alpha, alpha, alpha, 255);
    }
  }

  return Uint8List.fromList(img.encodePng(image));
}
