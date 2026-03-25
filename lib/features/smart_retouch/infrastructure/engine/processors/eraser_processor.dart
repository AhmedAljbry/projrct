import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import '../../../domain/models/retouch_operation.dart';

class EraserProcessor {
  /// Erasing makes pixels transparent — this is the real object-removal eraser.
  static void processErase({
    required img.Image targetImage,
    required img.Image originalImage,
    required EraseOperation operation,
  }) {
    if (operation.path.isEmpty) return;

    final double brushSize = operation.settings.size;
    final double radius = brushSize / 2;
    final double hardness = operation.settings.hardness;
    final double opacity = operation.settings.opacity;

    for (final point in operation.path) {
      _applyEraserDab(
        targetImage: targetImage,
        center: point,
        radius: radius,
        hardness: hardness,
        opacity: opacity,
      );
    }
  }

  static void _applyEraserDab({
    required img.Image targetImage,
    required Offset center,
    required double radius,
    required double hardness,
    required double opacity,
  }) {
    final int cx = center.dx.toInt();
    final int cy = center.dy.toInt();
    final int r = radius.toInt();

    final int width = targetImage.width;
    final int height = targetImage.height;

    for (int y = -r; y <= r; y++) {
      for (int x = -r; x <= r; x++) {
        final int targetX = cx + x;
        final int targetY = cy + y;

        if (targetX < 0 || targetX >= width || targetY < 0 || targetY >= height) continue;

        final double distanceSq = (x * x + y * y).toDouble();
        final double radiusSq = radius * radius;
        if (distanceSq > radiusSq) continue;

        // Feathering: how much to erase at this pixel
        final double distance = math.sqrt(distanceSq);
        final double featherStart = radius * hardness;
        double alpha = 1.0;
        if (distance > featherStart && radius > featherStart) {
          alpha = 1.0 - ((distance - featherStart) / (radius - featherStart));
        }
        alpha *= opacity;

        // Reduce alpha of target pixel proportionally
        final img.Pixel pixel = targetImage.getPixel(targetX, targetY);
        final double currentAlpha = pixel.a / 255.0;
        final double newAlpha = math.max(0.0, currentAlpha - alpha);
        // Use setPixelRgba to ensure the alpha write commits to the image buffer
        targetImage.setPixelRgba(targetX, targetY, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), (newAlpha * 255).round());
      }
    }
  }
}
