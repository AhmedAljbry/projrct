import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;

import '../domain/entities/editor_models.dart';

abstract class SegmentationAdapter {
  Future<SelectionRegion> buildSmartSelection(
    EditorDocument document, {
    ui.Offset? focusPoint,
  });

  Future<SelectionRegion> buildPersonSelection(
    EditorDocument document, {
    ui.Offset? focusPoint,
  });

  Future<void> dispose();
}

class HybridSegmentationAdapter implements SegmentationAdapter {
  HybridSegmentationAdapter({
    MlKitSegmentationAdapter? mlKit,
    HeuristicSegmentationAdapter? fallback,
  })  : _mlKit = mlKit ?? MlKitSegmentationAdapter(),
        _fallback = fallback ?? HeuristicSegmentationAdapter();

  final MlKitSegmentationAdapter _mlKit;
  final HeuristicSegmentationAdapter _fallback;

  @override
  Future<SelectionRegion> buildSmartSelection(
    EditorDocument document, {
    ui.Offset? focusPoint,
  }) async {
    try {
      final selection = await _mlKit.buildSmartSelection(
        document,
        focusPoint: focusPoint,
      );
      if (_isUsefulSelection(selection, document)) {
        return selection;
      }
    } catch (_) {}
    return _fallback.buildSmartSelection(document, focusPoint: focusPoint);
  }

  @override
  Future<SelectionRegion> buildPersonSelection(
    EditorDocument document, {
    ui.Offset? focusPoint,
  }) async {
    try {
      final selection = await _mlKit.buildPersonSelection(
        document,
        focusPoint: focusPoint,
      );
      if (_isUsefulSelection(selection, document)) {
        return selection;
      }
    } catch (_) {}
    return _fallback.buildPersonSelection(document, focusPoint: focusPoint);
  }

  bool _isUsefulSelection(SelectionRegion selection, EditorDocument document) {
    final bounds = selection.bounds;
    if (bounds.width < 8 || bounds.height < 8) {
      return false;
    }
    final coverage =
        (bounds.width * bounds.height) / (document.width * document.height);
    return coverage > 0.0006;
  }

  @override
  Future<void> dispose() async {
    await _mlKit.dispose();
    await _fallback.dispose();
  }
}

class MlKitSegmentationAdapter implements SegmentationAdapter {
  static const int maxSegmentationDimension = 512;
  static const double _subjectThreshold = 0.34;
  static const double _personThreshold = 0.42;

  SubjectSegmenter? _subjectSegmenter;
  SelfieSegmenter? _selfieSegmenter;
  FaceDetector? _faceDetector;

  @override
  Future<SelectionRegion> buildSmartSelection(
    EditorDocument document, {
    ui.Offset? focusPoint,
  }) async {
    if (!_supportsMlKit) {
      throw StateError('ML Kit smart selection is unavailable on this platform.');
    }

    _subjectSegmenter ??= SubjectSegmenter(
      options: SubjectSegmenterOptions(
        enableForegroundBitmap: false,
        enableForegroundConfidenceMask: true,
        enableMultipleSubjects: SubjectResultOptions(
          enableConfidenceMask: true,
          enableSubjectBitmap: false,
        ),
      ),
    );

    final prepared = await _prepareInput(document);
    final inputImage = _inputImageFromPrepared(prepared);
    final result = await _subjectSegmenter!.processImage(inputImage);

    final mask = _composeSubjectMask(
      result: result,
      sourceWidth: prepared.width,
      sourceHeight: prepared.height,
      targetWidth: document.width,
      targetHeight: document.height,
    );
    if (mask == null) {
      throw StateError('No smart subject mask available.');
    }

    final filtered = _selectFocusedComponent(
      alpha: _confidenceToAlpha(mask, threshold: _subjectThreshold),
      width: document.width,
      height: document.height,
      focusPoint: focusPoint,
      allowNearCenterFallback: true,
    );
    if (filtered == null) {
      throw StateError('No smart subject component found.');
    }

    return _selectionFromAlpha(
      document: document,
      fullAlpha: _softenAlpha(filtered.alpha, filtered.width, filtered.height),
      minX: filtered.minX,
      minY: filtered.minY,
      maxX: filtered.maxX,
      maxY: filtered.maxY,
      feather: 10,
      paddingScale: 0.06,
      topPaddingScale: 0.08,
    );
  }

