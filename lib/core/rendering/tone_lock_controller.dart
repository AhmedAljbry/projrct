/*
import 'package:flutter/material.dart';
import 'package:lama/core/utils/value_utils.dart';
import 'package:lama/features/architect_mode/domain/entities/material_region.dart';
import 'package:lama/features/tone_lock/domain/entities/tone_lock_state.dart';

class ToneLockController {
  const ToneLockController();

  Color apply({
    required Color original,
    required Color styled,
    required ToneLockState locks,
    required MaterialRegion material,
    required bool isSkin,
    required bool isNeutral,
    required double highlightMask,
    required double shadowMask,
  }) {
    var result = styled;
    if (locks.lockExposure) {
      final originalL = _luminance(original);
      final styledL = _luminance(result);
      final scale = originalL / (styledL == 0 ? 0.0001 : styledL);
      result = _scaleColor(result, scale);
    }
    if (locks.lockSkinTone && isSkin) {
      result = _blend(result, original, 0.44);
    }
    if (locks.lockWhites &&
        isNeutral &&
        HSLColor.fromColor(original).lightness > 0.7) {
      result = _blend(result, original, 0.52);
    }
    if (locks.lockShadows && shadowMask > 0.4) {
      result = _blend(result, original, 0.34);
    }
    if (locks.lockHighlights && highlightMask > 0.48) {
      result = _blend(result, original, 0.42);
    }
    if (locks.lockMaterialNeutrality && (material == MaterialRegion.concrete || material == MaterialRegion.paintedWall)) {
      result = _blend(result, original, 0.48);
    }
    if (locks.lockGlassReflectance && material == MaterialRegion.glass) {
      result = _blend(result, original, 0.38);
    }
    if (locks.lockConcreteNeutrality && material == MaterialRegion.concrete) {
      result = _blend(result, original, 0.52);
    }
    return result;
  }

  double _luminance(Color color) =>
      (0.2126 * color.r) + (0.7152 * color.g) + (0.0722 * color.b);

  Color _blend(Color a, Color b, double t) => Color.from(
        alpha: lerpDoubleSafe(a.a, b.a, t),
        red: lerpDoubleSafe(a.r, b.r, t),
        green: lerpDoubleSafe(a.g, b.g, t),
        blue: lerpDoubleSafe(a.b, b.b, t),
      );

  Color _scaleColor(Color color, double scale) => Color.from(
        alpha: color.a,
        red: clampUnit(color.r * scale),
        green: clampUnit(color.g * scale),
        blue: clampUnit(color.b * scale),
      );
}
*/
