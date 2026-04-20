import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

import '../domain/entities/editor_models.dart';
import 'image_codec_service.dart';

class SelectionService {
  SelectionMaskData buildMask(
      EditorDocument document, SelectionRegion selection) {
    final bounds = _pixelAlignedBounds(
      _inflateBounds(
        selection.bounds,
        selection.expand,
        document.width.toDouble(),
        document.height.toDouble(),
      ),
      document.width.toDouble(),
      document.height.toDouble(),
    );

    if (selection.maskData != null) {
      final normalizedMask = _normalizeMaskData(
        selection.maskData!,
        bounds,
      );
      final refinedMask = _refineSmartMask(normalizedMask);
      return _applyFeather(
        refinedMask,
        math.min(selection.feather, 3),
      );
    }

    final maskWidth = math.max(1, bounds.width.round());
    final maskHeight = math.max(1, bounds.height.round());
    final alpha = List<int>.filled(maskWidth * maskHeight, 0);

    if (selection.tool == SelectionTool.rectangle) {
      for (var y = 0; y < maskHeight; y++) {
        for (var x = 0; x < maskWidth; x++) {
          alpha[y * maskWidth + x] = 255;
        }
      }
    } else {
      final shiftedPath = selection.path
          .whereType<Offset>()
          .map((point) => Offset(point.dx - bounds.left, point.dy - bounds.top))
          .toList(growable: false);
      for (var y = 0; y < maskHeight; y++) {
        for (var x = 0; x < maskWidth; x++) {
          if (_pointInPolygon(Offset(x + 0.5, y + 0.5), shiftedPath)) {
            alpha[y * maskWidth + x] = 255;
          }
        }
      }
    }

    return _applyFeather(
      SelectionMaskData(
        bounds: bounds,
        width: maskWidth,
        height: maskHeight,
        alpha: alpha,
      ),
      selection.feather,
    );
  }