  @override
  Future<SelectionRegion> buildPersonSelection(
    EditorDocument document, {
    ui.Offset? focusPoint,
  }) async {
    if (!_supportsMlKit) {
      throw StateError('ML Kit people selection is unavailable on this platform.');
    }

    _selfieSegmenter ??= SelfieSegmenter(mode: SegmenterMode.single);
    _faceDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableTracking: false,
      ),
    );

    final prepared = await _prepareInput(document);
    final inputImage = _inputImageFromPrepared(prepared);
    final results = await Future.wait([
      _selfieSegmenter!.processImage(inputImage),
      _faceDetector!.processImage(inputImage),
    ]);

    final segmentationMask = results[0] as SegmentationMask;
    final faces = results[1] as List<Face>;
    final resizedMask = _resizeMask(
      sourceMask: segmentationMask.confidences,
      sourceWidth: segmentationMask.width,
      sourceHeight: segmentationMask.height,
      targetWidth: document.width,
      targetHeight: document.height,
    );

    final filtered = _selectFocusedComponent(
      alpha: _confidenceToAlpha(resizedMask, threshold: _personThreshold),
      width: document.width,
      height: document.height,
      focusPoint: _resolvePersonFocusPoint(
        focusPoint: focusPoint,
        faces: faces,
        preparedWidth: prepared.width,
        preparedHeight: prepared.height,
        targetWidth: document.width,
        targetHeight: document.height,
      ),
      allowNearCenterFallback: true,
    );
    if (filtered == null) {
      throw StateError('No people component found.');
    }

    return _selectionFromAlpha(
      document: document,
      fullAlpha: _softenAlpha(filtered.alpha, filtered.width, filtered.height),
      minX: filtered.minX,
      minY: filtered.minY,
      maxX: filtered.maxX,
      maxY: filtered.maxY,
      feather: 10,
      paddingScale: 0.08,
      topPaddingScale: 0.12,
    );
  }

  bool get _supportsMlKit =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<_PreparedSegmentationInput> _prepareInput(
    EditorDocument document,
  ) async {
    final preparedData = await compute(_prepareSegmentationInput, {
      'bytes': document.bytes,
      'width': document.width,
      'height': document.height,
    });
    if (preparedData == null) {
      throw StateError('Unable to prepare ML Kit input.');
    }
    return _PreparedSegmentationInput(
      bytes: preparedData['bytes'] as Uint8List,
      width: preparedData['width'] as int,
      height: preparedData['height'] as int,
    );
  }

  InputImage _inputImageFromPrepared(_PreparedSegmentationInput prepared) {
    return InputImage.fromBytes(
      bytes: prepared.bytes,
      metadata: InputImageMetadata(
        size: ui.Size(prepared.width.toDouble(), prepared.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: prepared.width,
      ),
    );
  }

  List<double>? _composeSubjectMask({
    required SubjectSegmentationResult result,
    required int sourceWidth,
    required int sourceHeight,
    required int targetWidth,
    required int targetHeight,
  }) {
    final candidates = <List<double>>[];
    for (final subject in result.subjects) {
      final confidenceMask = subject.confidenceMask;
      if (confidenceMask == null || confidenceMask.isEmpty) {
        continue;
      }
      final fullMask = List<double>.filled(targetWidth * targetHeight, 0);
      final scaleX = targetWidth / sourceWidth;
      final scaleY = targetHeight / sourceHeight;
      final mappedWidth = math.max(1, (subject.width * scaleX).round());
      final mappedHeight = math.max(1, (subject.height * scaleY).round());
      for (var y = 0; y < mappedHeight; y++) {
        final targetY = (subject.startY * scaleY).round() + y;
        if (targetY < 0 || targetY >= targetHeight) {
          continue;
        }
        for (var x = 0; x < mappedWidth; x++) {
          final targetX = (subject.startX * scaleX).round() + x;
          if (targetX < 0 || targetX >= targetWidth) {
            continue;
          }
          final sourceX = ((x / mappedWidth) * subject.width)
              .floor()
              .clamp(0, subject.width - 1);
          final sourceY = ((y / mappedHeight) * subject.height)
              .floor()
              .clamp(0, subject.height - 1);
          final maskIndex = sourceY * subject.width + sourceX;
          if (maskIndex < confidenceMask.length) {
            fullMask[targetY * targetWidth + targetX] = confidenceMask[maskIndex];
          }
        }
      }
      candidates.add(fullMask);
    }

    if (candidates.isNotEmpty) {
      return _mergeMasks(candidates, targetWidth * targetHeight);
    }

    final foregroundMask = result.foregroundConfidenceMask;
    if (foregroundMask == null || foregroundMask.isEmpty) {
      return null;
    }
    return _resizeMask(
      sourceMask: foregroundMask,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }

  List<double> _mergeMasks(List<List<double>> masks, int outputLength) {
    final merged = List<double>.filled(outputLength, 0);
    for (final mask in masks) {
      for (var i = 0; i < outputLength; i++) {
        if (mask[i] > merged[i]) {
          merged[i] = mask[i];
        }
      }
    }
    return merged;
  }

  List<double> _resizeMask({
    required List<double> sourceMask,
    required int sourceWidth,
    required int sourceHeight,
    required int targetWidth,
    required int targetHeight,
  }) {
    if (sourceWidth == targetWidth && sourceHeight == targetHeight) {
      return List<double>.from(sourceMask);
    }
    final resized = List<double>.filled(targetWidth * targetHeight, 0);
    for (var y = 0; y < targetHeight; y++) {
      final sourceY =
          ((y / targetHeight) * sourceHeight).floor().clamp(0, sourceHeight - 1);
      for (var x = 0; x < targetWidth; x++) {
        final sourceX =
            ((x / targetWidth) * sourceWidth).floor().clamp(0, sourceWidth - 1);
        resized[y * targetWidth + x] = sourceMask[sourceY * sourceWidth + sourceX];
      }
    }
    return resized;
  }

  ui.Offset? _resolvePersonFocusPoint({
    required ui.Offset? focusPoint,
    required List<Face> faces,
    required int preparedWidth,
    required int preparedHeight,
    required int targetWidth,
    required int targetHeight,
  }) {
    if (focusPoint != null) {
      return focusPoint;
    }
    if (faces.isEmpty) {
      return null;
    }
    final biggestFace = faces.reduce((best, current) {
      final bestArea = best.boundingBox.width * best.boundingBox.height;
      final currentArea = current.boundingBox.width * current.boundingBox.height;
      return currentArea > bestArea ? current : best;
    });
    return ui.Offset(
      (biggestFace.boundingBox.center.dx / preparedWidth) * targetWidth,
      (biggestFace.boundingBox.center.dy / preparedHeight) * targetHeight,
    );
  }

  @override
  Future<void> dispose() async {
    await _subjectSegmenter?.close();
    await _selfieSegmenter?.close();
    await _faceDetector?.close();
    _subjectSegmenter = null;
    _selfieSegmenter = null;
    _faceDetector = null;
  }
}

class HeuristicSegmentationAdapter implements SegmentationAdapter {
  @override
  Future<SelectionRegion> buildSmartSelection(
    EditorDocument document, {
    ui.Offset? focusPoint,
  }) async {
    if (focusPoint != null) {
      final focused = _buildFocusedSelection(document, focusPoint);
      if (focused != null) {
        return focused;
      }
    }
    return _buildGlobalFallback(document);
  }

  @override
  Future<SelectionRegion> buildPersonSelection(
    EditorDocument document, {
    ui.Offset? focusPoint,
  }) async {
    if (focusPoint != null) {
      final focused = _buildFocusedPersonSelection(document, focusPoint);
      if (focused != null) {
        return focused;
      }
    }
    return _buildCenterPersonSelection(document);
  }

  SelectionRegion? _buildFocusedSelection(
      EditorDocument document, ui.Offset focusPoint) {
    final image = document.bitmap;
    final startX = focusPoint.dx.round().clamp(0, image.width - 1);
    final startY = focusPoint.dy.round().clamp(0, image.height - 1);
    final seed = image.getPixel(startX, startY);
    final visited = Uint8List(image.width * image.height);
    final alpha = List<int>.filled(image.width * image.height, 0);
    final queue = Queue<(int, int)>()..add((startX, startY));
    visited[startY * image.width + startX] = 1;

    var minX = startX;
    var minY = startY;
    var maxX = startX;
    var maxY = startY;
    var accepted = 0;
    const neighbors = <(int, int)>[
      (-1, 0),
      (1, 0),
      (0, -1),
      (0, 1),
    ];

    while (queue.isNotEmpty && accepted < image.width * image.height * 0.35) {
      final current = queue.removeFirst();
      final x = current.$1;
      final y = current.$2;
      final pixel = image.getPixel(x, y);
      final colorDistance = _colorDistance(seed, pixel);
      final gradientPenalty = _localGradient(image, x, y);
      if (colorDistance > 58 || gradientPenalty > 42) {
        continue;
      }

      accepted += 1;
      alpha[y * image.width + x] = 255;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;

      for (final neighbor in neighbors) {
        final nx = x + neighbor.$1;
        final ny = y + neighbor.$2;
        if (nx < 0 || ny < 0 || nx >= image.width || ny >= image.height) {
          continue;
        }
        final index = ny * image.width + nx;
        if (visited[index] == 1) {
          continue;
        }
        visited[index] = 1;
        queue.add((nx, ny));
      }
    }

    if (accepted < 40) {
      return null;
    }

    return _legacySelectionFromAlpha(
      document: document,
      fullAlpha: alpha,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      feather: 12,
    );
  }

  SelectionRegion? _buildFocusedPersonSelection(
      EditorDocument document, ui.Offset focusPoint) {
    final image = document.bitmap;
    final startX = focusPoint.dx.round().clamp(0, image.width - 1);
    final startY = focusPoint.dy.round().clamp(0, image.height - 1);
    final seed = image.getPixel(startX, startY);
    final visited = Uint8List(image.width * image.height);
    final alpha = List<int>.filled(image.width * image.height, 0);
    final queue = Queue<(int, int)>()..add((startX, startY));
    visited[startY * image.width + startX] = 1;

    var minX = startX;
    var minY = startY;
    var maxX = startX;
    var maxY = startY;
    var accepted = 0;
    const neighbors = <(int, int)>[
      (-1, 0),
      (1, 0),
      (0, -1),
      (0, 1),
      (-1, -1),
      (1, -1),
      (-1, 1),
      (1, 1),
    ];

    final verticalFocus = startY / image.height;
    while (queue.isNotEmpty && accepted < image.width * image.height * 0.22) {
      final current = queue.removeFirst();
      final x = current.$1;
      final y = current.$2;
      final pixel = image.getPixel(x, y);
      final colorDistance = _colorDistance(seed, pixel);
      final gradientPenalty = _localGradient(image, x, y);
      final verticalBias =
          (1 - ((y / image.height) - verticalFocus).abs()).clamp(0.0, 1.0);
      final horizontalBias =
          (1 - ((x - startX).abs() / (image.width * 0.32))).clamp(0.0, 1.0);
      final score = 1.4 -
          (colorDistance / 72) -
          (gradientPenalty / 90) +
          verticalBias * 0.4 +
          horizontalBias * 0.2;
      if (score < 0.72) {
        continue;
      }

      accepted += 1;
      alpha[y * image.width + x] = 255;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;

      for (final neighbor in neighbors) {
        final nx = x + neighbor.$1;
        final ny = y + neighbor.$2;
        if (nx < 0 || ny < 0 || nx >= image.width || ny >= image.height) {
          continue;
        }
        final index = ny * image.width + nx;
        if (visited[index] == 1) {
          continue;
        }
        visited[index] = 1;
        queue.add((nx, ny));
      }
    }

    if (accepted < 120) {
      return null;
    }

    final expanded = _expandBounds(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      width: image.width,
      height: image.height,
      leftFactor: 0.12,
      rightFactor: 0.12,
      topFactor: 0.18,
      bottomFactor: 0.14,
    );

    return _legacySelectionFromAlpha(
      document: document,
      fullAlpha: alpha,
      minX: expanded.$1,
      minY: expanded.$2,
      maxX: expanded.$3,
      maxY: expanded.$4,
      feather: 10,
    );
  }

  SelectionRegion _buildCenterPersonSelection(EditorDocument document) {
    final image = document.bitmap;
    final edgeAverage = _edgeAverage(image);
    final alpha = List<int>.filled(image.width * image.height, 0);
    var minX = image.width;
    var minY = image.height;
    var maxX = -1;
    var maxY = -1;

    for (var y = 0; y < image.height; y++) {
      final normY = y / image.height;
      final verticalFocus = 1 - ((normY - 0.46).abs() / 0.46).clamp(0.0, 1.0);
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        final distance = math.sqrt(
          math.pow(r - edgeAverage.$1, 2) +
              math.pow(g - edgeAverage.$2, 2) +
              math.pow(b - edgeAverage.$3, 2),
        );
        final horizontalFocus =
            1 - ((x / image.width - 0.5).abs() / 0.5).clamp(0.0, 1.0);
        final slimBias = 1 - ((horizontalFocus - 0.55).abs()).clamp(0.0, 1.0);
        final value = ((distance / 125.0) * 0.75 +
                verticalFocus * 0.35 +
                horizontalFocus * 0.28 +
                slimBias * 0.12)
            .clamp(0.0, 1.0);
        final alphaValue = (value * 255).round();
        alpha[y * image.width + x] = alphaValue;
        if (alphaValue > 138) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      final bounds = ui.Rect.fromLTWH(
        image.width * 0.22,
        image.height * 0.1,
        image.width * 0.48,
        image.height * 0.8,
      );
      return SelectionRegion(
        documentId: document.id,
        tool: SelectionTool.smart,
        bounds: bounds,
        feather: 14,
      );
    }

    final expanded = _expandBounds(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      width: image.width,
      height: image.height,
      leftFactor: 0.14,
      rightFactor: 0.14,
      topFactor: 0.16,
      bottomFactor: 0.14,
    );

    return _legacySelectionFromAlpha(
      document: document,
      fullAlpha: alpha,
      minX: expanded.$1,
      minY: expanded.$2,
      maxX: expanded.$3,
      maxY: expanded.$4,
      feather: 12,
    );
  }

  SelectionRegion _buildGlobalFallback(EditorDocument document) {
    final image = document.bitmap;
    final edgeAverage = _edgeAverage(image);
    final alpha = List<int>.filled(image.width * image.height, 0);
    var minX = image.width;
    var minY = image.height;
    var maxX = -1;
    var maxY = -1;

    for (var y = 0; y < image.height; y++) {
      final fy = (y / image.height - 0.5).abs();
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        final distance = math.sqrt(
          math.pow(r - edgeAverage.$1, 2) +
              math.pow(g - edgeAverage.$2, 2) +
              math.pow(b - edgeAverage.$3, 2),
        );
        final focusBias = 1 -
            ((x / image.width - 0.5).abs() * 1.25 + fy * 1.5).clamp(0.0, 1.0);
        final value =
            ((distance / 130.0) * 0.75 + focusBias * 0.45).clamp(0.0, 1.0);
        final alphaValue = (value * 255).round();
        alpha[y * image.width + x] = alphaValue;
        if (alphaValue > 122) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      final bounds = ui.Rect.fromLTWH(
        image.width * 0.2,
        image.height * 0.12,
        image.width * 0.6,
        image.height * 0.76,
      );
      return SelectionRegion(
        documentId: document.id,
        tool: SelectionTool.smart,
        bounds: bounds,
        feather: 16,
      );
    }

    return _legacySelectionFromAlpha(
      document: document,
      fullAlpha: alpha,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      feather: 16,
    );
  }

  SelectionRegion _legacySelectionFromAlpha({
    required EditorDocument document,
    required List<int> fullAlpha,
    required int minX,
    required int minY,
    required int maxX,
    required int maxY,
    required double feather,
  }) {
    final bounds = ui.Rect.fromLTWH(
      minX.toDouble(),
      minY.toDouble(),
      (maxX - minX + 1).toDouble(),
      (maxY - minY + 1).toDouble(),
    );
    final width = bounds.width.round();
    final height = bounds.height.round();
    final cropped = List<int>.filled(width * height, 0);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        cropped[y * width + x] =
            fullAlpha[(minY + y) * document.width + minX + x];
      }
    }
    return SelectionRegion(
      documentId: document.id,
      tool: SelectionTool.smart,
      bounds: bounds,
      feather: feather,
      maskData: SelectionMaskData(
        bounds: bounds,
        width: width,
        height: height,
        alpha: cropped,
      ),
    );
  }

  (int, int, int, int) _expandBounds({
    required int minX,
    required int minY,
    required int maxX,
    required int maxY,
    required int width,
    required int height,
    required double leftFactor,
    required double rightFactor,
    required double topFactor,
    required double bottomFactor,
  }) {
    final boxWidth = math.max(1, maxX - minX + 1);
    final boxHeight = math.max(1, maxY - minY + 1);
    final left = math.max(0, (minX - boxWidth * leftFactor).floor());
    final top = math.max(0, (minY - boxHeight * topFactor).floor());
    final right = math.min(width - 1, (maxX + boxWidth * rightFactor).ceil());
    final bottom =
        math.min(height - 1, (maxY + boxHeight * bottomFactor).ceil());
    return (left, top, right, bottom);
  }

  double _colorDistance(img.Pixel a, img.Pixel b) {
    return math.sqrt(
      math.pow(a.r - b.r, 2) + math.pow(a.g - b.g, 2) + math.pow(a.b - b.b, 2),
    );
  }

  double _localGradient(img.Image image, int x, int y) {
    final center = image.getPixel(x, y);
    final right = image.getPixel((x + 1).clamp(0, image.width - 1), y);
    final down = image.getPixel(x, (y + 1).clamp(0, image.height - 1));
    return (_colorDistance(center, right) + _colorDistance(center, down)) / 2;
  }

  (double, double, double) _edgeAverage(img.Image image) {
    var sumR = 0.0;
    var sumG = 0.0;
    var sumB = 0.0;
    var count = 0.0;
    const sampleBand = 16;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (x < sampleBand ||
            y < sampleBand ||
            x >= image.width - sampleBand ||
            y >= image.height - sampleBand) {
          final pixel = image.getPixel(x, y);
          sumR += pixel.r.toDouble();
          sumG += pixel.g.toDouble();
          sumB += pixel.b.toDouble();
          count += 1;
        }
      }
    }
    if (count == 0) {
      return (128.0, 128.0, 128.0);
    }
    return (sumR / count, sumG / count, sumB / count);
  }

  @override
  Future<void> dispose() async {}
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

