import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:untitled2/vv/brush_settings.dart';
import 'package:untitled2/vv/mask_data.dart';

/// Converts brush stroke data into [MaskData] objects.
///
/// Supports:
///  - Single-tap circular dabs
///  - Drag strokes with dab spacing interpolation
///  - Touch smoothing via Catmull-Rom path interpolation
///  - Mask merging for multi-dab operations
class MaskGenerationService {
  /// Generate a mask for a list of stroke points (from a drag gesture).
  /// Points are assumed to be in image coordinate space.
  MaskData generateStrokeMask({
    required List<Offset> strokePoints,
    required BrushSettings brush,
    required int imageWidth,
    required int imageHeight,
  }) {
    assert(strokePoints.isNotEmpty);

    // Compute the bounding box for all dab positions.
    final allDabPositions = _computeDabPositions(strokePoints, brush);
    final bounds =
        _computeMaskBounds(allDabPositions, brush, imageWidth, imageHeight);

    if (bounds.isEmpty) return MaskData.empty(1, 1, MaskBounds.zero);

    final maskW = bounds.width;
    final maskH = bounds.height;
    final pixels = Float32List(maskW * maskH);

    for (final dabPos in allDabPositions) {
      _stampDab(
        pixels: pixels,
        maskWidth: maskW,
        maskHeight: maskH,
        maskOriginX: bounds.left,
        maskOriginY: bounds.top,
        dabX: dabPos.dx,
        dabY: dabPos.dy,
        radius: brush.radius,
        softness: brush.softness,
      );
    }

    return MaskData(
      width: maskW,
      height: maskH,
      pixels: pixels,
      bounds: bounds,
    );
  }

