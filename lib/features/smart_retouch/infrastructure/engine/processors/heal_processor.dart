import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:untitled2/features/smart_retouch/domain/models/retouch_mode.dart';

import '../../../domain/models/retouch_operation.dart';

class HealProcessor {
  /// Healing differs from Clone by attempting to match the luminance/color of the TARGET area
  /// while bringing only the TEXTURE from the SOURCE area.
  /// A true Poisson blend is too slow for real-time mobile strokes.
  /// We use a fast high-pass/luminance match approach here.
  static void processHeal({
    required img.Image targetImage,
    required img.Image originalImage,
    required StrokeOperation operation,
  }) {
    if (operation.path.isEmpty) return;

    final double brushSize = operation.settings.size;
    final double radius = brushSize / 2;
    final double hardness = operation.settings.hardness;
    final double opacity = operation.settings.opacity;

    final Offset sourceA = operation.sourceAnchor ?? operation.path.first;
    final Offset targetA = operation.targetAnchor ?? operation.path.first;
    final Offset vectorD = sourceA - targetA;

    for (final point in operation.path) {
      final Offset currentSource = (operation.alignmentMode == SourceAlignmentMode.aligned)
          ? point + vectorD
          : sourceA;

      _applyHealDab(
        targetImage: targetImage,
        sourceImage: originalImage,
        targetCenter: point,
        sourceCenter: currentSource,
        radius: radius,
        hardness: hardness,
        opacity: opacity,
      );
    }
  }

  static void _applyHealDab({
    required img.Image targetImage,
    required img.Image sourceImage,
    required Offset targetCenter,
    required Offset sourceCenter,
    required double radius,
    required double hardness,
    required double opacity,
  }) {
    final int cx = targetCenter.dx.toInt();
    final int cy = targetCenter.dy.toInt();
    final int sx = sourceCenter.dx.toInt();
    final int sy = sourceCenter.dy.toInt();
    final int r = radius.toInt();

    final int width = targetImage.width;
    final int height = targetImage.height;

    for (int y = -r; y <= r; y++) {
      for (int x = -r; x <= r; x++) {
        final int targetX = cx + x;
        final int targetY = cy + y;
        final int sourceX = sx + x;
        final int sourceY = sy + y;

        if (targetX < 0 || targetX >= width || targetY < 0 || targetY >= height) continue;
        if (sourceX < 0 || sourceX >= width || sourceY < 0 || sourceY >= height) continue;

        final double distanceSq = (x * x + y * y).toDouble();
        final double radiusSq = radius * radius;
        if (distanceSq > radiusSq) continue;

        final double distance = math.sqrt(distanceSq);
        final double featherStart = radius * hardness;

        double alpha = 1.0;
        if (distance > featherStart) {
          alpha = 1.0 - ((distance - featherStart) / (radius - featherStart));
        }
        alpha *= opacity;

        final img.Pixel sourcePixel = sourceImage.getPixel(sourceX, sourceY);
        final img.Pixel currentPixel = targetImage.getPixel(targetX, targetY);

        // Fast Luminance Matching Healing
        // 1. Calculate luminance of source and target
        final double lumS = 0.299 * sourcePixel.r + 0.587 * sourcePixel.g + 0.114 * sourcePixel.b;
        final double lumT = 0.299 * currentPixel.r + 0.587 * currentPixel.g + 0.114 * currentPixel.b;
        
        // 2. Adjust source color towards target luminance to keep texture but match local lighting
        final double diff = lumT - lumS;
        final num healR = (sourcePixel.r + diff).clamp(0, 255);
        final num healG = (sourcePixel.g + diff).clamp(0, 255);
        final num healB = (sourcePixel.b + diff).clamp(0, 255);

        // 3. Blend
        final num finalR = currentPixel.r + (healR - currentPixel.r) * alpha;
        final num finalG = currentPixel.g + (healG - currentPixel.g) * alpha;
        final num finalB = currentPixel.b + (healB - currentPixel.b) * alpha;

        targetImage.setPixel(targetX, targetY, targetImage.getColor(finalR, finalG, finalB));
      }
    }
  }
}
