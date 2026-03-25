import 'dart:math' as math;

import 'package:image/image.dart' as im;

import 'creative_types.dart';

double _lumaP(im.Pixel p) =>
    0.2126 * p.r.toInt() + 0.7152 * p.g.toInt() + 0.0722 * p.b.toInt();

/// Single-channel mask in the red channel (0–255). Other channels unused.
im.Image buildSoftMask(im.Image src, SmartMaskKind kind) {
  final w = src.width;
  final h = src.height;
  final out = im.Image(width: w, height: h);

  switch (kind) {
    case SmartMaskKind.none:
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          out.setPixelRgb(x, y, 255, 0, 0);
        }
      }
    case SmartMaskKind.sky:
      _fillSky(src, out);
    case SmartMaskKind.face:
    case SmartMaskKind.subject:
      _fillSkinish(src, out, kind == SmartMaskKind.subject);
    case SmartMaskKind.vegetation:
      _fillVegetation(src, out);
    case SmartMaskKind.materials:
    case SmartMaskKind.facade:
      _fillStructural(src, out);
  }
  _gaussianBlurSoft(out, radius: kind == SmartMaskKind.sky ? 9 : 5);
  return out;
}

void _fillSky(im.Image src, im.Image out) {
  final h = src.height;
  final third = h * 0.38;
  for (var y = 0; y < h; y++) {
    final rowBias = (third - y) / third;
    final vertical = rowBias.clamp(0.0, 1.0);
    for (var x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
      final blue = (b > r + 12 && b > g + 5) ? 1.0 : 0.45;
      final m = (vertical * blue * 255).round().clamp(0, 255);
      out.setPixelRgb(x, y, m, 0, 0);
    }
  }
}

void _fillSkinish(im.Image src, im.Image out, bool subjectWide) {
  final cx = src.width * 0.5;
  final cy = src.height * 0.42;
  final rw = src.width * (subjectWide ? 0.48 : 0.22);
  final rh = src.height * (subjectWide ? 0.62 : 0.3);

  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
      final mx = math.max(r, math.max(g, b));
      final sat = mx < 1 ? 0 : (mx - math.min(r, math.min(g, b))) / mx;

      double skin = 0;
      if (r > 80 && g > 45 && r > g && r > b && (r - g) > 15 && sat > 0.07 && sat < 0.55) {
        skin = 1.0;
      }

      final nx = (x - cx) / rw;
      final ny = (y - cy) / rh;
      final radial = 1.0 - math.min(1.0, math.sqrt(nx * nx + ny * ny));
      final geo = subjectWide ? radial : radial * 0.85 + 0.15;

      final v = (skin * 255 * geo).round().clamp(0, 255);
      out.setPixelRgb(x, y, v, 0, 0);
    }
  }
}

void _fillVegetation(im.Image src, im.Image out) {
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
      double m = 0;
      if (g > r + 10 && g > b + 8 && y > src.height * 0.18) {
        m = ((g - r) / 255.0 * 1.15).clamp(0.0, 1.0);
      }
      out.setPixelRgb(x, y, (m * 255).round(), 0, 0);
    }
  }
}

void _fillStructural(im.Image src, im.Image out) {
  // Mid-frequency emphasis proxy: stronger on harder edges / neutral walls
  for (var y = 1; y < src.height - 1; y++) {
    for (var x = 1; x < src.width - 1; x++) {
      final l0 = _lumaP(src.getPixel(x, y)).toDouble();
      final lx = _lumaP(src.getPixel(x + 1, y)).toDouble();
      final ly = _lumaP(src.getPixel(x, y + 1)).toDouble();
      final edge = ((lx - l0).abs() + (ly - l0).abs()) / 255.0;
      final p = src.getPixel(x, y);
      final sat = _saturation(p.r.toInt(), p.g.toInt(), p.b.toInt());
      final neutral = (1.0 - sat * 1.8).clamp(0.0, 1.0);
      final m = (edge * 0.65 + neutral * 0.35).clamp(0.0, 1.0);
      out.setPixelRgb(x, y, (m * 255).round(), 0, 0);
    }
  }
  // borders
  for (var x = 0; x < src.width; x++) {
    out.setPixelRgb(x, 0, 0, 0, 0);
    out.setPixelRgb(x, src.height - 1, 0, 0, 0);
  }
  for (var y = 0; y < src.height; y++) {
    out.setPixelRgb(0, y, 0, 0, 0);
    out.setPixelRgb(src.width - 1, y, 0, 0, 0);
  }
}

double _saturation(int r, int g, int b) {
  final mx = math.max(r, math.max(g, b)).toDouble();
  final mn = math.min(r, math.min(g, b)).toDouble();
  if (mx < 1e-6) return 0;
  return (mx - mn) / mx;
}

void _gaussianBlurSoft(im.Image mask, {int radius = 5}) {
  if (radius < 1) return;
  final tmp = im.Image.from(mask);
  final w = mask.width, h = mask.height;
  final kernel = _gauss1d(radius);
  final k = kernel.length ~/ 2;

  void horiz(im.Image src, im.Image dst) {
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        double acc = 0, ws = 0;
        for (var i = -k; i <= k; i++) {
          final xx = (x + i).clamp(0, w - 1);
          final wgt = kernel[i + k];
          acc += src.getPixel(xx, y).r.toInt() * wgt;
          ws += wgt;
        }
        final v = (acc / ws).round().clamp(0, 255);
        dst.setPixelRgb(x, y, v, 0, 0);
      }
    }
  }

  void vert(im.Image src, im.Image dst) {
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        double acc = 0, ws = 0;
        for (var j = -k; j <= k; j++) {
          final yy = (y + j).clamp(0, h - 1);
          final wgt = kernel[j + k];
          acc += src.getPixel(x, yy).r.toInt() * wgt;
          ws += wgt;
        }
        final v = (acc / ws).round().clamp(0, 255);
        dst.setPixelRgb(x, y, v, 0, 0);
      }
    }
  }

  horiz(mask, tmp);
  vert(tmp, mask);
}

List<double> _gauss1d(int r) {
  final size = r * 2 + 1;
  final k = List<double>.filled(size, 0);
  double s = 0;
  final sigma = r / 1.8;
  for (var i = 0; i < size; i++) {
    final x = i - r;
    k[i] = math.exp(-(x * x) / (2 * sigma * sigma));
    s += k[i];
  }
  for (var i = 0; i < size; i++) {
    k[i] /= s;
  }
  return k;
}

SmartMaskKind maskKindForRegion(RegionLabel r) {
  switch (r) {
    case RegionLabel.face:
      return SmartMaskKind.face;
    case RegionLabel.sky:
      return SmartMaskKind.sky;
    case RegionLabel.subject:
      return SmartMaskKind.subject;
    case RegionLabel.vegetation:
      return SmartMaskKind.vegetation;
    case RegionLabel.facade:
    case RegionLabel.windows:
    case RegionLabel.interiorPlanes:
      return SmartMaskKind.facade;
    case RegionLabel.background:
      return SmartMaskKind.none;
  }
}
