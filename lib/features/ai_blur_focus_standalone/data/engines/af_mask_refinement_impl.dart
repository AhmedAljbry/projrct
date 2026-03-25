import 'dart:math' as math;

import '../../domain/models/af_blur_settings.dart';
import '../../domain/models/af_focus_geometry.dart';
import '../../domain/models/af_mask_data.dart';
import '../../domain/services/af_mask_refiner.dart';

class AfMaskRefinementImpl implements AfMaskRefiner {
  static const _kernel = [0.0625, 0.25, 0.375, 0.25, 0.0625];

  @override
  AfMaskData refine({
    required AfMaskData mask,
    required AfBlurSettings settings,
    required List manualStrokes,
  }) {
    if (mask.confidenceMask.isEmpty) {
      return mask;
    }

    final refined = List<double>.from(mask.confidenceMask);
    final passes = 1 + (settings.edgeRefinement * 2).round();
    _smooth(refined, mask.width, mask.height, passes: passes);
    _fillHoles(
      refined,
      mask.width,
      mask.height,
      threshold: 0.42 - (settings.smartSettings.holeFill * 0.18),
    );
    _applyProtection(
      refined,
      mask.width,
      mask.height,
      mask.primaryBounds,
      mask.faceBounds,
      settings,
    );

    for (final stroke in manualStrokes) {
      if (stroke is AfManualStroke) {
        _applyStroke(refined, mask.width, mask.height, stroke);
      }
    }

    _antiAlias(refined);

    return AfMaskData(
      width: mask.width,
      height: mask.height,
      confidenceMask: refined,
      primaryBounds: mask.primaryBounds,
      faceBounds: mask.faceBounds,
      usedFallback: mask.usedFallback,
    );
  }

  void _smooth(List<double> mask, int width, int height,
      {required int passes}) {
    final tmp = List<double>.filled(width * height, 0.0);
    for (var pass = 0; pass < passes; pass++) {
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          var sum = 0.0;
          for (var k = -2; k <= 2; k++) {
            sum +=
                mask[y * width + (x + k).clamp(0, width - 1)] * _kernel[k + 2];
          }
          tmp[y * width + x] = sum;
        }
      }
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          var sum = 0.0;
          for (var k = -2; k <= 2; k++) {
            sum +=
                tmp[(y + k).clamp(0, height - 1) * width + x] * _kernel[k + 2];
          }
          mask[y * width + x] = sum;
        }
      }
    }
  }

  void _fillHoles(List<double> mask, int width, int height,
      {required double threshold}) {
    final copy = List<double>.from(mask);
    for (var y = 2; y < height - 2; y++) {
      for (var x = 2; x < width - 2; x++) {
        final index = y * width + x;
        if (copy[index] > threshold) {
          continue;
        }
        var neighbors = 0;
        for (var ky = -2; ky <= 2; ky++) {
          for (var kx = -2; kx <= 2; kx++) {
            if (copy[(y + ky) * width + (x + kx)] > 0.60) {
              neighbors++;
            }
          }
        }
        if (neighbors >= 5) {
          mask[index] = 0.72;
        }
      }
    }
  }

  void _applyProtection(
    List<double> mask,
    int width,
    int height,
    AfSegmentationBounds? primaryBounds,
    List<AfSegmentationBounds> faceBounds,
    AfBlurSettings settings,
  ) {
    if (primaryBounds == null && faceBounds.isEmpty) {
      return;
    }

    final subjectStrength = settings.subjectProtection;
    final antiHalo = settings.smartSettings.antiHalo;
    final estimatedFace = primaryBounds == null
        ? null
        : AfSegmentationBounds(
            left: primaryBounds.left + primaryBounds.width * 0.28,
            top: primaryBounds.top + primaryBounds.height * 0.06,
            width: primaryBounds.width * 0.44,
            height: primaryBounds.height * 0.32,
          );

    for (var y = 0; y < height; y++) {
      final ny = y / height;
      for (var x = 0; x < width; x++) {
        final nx = x / width;
        final index = y * width + x;
        var value = mask[index];
        if (value <= 0.0) {
          continue;
        }

        if (primaryBounds != null &&
            nx >= primaryBounds.left &&
            nx <= primaryBounds.left + primaryBounds.width &&
            ny >= primaryBounds.top &&
            ny <= primaryBounds.top + primaryBounds.height) {
          value = math.max(value, 0.16 + subjectStrength * 0.14);
        }

        if (settings.smartSettings.protectFace) {
          var inFace = false;
          if (faceBounds.isNotEmpty) {
            for (final face in faceBounds) {
              if (nx >= face.left &&
                  nx <= face.left + face.width &&
                  ny >= face.top &&
                  ny <= face.top + face.height) {
                inFace = true;
                break;
              }
            }
          } else if (estimatedFace != null) {
            final dx = (nx - (estimatedFace.left + estimatedFace.width * 0.5)) /
                math.max(estimatedFace.width * 0.5, 0.001);
            final dy = (ny - (estimatedFace.top + estimatedFace.height * 0.5)) /
                math.max(estimatedFace.height * 0.5, 0.001);
            inFace = (dx * dx + dy * dy) < 1.0;
          }
          if (inFace) {
            value = 1.0;
          }
        }

        if (value < 0.52) {
          value *= 1.0 - (antiHalo * 0.38);
        }

        mask[index] = value.clamp(0.0, 1.0);
      }
    }
  }

  void _applyStroke(
      List<double> mask, int width, int height, AfManualStroke stroke) {
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
          final target = stroke.add ? 1.0 : 0.0;
          mask[index] = ((mask[index] * (1 - influence)) + (target * influence))
              .clamp(0.0, 1.0);
        }
      }
    }
  }

  void _antiAlias(List<double> mask) {
    for (var i = 0; i < mask.length; i++) {
      final value = mask[i];
      if (value > 0.24 && value < 0.76) {
        mask[i] = _smoothstep(0.24, 0.76, value);
      }
    }
  }

  double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }
}
