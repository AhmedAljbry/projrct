import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;

import '../../domain/entities/clone_entities.dart';

class SegmentationEngine {
  static const double _confidenceThreshold = 0.32;
  static const int _maxSegmentationDimension = 512;

  SubjectSegmenter? _segmenter;

  Future<MaskData?> autoDetectSubject(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return null;

    try {
      _segmenter ??= SubjectSegmenter(
        options: SubjectSegmenterOptions(
          enableForegroundBitmap: false,
          enableForegroundConfidenceMask: true,
          enableMultipleSubjects: SubjectResultOptions(
            enableConfidenceMask: false,
            enableSubjectBitmap: false,
          ),
        ),
      );

      final preparedData = await compute(_isolatePrepareInput, {
        'bytes': imageBytes,
        'width': decoded.width,
        'height': decoded.height,
      });
      if (preparedData == null) {
        return _buildFallbackMask(decoded.width, decoded.height);
      }

      final prepared = _PreparedSegmentationInput(
        bytes: preparedData['bytes'] as Uint8List,
        width: preparedData['width'] as int,
        height: preparedData['height'] as int,
      );

      final inputImage = InputImage.fromBytes(
        bytes: prepared.bytes,
        metadata: InputImageMetadata(
          size: Size(prepared.width.toDouble(), prepared.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: prepared.width,
        ),
      );

      final result = await _segmenter!.processImage(inputImage);
      final mask = _composeMask(
        result: result,
        sourceWidth: prepared.width,
        sourceHeight: prepared.height,
        targetWidth: decoded.width,
        targetHeight: decoded.height,
      );

      if (mask == null) {
        return _buildFallbackMask(decoded.width, decoded.height);
      }

      return _buildMaskData(mask, decoded.width, decoded.height) ??
          _buildFallbackMask(decoded.width, decoded.height);
    } catch (_) {
      return _buildFallbackMask(decoded.width, decoded.height);
    }
  }

  Future<MaskData> refineMask(MaskData mask, {double feather = 0.0}) async {
    return mask;
  }

  List<double>? _composeMask({
    required SubjectSegmentationResult result,
    required int sourceWidth,
    required int sourceHeight,
    required int targetWidth,
    required int targetHeight,
  }) {
    Subject? primary;
    double bestArea = -1;
    for (final subject in result.subjects) {
      final area = subject.width * subject.height;
      if (area > bestArea) {
        bestArea = area.toDouble();
        primary = subject;
      }
    }

    if (primary?.confidenceMask != null &&
        primary!.confidenceMask!.isNotEmpty) {
      final mask = List<double>.filled(targetWidth * targetHeight, 0);
      final scaleX = targetWidth / sourceWidth;
      final scaleY = targetHeight / sourceHeight;
      final mappedWidth = math.max(1, (primary.width * scaleX).round());
      final mappedHeight = math.max(1, (primary.height * scaleY).round());

      for (var y = 0; y < mappedHeight; y++) {
        final targetY = (primary.startY * scaleY).round() + y;
        if (targetY < 0 || targetY >= targetHeight) continue;
        for (var x = 0; x < mappedWidth; x++) {
          final targetX = (primary.startX * scaleX).round() + x;
          if (targetX < 0 || targetX >= targetWidth) continue;

          final sourceX = ((x / mappedWidth) * primary.width)
              .floor()
              .clamp(0, primary.width - 1);
          final sourceY = ((y / mappedHeight) * primary.height)
              .floor()
              .clamp(0, primary.height - 1);

          final maskIndex = sourceY * primary.width + sourceX;
          if (maskIndex < primary.confidenceMask!.length) {
            mask[targetY * targetWidth + targetX] =
                primary.confidenceMask![maskIndex];
          }
        }
      }
      return mask;
    }

    if (result.foregroundConfidenceMask != null &&
        result.foregroundConfidenceMask!.isNotEmpty) {
      return _resizeMask(
        sourceMask: result.foregroundConfidenceMask!,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
    }

    return null;
  }

  List<double> _resizeMask({
    required List<double> sourceMask,
    required int sourceWidth,
    required int sourceHeight,
    required int targetWidth,
    required int targetHeight,
  }) {
    final resized = List<double>.filled(targetWidth * targetHeight, 0);
    for (var y = 0; y < targetHeight; y++) {
      final sourceY = ((y / targetHeight) * sourceHeight)
          .floor()
          .clamp(0, sourceHeight - 1);
      for (var x = 0; x < targetWidth; x++) {
        final sourceX =
            ((x / targetWidth) * sourceWidth).floor().clamp(0, sourceWidth - 1);
        final index = sourceY * sourceWidth + sourceX;
        if (index < sourceMask.length) {
          resized[y * targetWidth + x] = sourceMask[index];
        }
      }
    }
    return resized;
  }

  MaskData? _buildMaskData(List<double> mask, int width, int height) {
    int minX = width;
    int minY = height;
    int maxX = -1;
    int maxY = -1;
    final bytes = Uint8List(width * height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        final confidence = mask[index].clamp(0.0, 1.0);
        final alpha = (confidence * 255).round().clamp(0, 255);
        bytes[index] = alpha;
        if (confidence >= _confidenceThreshold) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      return null;
    }

    return MaskData(
      bytes: bytes,
      width: width,
      height: height,
      bounds: Rect.fromLTRB(
        minX.toDouble(),
        minY.toDouble(),
        (maxX + 1).toDouble(),
        (maxY + 1).toDouble(),
      ),
    );
  }

  MaskData _buildFallbackMask(int width, int height) {
    final bytes = Uint8List(width * height);
    final centerX = width * 0.5;
    final centerY = height * 0.44;
    final radiusX = width * 0.24;
    final radiusY = height * 0.34;

    for (var y = 0; y < height; y++) {
      final dy = (y - centerY) / radiusY;
      for (var x = 0; x < width; x++) {
        final dx = (x - centerX) / radiusX;
        final dist = math.sqrt(dx * dx + dy * dy);
        final value = ((1.0 - dist).clamp(0.0, 1.0) * 255).round();
        bytes[y * width + x] = value;
      }
    }

    return MaskData(
      bytes: bytes,
      width: width,
      height: height,
      bounds: Rect.fromLTWH(
        width * 0.26,
        height * 0.12,
        width * 0.48,
        height * 0.68,
      ),
    );
  }

  Future<void> dispose() async {
    await _segmenter?.close();
    _segmenter = null;
  }
}

class _PreparedSegmentationInput {
  const _PreparedSegmentationInput({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

Map<String, dynamic>? _isolatePrepareInput(Map<String, dynamic> data) {
  final imageBytes = data['bytes'] as Uint8List;
  final imageWidth = data['width'] as int;
  final imageHeight = data['height'] as int;

  if (imageBytes.isEmpty || imageWidth <= 0 || imageHeight <= 0) {
    return null;
  }

  final maxDimension = math.max(imageWidth, imageHeight);
  if (maxDimension <= SegmentationEngine._maxSegmentationDimension) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return null;
    }
    return _encodeToNv21(decoded);
  }

  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) {
    return null;
  }

  final scale = SegmentationEngine._maxSegmentationDimension / maxDimension;
  final targetWidth = math.max(128, (decoded.width * scale).round());
  final targetHeight = math.max(128, (decoded.height * scale).round());

  final resized = img.copyResize(
    decoded,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.linear,
  );

  return _encodeToNv21(resized);
}

Map<String, dynamic> _encodeToNv21(img.Image image) {
  final width = image.width;
  final height = image.height;
  final nv21Bytes = Uint8List((width * height * 1.5).ceil());
  var yIndex = 0;
  var uvIndex = width * height;

  for (var j = 0; j < height; j++) {
    for (var i = 0; i < width; i++) {
      final p = image.getPixel(i, j);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();

      final yy = ((66 * r + 129 * g + 25 * b + 128) >> 8) + 16;
      final u = ((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128;
      final v = ((112 * r - 94 * g - 18 * b + 128) >> 8) + 128;

      nv21Bytes[yIndex++] = yy.clamp(0, 255);
      if (j.isEven && i.isEven) {
        nv21Bytes[uvIndex++] = v.clamp(0, 255);
        nv21Bytes[uvIndex++] = u.clamp(0, 255);
      }
    }
  }

  return {
    'bytes': nv21Bytes,
    'width': width,
    'height': height,
  };
}
