import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:untitled2/features/blur_focus/domain/models/blur_mode.dart';

Map<String, dynamic>? renderBlurFocus(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final settings = Map<String, dynamic>.from(args['settings'] as Map);
  final segmentation = args['segmentation'] == null
      ? null
      : Map<String, dynamic>.from(args['segmentation'] as Map);
  final strokes = ((args['manualStrokes'] as List?) ?? const [])
      .map((value) => Map<String, dynamic>.from(value as Map))
      .toList();
  final qualityName = args['quality'] as String;

  final original = img.decodeImage(bytes);
  if (original == null) {
    return null;
  }

  final quality = BlurQuality.values.firstWhere(
    (value) => value.name == qualityName,
    orElse: () => BlurQuality.previewIdle,
  );

  final maxDim = math.max(original.width, original.height).toDouble();
  final sizePenalty = maxDim >= 3000 ? 0.72 : (maxDim >= 2200 ? 0.84 : 1.0);
  final baseScale = switch (quality) {
    BlurQuality.previewTrack => 0.12,
    BlurQuality.previewIdle => 0.28,
    BlurQuality.export => 1.0,
  };
  final scale = quality == BlurQuality.export
      ? 1.0
      : (baseScale * sizePenalty).clamp(0.08, 0.38);

  var working = original;
  if (scale < 0.999) {
    working = img.copyResize(
      original,
      width: math.max(64, (original.width * scale).round()),
      interpolation: quality == BlurQuality.previewTrack
          ? img.Interpolation.linear
          : img.Interpolation.cubic,
    );
  }

  final mask = _buildFocusMask(
    width: working.width,
    height: working.height,
    settings: settings,
    segmentation: segmentation,
    strokes: strokes,
    sourceWidth: original.width,
    sourceHeight: original.height,
  );

  final blurAmount = (settings['blurAmount'] as num).toDouble();
  final mildRadius = quality == BlurQuality.previewTrack
      ? math.max(1, (blurAmount / 5.6).round())
      : math.max(1, (blurAmount / 4.0).round());
  final mediumRadius = quality == BlurQuality.previewTrack
      ? math.max(2, (blurAmount / 4.0).round())
      : math.max(2, (blurAmount / 2.8).round());
  final strongRadius = quality == BlurQuality.export
      ? math.max(4, (blurAmount * 1.12).round())
      : math.max(3, (blurAmount / 2.0).round());

  final mediumBlur =
      img.gaussianBlur(img.Image.from(working), radius: mediumRadius);
  final mildBlur = quality == BlurQuality.previewTrack
      ? mediumBlur
      : img.gaussianBlur(img.Image.from(working), radius: mildRadius);
  final strongBlur = quality == BlurQuality.previewTrack
      ? mediumBlur
      : img.gaussianBlur(img.Image.from(working), radius: strongRadius);

  final sharpened = quality == BlurQuality.export
      ? _applyFocusBoost(
          working,
          amount: (settings['focusBoost'] as num).toDouble(),
        )
      : working;

  final result = img.Image(
    width: working.width,
    height: working.height,
    numChannels: 4,
  );

  final depthFalloff =
      (settings['depthFalloff'] as num).toDouble().clamp(0.0, 1.0);
  final invertMask = settings['invertMask'] == true;
  final exposure = (settings['previewExposure'] as num).toDouble();
  final smartSettings = settings['smartSettings'] == null
      ? const <String, dynamic>{}
      : Map<String, dynamic>.from(settings['smartSettings'] as Map);
  final smartFalloff =
      (smartSettings['falloffStrength'] as num?)?.toDouble() ?? 0.7;

  for (var y = 0; y < working.height; y++) {
    for (var x = 0; x < working.width; x++) {
      final index = y * working.width + x;
      var focus = mask[index].clamp(0.0, 1.0);
      if (invertMask) {
        focus = 1.0 - focus;
      }

      final rawMix = (1.0 - focus).clamp(0.0, 1.0);
      final extraFalloff =
          settings['mode'] == BlurMode.smart.name ? smartFalloff * 0.22 : 0.0;
      final blurMix = _cubicHermite(
        rawMix,
        exponent: 1.0 + depthFalloff + extraFalloff,
      );

      final mild = mildBlur.getPixel(x, y);
      final medium = mediumBlur.getPixel(x, y);
      final strong = strongBlur.getPixel(x, y);
      final boosted = sharpened.getPixel(x, y);

      final stage1 = _mixColor(mild, medium, blurMix);
      final stage2 =
          _mixColor(stage1, strong, (blurMix * 0.96).clamp(0.0, 1.0));

      var finalColor = _mixColor(stage2, boosted, focus);

      if (exposure.abs() > 0.001) {
        final adjustment = (exposure * 24).round();
        finalColor = img.ColorRgba8(
          _clampCh(finalColor.r.round() + adjustment),
          _clampCh(finalColor.g.round() + adjustment),
          _clampCh(finalColor.b.round() + adjustment),
          255,
        );
      }

      result.setPixelRgba(
        x,
        y,
        finalColor.r.round(),
        finalColor.g.round(),
        finalColor.b.round(),
        255,
      );
    }
  }

  final Uint8List encoded;
  if (quality == BlurQuality.export) {
    encoded = Uint8List.fromList(img.encodePng(result, level: 3));
  } else {
    encoded = Uint8List.fromList(
      img.encodeJpg(
        result,
        quality: quality == BlurQuality.previewTrack ? 74 : 86,
      ),
    );
  }

  return {
    'bytes': encoded,
    'width': result.width,
    'height': result.height,
    'isJpeg': quality != BlurQuality.export,
  };
}

