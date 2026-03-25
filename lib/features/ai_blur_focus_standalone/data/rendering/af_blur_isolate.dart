import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../domain/models/af_blur_mode.dart';

Map<String, dynamic>? afRenderBlur(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final settings = Map<String, dynamic>.from(args['settings'] as Map);
  final maskJson = args['mask'] == null
      ? null
      : Map<String, dynamic>.from(args['mask'] as Map);
  final strokes = ((args['strokes'] as List?) ?? const [])
      .map((value) => Map<String, dynamic>.from(value as Map))
      .toList();
  final qualityName = args['quality'] as String;

  final src = img.decodeImage(bytes);
  if (src == null) {
    return null;
  }

  final quality = AfRenderQuality.values.firstWhere(
    (value) => value.name == qualityName,
    orElse: () => AfRenderQuality.previewIdle,
  );

  final maxDim = math.max(src.width, src.height).toDouble();
  final penalty = maxDim >= 3000 ? 0.72 : (maxDim >= 2200 ? 0.84 : 1.0);
  final scale = switch (quality) {
    AfRenderQuality.track => (0.12 * penalty).clamp(0.08, 0.34),
    AfRenderQuality.previewIdle => (0.28 * penalty).clamp(0.12, 0.42),
    AfRenderQuality.export => 1.0,
  };

  final working = scale >= 0.999
      ? src
      : img.copyResize(
          src,
          width: math.max(96, (src.width * scale).round()),
          interpolation: quality == AfRenderQuality.track
              ? img.Interpolation.linear
              : img.Interpolation.cubic,
        );

  final mask = _buildMask(
    width: working.width,
    height: working.height,
    settings: settings,
    maskJson: maskJson,
    strokes: strokes,
    srcW: src.width,
    srcH: src.height,
  );

  final blurAmount = (settings['blurAmount'] as num).toDouble();
  final mildRadius = quality == AfRenderQuality.track
      ? math.max(1, (blurAmount / 5.8).round())
      : math.max(1, (blurAmount / 4.2).round());
  final mediumRadius = quality == AfRenderQuality.track
      ? math.max(2, (blurAmount / 4.2).round())
      : math.max(2, (blurAmount / 3.0).round());
  final strongRadius = quality == AfRenderQuality.export
      ? math.max(4, (blurAmount * 1.08).round())
      : math.max(3, (blurAmount / 2.1).round());

  final medium =
      img.gaussianBlur(img.Image.from(working), radius: mediumRadius);
  final mild = quality == AfRenderQuality.track
      ? medium
      : img.gaussianBlur(img.Image.from(working), radius: mildRadius);
  final strong = quality == AfRenderQuality.track
      ? medium
      : img.gaussianBlur(img.Image.from(working), radius: strongRadius);
  final boosted = quality == AfRenderQuality.export
      ? _focusBoost(working, (settings['focusBoost'] as num).toDouble())
      : working;

  final result =
      img.Image(width: working.width, height: working.height, numChannels: 4);
  final invert = settings['invertMask'] == true;
  final depthFalloff =
      (settings['depthFalloff'] as num).toDouble().clamp(0.0, 1.0);
  final exposure = (settings['previewExposure'] as num).toDouble();

  for (var y = 0; y < working.height; y++) {
    for (var x = 0; x < working.width; x++) {
      var focus = mask[y * working.width + x].clamp(0.0, 1.0);
      if (invert) {
        focus = 1.0 - focus;
      }

      final blurMix =
          _hermite((1.0 - focus).clamp(0.0, 1.0), 1.0 + depthFalloff);
      final mildPixel = mild.getPixel(x, y);
      final mediumPixel = medium.getPixel(x, y);
      final strongPixel = strong.getPixel(x, y);
      final boostedPixel = boosted.getPixel(x, y);

      final stage1 = _mix(mildPixel, mediumPixel, blurMix);
      final stage2 =
          _mix(stage1, strongPixel, (blurMix * 0.96).clamp(0.0, 1.0));
      var color = _mix(stage2, boostedPixel, focus);

      if (exposure.abs() > 0.001) {
        final adjustment = (exposure * 24).round();
        color = img.ColorRgba8(
          _ch(color.r.round() + adjustment),
          _ch(color.g.round() + adjustment),
          _ch(color.b.round() + adjustment),
          255,
        );
      }

      result.setPixelRgba(
        x,
        y,
        color.r.round(),
        color.g.round(),
        color.b.round(),
        255,
      );
    }
  }

  final Uint8List encoded;
  if (quality == AfRenderQuality.export) {
    encoded = Uint8List.fromList(img.encodePng(result, level: 3));
  } else {
    encoded = Uint8List.fromList(
      img.encodeJpg(result,
          quality: quality == AfRenderQuality.track ? 74 : 86),
    );
  }

  return {
    'bytes': encoded,
    'width': result.width,
    'height': result.height,
  };
}

