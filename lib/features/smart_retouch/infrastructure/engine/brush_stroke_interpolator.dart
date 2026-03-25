import 'dart:math' as math;
import 'package:flutter/material.dart';

class BrushStrokeInterpolator {
  /// Generates intermediate brush dabs between two points based on the brush size and spacing setting.
  /// Spacing is defined as a percentage of the brush size (e.g., 0.1 for 10% spacing).
  static List<Offset> interpolateStroke(Offset p1, Offset p2, double brushSize, double spacingRatio) {
    final List<Offset> interpolated = [];
    final double distance = (p1 - p2).distance;
    final double step = math.max(1.0, brushSize * math.max(0.01, spacingRatio)); // Minimum step 1 pixel

    if (distance <= step) {
      // Points are too close together to need interpolation beyond maybe the first depending on needs,
      // but usually we return the end point or nothing if it's already covered. 
      // Safe play: return p1 and p2.
      return [p1, p2];
    }

    final int numSteps = (distance / step).ceil();
    for (int i = 0; i <= numSteps; i++) {
      final double t = i / numSteps;
      final double dx = p1.dx + (p2.dx - p1.dx) * t;
      final double dy = p1.dy + (p2.dy - p1.dy) * t;
      interpolated.add(Offset(dx, dy));
    }

    return interpolated;
  }

  /// Refines a raw path of user touch inputs into a smooth continuous path with proper spacing.
  static List<Offset> smoothAndInterpolatePath(List<Offset> rawPoints, double brushSize, double spacingRatio) {
    if (rawPoints.isEmpty) return [];
    if (rawPoints.length == 1) return [rawPoints.first];

    final List<Offset> finalPath = [rawPoints.first];

    for (int i = 0; i < rawPoints.length - 1; i++) {
      final p1 = finalPath.last; // start from the last inserted point to avoid gaps
      final p2 = rawPoints[i + 1];
      
      final subPath = interpolateStroke(p1, p2, brushSize, spacingRatio);
      // skip the first point of subPath since it's already at finalPath.last
      if (subPath.length > 1) {
        finalPath.addAll(subPath.sublist(1));
      }
    }

    return finalPath;
  }
}