double _cubicHermite(double t, {double exponent = 1.0}) {
  final smooth = t * t * (3.0 - 2.0 * t);
  return math.pow(smooth, exponent).toDouble();
}

List<double> _buildFocusMask({
  required int width,
  required int height,
  required Map<String, dynamic> settings,
  required Map<String, dynamic>? segmentation,
  required List<Map<String, dynamic>> strokes,
  required int sourceWidth,
  required int sourceHeight,
}) {
  final mask = List<double>.filled(width * height, 0.0);
  final mode = BlurMode.values.firstWhere(
    (value) => value.name == settings['mode'],
    orElse: () => BlurMode.smart,
  );

  switch (mode) {
    case BlurMode.smart:
      _buildSmartMask(
        mask,
        width,
        height,
        segmentation,
        strokes,
        settings,
        sourceWidth,
        sourceHeight,
      );
    case BlurMode.circle:
      _buildCircleMask(
        mask,
        width,
        height,
        Map<String, dynamic>.from(settings['circleSettings'] as Map),
      );
    case BlurMode.line:
      _buildLineMask(
        mask,
        width,
        height,
        Map<String, dynamic>.from(settings['lineSettings'] as Map),
      );
  }

  return mask;
}

void _buildSmartMask(
  List<double> mask,
  int width,
  int height,
  Map<String, dynamic>? segmentation,
  List<Map<String, dynamic>> strokes,
  Map<String, dynamic> settings,
  int sourceWidth,
  int sourceHeight,
) {
  if (segmentation == null) {
    _buildCircleMask(mask, width, height, const {
      'centerX': 0.5,
      'centerY': 0.42,
      'radiusX': 0.26,
      'radiusY': 0.34,
      'rotation': 0.0,
    });
    return;
  }

  final segWidth = segmentation['width'] as int? ?? sourceWidth;
  final segHeight = segmentation['height'] as int? ?? sourceHeight;
  final sourceMask = ((segmentation['confidenceMask'] as List?) ?? const [])
      .map((value) => (value as num).toDouble())
      .toList();
  final transition =
      (settings['transitionAmount'] as num).toDouble().clamp(0.05, 1.0);
  final protect =
      (settings['subjectProtection'] as num).toDouble().clamp(0.0, 1.0);
  final edge = (settings['edgeRefinement'] as num).toDouble().clamp(0.0, 1.0);
  final smartSettings =
      Map<String, dynamic>.from(settings['smartSettings'] as Map);
  final protectFace = smartSettings['protectFace'] == true;
  final antiHalo = (smartSettings['antiHalo'] as num?)?.toDouble() ?? 0.55;
  final contourCleanup =
      (smartSettings['contourCleanup'] as num?)?.toDouble() ?? 0.5;
  final falloffStrength =
      (smartSettings['falloffStrength'] as num?)?.toDouble() ?? 0.7;
  final primaryBounds = segmentation['primaryBounds'] == null
      ? null
      : Map<String, dynamic>.from(segmentation['primaryBounds'] as Map);
  final faceBounds = ((segmentation['faceBounds'] as List?) ?? const [])
      .map((value) => Map<String, dynamic>.from(value as Map))
      .toList();

  for (var y = 0; y < height; y++) {
    final sy = ((y / height) * segHeight).floor().clamp(0, segHeight - 1);
    for (var x = 0; x < width; x++) {
      final sx = ((x / width) * segWidth).floor().clamp(0, segWidth - 1);
      final si = sy * segWidth + sx;
      var value = si < sourceMask.length ? sourceMask[si] : 0.0;

      value = math
          .pow(
            value.clamp(0.0, 1.0),
            1.08 - (edge * 0.26) - (contourCleanup * 0.14),
          )
          .toDouble();

      final rampStart = 0.12 - (transition * 0.05);
      final rampEnd = rampStart +
          math.max(
            0.05,
            0.18 - (transition * 0.09) + ((1.0 - falloffStrength) * 0.05),
          );
      final softened = _smoothstep(rampStart, rampEnd, value);
      var finalValue = math.max(value * (protect + antiHalo * 0.06), softened);

      final nx = x / width;
      final ny = y / height;

      if (primaryBounds != null) {
        final left = ((primaryBounds['left'] as num?)?.toDouble() ?? 0.0) -
            (antiHalo * 0.015);
        final top = ((primaryBounds['top'] as num?)?.toDouble() ?? 0.0) -
            (antiHalo * 0.015);
        final right = left +
            (((primaryBounds['width'] as num?)?.toDouble() ?? 1.0) +
                antiHalo * 0.03);
        final bottom = top +
            (((primaryBounds['height'] as num?)?.toDouble() ?? 1.0) +
                antiHalo * 0.03);
        if (nx >= left && nx <= right && ny >= top && ny <= bottom) {
          finalValue = math.max(finalValue, 0.14 + (protect * 0.12));
        }
      }

      if (protectFace && faceBounds.isNotEmpty) {
        for (final face in faceBounds) {
          final left = (face['left'] as num?)?.toDouble() ?? 0.0;
          final top = (face['top'] as num?)?.toDouble() ?? 0.0;
          final faceWidth = (face['width'] as num?)?.toDouble() ?? 0.0;
          final faceHeight = (face['height'] as num?)?.toDouble() ?? 0.0;
          if (nx >= left &&
              nx <= (left + faceWidth) &&
              ny >= top &&
              ny <= (top + faceHeight)) {
            finalValue = 1.0;
            break;
          }
        }
      }

      mask[y * width + x] = math
          .pow(
            finalValue.clamp(0.0, 1.0),
            1.0 - (antiHalo * 0.16),
          )
          .toDouble();
    }
  }

  _applyStrokesToMask(mask, width, height, strokes);
}

