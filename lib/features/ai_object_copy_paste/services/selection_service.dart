import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

import '../domain/entities/editor_models.dart';
import 'image_codec_service.dart';

class SelectionService {
  SelectionMaskData buildMask(
      EditorDocument document, SelectionRegion selection) {
    final bounds = _inflateBounds(
      selection.bounds,
      selection.expand,
      document.width.toDouble(),
      document.height.toDouble(),
    );

    if (selection.maskData != null) {
      return _applyFeather(selection.maskData!, selection.feather);
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
    final mask = buildMask(document, selection);
    final patch =
        img.Image(width: mask.width, height: mask.height, numChannels: 4);

    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        final srcX = mask.bounds.left.round() + x;
        final srcY = mask.bounds.top.round() + y;
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
    return Rect.fromLTWH(
      (bounds.left - expand).clamp(0.0, maxWidth - 1),
      (bounds.top - expand).clamp(0.0, maxHeight - 1),
      (bounds.width + expand * 2).clamp(1.0, maxWidth),
      (bounds.height + expand * 2).clamp(1.0, maxHeight),
    );
  }
}
