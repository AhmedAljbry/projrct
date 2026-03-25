import 'dart:math' as math;

import 'package:image/image.dart' as im;

import 'creative_types.dart';

SceneAnalysis analyzeScene(im.Image img) {
  final w = img.width;
  final h = img.height;
  if (w < 2 || h < 2) {
    return const SceneAnalysis(
      kind: SceneKind.general,
      confidence: 0.2,
      meanLuma: 0.5,
      colorVariance: 0.1,
      skyScore: 0,
      skinScore: 0,
      greenScore: 0,
      edgeDensity: 0,
      nightScore: 0,
    );
  }

  double sumL = 0, sumL2 = 0;
  int n = 0;

  // Strided sampling for speed
  final stepX = math.max(1, w ~/ 96);
  final stepY = math.max(1, h ~/ 96);

  int skyPixels = 0, skyN = 0;
  int skinPixels = 0, skinN = 0;
  int greenPixels = 0, greenN = 0;

  final third = h ~/ 3;

  for (var y = 0; y < h; y += stepY) {
    for (var x = 0; x < w; x += stepX) {
      final p = img.getPixel(x, y);
      final r = p.r.toDouble();
      final g = p.g.toDouble();
      final b = p.b.toDouble();
      final l = _luma(r, g, b);
      sumL += l;
      sumL2 += l * l;
      n++;

      final sat = _sat(r, g, b);

      if (y < third * 1.15) {
        skyN++;
        if (b > r + 18 && b > g + 8 && l > 45) skyPixels++;
      }

      skinN++;
      if (r > 75 && g > 40 && b > 25 && r > g && r > b && (r - g) > 12 && sat > 0.08 && sat < 0.55) {
        skinPixels++;
      }

      if (y > third && g > r + 12 && g > b + 8 && sat > 0.12) {
        greenN++;
        greenPixels++;
      }
    }
  }

  final meanL = sumL / n;
  final varL = (sumL2 / n - meanL * meanL).clamp(0.0, 1e9);
  final stdL = math.sqrt(varL);

  final skyScore = skyN > 0 ? skyPixels / skyN : 0.0;
  final skinScore = skinN > 0 ? skinPixels / skinN : 0.0;
  final greenScore = greenN > 0 ? greenPixels / math.max(1, n - greenN).toDouble() : 0.0;

  final edgeDensity = _sampleEdgeDensity(img);

  final nightScore = (meanL < 58 && stdL > 32) ? 1.0 : (meanL < 78 ? (1.0 - meanL / 120).clamp(0.0, 0.85) : 0.0);

  final ar = w / h;

  // Scores per class
  var best = SceneKind.general;
  double bestScore = 0.35;

  void consider(SceneKind k, double s) {
    if (s > bestScore) {
      bestScore = s;
      best = k;
    }
  }

  consider(SceneKind.portrait, skinScore * 1.15 + (ar < 1.1 ? 0.12 : 0));
  consider(SceneKind.architecture, edgeDensity * 0.95 + (ar > 1.1 && greenScore < 0.25 ? 0.15 : 0));
  consider(SceneKind.landscape, greenScore * 0.9 + skyScore * 0.65);
  consider(SceneKind.wildlife, greenScore * 0.55 + skinScore * 0.25 + edgeDensity * 0.35);
  consider(SceneKind.product, (meanL > 110 && stdL < 42) ? 0.55 : 0.25);
  consider(SceneKind.night, nightScore);

  final confidence = bestScore.clamp(0.35, 0.95).toDouble();

  return SceneAnalysis(
    kind: best,
    confidence: confidence,
    meanLuma: meanL / 255.0,
    colorVariance: (math.sqrt(varL) / 128.0).clamp(0.0, 1.0),
    skyScore: skyScore.clamp(0.0, 1.0),
    skinScore: skinScore.clamp(0.0, 1.0),
    greenScore: greenScore.clamp(0.0, 1.0),
    edgeDensity: edgeDensity.clamp(0.0, 1.0),
    nightScore: nightScore.clamp(0.0, 1.0),
  );
}

double _luma(double r, double g, double b) => 0.2126 * r + 0.7152 * g + 0.0722 * b;

double _sat(double r, double g, double b) {
  final mx = math.max(r, math.max(g, b));
  final mn = math.min(r, math.min(g, b));
  if (mx < 1e-6) return 0;
  return (mx - mn) / mx;
}

double _sampleEdgeDensity(im.Image img) {
  final w = img.width;
  final h = img.height;
  final sx = math.max(1, w ~/ 64);
  final sy = math.max(1, h ~/ 64);
  double acc = 0;
  int c = 0;
  for (var y = sy; y < h - sy; y += sy) {
    for (var x = sx; x < w - sx; x += sx) {
      final l0 = _luma(img.getPixel(x, y).r.toDouble(), img.getPixel(x, y).g.toDouble(), img.getPixel(x, y).b.toDouble());
      final lx = _luma(img.getPixel(x + 1, y).r.toDouble(), img.getPixel(x + 1, y).g.toDouble(), img.getPixel(x + 1, y).b.toDouble());
      final ly = _luma(img.getPixel(x, y + 1).r.toDouble(), img.getPixel(x, y + 1).g.toDouble(), img.getPixel(x, y + 1).b.toDouble());
      acc += (lx - l0).abs() + (ly - l0).abs();
      c++;
    }
  }
  if (c == 0) return 0;
  return (acc / c / 255.0).clamp(0, 1);
}
