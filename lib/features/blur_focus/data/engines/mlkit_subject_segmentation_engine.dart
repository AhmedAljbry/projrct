import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:untitled2/features/blur_focus/data/engines/subject_segmentation_engine.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';

class MlKitSubjectSegmentationEngine implements SubjectSegmentationEngine {
  static const int _maxSegmentationDimension = 512;

  SubjectSegmenter? _segmenter;
  FaceDetector? _faceDetector;

  @override
  Future<SegmentationResultData> detectSubject({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return _buildFallbackMask(imageWidth: imageWidth, imageHeight: imageHeight);
    }

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
      _faceDetector ??= FaceDetector(
        options: FaceDetectorOptions(
          enableTracking: false,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      final preparedData = await compute(_isolatePrepareInput, {
        'bytes': imageBytes,
        'width': imageWidth,
        'height': imageHeight,
      });

      if (preparedData == null) {
         return _buildFallbackMask(imageWidth: imageWidth, imageHeight: imageHeight);
      }

      final prepared = _PreparedSegmentationInput(
        bytes: preparedData['bytes'] as Uint8List,
        width: preparedData['width'] as int,
        height: preparedData['height'] as int,
      );

      if (prepared == null) {
         return _buildFallbackMask(imageWidth: imageWidth, imageHeight: imageHeight);
      }

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
      final faces = await _faceDetector!.processImage(inputImage);

      final subjectMask = _composeBestMask(
        result: result,
        faces: faces,
        sourceWidth: prepared.width,
        sourceHeight: prepared.height,
        targetWidth: imageWidth,
        targetHeight: imageHeight,
      );
      if (subjectMask == null) {
        return _buildFallbackMask(imageWidth: imageWidth, imageHeight: imageHeight);
      }
      return subjectMask;
    } catch (_) {
      return _buildFallbackMask(imageWidth: imageWidth, imageHeight: imageHeight);
    }
  }

// Removed old method. Use top-level _isolatePrepareInput below.

  SegmentationResultData? _composeBestMask({
    required SubjectSegmentationResult result,
    required List<Face> faces,
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

    if (primary?.confidenceMask != null && primary!.confidenceMask!.isNotEmpty) {
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
          
          final sourceX = ((x / mappedWidth) * primary.width).floor().clamp(0, primary.width - 1);
          final sourceY = ((y / mappedHeight) * primary.height).floor().clamp(0, primary.height - 1);
          
          final maskIndex = sourceY * primary.width + sourceX;
          if (maskIndex < primary.confidenceMask!.length) {
            mask[targetY * targetWidth + targetX] = primary.confidenceMask![maskIndex];
          }
        }
      }
      
      final faceBounds = faces.map((face) => SegmentationBounds(
        left: (face.boundingBox.left / sourceWidth).clamp(0.0, 1.0),
        top: (face.boundingBox.top / sourceHeight).clamp(0.0, 1.0),
        width: (face.boundingBox.width / sourceWidth).clamp(0.0, 1.0),
        height: (face.boundingBox.height / sourceHeight).clamp(0.0, 1.0),
      )).toList();

      return SegmentationResultData(
        width: targetWidth,
        height: targetHeight,
        confidenceMask: mask,
        primaryBounds: SegmentationBounds(
          left: (primary.startX / sourceWidth).clamp(0.0, 1.0),
          top: (primary.startY / sourceHeight).clamp(0.0, 1.0),
          width: (primary.width / sourceWidth).clamp(0.0, 1.0),
          height: (primary.height / sourceHeight).clamp(0.0, 1.0),
        ),
        faceBounds: faceBounds,
        createdAt: DateTime.now(),
      );
    }

    if (result.foregroundConfidenceMask != null && result.foregroundConfidenceMask!.isNotEmpty) {
      final normalized = _resizeMask(
        sourceMask: result.foregroundConfidenceMask!,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      
       final faceBounds = faces.map((face) => SegmentationBounds(
        left: (face.boundingBox.left / sourceWidth).clamp(0.0, 1.0),
        top: (face.boundingBox.top / sourceHeight).clamp(0.0, 1.0),
        width: (face.boundingBox.width / sourceWidth).clamp(0.0, 1.0),
        height: (face.boundingBox.height / sourceHeight).clamp(0.0, 1.0),
      )).toList();

      return SegmentationResultData(
        width: targetWidth,
        height: targetHeight,
        confidenceMask: normalized,
        primaryBounds: const SegmentationBounds(left: 0.22, top: 0.1, width: 0.56, height: 0.78),
        faceBounds: faceBounds,
        createdAt: DateTime.now(),
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

  SegmentationResultData _buildFallbackMask({
    required int imageWidth,
    required int imageHeight,
  }) {
    final mask = List<double>.filled(imageWidth * imageHeight, 0);
    const centerX = 0.5;
    const centerY = 0.42;
    const radiusX = 0.26;
    const radiusY = 0.34;
    for (var y = 0; y < imageHeight; y++) {
      final dy = ((y / imageHeight) - centerY) / radiusY;
      for (var x = 0; x < imageWidth; x++) {
        final dx = ((x / imageWidth) - centerX) / radiusX;
        final dist = math.sqrt(dx * dx + dy * dy);
        final value = (1 - (dist - 0.65).clamp(0.0, 1.0)).clamp(0.0, 1.0);
        mask[y * imageWidth + x] = value * value;
      }
    }
    return SegmentationResultData(
      width: imageWidth,
      height: imageHeight,
      confidenceMask: const [],
      primaryBounds: null, // Allow UI to know no subject was found
      usedFallback: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> dispose() async {
    await _segmenter?.close();
    await _faceDetector?.close();
    _segmenter = null;
    _faceDetector = null;
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
