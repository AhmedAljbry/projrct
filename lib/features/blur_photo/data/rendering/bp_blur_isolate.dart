import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../domain/entities/blur_mode.dart';

/// Top-level isolate entry point. Must be a free function — no closures.
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

  // ── Scale working copy ────────────────────────────────────────────────────
  final maxDim = math.max(src.width, src.height).toDouble();
  final penalty = maxDim >= 3000
      ? 0.72
      : maxDim >= 2200
          ? 0.84
          : 1.0;
  final trackScaleBase =
      (mode == BlurPhotoMode.circle || mode == BlurPhotoMode.line) ? 0.11 : 0.15;
  final scale = switch (quality) {
    BpRenderQuality.track => (trackScaleBase * penalty).clamp(0.08, 0.28),
    BpRenderQuality.previewIdle => (0.34 * penalty).clamp(0.18, 0.44),
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

  // ── Focus mask (0.0 = bg/blur, 1.0 = subject/sharp) ──────────────────────
  final focusMask = _buildFocusMask(
    width: working.width,
    height: working.height,
    settings: settingsJson,
    maskJson: maskJson,
    srcW: src.width,
    srcH: src.height,
  );

  // ── Blur kernels ──────────────────────────────────────────────────────────
  final blurAmt = (settingsJson['blurIntensity'] as num).toDouble();

  final strongR = quality == BpRenderQuality.export
      ? math.max(5, (blurAmt * 1.15).round())
      : quality == BpRenderQuality.previewIdle
          ? math.max(3, (blurAmt * 0.66).round())
          : math.max(2, ((mode == BlurPhotoMode.circle || mode == BlurPhotoMode.line)
                  ? blurAmt * 0.28
                  : blurAmt * 0.38)
              .round());

  // For track quality we skip the expensive medium blur.
  final blurredImg =
      img.gaussianBlur(img.Image.from(working), radius: strongR);

  // ── Composite: subject=100% sharp, background=100% blurred ───────────────
  final result =
      img.Image(width: working.width, height: working.height, numChannels: 4);

  for (var y = 0; y < working.height; y++) {
    for (var x = 0; x < working.width; x++) {
      final idx = y * working.width + x;

      // focus: 1.0 = keep sharp (subject), 0.0 = apply blur (background)
      final focus = focusMask[idx];

      // Hard-clamp: pixels clearly inside subject stay 100% sharp.
      // Pixels clearly in background stay 100% blurred.
      // Only the narrow edge band gets a smooth gradient.
      final sharpWeight = _sharpWeight(focus);

      final sharpPx = working.getPixel(x, y);
      final blurPx = blurredImg.getPixel(x, y);

      final r = _ch((sharpPx.r * sharpWeight + blurPx.r * (1 - sharpWeight)).round());
      final g = _ch((sharpPx.g * sharpWeight + blurPx.g * (1 - sharpWeight)).round());
      final b = _ch((sharpPx.b * sharpWeight + blurPx.b * (1 - sharpWeight)).round());

      result.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // ── Encode ────────────────────────────────────────────────────────────────
  final Uint8List encoded;
  if (quality == BpRenderQuality.export) {
    encoded = Uint8List.fromList(img.encodePng(result, level: 3));
  } else {
    encoded = Uint8List.fromList(
      img.encodeJpg(result,
          quality: quality == BpRenderQuality.track ? 72 : 86),
    );
  }

  return {
    'bytes': encoded,
    'width': result.width,
    'height': result.height,
  };
}

// ── Sharp weight curve ────────────────────────────────────────────────────────

/// Maps a focus value to a sharp-pixel weight.
/// The mask already encodes a very tight binary signal (see _smartMask):
///   focus >= 0.50 → subject interior  → 1.0  (100% sharp, zero blur)
///   focus <= 0.05 → confirmed background → 0.0  (100% blurred)
///   0.05..0.50   → narrow real edge   → smooth feather
///
/// Keeping this tight ensures NO ghosting leaks into the subject body.
double _sharpWeight(double focus) {
  if (focus >= 0.50) return 1.0;
  if (focus <= 0.05) return 0.0;
  final t = (focus - 0.05) / (0.50 - 0.05);
  return t * t * (3.0 - 2.0 * t);
}

// ── Mask builders ─────────────────────────────────────────────────────────────

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
      _circleMask(mask, width, height,
          Map<String, dynamic>.from(settings['circle'] as Map));
      break;
    case BlurPhotoMode.line:
      _lineMask(mask, width, height,
          Map<String, dynamic>.from(settings['line'] as Map));
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

// ── Smart mask ────────────────────────────────────────────────────────────────

/// Builds the focus mask from the ML Kit confidence values.
/// The mask is subsequently consumed by [_sharpWeight] so the thresholds
/// here define the raw confidence space, not the final blur/sharp boundary.
void _smartMask(
  List<double> mask,
  int width,
  int height,
  Map<String, dynamic>? maskJson,
  Map<String, dynamic> settings,
  int srcW,
  int srcH,
) {
  // ── Fallback: no real segmentation data ──────────────────────────────────
  if (maskJson == null || maskJson['usedFallback'] == true) {
    // Safe centred ellipse that protects a generic portrait/subject region.
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
        // Smoothly pull outward — subject center = 1.0, edges taper off.
        mask[y * width + x] = _smoothstep(1.20, 0.60, n);
      }
    }
    return;
  }

  // ── Real ML Kit confidence mask ───────────────────────────────────────────
  final confidence = ((maskJson['confidenceMask'] as List?) ?? const [])
      .map((v) => (v as num).toDouble())
      .toList();
  final srcMaskW = maskJson['width'] as int? ?? srcW;
  final srcMaskH = maskJson['height'] as int? ?? srcH;

  if (confidence.isEmpty) {
    for (var i = 0; i < mask.length; i++) {
      mask[i] = 0.0;
    }
    return;
  }

  // ── Aggressive subject protection ─────────────────────────────────────────
  // ML Kit confidence values:
  //   1.0  = definitely subject (body interior)
  //   0.6+ = high-confidence subject (fur, edges, accessories held by subject)
  //   0.3+ = likely subject — we treat ALL of these as fully sharp
  //   < 0.12 = confirmed background
  //
  // Strategy: use a VERY low threshold (0.30) so the full body including
  // fur, clothing, and items held by the subject stay 100% sharp.
  // Only a tiny feather band (0.12..0.30) gets any transition.
  // This eliminates ghosting completely on the subject.
  const kSubjectThreshold  = 0.30; // confidence >= this → fully sharp (1.0)
  const kBgThreshold       = 0.12; // confidence <= this → fully blurred (0.0)
  // Use feather band 0.12..0.30 for natural-looking edge.

  for (var y = 0; y < height; y++) {
    final sy =
        ((y / height) * srcMaskH).floor().clamp(0, srcMaskH - 1);
    for (var x = 0; x < width; x++) {
      final sx =
          ((x / width) * srcMaskW).floor().clamp(0, srcMaskW - 1);

      final c = confidence[sy * srcMaskW + sx].clamp(0.0, 1.0);

      final double focused;
      if (c >= kSubjectThreshold) {
        focused = 1.0; // subject body → never blurred
      } else if (c <= kBgThreshold) {
        focused = 0.0; // confirmed background → fully blurred
      } else {
        // Narrow feather: smoothly transition only this tiny edge band.
        focused = _smoothstep(kBgThreshold, kSubjectThreshold, c);
      }

      mask[y * width + x] = focused;
    }
  }
}

