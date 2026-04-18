import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../domain/entities/blur_mode.dart';
import '../../domain/entities/blur_style.dart';

Map<String, dynamic>? bpRenderBlur(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final settingsJson = Map<String, dynamic>.from(args['settings'] as Map);
  final maskJson = args['mask'] == null
      ? null
      : Map<String, dynamic>.from(args['mask'] as Map);
  final qualityName = args['quality'] as String;

  final src = img.decodeImage(bytes);
  if (src == null) return null;

  final quality = BpRenderQuality.values.firstWhere(
    (q) => q.name == qualityName,
    orElse: () => BpRenderQuality.previewIdle,
  );
  final mode = BlurPhotoMode.values.firstWhere(
    (m) => m.name == settingsJson['mode'],
    orElse: () => BlurPhotoMode.full,
  );
  final style = BlurPhotoStyle.values.firstWhere(
    (s) => s.name == settingsJson['style'],
    orElse: () => BlurPhotoStyle.soft,
  );

  final maxDim = math.max(src.width, src.height).toDouble();
  final penalty = maxDim >= 3000
      ? 0.72
      : maxDim >= 2200
          ? 0.84
          : 1.0;
  final trackScaleBase =
      (mode == BlurPhotoMode.circle || mode == BlurPhotoMode.line)
          ? 0.09
          : 0.15;
  final scale = switch (quality) {
    BpRenderQuality.track => (trackScaleBase * penalty).clamp(0.08, 0.28),
    BpRenderQuality.previewIdle => (0.28 * penalty).clamp(0.16, 0.38),
    BpRenderQuality.export => (1500.0 / maxDim).clamp(0.2, 1.0),
  };

  final working = scale >= 0.999
      ? src
      : img.copyResize(
          src,
          width: math.max(96, (src.width * scale).round()),
          interpolation: quality == BpRenderQuality.track
              ? img.Interpolation.linear
              : img.Interpolation.cubic,
        );

  final focusMask = _buildFocusMask(
    width: working.width,
    height: working.height,
    settings: settingsJson,
    maskJson: maskJson,
    srcW: src.width,
    srcH: src.height,
  );

  final blurAmt = (settingsJson['blurIntensity'] as num).toDouble();
  final styleConfig = _styleConfigFor(style);

  final strongRBase = quality == BpRenderQuality.export
      ? math.max(5, (blurAmt * 1.15).round())
      : quality == BpRenderQuality.previewIdle
          ? math.max(3, (blurAmt * 0.66).round())
          : math.max(
              2,
              ((mode == BlurPhotoMode.circle || mode == BlurPhotoMode.line)
                      ? blurAmt * 0.28
                      : blurAmt * 0.38)
                  .round(),
            );
  final strongR =
      math.max(2, (strongRBase * styleConfig.radiusMultiplier).round());

  final blurredImg = img.gaussianBlur(img.Image.from(working), radius: strongR);
  final secondaryBlur = styleConfig.secondaryBlurRadius > 0
      ? img.gaussianBlur(
          img.Image.from(working),
          radius: math.max(
            1,
            (strongR * styleConfig.secondaryBlurRadius).round(),
          ),
        )
      : null;

  final result =
      img.Image(width: working.width, height: working.height, numChannels: 4);

  for (var y = 0; y < working.height; y++) {
    for (var x = 0; x < working.width; x++) {
      final idx = y * working.width + x;
      final focus = focusMask[idx];
      final sharpWeight = _sharpWeight(focus);

      final sharpPx = working.getPixel(x, y);
      final blurPx = blurredImg.getPixel(x, y);

      var blurR = blurPx.r.toDouble();
      var blurG = blurPx.g.toDouble();
      var blurB = blurPx.b.toDouble();

      if (secondaryBlur != null) {
        final extraPx = secondaryBlur.getPixel(x, y);
        blurR = _mix(blurR, extraPx.r.toDouble(), styleConfig.secondaryMix);
        blurG = _mix(blurG, extraPx.g.toDouble(), styleConfig.secondaryMix);
        blurB = _mix(blurB, extraPx.b.toDouble(), styleConfig.secondaryMix);
      }

      if (styleConfig.brightnessBoost != 0) {
        blurR = (blurR + 255 * styleConfig.brightnessBoost).clamp(0, 255);
        blurG = (blurG + 255 * styleConfig.brightnessBoost).clamp(0, 255);
        blurB = (blurB + 255 * styleConfig.brightnessBoost).clamp(0, 255);
      }

      if (style == BlurPhotoStyle.motion) {
        final offsetX =
            (x + strongR * 0.35).round().clamp(0, working.width - 1);
        final motionPx = blurredImg.getPixel(offsetX, y);
        blurR = _mix(blurR, motionPx.r.toDouble(), 0.45);
        blurG = _mix(blurG, motionPx.g.toDouble(), 0.45);
        blurB = _mix(blurB, motionPx.b.toDouble(), 0.45);
      }

      if (style == BlurPhotoStyle.spotlight) {
        final dx = (x / working.width) - 0.5;
        final dy = (y / working.height) - 0.5;
        final vignette =
            1.0 - (math.sqrt(dx * dx + dy * dy) * 1.15).clamp(0.0, 0.35);
        blurR *= vignette;
        blurG *= vignette;
        blurB *= vignette;
      }

      final r =
          _ch((sharpPx.r * sharpWeight + blurR * (1 - sharpWeight)).round());
      final g =
          _ch((sharpPx.g * sharpWeight + blurG * (1 - sharpWeight)).round());
      final b =
          _ch((sharpPx.b * sharpWeight + blurB * (1 - sharpWeight)).round());

      result.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  final Uint8List encoded;
  if (quality == BpRenderQuality.export) {
    encoded = Uint8List.fromList(img.encodePng(result, level: 3));
  } else {
    encoded = Uint8List.fromList(
      img.encodeJpg(
        result,
        quality: quality == BpRenderQuality.track ? 72 : 86,
      ),
    );
  }

  return {
    'bytes': encoded,
    'width': result.width,
    'height': result.height,
  };
}

double _sharpWeight(double focus) {
  if (focus >= 0.50) return 1.0;
  if (focus <= 0.05) return 0.0;
  final t = (focus - 0.05) / (0.50 - 0.05);
  return t * t * (3.0 - 2.0 * t);
}

List<double> _buildFocusMask({
  required int width,
  required int height,
  required Map<String, dynamic> settings,
  required Map<String, dynamic>? maskJson,
  required int srcW,
  required int srcH,
}) {
  final mask = List<double>.filled(width * height, 0.0);
  final mode = BlurPhotoMode.values.firstWhere(
    (m) => m.name == settings['mode'],
    orElse: () => BlurPhotoMode.full,
  );
  switch (mode) {
    case BlurPhotoMode.full:
      break;
    case BlurPhotoMode.text:
      _textMask(mask, width, height, maskJson, srcW, srcH);
      break;
    case BlurPhotoMode.smart:
      _smartMask(mask, width, height, maskJson, settings, srcW, srcH);
      break;
    case BlurPhotoMode.circle:
      _circleMask(
        mask,
        width,
        height,
        Map<String, dynamic>.from(settings['circle'] as Map),
      );
      break;
    case BlurPhotoMode.line:
      _lineMask(
        mask,
        width,
        height,
        Map<String, dynamic>.from(settings['line'] as Map),
      );
      break;
  }
  return mask;
}

void _textMask(
  List<double> mask,
  int width,
  int height,
  Map<String, dynamic>? maskJson,
  int srcW,
  int srcH,
) {
  for (var i = 0; i < mask.length; i++) {
    mask[i] = 1.0;
  }

  final rawRegions = (maskJson?['regions'] as List?) ?? const [];
  if (rawRegions.isEmpty) {
    return;
  }

  final maskW = (maskJson?['width'] as int?) ?? srcW;
  final maskH = (maskJson?['height'] as int?) ?? srcH;

  for (final rawRegion in rawRegions) {
    final region = Map<String, dynamic>.from(rawRegion as Map);
    final left = ((region['left'] as num?)?.toDouble() ?? 0) / maskW;
    final top = ((region['top'] as num?)?.toDouble() ?? 0) / maskH;
    final right = ((region['right'] as num?)?.toDouble() ?? 0) / maskW;
    final bottom = ((region['bottom'] as num?)?.toDouble() ?? 0) / maskH;

    final featherX = math.max(0.006, (right - left) * 0.08);
    final featherY = math.max(0.008, (bottom - top) * 0.12);

    for (var y = 0; y < height; y++) {
      final ny = y / height;
      if (ny < top - featherY || ny > bottom + featherY) {
        continue;
      }

      for (var x = 0; x < width; x++) {
        final nx = x / width;
        if (nx < left - featherX || nx > right + featherX) {
          continue;
        }

        final dx = nx < left
            ? (left - nx) / featherX
            : nx > right
                ? (nx - right) / featherX
                : 0.0;
        final dy = ny < top
            ? (top - ny) / featherY
            : ny > bottom
                ? (ny - bottom) / featherY
                : 0.0;
        final edge = math.max(dx, dy).clamp(0.0, 1.0);
        final blurBand = edge == 0.0 ? 0.0 : _smoothstep(1.0, 0.0, edge);
        final focus = edge == 0.0 ? 0.0 : blurBand;
        final index = y * width + x;
        if (focus < mask[index]) {
          mask[index] = focus;
        }
      }
    }
  }
}

void _smartMask(
  List<double> mask,
  int width,
  int height,
  Map<String, dynamic>? maskJson,
  Map<String, dynamic> settings,
  int srcW,
  int srcH,
) {
  if (maskJson == null || maskJson['usedFallback'] == true) {
    const cx = 0.50;
    const cy = 0.48;
    const rX = 0.36;
    const rY = 0.48;
    for (var y = 0; y < height; y++) {
      final ny = (y / height) - cy;
      for (var x = 0; x < width; x++) {
        final nx = (x / width) - cx;
        final n = math.sqrt(
          math.pow(nx / rX, 2) + math.pow(ny / rY, 2),
        );
        mask[y * width + x] = _smoothstep(1.20, 0.60, n);
      }
    }
    return;
  }

  final confidence = ((maskJson['confidenceMask'] as List?) ?? const [])
      .map((v) => (v as num).toDouble())
      .toList();
  final srcMaskW = maskJson['width'] as int? ?? srcW;
  final srcMaskH = maskJson['height'] as int? ?? srcH;

  if (confidence.isEmpty ||
      srcMaskW <= 0 ||
      srcMaskH <= 0 ||
      confidence.length < (srcMaskW * srcMaskH)) {
    const cx = 0.50;
    const cy = 0.48;
    const rX = 0.36;
    const rY = 0.48;
    for (var y = 0; y < height; y++) {
      final ny = (y / height) - cy;
      for (var x = 0; x < width; x++) {
        final nx = (x / width) - cx;
        final n = math.sqrt(
          math.pow(nx / rX, 2) + math.pow(ny / rY, 2),
        );
        mask[y * width + x] = _smoothstep(1.20, 0.60, n);
      }
    }
    return;
  }

  const subjectThreshold = 0.30;
  const backgroundThreshold = 0.12;

  for (var y = 0; y < height; y++) {
    final sy = ((y / height) * srcMaskH).floor().clamp(0, srcMaskH - 1);
    for (var x = 0; x < width; x++) {
      final sx = ((x / width) * srcMaskW).floor().clamp(0, srcMaskW - 1);

      final c = confidence[sy * srcMaskW + sx].clamp(0.0, 1.0);

      final double focused;
      if (c >= subjectThreshold) {
        focused = 1.0;
      } else if (c <= backgroundThreshold) {
        focused = 0.0;
      } else {
        focused = _smoothstep(backgroundThreshold, subjectThreshold, c);
      }

      mask[y * width + x] = focused;
    }
  }
}

void _circleMask(
  List<double> mask,
  int width,
  int height,
  Map<String, dynamic> c,
) {
  final cx = (c['centerX'] as num?)?.toDouble() ?? 0.50;
  final cy = (c['centerY'] as num?)?.toDouble() ?? 0.45;
  final rx = (c['radiusX'] as num?)?.toDouble() ?? 0.24;
  final ry = (c['radiusY'] as num?)?.toDouble() ?? 0.24;
  final rot = (c['rotation'] as num?)?.toDouble() ?? 0.0;
  final feather = (c['feather'] as num?)?.toDouble() ?? 0.18;
  final shapeType = (c['shapeType'] as String?) ?? 'ellipse';
  final cosR = math.cos(rot);
  final sinR = math.sin(rot);

  for (var y = 0; y < height; y++) {
    final ny = (y / height) - cy;
    for (var x = 0; x < width; x++) {
      final nx = (x / width) - cx;
      final rxv = nx * cosR + ny * sinR;
      final ryv = -nx * sinR + ny * cosR;

      if (shapeType == 'rectangle') {
        final dx = rxv.abs() / math.max(rx, 0.001);
        final dy = ryv.abs() / math.max(ry, 0.001);
        final n = math.max(dx, dy);
        final outer = 1.0 + feather * 0.9;
        final inner = 1.0 - feather * 0.25;
        mask[y * width + x] = _smoothstep(outer, inner, n);
      } else {
        final n = math.sqrt(
          math.pow(rxv / math.max(rx, 0.001), 2) +
              math.pow(ryv / math.max(ry, 0.001), 2),
        );
        final outer = 1.0 + feather * 0.55;
        final inner = 1.0 - feather * 0.35;
        mask[y * width + x] = _smoothstep(outer, inner, n);
      }
    }
  }
}

void _lineMask(
  List<double> mask,
  int width,
  int height,
  Map<String, dynamic> l,
) {
  final cx = (l['centerX'] as num?)?.toDouble() ?? 0.50;
  final cy = (l['centerY'] as num?)?.toDouble() ?? 0.50;
  final angle = (l['angle'] as num?)?.toDouble() ?? 0.0;
  final band = (l['bandWidth'] as num?)?.toDouble() ?? 0.22;
  final feather = (l['feather'] as num?)?.toDouble() ?? 0.18;
  final sinA = math.sin(angle);
  final cosA = math.cos(angle);

  final protectedDepth = band * 0.35;
  final transitionEnd = protectedDepth + feather + 0.02;

  for (var y = 0; y < height; y++) {
    final ny = (y / height) - cy;
    for (var x = 0; x < width; x++) {
      final nx = (x / width) - cx;
      final signedDist = (-nx * sinA) + (ny * cosA);
      mask[y * width + x] = _smoothstep(
        transitionEnd,
        protectedDepth,
        signedDist,
      );
    }
  }
}

double _smoothstep(double edge0, double edge1, double x) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

int _ch(int v) => v.clamp(0, 255);

double _mix(double a, double b, double t) => a + ((b - a) * t);

_BlurStyleConfig _styleConfigFor(BlurPhotoStyle style) => switch (style) {
      BlurPhotoStyle.soft => const _BlurStyleConfig(),
      BlurPhotoStyle.frost => const _BlurStyleConfig(
          radiusMultiplier: 1.1,
          brightnessBoost: 0.06,
          secondaryBlurRadius: 0.6,
          secondaryMix: 0.35,
        ),
      BlurPhotoStyle.motion => const _BlurStyleConfig(
          radiusMultiplier: 1.22,
          secondaryBlurRadius: 0.35,
          secondaryMix: 0.28,
        ),
      BlurPhotoStyle.crystal => const _BlurStyleConfig(
          radiusMultiplier: 0.86,
          secondaryBlurRadius: 0.45,
          secondaryMix: 0.14,
        ),
      BlurPhotoStyle.spotlight => const _BlurStyleConfig(
          radiusMultiplier: 1.0,
          brightnessBoost: -0.05,
        ),
    };

class _BlurStyleConfig {
  const _BlurStyleConfig({
    this.radiusMultiplier = 1.0,
    this.brightnessBoost = 0.0,
    this.secondaryBlurRadius = 0.0,
    this.secondaryMix = 0.0,
  });

  final double radiusMultiplier;
  final double brightnessBoost;
  final double secondaryBlurRadius;
  final double secondaryMix;
}