List<double> _buildMask({
  required int width,
  required int height,
  required Map<String, dynamic> settings,
  required Map<String, dynamic>? maskJson,
  required List<Map<String, dynamic>> strokes,
  required int srcW,
  required int srcH,
}) {
  final mask = List<double>.filled(width * height, 0.0);
  final mode = AfBlurMode.values.firstWhere(
    (value) => value.name == settings['mode'],
    orElse: () => AfBlurMode.smart,
  );

  switch (mode) {
    case AfBlurMode.smart:
      _smartMask(mask, width, height, maskJson, strokes, settings, srcW, srcH);
    case AfBlurMode.circle:
      _circleMask(mask, width, height,
          Map<String, dynamic>.from(settings['circleSettings'] as Map));
    case AfBlurMode.line:
      _lineMask(mask, width, height,
          Map<String, dynamic>.from(settings['lineSettings'] as Map));
  }

  return mask;
}

void _smartMask(
  List<double> mask,
  int width,
  int height,
  Map<String, dynamic>? maskJson,
  List<Map<String, dynamic>> strokes,
  Map<String, dynamic> settings,
  int srcW,
  int srcH,
) {
  if (maskJson == null || maskJson['usedFallback'] == true) {
    for (var i = 0; i < mask.length; i++) {
      mask[i] = 1.0;
    }
    return;
  }

  final source = ((maskJson['confidenceMask'] as List?) ?? const [])
      .map((value) => (value as num).toDouble())
      .toList();
  final sourceWidth = maskJson['width'] as int? ?? srcW;
  final sourceHeight = maskJson['height'] as int? ?? srcH;
  if (source.isEmpty) {
    for (var i = 0; i < mask.length; i++) {
      mask[i] = 1.0;
    }
    return;
  }

  final transition =
      (settings['transitionAmount'] as num).toDouble().clamp(0.05, 1.0);
  final protection =
      (settings['subjectProtection'] as num).toDouble().clamp(0.0, 1.0);
  final edgeRefinement =
      (settings['edgeRefinement'] as num).toDouble().clamp(0.0, 1.0);
  final smart = Map<String, dynamic>.from(settings['smartSettings'] as Map);
  final antiHalo = (smart['antiHalo'] as num?)?.toDouble() ?? 0.5;
  final protectFace = smart['protectFace'] == true;
  final faceBounds = ((maskJson['faceBounds'] as List?) ?? const [])
      .map((value) => Map<String, dynamic>.from(value as Map))
      .toList();

  for (var y = 0; y < height; y++) {
    final sy = ((y / height) * sourceHeight).floor().clamp(0, sourceHeight - 1);
    for (var x = 0; x < width; x++) {
      final sx = ((x / width) * sourceWidth).floor().clamp(0, sourceWidth - 1);
      var value = source[sy * sourceWidth + sx].clamp(0.0, 1.0);
      value = math.pow(value, 1.06 - edgeRefinement * 0.28).toDouble();
      final soft = _smoothstep(
        0.12 - transition * 0.05,
        0.24 - transition * 0.08,
        value,
      );
      var finalValue = math.max(value * protection, soft);

      if (protectFace && faceBounds.isNotEmpty) {
        final nx = x / width;
        final ny = y / height;
        for (final face in faceBounds) {
          final left = (face['left'] as num?)?.toDouble() ?? 0.0;
          final top = (face['top'] as num?)?.toDouble() ?? 0.0;
          final faceWidth = (face['width'] as num?)?.toDouble() ?? 0.0;
          final faceHeight = (face['height'] as num?)?.toDouble() ?? 0.0;
          if (nx >= left &&
              nx <= left + faceWidth &&
              ny >= top &&
              ny <= top + faceHeight) {
            finalValue = 1.0;
            break;
          }
        }
      }

      if (finalValue < 0.52) {
        finalValue *= 1.0 - antiHalo * 0.34;
      }
      mask[y * width + x] = finalValue.clamp(0.0, 1.0);
    }
  }

  _applyStrokes(mask, width, height, strokes);
}