  /// Generate a single spot-heal mask for a tap gesture.
  MaskData generateSpotMask({
    required Offset tapPosition,
    required BrushSettings brush,
    required int imageWidth,
    required int imageHeight,
  }) {
    return generateStrokeMask(
      strokePoints: [tapPosition],
      brush: brush,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  /// Merge multiple masks from a session into a single combined mask.
  /// All masks are composited using max-alpha blending.
  MaskData mergeMasks(List<MaskData> masks, int imageWidth, int imageHeight) {
    if (masks.isEmpty) {
      return MaskData.empty(imageWidth, imageHeight, MaskBounds.zero);
    }
    if (masks.length == 1) return masks.first;

    // Compute the union bounding box.
    int minL = imageWidth, minT = imageHeight, maxR = 0, maxB = 0;
    for (final m in masks) {
      if (m.bounds.left < minL) minL = m.bounds.left;
      if (m.bounds.top < minT) minT = m.bounds.top;
      if (m.bounds.right > maxR) maxR = m.bounds.right;
      if (m.bounds.bottom > maxB) maxB = m.bounds.bottom;
    }

    final unionBounds =
        MaskBounds(left: minL, top: minT, right: maxR, bottom: maxB)
            .clampTo(imageWidth, imageHeight);

    final mergedPixels = Float32List(unionBounds.width * unionBounds.height);

    for (final mask in masks) {
      for (int my = 0; my < mask.height; my++) {
        for (int mx = 0; mx < mask.width; mx++) {
          final val = mask.valueAt(mx, my);
          if (val < 0.001) continue;
          final imgX = mask.bounds.left + mx;
          final imgY = mask.bounds.top + my;
          final localX = imgX - unionBounds.left;
          final localY = imgY - unionBounds.top;
          if (localX < 0 ||
              localY < 0 ||
              localX >= unionBounds.width ||
              localY >= unionBounds.height) {
            continue;
          }
          final idx = localY * unionBounds.width + localX;
          if (val > mergedPixels[idx]) mergedPixels[idx] = val;
        }
      }
    }

    return MaskData(
      width: unionBounds.width,
      height: unionBounds.height,
      pixels: mergedPixels,
      bounds: unionBounds,
    );
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  /// Compute dab positions along the stroke path using spacing.
  /// Uses Catmull-Rom interpolation when ≥4 points are available for smoothing.
  List<Offset> _computeDabPositions(
      List<Offset> rawPoints, BrushSettings brush) {
    if (rawPoints.length == 1) return [rawPoints.first];

    // Smooth the path using Catmull-Rom interpolation.
    final segmentsPerSpan = brush.radius <= 18
        ? 14
        : brush.radius <= 36
            ? 10
            : 8;
    final smoothed =
        _catmullRomPath(rawPoints, segmentsPerSpan: segmentsPerSpan);
    final spacing = math.max(0.75, brush.spacing * brush.radius * 2.0);
    if (spacing < 1.0) return smoothed;

    final dabs = <Offset>[smoothed.first];
    double accumulated = 0.0;

    for (int i = 1; i < smoothed.length; i++) {
      final prev = smoothed[i - 1];
      final curr = smoothed[i];
      final segLen = (curr - prev).distance;
      accumulated += segLen;

      while (accumulated >= spacing) {
        accumulated -= spacing;
        // Interpolate back along segment to place dab at exact spacing interval.
        final t = 1.0 - (accumulated / segLen).clamp(0.0, 1.0);
        dabs.add(Offset.lerp(prev, curr, t)!);
      }
    }

    if (dabs.isEmpty || (dabs.last - smoothed.last).distance > spacing * 0.5) {
      dabs.add(smoothed.last);
    }

    return dabs;
  }

  /// Catmull-Rom spline interpolation to smooth raw touch points.
  List<Offset> _catmullRomPath(List<Offset> pts, {int segmentsPerSpan = 8}) {
    if (pts.length < 2) return pts;
    if (pts.length == 2) {
      return [pts.first, pts.last];
    }

    final result = <Offset>[];
    // Pad endpoints.
    final extended = [pts.first, ...pts, pts.last];

    for (int i = 1; i < extended.length - 2; i++) {
      final p0 = extended[i - 1];
      final p1 = extended[i];
      final p2 = extended[i + 1];
      final p3 = extended[i + 2];

      for (int s = 0; s <= segmentsPerSpan; s++) {
        final t = s / segmentsPerSpan;
        final t2 = t * t;
        final t3 = t2 * t;

        final x = 0.5 *
            ((2 * p1.dx) +
                (-p0.dx + p2.dx) * t +
                (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
                (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);
        final y = 0.5 *
            ((2 * p1.dy) +
                (-p0.dy + p2.dy) * t +
                (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
                (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

        result.add(Offset(x, y));
      }
    }

    return result;
  }

  void _stampDab({
    required Float32List pixels,
    required int maskWidth,
    required int maskHeight,
    required int maskOriginX,
    required int maskOriginY,
    required double dabX,
    required double dabY,
    required double radius,
    required double softness,
  }) {
    final iRadius = radius.ceil() + 1;
    final hardRadius = radius * (1.0 - softness.clamp(0.0, 0.99));

    for (int py = -iRadius; py <= iRadius; py++) {
      for (int px = -iRadius; px <= iRadius; px++) {
        final worldX = (dabX + px).floor();
        final worldY = (dabY + py).floor();
        final localX = worldX - maskOriginX;
        final localY = worldY - maskOriginY;
        if (localX < 0 ||
            localY < 0 ||
            localX >= maskWidth ||
            localY >= maskHeight) {
          continue;
        }

        final dx = worldX + 0.5 - dabX;
        final dy = worldY + 0.5 - dabY;
        final dist = math.sqrt(dx * dx + dy * dy);

        double alpha;
        if (dist <= hardRadius) {
          alpha = 1.0;
        } else if (dist < radius) {
          final t = (dist - hardRadius) / (radius - hardRadius);
          alpha = 0.5 + 0.5 * math.cos(math.pi * t);
        } else {
          continue;
        }

        final idx = localY * maskWidth + localX;
        if (alpha > pixels[idx]) pixels[idx] = alpha;
      }
    }
  }

  MaskBounds _computeMaskBounds(
    List<Offset> dabPositions,
    BrushSettings brush,
    int imageWidth,
    int imageHeight,
  ) {
    if (dabPositions.isEmpty) return MaskBounds.zero;
    final r = brush.radius.ceil() + 1;
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in dabPositions) {
      if (p.dx - r < minX) minX = p.dx - r;
      if (p.dy - r < minY) minY = p.dy - r;
      if (p.dx + r > maxX) maxX = p.dx + r;
      if (p.dy + r > maxY) maxY = p.dy + r;
    }
    return MaskBounds(
      left: minX.floor(),
      top: minY.floor(),
      right: maxX.ceil(),
      bottom: maxY.ceil(),
    ).clampTo(imageWidth, imageHeight);
  }
}