// ── Circle mask ───────────────────────────────────────────────────────────────

void _circleMask(
    List<double> mask, int width, int height, Map<String, dynamic> c) {
  final cx = (c['centerX'] as num?)?.toDouble() ?? 0.50;
  final cy = (c['centerY'] as num?)?.toDouble() ?? 0.45;
  final rx = (c['radiusX'] as num?)?.toDouble() ?? 0.24;
  final ry = (c['radiusY'] as num?)?.toDouble() ?? 0.24;
  final rot = (c['rotation'] as num?)?.toDouble() ?? 0.0;
  final feather = (c['feather'] as num?)?.toDouble() ?? 0.18;
  final cosR = math.cos(rot);
  final sinR = math.sin(rot);
  final outer = 1.0 + feather * 0.55;
  final inner = 1.0 - feather * 0.35;

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
      mask[y * width + x] = _smoothstep(outer, inner, n);
    }
  }
}

// ── Line mask ─────────────────────────────────────────────────────────────────

void _lineMask(
    List<double> mask, int width, int height, Map<String, dynamic> l) {
  final cx = (l['centerX'] as num?)?.toDouble() ?? 0.50;
  final cy = (l['centerY'] as num?)?.toDouble() ?? 0.50;
  final angle = (l['angle'] as num?)?.toDouble() ?? 0.0;
  final band = (l['bandWidth'] as num?)?.toDouble() ?? 0.22;
  final feather = (l['feather'] as num?)?.toDouble() ?? 0.18;
  final sinA = math.sin(angle);
  final cosA = math.cos(angle);

  for (var y = 0; y < height; y++) {
    final ny = (y / height) - cy;
    for (var x = 0; x < width; x++) {
      final nx = (x / width) - cx;
      final dist = ((-nx * sinA) + (ny * cosA)).abs();
      mask[y * width + x] = _smoothstep(band + feather, band, dist);
    }
  }
}

// ── Math helpers ──────────────────────────────────────────────────────────────

double _smoothstep(double edge0, double edge1, double x) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

int _ch(int v) => v.clamp(0, 255);
