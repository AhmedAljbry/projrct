import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

import '../domain/entities/editor_models.dart';
import '../engine/object_copy_paste_engine.dart';

class ExportService {
  Uint8List export({
    required EditorDocument targetDocument,
    required List<PastedItem> items,
    bool asPng = true,
  }) {
    final canvas = img.Image.from(targetDocument.bitmap);
    final engine = ObjectCopyPasteEngine();

    for (final item in items.where((element) =>
        element.visible && element.targetDocumentId == targetDocument.id)) {
      final transformed = _transformPatch(item);
      final harmonized = _harmonizePatch(
          item, transformed, canvas, engine.transformedRect(item));
      final rect = engine.transformedRect(item);
      img.compositeImage(
        canvas,
        harmonized,
        dstX: (rect.left - harmonized.width / 2 + rect.width / 2).round(),
        dstY: (rect.top - harmonized.height / 2 + rect.height / 2).round(),
      );
    }

    return Uint8List.fromList(
      asPng
          ? img.encodePng(canvas, level: 2)
          : img.encodeJpg(canvas, quality: 97),
    );
  }

  img.Image _transformPatch(PastedItem item) {
    var working = img.Image.from(item.clipboard.bitmap);
    if (item.flipX) {
      working = img.flipHorizontal(working);
    }
    if (item.flipY) {
      working = img.flipVertical(working);
    }
    final targetWidth = (working.width * item.scale).round().clamp(1, 100000);
    final targetHeight = (working.height * item.scale).round().clamp(1, 100000);
    if (targetWidth != working.width || targetHeight != working.height) {
      working = img.copyResize(
        working,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.cubic,
      );
    }
    if (item.rotation.abs() > 0.001) {
      working = img.copyRotate(working, angle: item.rotation * 57.2958);
    }
    if (item.feather > 0) {
      working = _featherPatchEdges(working, item.feather);
    }
    if (item.opacity < 1) {
      for (final pixel in working) {
        pixel.a = (pixel.a * item.opacity).clamp(0, 255).round();
      }
    }
    return working;
  }

  img.Image _featherPatchEdges(img.Image source, double feather) {
    final radius = (feather / 4).round().clamp(1, 24);
    if (radius <= 0) {
      return source;
    }

    final width = source.width;
    final height = source.height;
    final alpha = List<int>.filled(width * height, 0);
    var index = 0;
    for (final pixel in source) {
      alpha[index++] = pixel.a.toInt();
    }

    final horizontal = List<int>.filled(alpha.length, 0);
    final blurred = List<int>.filled(alpha.length, 0);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var sum = 0;
        var count = 0;
        for (var k = -radius; k <= radius; k++) {
          final sampleX = x + k;
          if (sampleX < 0 || sampleX >= width) {
            continue;
          }
          sum += alpha[y * width + sampleX];
          count += 1;
        }
        horizontal[y * width + x] = count == 0 ? 0 : (sum / count).round();
      }
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var sum = 0;
        var count = 0;
        for (var k = -radius; k <= radius; k++) {
          final sampleY = y + k;
          if (sampleY < 0 || sampleY >= height) {
            continue;
          }
          sum += horizontal[sampleY * width + x];
          count += 1;
        }
        blurred[y * width + x] = count == 0 ? 0 : (sum / count).round();
      }
    }

    final output = img.Image.from(source);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        output.getPixel(x, y).a = blurred[y * width + x];
      }
    }
    return output;
  }

  img.Image _harmonizePatch(
    PastedItem item,
    img.Image patch,
    img.Image target,
    Rect targetRect,
  ) {
    final region = _averageColor(
      target,
      Rect.fromLTWH(
        targetRect.left.clamp(0.0, target.width - 1.0),
        targetRect.top.clamp(0.0, target.height - 1.0),
        targetRect.width.clamp(1.0, target.width.toDouble()),
        targetRect.height.clamp(1.0, target.height.toDouble()),
      ),
    );
    final source = _averagePatchColor(patch);
    final luminanceScale =
        source.$4 <= 0.001 ? 1.0 : (region.$4 / source.$4).clamp(0.6, 1.6);
    for (final pixel in patch) {
      if (pixel.a == 0) {
        continue;
      }
      var r = pixel.r.toDouble();
      var g = pixel.g.toDouble();
      var b = pixel.b.toDouble();
      r += (region.$1 - source.$1) * item.colorMatchStrength;
      g += (region.$2 - source.$2) * item.colorMatchStrength;
      b += (region.$3 - source.$3) * item.colorMatchStrength;
      final adjustedLuma =
          1 + (luminanceScale - 1) * item.lightingMatchStrength;
      pixel
        ..r = (r * adjustedLuma).clamp(0, 255).round()
        ..g = (g * adjustedLuma).clamp(0, 255).round()
        ..b = (b * adjustedLuma).clamp(0, 255).round();
    }
    return patch;
  }

  (double, double, double, double) _averageColor(img.Image image, Rect rect) {
    var sumR = 0.0;
    var sumG = 0.0;
    var sumB = 0.0;
    var count = 0.0;
    final startX = rect.left.round().clamp(0, image.width - 1);
    final endX = (rect.right.round()).clamp(0, image.width);
    final startY = rect.top.round().clamp(0, image.height - 1);
    final endY = (rect.bottom.round()).clamp(0, image.height);
    for (var y = startY; y < endY; y++) {
      for (var x = startX; x < endX; x++) {
        final pixel = image.getPixel(x, y);
        sumR += pixel.r.toDouble();
        sumG += pixel.g.toDouble();
        sumB += pixel.b.toDouble();
        count += 1;
      }
    }
    if (count == 0) {
      return (128, 128, 128, 128);
    }
    final r = sumR / count;
    final g = sumG / count;
    final b = sumB / count;
    return (r, g, b, 0.2126 * r + 0.7152 * g + 0.0722 * b);
  }

  (double, double, double, double) _averagePatchColor(img.Image image) {
    var sumR = 0.0;
    var sumG = 0.0;
    var sumB = 0.0;
    var weight = 0.0;
    for (final pixel in image) {
      if (pixel.a == 0) {
        continue;
      }
      final alpha = pixel.a / 255.0;
      sumR += pixel.r.toDouble() * alpha;
      sumG += pixel.g.toDouble() * alpha;
      sumB += pixel.b.toDouble() * alpha;
      weight += alpha;
    }
    if (weight == 0) {
      return (128, 128, 128, 128);
    }
    final r = sumR / weight;
    final g = sumG / weight;
    final b = sumB / weight;
    return (r, g, b, 0.2126 * r + 0.7152 * g + 0.0722 * b);
  }
}