class _ConnectedComponent {
  const _ConnectedComponent({
    required this.indices,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final List<int> indices;
  final int minX;
  final int minY;
  final int maxX;
  final int maxY;

  int get pixelCount => indices.length;

  ui.Rect get bounds => ui.Rect.fromLTRB(
        minX.toDouble(),
        minY.toDouble(),
        (maxX + 1).toDouble(),
        (maxY + 1).toDouble(),
      );

  bool contains(int x, int y) =>
      x >= minX && x <= maxX && y >= minY && y <= maxY;
}

class _ComponentSelection {
  const _ComponentSelection({
    required this.alpha,
    required this.width,
    required this.height,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final List<int> alpha;
  final int width;
  final int height;
  final int minX;
  final int minY;
  final int maxX;
  final int maxY;
}

extension on MlKitSegmentationAdapter {
  List<int> _confidenceToAlpha(List<double> mask, {required double threshold}) {
    final alpha = List<int>.filled(mask.length, 0);
    for (var i = 0; i < mask.length; i++) {
      final confidence = mask[i].clamp(0.0, 1.0);
      if (confidence <= threshold) {
        alpha[i] = 0;
        continue;
      }
      final normalized =
          ((confidence - threshold) / (1 - threshold)).clamp(0.0, 1.0);
      alpha[i] = (normalized * 255).round();
    }
    return alpha;
  }

  List<int> _softenAlpha(List<int> alpha, int width, int height) {
    final expanded = _dilate(alpha, width, height, radius: 1);
    return _boxBlur(expanded, width, height, radius: 2);
  }

  List<int> _dilate(List<int> alpha, int width, int height,
      {required int radius}) {
    if (radius <= 0) {
      return List<int>.from(alpha);
    }
    final result = List<int>.filled(alpha.length, 0);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var best = 0;
        for (var yy = math.max(0, y - radius);
            yy <= math.min(height - 1, y + radius);
            yy++) {
          for (var xx = math.max(0, x - radius);
              xx <= math.min(width - 1, x + radius);
              xx++) {
            final candidate = alpha[yy * width + xx];
            if (candidate > best) {
              best = candidate;
            }
          }
        }
        result[y * width + x] = best;
      }
    }
    return result;
  }

  List<int> _boxBlur(List<int> alpha, int width, int height,
      {required int radius}) {
    if (radius <= 0) {
      return List<int>.from(alpha);
    }
    final horizontal = List<int>.filled(alpha.length, 0);
    final output = List<int>.filled(alpha.length, 0);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var sum = 0;
        var count = 0;
        for (var xx = math.max(0, x - radius);
            xx <= math.min(width - 1, x + radius);
            xx++) {
          sum += alpha[y * width + xx];
          count += 1;
        }
        horizontal[y * width + x] = (sum / count).round();
      }
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var sum = 0;
        var count = 0;
        for (var yy = math.max(0, y - radius);
            yy <= math.min(height - 1, y + radius);
            yy++) {
          sum += horizontal[yy * width + x];
          count += 1;
        }
        output[y * width + x] = (sum / count).round();
      }
    }
    return output;
  }

  _ComponentSelection? _selectFocusedComponent({
    required List<int> alpha,
    required int width,
    required int height,
    required ui.Offset? focusPoint,
    required bool allowNearCenterFallback,
  }) {
    final visited = Uint8List(alpha.length);
    final components = <_ConnectedComponent>[];
    final focusX = focusPoint?.dx.round().clamp(0, width - 1);
    final focusY = focusPoint?.dy.round().clamp(0, height - 1);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        if (visited[index] == 1 || alpha[index] < 16) {
          continue;
        }
        final component = _collectComponent(
          alpha: alpha,
          visited: visited,
          width: width,
          height: height,
          startX: x,
          startY: y,
        );
        if (component.pixelCount >=
            math.max(24, (width * height * 0.00015).round())) {
          components.add(component);
        }
      }
    }

    if (components.isEmpty) {
      return null;
    }

    _ConnectedComponent? best;
    var bestScore = double.negativeInfinity;
    for (final component in components) {
      final areaScore = component.pixelCount.toDouble();
      final center = component.bounds.center;
      var focusScore = 0.0;
      if (focusX != null && focusY != null) {
        if (component.contains(focusX, focusY)) {
          focusScore += width * height;
        }
        final dx = center.dx - focusX;
        final dy = center.dy - focusY;
        focusScore += math.max(
              0.0,
              1 - (math.sqrt(dx * dx + dy * dy) / math.max(width, height)),
            ) *
            (width * height * 0.22);
      } else if (allowNearCenterFallback) {
        final dx = center.dx - (width / 2);
        final dy = center.dy - (height / 2);
        focusScore += math.max(
              0.0,
              1 - (math.sqrt(dx * dx + dy * dy) / math.max(width, height)),
            ) *
            (width * height * 0.12);
      }
      final score = areaScore + focusScore;
      if (score > bestScore) {
        bestScore = score;
        best = component;
      }
    }

    if (best == null) {
      return null;
    }

    final filtered = List<int>.filled(alpha.length, 0);
    for (final index in best.indices) {
      filtered[index] = alpha[index];
    }

    return _ComponentSelection(
      alpha: filtered,
      width: width,
      height: height,
      minX: best.minX,
      minY: best.minY,
      maxX: best.maxX,
      maxY: best.maxY,
    );
  }

  _ConnectedComponent _collectComponent({
    required List<int> alpha,
    required Uint8List visited,
    required int width,
    required int height,
    required int startX,
    required int startY,
  }) {
    final queue = Queue<(int, int)>()..add((startX, startY));
    final indices = <int>[];
    visited[startY * width + startX] = 1;
    var minX = startX;
    var minY = startY;
    var maxX = startX;
    var maxY = startY;

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final x = current.$1;
      final y = current.$2;
      final index = y * width + x;
      if (alpha[index] < 16) {
        continue;
      }
      indices.add(index);
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;

      for (final neighbor in const <(int, int)>[
        (-1, 0),
        (1, 0),
        (0, -1),
        (0, 1),
        (-1, -1),
        (1, -1),
        (-1, 1),
        (1, 1),
      ]) {
        final nx = x + neighbor.$1;
        final ny = y + neighbor.$2;
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
          continue;
        }
        final neighborIndex = ny * width + nx;
        if (visited[neighborIndex] == 1 || alpha[neighborIndex] < 16) {
          continue;
        }
        visited[neighborIndex] = 1;
        queue.add((nx, ny));
      }
    }

    return _ConnectedComponent(
      indices: indices,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
    );
  }

  SelectionRegion _selectionFromAlpha({
    required EditorDocument document,
    required List<int> fullAlpha,
    required int minX,
    required int minY,
    required int maxX,
    required int maxY,
    required double feather,
    required double paddingScale,
    required double topPaddingScale,
  }) {
    final boxWidth = math.max(1, maxX - minX + 1);
    final boxHeight = math.max(1, maxY - minY + 1);
    final left = math.max(0, (minX - boxWidth * paddingScale).floor());
    final top = math.max(0, (minY - boxHeight * topPaddingScale).floor());
    final right =
        math.min(document.width - 1, (maxX + boxWidth * paddingScale).ceil());
    final bottom =
        math.min(document.height - 1, (maxY + boxHeight * paddingScale).ceil());
    final bounds = ui.Rect.fromLTRB(
      left.toDouble(),
      top.toDouble(),
      (right + 1).toDouble(),
      (bottom + 1).toDouble(),
    );
    final width = bounds.width.round();
    final height = bounds.height.round();
    final cropped = List<int>.filled(width * height, 0);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        cropped[y * width + x] = fullAlpha[(top + y) * document.width + left + x];
      }
    }
    return SelectionRegion(
      documentId: document.id,
      tool: SelectionTool.smart,
      bounds: bounds,
      feather: feather,
      maskData: SelectionMaskData(
        bounds: bounds,
        width: width,
        height: height,
        alpha: cropped,
      ),
    );
  }
}

Map<String, dynamic>? _prepareSegmentationInput(Map<String, dynamic> data) {
  final imageBytes = data['bytes'] as Uint8List;
  final imageWidth = data['width'] as int;
  final imageHeight = data['height'] as int;

  if (imageBytes.isEmpty || imageWidth <= 0 || imageHeight <= 0) {
    return null;
  }

  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) {
    return null;
  }

  final maxDimension = math.max(decoded.width, decoded.height);
  if (maxDimension <= MlKitSegmentationAdapter.maxSegmentationDimension) {
    return _encodeToNv21(decoded);
  }

  final scale = MlKitSegmentationAdapter.maxSegmentationDimension / maxDimension;
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
      final pixel = image.getPixel(i, j);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

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
