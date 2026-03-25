import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;

import '../../domain/models/af_focus_geometry.dart';
import '../../domain/models/af_mask_data.dart';
import '../../domain/services/af_segmentation_engine.dart';

class _PreparedInput {
  const _PreparedInput({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

class AfMlKitSegmentationEngine implements AfSegmentationEngine {
  AfMlKitSegmentationEngine() {
    _segmenter = SubjectSegmenter(
      options: SubjectSegmenterOptions(
        enableForegroundBitmap: true,
        enableForegroundConfidenceMask: true,
        enableMultipleSubjects: SubjectResultOptions(
          enableConfidenceMask: false,
          enableSubjectBitmap: false,
        ),
      ),
    );
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );
  }

  static const int _maxSegmentationDimension = 512;

  late final SubjectSegmenter _segmenter;
  late final FaceDetector _faceDetector;

  @override
  Future<AfMaskData> detectSubject({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    if (imageBytes.isEmpty || imageWidth <= 0 || imageHeight <= 0) {
      return AfMaskData(
        width: imageWidth,
        height: imageHeight,
        confidenceMask: const [],
        usedFallback: true,
      );
    }

    final preparedData = await compute(_isolatePrepareInput, {
      'bytes': imageBytes,
      'width': imageWidth,
      'height': imageHeight,
    });

    if (preparedData == null) {
      return AfMaskData(
        width: imageWidth,
        height: imageHeight,
        confidenceMask: const [],
        usedFallback: true,
      );
    }
    
    final prepared = _PreparedInput(
      bytes: preparedData['bytes'] as Uint8List,
      width: preparedData['width'] as int,
      height: preparedData['height'] as int,
    );

    if (prepared == null) {
      return AfMaskData(
        width: imageWidth,
        height: imageHeight,
        confidenceMask: const [],
        usedFallback: true,
      );
    }

    try {
      final inputImage = InputImage.fromBytes(
        bytes: prepared.bytes,
        metadata: InputImageMetadata(
          size: Size(prepared.width.toDouble(), prepared.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: prepared.width,
        ),
      );
      final results = await Future.wait([
        _segmenter.processImage(inputImage),
        _faceDetector.processImage(inputImage),
      ]);

      final segmentation = results[0] as SubjectSegmentationResult;
      final faces = results[1] as List<Face>;
      final faceBounds = faces.map((face) {
        return AfSegmentationBounds(
          left: (face.boundingBox.left / prepared.width).clamp(0.0, 1.0),
          top: (face.boundingBox.top / prepared.height).clamp(0.0, 1.0),
          width: (face.boundingBox.width / prepared.width).clamp(0.0, 1.0),
          height: (face.boundingBox.height / prepared.height).clamp(0.0, 1.0),
        );
      }).toList();

      final mask = _extractBestMask(segmentation, prepared.width, prepared.height);
      if (mask == null || mask.isEmpty) {
        return AfMaskData(
          width: imageWidth,
          height: imageHeight,
          confidenceMask: const [],
          faceBounds: faceBounds,
          usedFallback: true,
        );
      }
      
      final normalizedMask = _resizeMask(
         sourceMask: mask,
         sourceWidth: prepared.width,
         sourceHeight: prepared.height,
         targetWidth: imageWidth,
         targetHeight: imageHeight,
      );

      return AfMaskData(
        width: imageWidth,
        height: imageHeight,
        confidenceMask: normalizedMask,
        primaryBounds: _findPrimaryBounds(normalizedMask, imageWidth, imageHeight),
        faceBounds: faceBounds,
        usedFallback: false,
      );
    } catch (_) {
      return AfMaskData(
        width: imageWidth,
        height: imageHeight,
        confidenceMask: const [],
        usedFallback: true,
      );
    }
  }

// Removed old method. Use top-level _isolatePrepareInput.
  
  List<double> _resizeMask({
    required List<double> sourceMask,
    required int sourceWidth,
    required int sourceHeight,
    required int targetWidth,
    required int targetHeight,
  }) {
    if (sourceWidth == targetWidth && sourceHeight == targetHeight) {
      return sourceMask;
    }
    final resized = List<double>.filled(targetWidth * targetHeight, 0);
    for (var y = 0; y < targetHeight; y++) {
      final sourceY = ((y / targetHeight) * sourceHeight).floor().clamp(0, sourceHeight - 1);
      for (var x = 0; x < targetWidth; x++) {
        final sourceX = ((x / targetWidth) * sourceWidth).floor().clamp(0, sourceWidth - 1);
        final index = sourceY * sourceWidth + sourceX;
        if (index < sourceMask.length) {
          resized[y * targetWidth + x] = sourceMask[index];
        }
      }
    }
    return resized;
  }

  List<double>? _extractBestMask(
    SubjectSegmentationResult result,
    int imageWidth,
    int imageHeight,
  ) {
    Subject? subject;
    var bestArea = 0.0;
    for (final candidate in result.subjects) {
      final area = candidate.width * candidate.height;
      if (candidate.confidenceMask == null || area <= 0) {
        continue;
      }
      if (area > bestArea) {
        bestArea = area.toDouble();
        subject = candidate;
      }
    }

    if (subject != null && subject.confidenceMask != null) {
      final fullMask = List<double>.filled(imageWidth * imageHeight, 0.0);
      final sw = subject.width;
      final sh = subject.height;
      final sx = subject.startX;
      final sy = subject.startY;
      for (var y = 0; y < sh; y++) {
        for (var x = 0; x < sw; x++) {
          final tx = sx + x;
          final ty = sy + y;
          if (tx < 0 || ty < 0 || tx >= imageWidth || ty >= imageHeight) {
            continue;
          }
          fullMask[ty * imageWidth + tx] =
              subject.confidenceMask![y * sw + x].toDouble();
        }
      }
      return fullMask;
    }

    final foregroundMask = result.foregroundConfidenceMask;
    if (foregroundMask == null || foregroundMask.isEmpty) {
      return null;
    }
    if (foregroundMask.length != imageWidth * imageHeight) {
      return null;
    }
    return foregroundMask.map((value) => value.toDouble()).toList();
  }

  AfSegmentationBounds? _findPrimaryBounds(
      List<double> mask, int width, int height) {
    var minX = width;
    var minY = height;
    var maxX = -1;
    var maxY = -1;

    final step = math.max(1, math.sqrt(mask.length / 800).floor());
    for (var y = 0; y < height; y += step) {
      for (var x = 0; x < width; x += step) {
        final value = mask[y * width + x];
        if (value < 0.35) {
          continue;
        }
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    if (maxX <= minX || maxY <= minY) {
      return null;
    }

    final padX = ((maxX - minX) * 0.06).round();
    final padY = ((maxY - minY) * 0.06).round();
    final left = (minX - padX).clamp(0, width - 1);
    final top = (minY - padY).clamp(0, height - 1);
    final right = (maxX + padX).clamp(0, width - 1);
    final bottom = (maxY + padY).clamp(0, height - 1);

    return AfSegmentationBounds(
      left: left / width,
      top: top / height,
      width: (right - left) / width,
      height: (bottom - top) / height,
    );
  }

  @override
  Future<void> dispose() async {
    await _segmenter.close();
    await _faceDetector.close();
  }
}

Map<String, dynamic>? _isolatePrepareInput(Map<String, dynamic> data) {
  final imageBytes = data['bytes'] as Uint8List;
  final imageWidth = data['width'] as int;
  final imageHeight = data['height'] as int;

  if (imageBytes.isEmpty || imageWidth <= 0 || imageHeight <= 0) {
    return null;
  }

  final maxDimension = math.max(imageWidth, imageHeight);
  if (maxDimension <= 512) {
    return {'bytes': imageBytes, 'width': imageWidth, 'height': imageHeight};
  }

  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) {
    return null;
  }

  final scale = 512 / maxDimension;
  final targetWidth = math.max(128, (decoded.width * scale).round());
  final targetHeight = math.max(128, (decoded.height * scale).round());

  final resized = img.copyResize(
    decoded,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.linear,
  );

  final nv21Bytes = Uint8List((targetWidth * targetHeight * 1.5).ceil());
  int yIndex = 0;
  int uvIndex = targetWidth * targetHeight;
  for (var j = 0; j < targetHeight; j++) {
    for (var i = 0; i < targetWidth; i++) {
      final p = resized.getPixel(i, j);
      int r = p.r.toInt();
      int g = p.g.toInt();
      int b = p.b.toInt();

      int yy = ((66 * r + 129 * g + 25 * b + 128) >> 8) + 16;
      int u = ((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128;
      int v = ((112 * r - 94 * g - 18 * b + 128) >> 8) + 128;

      nv21Bytes[yIndex++] = yy.clamp(0, 255);
      if (j % 2 == 0 && i % 2 == 0) {
        nv21Bytes[uvIndex++] = v.clamp(0, 255);
        nv21Bytes[uvIndex++] = u.clamp(0, 255);
      }
    }
  }

  return {
    'bytes': nv21Bytes,
    'width': targetWidth,
    'height': targetHeight,
  };
}
