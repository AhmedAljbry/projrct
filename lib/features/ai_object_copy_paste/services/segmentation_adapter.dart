import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

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
  HybridSegmentationAdapter({HeuristicSegmentationAdapter? fallback})
      : _fallback = fallback ?? HeuristicSegmentationAdapter();

  final HeuristicSegmentationAdapter _fallback;

  @override
  Future<SelectionRegion> buildSmartSelection(
    EditorDocument document, {
    ui.Offset? focusPoint,
  }) {
    return _fallback.buildSmartSelection(document, focusPoint: focusPoint);
  }

  @override
  Future<SelectionRegion> buildPersonSelection(
    EditorDocument document, {
    ui.Offset? focusPoint,
  }) {
    return _fallback.buildPersonSelection(document, focusPoint: focusPoint);
  }

  @override
  Future<void> dispose() async {}
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

    return _selectionFromAlpha(
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
      final verticalBias = (1 - ((y / image.height) - verticalFocus).abs())
          .clamp(0.0, 1.0);
      final horizontalBias =
          (1 - ((x - startX).abs() / (image.width * 0.32))).clamp(0.0, 1.0);
      final score =
          1.4 - (colorDistance / 72) - (gradientPenalty / 90) + verticalBias * 0.4 + horizontalBias * 0.2;
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

    return _selectionFromAlpha(
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

    return _selectionFromAlpha(
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

    return _selectionFromAlpha(
      document: document,
      fullAlpha: alpha,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      feather: 16,
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