  Future<PatchClipboard> copySelection({
    required EditorDocument document,
    required SelectionRegion selection,
    required ImageCodecService codecService,
  }) async {
    final mask = _trimTransparentBounds(buildMask(document, selection));
    final patch =
        img.Image(width: mask.width, height: mask.height, numChannels: 4);
    final srcLeft = mask.bounds.left.toInt();
    final srcTop = mask.bounds.top.toInt();

    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        final srcX = srcLeft + x;
        final srcY = srcTop + y;
        if (srcX < 0 ||
            srcY < 0 ||
            srcX >= document.width ||
            srcY >= document.height) {
          patch.setPixelRgba(x, y, 0, 0, 0, 0);
          continue;
        }
        final pixel = document.bitmap.getPixel(srcX, srcY);
        patch.setPixelRgba(
            x, y, pixel.r, pixel.g, pixel.b, mask.alpha[y * mask.width + x]);
      }
    }

    final pngBytes = Uint8List.fromList(img.encodePng(patch, level: 2));
    return codecService.decodeClipboard(
      pngBytes: pngBytes,
      sourceDocumentId: document.id,
      sourceBounds: mask.bounds,
    );
  }

  SelectionMaskData _normalizeMaskData(
    SelectionMaskData mask,
    Rect targetBounds,
  ) {
    final targetWidth = math.max(1, targetBounds.width.round());
    final targetHeight = math.max(1, targetBounds.height.round());
    if (mask.width == targetWidth &&
        mask.height == targetHeight &&
        mask.bounds == targetBounds) {
      return mask;
    }

    final resized = List<int>.filled(targetWidth * targetHeight, 0);
    for (var y = 0; y < targetHeight; y++) {
      final sourceY =
          ((y / targetHeight) * mask.height).floor().clamp(0, mask.height - 1);
      for (var x = 0; x < targetWidth; x++) {
        final sourceX =
            ((x / targetWidth) * mask.width).floor().clamp(0, mask.width - 1);
        resized[y * targetWidth + x] = mask.alpha[sourceY * mask.width + sourceX];
      }
    }

    return SelectionMaskData(
      bounds: targetBounds,
      width: targetWidth,
      height: targetHeight,
      alpha: resized,
    );
  }

  SelectionMaskData _refineSmartMask(SelectionMaskData mask) {
    final closed = _closeMask(mask.alpha, mask.width, mask.height, radius: 1);
    final filled = _fillInnerHoles(closed, mask.width, mask.height);
    final dilated = _dilate(filled, mask.width, mask.height, radius: 1);
    final softened = _lightBlur(dilated, mask.width, mask.height);
    final strengthened = List<int>.filled(softened.length, 0);
    for (var i = 0; i < softened.length; i++) {
      final original = mask.alpha[i];
      final smooth = softened[i];
      final boosted = math.max(original, (smooth * 0.96).round());
      strengthened[i] = boosted >= 18 ? boosted : 0;
    }
    return SelectionMaskData(
      bounds: mask.bounds,
      width: mask.width,
      height: mask.height,
      alpha: strengthened,
    );
  }

  List<int> _dilate(List<int> alpha, int width, int height, {required int radius}) {
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
            final value = alpha[yy * width + xx];
            if (value > best) {
              best = value;
            }
          }
        }
        result[y * width + x] = best;
      }
    }
    return result;
  }

  List<int> _erode(List<int> alpha, int width, int height, {required int radius}) {
    final result = List<int>.filled(alpha.length, 0);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var minValue = 255;
        for (var yy = math.max(0, y - radius);
            yy <= math.min(height - 1, y + radius);
            yy++) {
          for (var xx = math.max(0, x - radius);
              xx <= math.min(width - 1, x + radius);
              xx++) {
            final value = alpha[yy * width + xx];
            if (value < minValue) {
              minValue = value;
            }
          }
        }
        result[y * width + x] = minValue;
      }
    }
    return result;
  }

  List<int> _closeMask(List<int> alpha, int width, int height, {required int radius}) {
    final dilated = _dilate(alpha, width, height, radius: radius);
    return _erode(dilated, width, height, radius: radius);
  }

  List<int> _lightBlur(List<int> alpha, int width, int height) {
    final output = List<int>.filled(alpha.length, 0);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var sum = 0;
        var count = 0;
        for (var yy = math.max(0, y - 1); yy <= math.min(height - 1, y + 1); yy++) {
          for (var xx = math.max(0, x - 1); xx <= math.min(width - 1, x + 1); xx++) {
            sum += alpha[yy * width + xx];
            count += 1;
          }
        }
        output[y * width + x] = (sum / count).round();
      }
    }
    return output;
  }

  List<int> _fillInnerHoles(List<int> alpha, int width, int height) {
    final binary = List<int>.filled(alpha.length, 0);
    for (var i = 0; i < alpha.length; i++) {
      binary[i] = alpha[i] >= 24 ? 1 : 0;
    }

    final visited = Uint8List(alpha.length);
    final queue = <int>[];

    void enqueueIfBackground(int x, int y) {
      final index = y * width + x;
      if (visited[index] == 1 || binary[index] == 1) {
        return;
      }
      visited[index] = 1;
      queue.add(index);
    }

    for (var x = 0; x < width; x++) {
      enqueueIfBackground(x, 0);
      enqueueIfBackground(x, height - 1);
    }
    for (var y = 0; y < height; y++) {
      enqueueIfBackground(0, y);
      enqueueIfBackground(width - 1, y);
    }

    var head = 0;
    while (head < queue.length) {
      final index = queue[head++];
      final x = index % width;
      final y = index ~/ width;
      for (final offset in const <(int, int)>[
        (-1, 0),
        (1, 0),
        (0, -1),
        (0, 1),
      ]) {
        final nx = x + offset.$1;
        final ny = y + offset.$2;
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
          continue;
        }
        final neighborIndex = ny * width + nx;
        if (visited[neighborIndex] == 1 || binary[neighborIndex] == 1) {
          continue;
        }
        visited[neighborIndex] = 1;
        queue.add(neighborIndex);
      }
    }

    final filled = List<int>.from(alpha);
    for (var i = 0; i < filled.length; i++) {
      if (binary[i] == 0 && visited[i] == 0) {
        filled[i] = 255;
      }
    }
    return filled;
  }

  SelectionMaskData _trimTransparentBounds(SelectionMaskData mask) {
    var minX = mask.width;
    var minY = mask.height;
    var maxX = -1;
    var maxY = -1;
    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        if (mask.alpha[y * mask.width + x] <= 8) {
          continue;
        }
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    if (maxX < minX || maxY < minY) {
      return mask;
    }

    const padding = 2;
    minX = math.max(0, minX - padding);
    minY = math.max(0, minY - padding);
    maxX = math.min(mask.width - 1, maxX + padding);
    maxY = math.min(mask.height - 1, maxY + padding);

    final trimmedWidth = maxX - minX + 1;
    final trimmedHeight = maxY - minY + 1;
    if (trimmedWidth == mask.width && trimmedHeight == mask.height) {
      return mask;
    }

    final trimmed = List<int>.filled(trimmedWidth * trimmedHeight, 0);
    for (var y = 0; y < trimmedHeight; y++) {
      for (var x = 0; x < trimmedWidth; x++) {
        trimmed[y * trimmedWidth + x] =
            mask.alpha[(minY + y) * mask.width + minX + x];
      }
    }

    return SelectionMaskData(
      bounds: Rect.fromLTWH(
        mask.bounds.left + minX,
        mask.bounds.top + minY,
        trimmedWidth.toDouble(),
        trimmedHeight.toDouble(),
      ),
      width: trimmedWidth,
      height: trimmedHeight,
      alpha: trimmed,
    );
  }

  SelectionMaskData _applyFeather(SelectionMaskData mask, double feather) {
    final radius = feather.round();
    if (radius <= 0) {
      return mask;
    }
    final blurred = List<int>.from(mask.alpha);
    final temp = List<int>.from(mask.alpha);
    for (var pass = 0; pass < 2; pass++) {
      for (var y = 0; y < mask.height; y++) {
        for (var x = 0; x < mask.width; x++) {
          var sum = 0;
          var count = 0;
          for (var k = -radius; k <= radius; k++) {
            final sampleX = pass == 0 ? x + k : x;
            final sampleY = pass == 0 ? y : y + k;
            if (sampleX < 0 ||
                sampleY < 0 ||
                sampleX >= mask.width ||
                sampleY >= mask.height) {
              continue;
            }
            sum += (pass == 0 ? temp : blurred)[sampleY * mask.width + sampleX];
            count += 1;
          }
          final value = count == 0 ? 0 : (sum / count).round();
          if (pass == 0) {
            blurred[y * mask.width + x] = value;
          } else {
            temp[y * mask.width + x] = value;
          }
        }
      }
    }
    return SelectionMaskData(
      bounds: mask.bounds,
      width: mask.width,
      height: mask.height,
      alpha: temp,
    );
  }

  bool _pointInPolygon(Offset point, List<Offset> polygon) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].dx;
      final yi = polygon[i].dy;
      final xj = polygon[j].dx;
      final yj = polygon[j].dy;
      final intersect = ((yi > point.dy) != (yj > point.dy)) &&
          (point.dx <
              (xj - xi) *
                      (point.dy - yi) /
                      ((yj - yi) == 0 ? 0.0001 : (yj - yi)) +
                  xi);
      if (intersect) {
        inside = !inside;
      }
    }
    return inside;
  }

  Rect _inflateBounds(
      Rect bounds, double expand, double maxWidth, double maxHeight) {
    final left = (bounds.left - expand).clamp(0.0, maxWidth - 1);
    final top = (bounds.top - expand).clamp(0.0, maxHeight - 1);
    final right = (bounds.right + expand).clamp(left + 1, maxWidth);
    final bottom = (bounds.bottom + expand).clamp(top + 1, maxHeight);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect _pixelAlignedBounds(Rect bounds, double maxWidth, double maxHeight) {
    final left = bounds.left.floorToDouble().clamp(0.0, maxWidth - 1);
    final top = bounds.top.floorToDouble().clamp(0.0, maxHeight - 1);
    final right = bounds.right.ceilToDouble().clamp(left + 1, maxWidth);
    final bottom = bounds.bottom.ceilToDouble().clamp(top + 1, maxHeight);
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
