import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

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

/// Wraps the Google ML Kit subject segmentation SDK for the Blur Photo feature.
/// Uses file-based [InputImage] matching the existing working implementation.
class BpSegmentationDatasource {
  static const int _maxSegmentationDimension = 512;

  SubjectSegmenter? _segmenter;
  TextRecognizer? _textRecognizer;
  Map<String, dynamic>? _cachedResult;
  int? _cachedHash;
  Map<String, dynamic>? _cachedTextResult;
  int? _cachedTextHash;

  Future<Map<String, dynamic>?> detectSubject({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    if (imageBytes.isEmpty || imageWidth <= 0 || imageHeight <= 0) {
      return _fallback();
    }

    // Simple identity cache — avoids rerunning on same image.
    final hash = Object.hashAll([imageWidth, imageHeight, imageBytes.length]);
    if (_cachedHash == hash && _cachedResult != null) return _cachedResult;

    final prepared = _prepareInput(
      imageBytes: imageBytes,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );

    if (prepared == null) {
      return _fallback();
    }

    final uniqueId = DateTime.now().microsecondsSinceEpoch;
    final tempFile = File(
      '${Directory.systemTemp.path}/bp_seg_$uniqueId.png',
    );
    await tempFile.writeAsBytes(prepared.bytes, flush: true);

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

      final inputImage = InputImage.fromFile(tempFile);
      final result = await _segmenter!.processImage(inputImage);

      // Try to obtain the foreground confidence mask.
      final mask = _extractMask(result, prepared.width, prepared.height);
      if (mask == null || mask.isEmpty) return _fallback();

      final normalizedMask = _resizeMask(
        sourceMask: mask,
        sourceWidth: prepared.width,
        sourceHeight: prepared.height,
        targetWidth: imageWidth,
        targetHeight: imageHeight,
      );

      _cachedHash = hash;
      _cachedResult = {
        'confidenceMask': normalizedMask,
        'width': imageWidth,
        'height': imageHeight,
        'usedFallback': false,
      };
      return _cachedResult;
    } catch (_) {
      return _fallback();
    } finally {
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>?> detectTextRegions({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    if (imageBytes.isEmpty || imageWidth <= 0 || imageHeight <= 0) {
      return _emptyTextResult(imageWidth, imageHeight);
    }

    final hash = Object.hashAll([
      imageWidth,
      imageHeight,
      imageBytes.length,
      'text',
    ]);
    if (_cachedTextHash == hash && _cachedTextResult != null) {
      return _cachedTextResult;
    }

    final prepared = _prepareInput(
      imageBytes: imageBytes,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    if (prepared == null) {
      return _emptyTextResult(imageWidth, imageHeight);
    }

    final uniqueId = DateTime.now().microsecondsSinceEpoch;
    final tempFile = File('${Directory.systemTemp.path}/bp_txt_$uniqueId.png');
    await tempFile.writeAsBytes(prepared.bytes, flush: true);

    try {
      _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFile(tempFile);
      final result = await _textRecognizer!.processImage(inputImage);
      final regions = <Map<String, double>>[];

      for (final block in result.blocks) {
        final rect = block.boundingBox;
        final widthScale = imageWidth / prepared.width;
        final heightScale = imageHeight / prepared.height;
        final left = (rect.left * widthScale).clamp(0.0, imageWidth.toDouble());
        final top = (rect.top * heightScale).clamp(0.0, imageHeight.toDouble());
        final right =
            (rect.right * widthScale).clamp(left, imageWidth.toDouble());
        final bottom =
            (rect.bottom * heightScale).clamp(top, imageHeight.toDouble());
        if ((right - left) < 6 || (bottom - top) < 6) {
          continue;
        }
        regions.add({
          'left': left,
          'top': top,
          'right': right,
          'bottom': bottom,
        });
      }

      _cachedTextHash = hash;
      _cachedTextResult = {
        'regions': regions,
        'width': imageWidth,
        'height': imageHeight,
      };
      return _cachedTextResult;
    } catch (_) {
      return _emptyTextResult(imageWidth, imageHeight);
    } finally {
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  _PreparedInput? _prepareInput({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) {
    final maxDimension = math.max(imageWidth, imageHeight);
    if (maxDimension <= _maxSegmentationDimension) {
      return _PreparedInput(bytes: imageBytes, width: imageWidth, height: imageHeight);
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return null;
    }

    final scale = _maxSegmentationDimension / maxDimension;
    final targetWidth = math.max(128, (decoded.width * scale).round());
    final targetHeight = math.max(128, (decoded.height * scale).round());
    
    final resized = img.copyResize(
      decoded,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );

    final jpegBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));

    return _PreparedInput(
      bytes: jpegBytes,
      width: targetWidth,
      height: targetHeight,
    );
  }
  
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

  List<double>? _extractMask(
    SubjectSegmentationResult result,
    int imageWidth,
    int imageHeight,
  ) {
    // Prefer per-subject mask for the largest detected subject.
    Subject? best;
    var bestArea = 0;
    for (final s in result.subjects) {
      final area = s.width * s.height;
      if (s.confidenceMask != null && area > bestArea) {
        bestArea = area;
        best = s;
      }
    }

    if (best != null && best.confidenceMask != null) {
      final fullMask = List<double>.filled(imageWidth * imageHeight, 0.0);
      final sw = best.width;
      final sh = best.height;
      final sx = best.startX;
      final sy = best.startY;
      for (var y = 0; y < sh; y++) {
        for (var x = 0; x < sw; x++) {
          final tx = sx + x;
          final ty = sy + y;
          if (tx < 0 || ty < 0 || tx >= imageWidth || ty >= imageHeight) {
            continue;
          }
          fullMask[ty * imageWidth + tx] =
              best.confidenceMask![y * sw + x].toDouble();
        }
      }
      return fullMask;
    }

    // Fallback: use foreground confidence mask.
    final fg = result.foregroundConfidenceMask;
    if (fg != null && fg.length == imageWidth * imageHeight) {
      return fg.map((v) => v.toDouble()).toList();
    }
    return null;
  }

  Map<String, dynamic> _fallback() => {
        'confidenceMask': <double>[],
        'width': 0,
        'height': 0,
        'usedFallback': true,
      };

  Map<String, dynamic> _emptyTextResult(int width, int height) => {
        'regions': const <Map<String, double>>[],
        'width': width,
        'height': height,
      };

  Future<void> dispose() async {
    await _segmenter?.close();
    await _textRecognizer?.close();
    _segmenter = null;
    _textRecognizer = null;
    _cachedResult = null;
    _cachedHash = null;
    _cachedTextResult = null;
    _cachedTextHash = null;
  }
}
