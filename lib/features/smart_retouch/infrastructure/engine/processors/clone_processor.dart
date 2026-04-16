import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:untitled2/features/smart_retouch/domain/models/retouch_mode.dart';
import '../../../domain/models/retouch_operation.dart';

class CloneProcessor {
  static void processClone({
    required img.Image targetImage,
    required img.Image originalImage,
    required StrokeOperation operation,
  }) {
    if (operation.path.isEmpty) return;

    final double radius = operation.settings.size / 2.0;
    final double hardness = operation.settings.hardness.clamp(0.0, 1.0);
    final double opacity = operation.settings.opacity.clamp(0.0, 1.0);

    final Offset sourceA = operation.sourceAnchor ?? operation.path.first;
    final Offset targetA = operation.targetAnchor ?? operation.path.first;
    final Offset vectorD = sourceA - targetA;

    for (final point in operation.path) {
      final Offset currentSource =
          (operation.alignmentMode == SourceAlignmentMode.aligned)
              ? point + vectorD
              : sourceA;

      _applyCloneDab(
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

  static void _applyCloneDab({
    required img.Image targetImage,
    required img.Image sourceImage,
    required Offset targetCenter,
    required Offset sourceCenter,
    required double radius,
    required double hardness,
    required double opacity,
  }) {
    final int width = targetImage.width;
    final int height = targetImage.height;
    final int r = radius.ceil();
    final double safeHardness = hardness.clamp(0.0, 0.98);
    final img.Pixel sourceCenterPixel = sourceImage.getPixel(
      sourceCenter.dx.round().clamp(0, sourceImage.width - 1),
      sourceCenter.dy.round().clamp(0, sourceImage.height - 1),
    );
    final img.Pixel targetCenterPixel = targetImage.getPixel(
      targetCenter.dx.round().clamp(0, width - 1),
      targetCenter.dy.round().clamp(0, height - 1),
    );
    final double sourceLuma = 0.299 * sourceCenterPixel.r +
        0.587 * sourceCenterPixel.g +
        0.114 * sourceCenterPixel.b;
    final double targetLuma = 0.299 * targetCenterPixel.r +
        0.587 * targetCenterPixel.g +
        0.114 * targetCenterPixel.b;
    final double lumaDelta =
        ((targetLuma - sourceLuma) * 0.12).clamp(-12.0, 12.0);

    for (int y = -r; y <= r; y++) {
      for (int x = -r; x <= r; x++) {
        final double dx = x.toDouble();
        final double dy = y.toDouble();
        final double distance = math.sqrt(dx * dx + dy * dy);
        if (distance > radius) continue;

        final double tx = targetCenter.dx + dx;
        final double ty = targetCenter.dy + dy;
        final double sx = sourceCenter.dx + dx;
        final double sy = sourceCenter.dy + dy;

        if (!_insideBounds(tx, ty, width, height)) continue;
        if (!_insideBounds(sx, sy, width, height)) continue;

        final int targetX = tx.round();
        final int targetY = ty.round();

        final img.Pixel dst = targetImage.getPixel(targetX, targetY);
        final _Rgb src = _sampleBilinear(sourceImage, sx, sy);
        final _Rgb corrected = _Rgb(
          (src.r + lumaDelta).clamp(0.0, 255.0),
          (src.g + lumaDelta).clamp(0.0, 255.0),
          (src.b + lumaDelta).clamp(0.0, 255.0),
        );

        final double edge0 = radius * safeHardness;
        double feather;
        if (distance <= edge0) {
          feather = 1.0;
        } else {
          final double t =
              ((distance - edge0) / (radius - edge0)).clamp(0.0, 1.0);
          feather = 1.0 - _smoothstep(t);
        }
        final double alpha = (feather * opacity).clamp(0.0, 1.0);
        if (alpha <= 0.0) continue;

        final int outR = _lerp(dst.r.toDouble(), corrected.r, alpha);
        final int outG = _lerp(dst.g.toDouble(), corrected.g, alpha);
        final int outB = _lerp(dst.b.toDouble(), corrected.b, alpha);

        targetImage.setPixelRgba(
          targetX,
          targetY,
          outR,
          outG,
          outB,
          dst.a.toInt(),
        );
      }
    }
  }

  static _Rgb _sampleBilinear(img.Image image, double x, double y) {
    final int x0 = x.floor();
    final int y0 = y.floor();
    final int x1 = math.min(x0 + 1, image.width - 1);
    final int y1 = math.min(y0 + 1, image.height - 1);

    final double fx = x - x0;
    final double fy = y - y0;

    final img.Pixel p00 = image.getPixel(x0, y0);
    final img.Pixel p10 = image.getPixel(x1, y0);
    final img.Pixel p01 = image.getPixel(x0, y1);
    final img.Pixel p11 = image.getPixel(x1, y1);

    return _Rgb(
      _bilinear(p00.r.toDouble(), p10.r.toDouble(), p01.r.toDouble(),
          p11.r.toDouble(), fx, fy),
      _bilinear(p00.g.toDouble(), p10.g.toDouble(), p01.g.toDouble(),
          p11.g.toDouble(), fx, fy),
      _bilinear(p00.b.toDouble(), p10.b.toDouble(), p01.b.toDouble(),
          p11.b.toDouble(), fx, fy),
    );
  }

  static double _bilinear(
    double c00,
    double c10,
    double c01,
    double c11,
    double fx,
    double fy,
  ) {
    final double top = c00 + (c10 - c00) * fx;
    final double bottom = c01 + (c11 - c01) * fx;
    return top + (bottom - top) * fy;
  }

  static bool _insideBounds(double x, double y, int width, int height) {
    return x >= 0 && y >= 0 && x < width - 1 && y < height - 1;
  }

  static int _lerp(double a, double b, double t) {
    return (a + (b - a) * t).round().clamp(0, 255);
  }

  static double _smoothstep(double t) {
    return t * t * (3.0 - 2.0 * t);
  }
}

class _Rgb {
  final double r;
  final double g;
  final double b;

  const _Rgb(this.r, this.g, this.b);
}