void _buildCircleMask(
  List<double> mask,
  int width,
  int height,
  Map<String, dynamic> circle,
) {
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
      final rotX = (nx * cosR) + (ny * sinR);
      final rotY = (-nx * sinR) + (ny * cosR);
      final normalized = math.sqrt(
        math.pow(rotX / math.max(rx, 0.001), 2) +
            math.pow(rotY / math.max(ry, 0.001), 2),
      );
      mask[y * width + x] =
          math.pow(_smoothstep(1.2, 0.8, normalized), 1.2).toDouble();
    }
  }
}

void _buildLineMask(
  List<double> mask,
  int width,
  int height,
  Map<String, dynamic> line,
) {
  final cx = (line['centerX'] as num?)?.toDouble() ?? 0.5;
  final cy = (line['centerY'] as num?)?.toDouble() ?? 0.5;
  final angle = (line['angle'] as num?)?.toDouble() ?? 0.0;
  final bandWidth = (line['width'] as num?)?.toDouble() ?? 0.22;
  final transition = (line['transition'] as num?)?.toDouble() ?? 0.18;
  final sinR = math.sin(angle);
  final cosR = math.cos(angle);

  for (var y = 0; y < height; y++) {
    final ny = (y / height) - cy;
    for (var x = 0; x < width; x++) {
      final nx = (x / width) - cx;
      final distance = ((-nx * sinR) + (ny * cosR)).abs();
      mask[y * width + x] = math
          .pow(
            _smoothstep(bandWidth + transition, bandWidth, distance),
            1.1,
          )
          .toDouble();
    }
  }
}

void _applyStrokesToMask(
  List<double> mask,
  int width,
  int height,
  List<Map<String, dynamic>> strokes,
) {
  for (final stroke in strokes) {
    final blendMode = stroke['blendMode'] as String? ?? 'include';
    final radius = (stroke['radius'] as num?)?.toDouble() ?? 0.055;
    final hardness = (stroke['hardness'] as num?)?.toDouble() ?? 0.85;
    final points = ((stroke['points'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
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
          final target = blendMode == 'exclude' ? 0.0 : 1.0;
          mask[index] =
              ((mask[index] * (1 - t)) + (target * t)).clamp(0.0, 1.0);
        }
      }
    }
  }
}

img.Image _applyFocusBoost(img.Image source, {required double amount}) {
  final boost = amount.clamp(0.0, 0.4);
  if (boost <= 0.001) {
    return source;
  }

  final blurred = img.gaussianBlur(img.Image.from(source), radius: 3);
  final result = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final original = source.getPixel(x, y);
      final smooth = blurred.getPixel(x, y);
      final factor = boost * 2.4;
      result.setPixelRgba(
        x,
        y,
        _clampCh((original.r + (original.r - smooth.r) * factor).round()),
        _clampCh((original.g + (original.g - smooth.g) * factor).round()),
        _clampCh((original.b + (original.b - smooth.b) * factor).round()),
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

img.Color _mixColor(img.Color a, img.Color b, double t) {
  final c = t.clamp(0.0, 1.0);
  return img.ColorRgba8(
    _clampCh((a.r + (b.r - a.r) * c).round()),
    _clampCh((a.g + (b.g - a.g) * c).round()),
    _clampCh((a.b + (b.b - a.b) * c).round()),
    255,
  );
}

int _clampCh(int value) => value.clamp(0, 255);