void _circleMask(
    List<double> mask, int width, int height, Map<String, dynamic> circle) {
  final cx = (circle['centerX'] as num?)?.toDouble() ?? 0.5;
  final cy = (circle['centerY'] as num?)?.toDouble() ?? 0.45;
  final rx = (circle['radiusX'] as num?)?.toDouble() ?? 0.24;
  final ry = (circle['radiusY'] as num?)?.toDouble() ?? 0.24;
  final rotation = (circle['rotation'] as num?)?.toDouble() ?? 0.0;
  final cosR = math.cos(rotation);
  final sinR = math.sin(rotation);

  for (var y = 0; y < height; y++) {
    final ny = (y / height) - cy;
    for (var x = 0; x < width; x++) {
      final nx = (x / width) - cx;
      final rxv = nx * cosR + ny * sinR;
      final ryv = -nx * sinR + ny * cosR;
      final n = math.sqrt(
        math.pow(rxv / math.max(rx, 0.001), 2) +
            math.pow(ryv / math.max(ry, 0.001), 2),
      );
      mask[y * width + x] = math.pow(_smoothstep(1.2, 0.8, n), 1.2).toDouble();
    }
  }
}

void _lineMask(
    List<double> mask, int width, int height, Map<String, dynamic> line) {
  final cx = (line['centerX'] as num?)?.toDouble() ?? 0.5;
  final cy = (line['centerY'] as num?)?.toDouble() ?? 0.5;
  final angle = (line['angle'] as num?)?.toDouble() ?? 0.0;
  final band = (line['width'] as num?)?.toDouble() ?? 0.22;
  final transition = (line['transition'] as num?)?.toDouble() ?? 0.18;
  final sinA = math.sin(angle);
  final cosA = math.cos(angle);

  for (var y = 0; y < height; y++) {
    final ny = (y / height) - cy;
    for (var x = 0; x < width; x++) {
      final nx = (x / width) - cx;
      final distance = ((-nx * sinA) + (ny * cosA)).abs();
      mask[y * width + x] = math
          .pow(_smoothstep(band + transition, band, distance), 1.1)
          .toDouble();
    }
  }
}

void _applyStrokes(List<double> mask, int width, int height,
    List<Map<String, dynamic>> strokes) {
  for (final stroke in strokes) {
    final add = stroke['add'] as bool? ?? true;
    final radius = (stroke['radius'] as num?)?.toDouble() ?? 0.055;
    final hardness = (stroke['hardness'] as num?)?.toDouble() ?? 0.85;
    final points = ((stroke['points'] as List?) ?? const [])
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();

    for (final point in points) {
      final centerX = ((point['x'] as num?)?.toDouble() ?? 0.0) * width;
      final centerY = ((point['y'] as num?)?.toDouble() ?? 0.0) * height;
      final radiusPx = radius * math.min(width, height);
      final hardnessRadius = radiusPx * hardness;
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
          final t = distance <= hardnessRadius
              ? 1.0
              : _smoothstep(radiusPx, hardnessRadius, distance);
          final index = y * width + x;
          final target = add ? 1.0 : 0.0;
          mask[index] =
              ((mask[index] * (1 - t)) + (target * t)).clamp(0.0, 1.0);
        }
      }
    }
  }
}

img.Image _focusBoost(img.Image source, double amount) {
  final boost = amount.clamp(0.0, 0.4);
  if (boost <= 0.001) {
    return source;
  }
  final blurred = img.gaussianBlur(img.Image.from(source), radius: 3);
  final result =
      img.Image(width: source.width, height: source.height, numChannels: 4);
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final original = source.getPixel(x, y);
      final smooth = blurred.getPixel(x, y);
      final factor = boost * 2.4;
      result.setPixelRgba(
        x,
        y,
        _ch((original.r + (original.r - smooth.r) * factor).round()),
        _ch((original.g + (original.g - smooth.g) * factor).round()),
        _ch((original.b + (original.b - smooth.b) * factor).round()),
        255,
      );
    }
  }
  return result;
}

double _smoothstep(double edge0, double edge1, double x) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

double _hermite(double t, double exponent) {
  return math.pow(t * t * (3.0 - 2.0 * t), exponent).toDouble();
}

img.Color _mix(img.Color a, img.Color b, double t) {
  final c = t.clamp(0.0, 1.0);
  return img.ColorRgba8(
    _ch((a.r + (b.r - a.r) * c).round()),
    _ch((a.g + (b.g - a.g) * c).round()),
    _ch((a.b + (b.b - a.b) * c).round()),
    255,
  );
}

int _ch(int value) => value.clamp(0, 255);
