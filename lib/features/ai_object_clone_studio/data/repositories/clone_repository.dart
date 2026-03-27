import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../domain/entities/clone_entities.dart';
import '../../domain/repositories/iclone_repository.dart';
import '../../engine/blending/blending_engine.dart';
import '../../engine/segmentation/segmentation_engine.dart';

class CloneRepository implements ICloneRepository {
  final SegmentationEngine segmentationEngine;
  final BlendingEngine blendingEngine;

  CloneRepository({
    required this.segmentationEngine,
    required this.blendingEngine,
  });

  @override
  Future<ClonedObject> extractObject({
    required Uint8List imageBytes,
    required List<Offset> points,
    required SelectionMode mode,
  }) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return ClonedObject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageBytes: imageBytes,
        mask: MaskData(
          bytes: Uint8List(0),
          width: 1,
          height: 1,
          bounds: const Rect.fromLTWH(0, 0, 1, 1),
        ),
        originalSize: const Size(1, 1),
      );
    }

    final detectedMask = await segmentationEngine.autoDetectSubject(imageBytes);
    final mask = detectedMask ?? _buildPointFallbackMask(decoded, points);
    final cropped = _cropMaskedObject(decoded, mask);

    return ClonedObject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imageBytes: cropped,
      mask: mask,
      originalSize: Size(mask.bounds.width, mask.bounds.height),
    );
  }

  @override
  Future<Uint8List> harmonizeLayer({
    required Uint8List targetImage,
    required EditLayer layer,
  }) async {
    return blendingEngine.harmonize(
      sourceObject: layer.object.imageBytes,
      targetImage: targetImage,
      strength: layer.harmonization.colorMatch,
    );
  }

  @override
  Future<Uint8List> finalizeImage({
    required Uint8List baseImage,
    required List<EditLayer> layers,
  }) async {
    return baseImage;
  }

  MaskData _buildPointFallbackMask(img.Image image, List<Offset> points) {
    final width = image.width;
    final height = image.height;
    final bytes = Uint8List(width * height);

    final center = points.isNotEmpty
        ? Offset(
            points.map((p) => p.dx).reduce((a, b) => a + b) / points.length,
            points.map((p) => p.dy).reduce((a, b) => a + b) / points.length,
          )
        : Offset(width / 2, height / 2);

    final radiusX = math.max(width * 0.16, 72.0);
    final radiusY = math.max(height * 0.24, 120.0);

    for (var y = 0; y < height; y++) {
      final dy = (y - center.dy) / radiusY;
      for (var x = 0; x < width; x++) {
        final dx = (x - center.dx) / radiusX;
        final dist = math.sqrt(dx * dx + dy * dy);
        final alpha = ((1.0 - dist).clamp(0.0, 1.0) * 255).round();
        bytes[y * width + x] = alpha;
      }
    }

    final bounds = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    ).intersect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    return MaskData(
      bytes: bytes,
      width: width,
      height: height,
      bounds: bounds,
    );
  }

  Uint8List _cropMaskedObject(img.Image source, MaskData mask) {
    final left = mask.bounds.left.floor().clamp(0, source.width - 1);
    final top = mask.bounds.top.floor().clamp(0, source.height - 1);
    final right = mask.bounds.right.ceil().clamp(left + 1, source.width);
    final bottom = mask.bounds.bottom.ceil().clamp(top + 1, source.height);

    final cropWidth = math.max(1, right - left);
    final cropHeight = math.max(1, bottom - top);
    final output =
        img.Image(width: cropWidth, height: cropHeight, numChannels: 4);

    for (var y = 0; y < cropHeight; y++) {
      for (var x = 0; x < cropWidth; x++) {
        final srcX = left + x;
        final srcY = top + y;
        final pixel = source.getPixel(srcX, srcY);
        final alpha = mask.bytes[srcY * mask.width + srcX];
        output.setPixelRgba(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          alpha,
        );
      }
    }

    return Uint8List.fromList(img.encodePng(output, level: 4));
  }
}
