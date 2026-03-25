import 'dart:math' as math;

import 'package:untitled2/features/blur_focus/data/engines/focus_mask_refinement_engine.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_settings.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';

class FocusMaskRefinementEngineImpl implements FocusMaskRefinementEngine {
  static const List<double> _kernel = [0.0625, 0.25, 0.375, 0.25, 0.0625];

  @override
  SegmentationResultData refine({
    required SegmentationResultData segmentation,
    required BlurSettings settings,
    required List<ManualMaskStroke> manualStrokes,
  }) {
    final refined = List<double>.from(segmentation.confidenceMask);
    if (refined.isEmpty) {
      return segmentation;
    }

    final passes = 1 + (settings.edgeRefinement * 2).round();
    _smoothGaussian(
      refined,
      segmentation.width,
      segmentation.height,
      passes: passes,
    );

    _fillHoles(
      refined,
      segmentation.width,
      segmentation.height,
      threshold: 0.42 - (settings.smartSettings.holeFill * 0.18),
    );

    _applyProtection(
      refined,
      segmentation.width,
      segmentation.height,
      segmentation.primaryBounds,
      segmentation.faceBounds,
      settings,
    );

    _applyManualStrokes(
      refined,
      segmentation.width,
      segmentation.height,
      manualStrokes,
    );

    _antiAliasEdges(refined);

    return SegmentationResultData(
      width: segmentation.width,
      height: segmentation.height,
      confidenceMask: refined,
      primaryBounds: segmentation.primaryBounds,
      faceBounds: segmentation.faceBounds,
      usedFallback: segmentation.usedFallback,
      createdAt: DateTime.now(),
    );
  }

  void _smoothGaussian(
    List<double> mask,
    int width,
    int height, {
    required int passes,
  }) {
    final tmp = List<double>.filled(width * height, 0.0);
    for (var pass = 0; pass < passes; pass++) {
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          var sum = 0.0;
          for (var k = -2; k <= 2; k++) {
            final sx = (x + k).clamp(0, width - 1);
            sum += mask[y * width + sx] * _kernel[k + 2];
          }
          tmp[y * width + x] = sum;
        }
      }

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          var sum = 0.0;
          for (var k = -2; k <= 2; k++) {
            final sy = (y + k).clamp(0, height - 1);
            sum += tmp[sy * width + x] * _kernel[k + 2];
          }
          mask[y * width + x] = sum;
        }
      }
    }
  }

  void _fillHoles(
    List<double> mask,
    int width,
    int height, {
    required double threshold,
  }) {
    final copy = List<double>.from(mask);
    for (var y = 2; y < height - 2; y++) {
      for (var x = 2; x < width - 2; x++) {
        final index = y * width + x;
        if (copy[index] > threshold) {
          continue;
        }
        var filledNeighbors = 0;
        for (var ky = -2; ky <= 2; ky++) {
          for (var kx = -2; kx <= 2; kx++) {
            if (copy[(y + ky) * width + (x + kx)] > 0.60) {
              filledNeighbors++;
            }
          }
        }
        if (filledNeighbors >= 5) {
          mask[index] = 0.70;
        }
      }
    }
  }

  void _applyProtection(
    List<double> mask,
    int width,
    int height,
    SegmentationBounds? bounds,
    List<SegmentationBounds> faceBounds,
    BlurSettings settings,
  ) {
    if (bounds == null) {
      return;
    }

    final strength = settings.subjectProtection;
    final haloReduction = settings.smartSettings.antiHalo;

    final fallbackFaceCX = bounds.left + (bounds.width * 0.5);
    final fallbackFaceCY = bounds.top + (bounds.height * 0.22);
    final fallbackFaceRX = bounds.width * 0.22;
    final fallbackFaceRY = bounds.height * 0.16;

    for (var y = 0; y < height; y++) {
      final ny = y / height;
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        var value = mask[index];
        if (value <= 0) {
          continue;
        }
        final nx = x / width;

        if (settings.smartSettings.protectFace) {
          var inFace = false;
          if (faceBounds.isNotEmpty) {
            for (final face in faceBounds) {
              if (nx >= face.left &&
                  nx <= (face.left + face.width) &&
                  ny >= face.top &&
                  ny <= (face.top + face.height)) {
                inFace = true;
                break;
              }
            }
          } else {
            final dx = (nx - fallbackFaceCX) / math.max(fallbackFaceRX, 0.001);
            final dy = (ny - fallbackFaceCY) / math.max(fallbackFaceRY, 0.001);
            final faceDistance = math.sqrt(dx * dx + dy * dy);
            if (faceDistance < 1.0) {
              inFace = true;
            }
          }

          if (inFace) {
            value = math.max(value, 0.92 + (0.08 * strength));
          }
        }

        if (settings.smartSettings.protectHands) {
          final handBoost = _handProtection(nx, ny, bounds);
          value = math.max(value, handBoost * 0.7 * strength);
        }

        if (value < 0.52) {
          value *= 1.0 - (haloReduction * 0.38);
        }

        mask[index] = value.clamp(0.0, 1.0);
      }
    }
  }

  double _handProtection(double x, double y, SegmentationBounds bounds) {
    final leftHandX = bounds.left + (bounds.width * 0.12);
    final rightHandX = bounds.left + (bounds.width * 0.88);
    final handY = bounds.top + (bounds.height * 0.58);
    final left = _radial(x, y, leftHandX, handY, 0.12, 0.14);
    final right = _radial(x, y, rightHandX, handY, 0.12, 0.14);
    return math.max(left, right);
  }

  double _radial(
    double x,
    double y,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final dx = (x - cx) / rx;
    final dy = (y - cy) / ry;
    return (1.0 - math.sqrt(dx * dx + dy * dy)).clamp(0.0, 1.0);
  }

  void _applyManualStrokes(
    List<double> mask,
    int width,
    int height,
    List<ManualMaskStroke> manualStrokes,
  ) {
    for (final stroke in manualStrokes) {
      for (final point in stroke.points) {
        final radiusPx = stroke.radius * math.min(width, height);
        final innerRadius = radiusPx * stroke.hardness.clamp(0.05, 1.0);
        final centerX = point.x * width;
        final centerY = point.y * height;
        final minX = (centerX - radiusPx).floor().clamp(0, width - 1);
        final maxX = (centerX + radiusPx).ceil().clamp(0, width - 1);
        final minY = (centerY - radiusPx).floor().clamp(0, height - 1);
        final maxY = (centerY + radiusPx).ceil().clamp(0, height - 1);

        for (var y = minY; y <= maxY; y++) {
          for (var x = minX; x <= maxX; x++) {
            final dx = x - centerX;
            final dy = y - centerY;
            final distance = math.sqrt(dx * dx + dy * dy);
            if (distance > radiusPx) {
              continue;
            }
            final influence = distance <= innerRadius
                ? 1.0
                : _smoothstep(radiusPx, innerRadius, distance);
            final index = y * width + x;
            final target =
                stroke.blendMode == ManualMaskBlendMode.include ? 1.0 : 0.0;
            mask[index] =
                (mask[index] * (1 - influence)) + (target * influence);
          }
        }
      }
    }
  }

  void _antiAliasEdges(List<double> mask) {
    for (var i = 0; i < mask.length; i++) {
      final value = mask[i];
      if (value > 0.25 && value < 0.75) {
        mask[i] = _smoothstep(0.25, 0.75, value);
      }
    }
  }

  double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }
}
