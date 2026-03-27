import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../domain/models/retouch_operation.dart';

class EraserProcessor {
  // Restore original pixels inside the brush area instead of erasing to transparency.
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
        originalImage: originalImage,
        center: point,
        radius: radius,
        hardness: hardness,
        opacity: opacity,
      );
    }
  }

  static void _applyEraserDab({
    required img.Image targetImage,
    required img.Image originalImage,
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

        if (targetX < 0 ||
            targetX >= width ||
            targetY < 0 ||
            targetY >= height) {
          continue;
        }

        final double distanceSq = (x * x + y * y).toDouble();
        final double radiusSq = radius * radius;
        if (distanceSq > radiusSq) continue;

        final double distance = math.sqrt(distanceSq);
        final double featherStart = radius * hardness;
        double alpha = 1.0;
        if (distance > featherStart && radius > featherStart) {
          alpha = 1.0 - ((distance - featherStart) / (radius - featherStart));
        }
        alpha *= opacity;

        final img.Pixel currentPixel = targetImage.getPixel(targetX, targetY);
        final img.Pixel originalPixel =
            originalImage.getPixel(targetX, targetY);

        targetImage.setPixelRgba(
          targetX,
          targetY,
          _lerp(currentPixel.r.toDouble(), originalPixel.r.toDouble(), alpha),
          _lerp(currentPixel.g.toDouble(), originalPixel.g.toDouble(), alpha),
          _lerp(currentPixel.b.toDouble(), originalPixel.b.toDouble(), alpha),
          _lerp(currentPixel.a.toDouble(), originalPixel.a.toDouble(), alpha),
        );
      }
    }
  }

  static int _lerp(double a, double b, double t) {
    return (a + (b - a) * t).round().clamp(0, 255);
  }
}
