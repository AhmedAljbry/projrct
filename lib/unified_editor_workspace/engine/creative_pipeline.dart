import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as im;

import 'creative_types.dart';
import 'image_analysis.dart';
import 'mask_engine.dart';
import 'style_registry.dart';

/// Serializable payload for [compute].
class CreativePipelineArgs {
  final Uint8List bytes;
  final int maxSide;
  final int jpegQuality;
  final Map<String, dynamic> cfg;

  CreativePipelineArgs({
    required this.bytes,
    required this.maxSide,
    required this.jpegQuality,
    required this.cfg,
  });

  Map<String, dynamic> toMap() => {
        'bytes': bytes,
        'maxSide': maxSide,
        'jpegQuality': jpegQuality,
        'cfg': cfg,
      };

  static CreativePipelineArgs fromMap(Map<String, dynamic> m) => CreativePipelineArgs(
        bytes: m['bytes'] as Uint8List,
        maxSide: m['maxSide'] as int,
        jpegQuality: m['jpegQuality'] as int,
        cfg: Map<String, dynamic>.from(m['cfg'] as Map),
      );
}

/// Top-level entry for Flutter `compute`.
Uint8List runCreativePipelineIsolate(Map<String, dynamic> map) {
  final args = CreativePipelineArgs.fromMap(map);
  final raw = im.decodeImage(args.bytes);
  if (raw == null) {
    return args.bytes;
  }
  final maxDim = math.max(raw.width, raw.height);
  final im.Image img;
  if (maxDim <= args.maxSide) {
    img = im.copyResize(raw, width: raw.width, height: raw.height);
  } else {
    final s = args.maxSide / maxDim;
    img = im.copyResize(
      raw,
      width: (raw.width * s).round(),
      height: (raw.height * s).round(),
      interpolation: im.Interpolation.linear,
    );
  }

  final analysis = analyzeScene(img);
  final routing = SceneRoutingWeights.forScene(analysis.kind);
  final style = _paramsFromCfg(args.cfg);
  final adjusted = _applySceneRouting(style, analysis, routing);
  final out = _processImage(
    img,
    analysis: analysis,
    routing: routing,
    style: adjusted,
    cfg: args.cfg,
  );

  return Uint8List.fromList(im.encodeJpg(out, quality: args.jpegQuality));
}

StylePack? _findPack(String id) {
  for (final p in CreativeStyleRegistry.corePacks) {
    if (p.id == id) return p;
  }
  for (final p in CreativeStyleRegistry.architectPacks) {
    if (p.id == id) return p;
  }
  return null;
}

StyleTransferParams _paramsFromCfg(Map<String, dynamic> c) {
  StyleTransferParams base = const StyleTransferParams();
  final pid = c['packId'] as String?;
  if (pid != null) {
    final pack = _findPack(pid);
    if (pack != null) base = pack.params;
  }

  final sec = c['secondaryPackId'] as String?;
  final bt = (c['blendT'] as num?)?.toDouble() ?? 0.0;
  if (sec != null && bt > 0.01) {
    final p2 = _findPack(sec);
    if (p2 != null) base = base.lerpTowards(p2.params, bt.clamp(0.0, 1.0));
  }

  final samples = c['samplePackIds'] as List?;
  final weights = c['sampleWeights'] as List?;
  if (samples != null && weights != null && samples.isNotEmpty) {
    final acc = <StyleTransferParams>[];
    final ww = <double>[];
    for (var i = 0; i < samples.length; i++) {
      final id = samples[i] as String?;
      if (id == null) continue;
      final pk = _findPack(id);
      if (pk == null) continue;
      acc.add(pk.params);
      ww.add(i < weights.length ? (weights[i] as num).toDouble().clamp(0.05, 1.0) : 1.0);
    }
    if (acc.isNotEmpty) {
      final mix = (c['sampleMixStrength'] as num?)?.toDouble() ?? 0.72;
      final blended = StyleTransferParams.weightedMean(acc, ww);
      base = base.lerpTowards(blended, mix.clamp(0.0, 1.0));
    }
  }

  base = base.copyWith(
    exposure: (c['exposure'] as num?)?.toDouble(),
    contrast: (c['contrast'] as num?)?.toDouble(),
    saturation: (c['saturation'] as num?)?.toDouble(),
    vibrance: (c['vibrance'] as num?)?.toDouble(),
    highlightRoll: (c['highlightRoll'] as num?)?.toDouble(),
    shadowLift: (c['shadowLift'] as num?)?.toDouble(),
    warmth: (c['warmth'] as num?)?.toDouble(),
    globalHue: (c['globalHue'] as num?)?.toDouble(),
    detailRecovery: (c['detailRecovery'] as num?)?.toDouble(),
  );

  final qp = c['quickProfile'] as String?;
  if (qp == 'viral') {
    base = base.copyWith(
      saturation: math.min(1.35, base.saturation * 1.08),
      vibrance: math.min(0.85, base.vibrance + 0.12),
    );
  } else if (qp == 'natural') {
    base = base.copyWith(
      saturation: base.saturation * 0.99,
      contrast: base.contrast * 0.995,
      highlightRoll: math.min(0.92, base.highlightRoll * 1.06),
    );
  } else if (qp == 'fix') {
    base = base.copyWith(
      contrast: math.min(1.18, base.contrast * 1.05),
      detailRecovery: math.min(0.45, base.detailRecovery + 0.1),
      shadowLift: math.min(0.22, base.shadowLift + 0.05),
    );
  }

  return base;
}

StyleTransferParams _applySceneRouting(
  StyleTransferParams p,
  SceneAnalysis a,
  SceneRoutingWeights w,
) {
  var sat = p.saturation.clamp(0.75, 1.35);
  sat = math.min(sat, w.maxSaturation);
  if (a.kind == SceneKind.night) {
    sat *= 0.92;
  }
  final hl = (p.highlightRoll * w.highlightProtection).clamp(0.2, 0.95);
  final skin = (p.skinProtection * (0.55 + w.skinLumaPreserve * 0.45)).clamp(0.3, 0.95);
  final neutral = (p.neutralProtection + w.architectNeutralBias * 0.15).clamp(0.2, 0.92);
  return p.copyWith(
    saturation: sat,
    highlightRoll: hl,
    skinProtection: skin,
    neutralProtection: neutral,
    shadowLift: p.shadowLift * (1.0 - w.shadowNoiseGuard * 0.25),
  );
}

im.Image _processImage(
  im.Image src, {
  required SceneAnalysis analysis,
  required SceneRoutingWeights routing,
  required StyleTransferParams style,
  required Map<String, dynamic> cfg,
}) {
  final w = src.width;
  final h = src.height;
  final origL = List<double>.filled(w * h, 0);
  final edgeW = List<double>.filled(w * h, 0);

  _prefillLumaAndEdges(src, origL, edgeW, w, h);

  final out = im.Image.from(src);
  final faceMask = buildSoftMask(src, SmartMaskKind.face);

  im.Image? mlMask;
  final mlRaw = cfg['mlMaskPng'] as Uint8List?;
  if (mlRaw != null && mlRaw.isNotEmpty) {
    final decM = im.decodeImage(mlRaw);
    if (decM != null) {
      mlMask = decM.width == w && decM.height == h
          ? decM
          : im.copyResize(decM, width: w, height: h, interpolation: im.Interpolation.linear);
    }
  }
  final mlBlend = (cfg['mlSubjectBlend'] as num?)?.toDouble() ?? 0.72;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final p = src.getPixel(x, y);
      double r = p.r.toDouble();
      double g = p.g.toDouble();
      double b = p.b.toDouble();

      final oL = origL[i];
      final e = edgeW[i];
      var mskin = (faceMask.getPixel(x, y).r.toInt() / 255.0).clamp(0.0, 1.0);
      if (mlMask != null) {
        final mv = mlMask.getPixel(x, y).r.toInt() / 255.0;
        mskin = (mskin * (1.0 - mlBlend) + mv * mlBlend).clamp(0.0, 1.0);
      }

      // Parametric "curves" from Pro refine
      final sh = (cfg['curveShadow'] as num?)?.toDouble() ?? 0.5;
      final mid = (cfg['curveMid'] as num?)?.toDouble() ?? 0.5;
      final hi = (cfg['curveHi'] as num?)?.toDouble() ?? 0.5;
      final master = (cfg['curveMaster'] as num?)?.toDouble() ?? 0.5;

      var l = _lumaD(r, g, b) / 255.0;
      l = _curveZone(l, sh, mid, hi, master);

      l *= math.pow(2, style.exposure * 0.35); // soft exposure
      l = ((l - 0.5) * style.contrast + 0.5).clamp(0.0, 1.0);
      l = _highlightRolloff(l, style.highlightRoll);
      l = (l + style.shadowLift * (1 - l) * 0.25).clamp(0.0, 1.0);

      var sat0 = _satD(r, g, b);
      var hue = _hueD(r, g, b);

      // Pro HSL
      hue += ((cfg['hueShift'] as num?)?.toDouble() ?? 0.0) * 180;
      sat0 *= 1.0 + ((cfg['satMul'] as num?)?.toDouble() ?? 0.0);
      l *= 1.0 + 0.35 * ((cfg['lumMul'] as num?)?.toDouble() ?? 0.0);
      l = l.clamp(0.0, 1.0);

      sat0 *= style.saturation;
      sat0 += style.vibrance * (1 - sat0) * 0.35;
      sat0 = sat0.clamp(0, 1.2);

      hue += style.globalHue * 40;

      // Warmth: subtle channel tilt
      final wr = style.warmth * 10;
      r += wr;
      b -= wr * 0.85;

      var rgb = _hslToRgb(hue, sat0.clamp(0, 1), l * 255.0);
      r = rgb[0];
      g = rgb[1];
      b = rgb[2];

      // Architecture yellow-guard on neutral planes
      if (analysis.kind == SceneKind.architecture && sat0 < 0.18) {
        final yl = (r + g) * 0.5 - b;
        if (yl > 18) {
          r -= yl * 0.08 * routing.architectNeutralBias;
          g -= yl * 0.05 * routing.architectNeutralBias;
        }
      }

      // Luminance preservation blend
      final newL = _lumaD(r, g, b);
      final preserve = 0.35 + style.textureProtection * 0.35 * (1 - e);
      final scale = ((oL + 1e-6) / (newL + 1e-6)).clamp(0.65, 1.45);
      final t = preserve * (analysis.kind == SceneKind.portrait ? 0.85 : 1.0);
      r = r * (scale * t + (1 - t));
      g = g * (scale * t + (1 - t));
      b = b * (scale * t + (1 - t));

      // Skin protection
      final sp = style.skinProtection * mskin * (analysis.kind == SceneKind.portrait ? 1.0 : 0.55);
      r = r * (1 - sp) + p.r.toDouble() * sp;
      g = g * (1 - sp) + p.g.toDouble() * sp;
      b = b * (1 - sp) + p.b.toDouble() * sp;

      // Neutral protection
      if (sat0 < 0.12) {
        final np = style.neutralProtection * (1 - sat0 * 6);
        r = r * (1 - np) + p.r.toDouble() * np;
        g = g * (1 - np) + p.g.toDouble() * np;
        b = b * (1 - np) + p.b.toDouble() * np;
      }

      // Edge preservation: dampen deviation from original chroma
      final ep = style.edgePreservation * e;
      r = r * (1 - ep) + p.r.toDouble() * ep;
      g = g * (1 - ep) + p.g.toDouble() * ep;
      b = b * (1 - ep) + p.b.toDouble() * ep;

      // Landscape green control (lower half)
      if (analysis.kind == SceneKind.landscape && y > h * 0.35) {
        final greenBias = g - (r + b) * 0.5;
        if (greenBias > 0) {
          final damp = routing.greenControl;
          g *= 0.97 + (damp) * 0.03;
        }
      }

      // Tone lock toward original mid gray
      final tl = (cfg['toneLock'] as num?)?.toDouble() ?? 0.0;
      if (tl > 0.04) {
        final oMid = oL / 255.0;
        final nMid = _lumaD(r, g, b) / 255.0;
        final adj = (oMid - nMid) * tl * 0.5;
        r += adj * 255 * 0.25;
        g += adj * 255 * 0.25;
        b += adj * 255 * 0.25;
      }

      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);

      out.setPixelRgb(x, y, r.round(), g.round(), b.round());
    }
  }

  final lt = (cfg['localTransfer'] as num?)?.toDouble() ?? 0.0;
  if (lt > 0.02) {
    _applyLocalColorTransfer(out, src, lt, cfg, w, h);
  }

  _detailRecoveryLuma(out, src, style.detailRecovery, edgeW, w, h);

  // Glass / sky hooks (mild sharpening in highlights for architect)
  final glass = (cfg['glassEnhance'] as num?)?.toDouble() ?? 0.0;
  if (glass > 0.05) {
    _detailRecoveryLuma(out, src, glass * 0.35, edgeW, w, h);
  }

  final skyE = (cfg['skyEnhance'] as num?)?.toDouble() ?? 0.0;
  if (skyE > 0.04) {
    final sm = buildSoftMask(src, SmartMaskKind.sky);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final m = sm.getPixel(x, y).r.toInt() / 255.0;
        if (m < 0.04) continue;
        final p = out.getPixel(x, y);
        var r = p.r.toDouble();
        var g = p.g.toDouble();
        var b = p.b.toDouble();
        b += skyE * 14 * m;
        r -= skyE * 3 * m;
        out.setPixelRgb(
          x,
          y,
          r.round().clamp(0, 255),
          g.round().clamp(0, 255),
          b.round().clamp(0, 255),
        );
      }
    }
  }

  return out;
}

im.Image _boxBlurLuma(im.Image src, int w, int h) {
  final out = im.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var acc = 0.0;
      var c = 0;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final yy = (y + dy).clamp(0, h - 1);
          final xx = (x + dx).clamp(0, w - 1);
          final p = src.getPixel(xx, yy);
          acc += _lumaD(p.r.toDouble(), p.g.toDouble(), p.b.toDouble());
          c++;
        }
      }
      final v = (acc / c).round().clamp(0, 255);
      out.setPixelRgb(x, y, v, v, v);
    }
  }
  return out;
}

void _prefillLumaAndEdges(
  im.Image src,
  List<double> origL,
  List<double> edgeW,
  int w,
  int h,
) {
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final p = src.getPixel(x, y);
      origL[i] = _lumaD(p.r.toDouble(), p.g.toDouble(), p.b.toDouble());
    }
  }
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final i = y * w + x;
      final lx = origL[i + 1] - origL[i - 1];
      final ly = origL[i + w] - origL[i - w];
      edgeW[i] = (math.sqrt(lx * lx + ly * ly) / 255.0).clamp(0.0, 1.0);
    }
  }
}

double _curveZone(double l, double shadows, double mid, double hi, double master) {
  var v = l;
  v = math.pow(v, 0.85 + (0.35 - shadows) * 0.25).toDouble();
  v = (v - 0.5) * (0.92 + mid * 0.18) + 0.5;
  v = v * (0.88 + hi * 0.14);
  v = (v - 0.5) * (0.9 + master * 0.22) + 0.5;
  return v.clamp(0.0, 1.0);
}

double _highlightRolloff(double l, double strength) {
  if (strength <= 0) return l;
  if (l < 0.75) return l;
  final x = (l - 0.75) / 0.25;
  final c = 1.0 - math.pow(x, 1.0 + strength * 2.5) * strength * 0.35;
  return (0.75 + (l - 0.75) * c).clamp(0.0, 1.0);
}

void _applyLocalColorTransfer(
  im.Image out,
  im.Image src,
  double amount,
  Map<String, dynamic> cfg,
  int w,
  int h,
) {
  final srcLabel = (cfg['ltSource'] as String?) ?? 'Subject';
  final tgtLabel = (cfg['ltTarget'] as String?) ?? 'Background';
  final feather = (cfg['ltFeather'] as num?)?.toDouble() ?? 0.32;

  final mS = buildSoftMask(src, _kindFromLabel(srcLabel));
  final mT = buildSoftMask(src, _kindFromLabel(tgtLabel));

  double sr = 0, sg = 0, sb = 0, sn = 0;
  double tr = 0, tg = 0, tb = 0, tn = 0;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = src.getPixel(x, y);
      final ws = mS.getPixel(x, y).r.toInt() / 255.0;
      final wt = mT.getPixel(x, y).r.toInt() / 255.0;
      if (ws > 0.05) {
        sr += p.r.toInt() * ws;
        sg += p.g.toInt() * ws;
        sb += p.b.toInt() * ws;
        sn += ws;
      }
      if (wt > 0.05) {
        tr += p.r.toInt() * wt;
        tg += p.g.toInt() * wt;
        tb += p.b.toInt() * wt;
        tn += wt;
      }
    }
  }
  if (sn < 1 || tn < 1) return;
  sr /= sn;
  sg /= sn;
  sb /= sn;
  tr /= tn;
  tg /= tn;
  tb /= tn;

  final dr = sr - tr;
  final dg = sg - tg;
  final db = sb - tb;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final wt = (mT.getPixel(x, y).r.toInt() / 255.0);
      final ws = feather.clamp(0.05, 0.95);
      final a = amount * wt * ws;
      if (a <= 0.001) continue;
      final p = out.getPixel(x, y);
      var r = p.r.toDouble() + dr * a;
      var g = p.g.toDouble() + dg * a;
      var b = p.b.toDouble() + db * a;
      out.setPixelRgb(x, y, r.round().clamp(0, 255), g.round().clamp(0, 255), b.round().clamp(0, 255));
    }
  }
}

SmartMaskKind _kindFromLabel(String label) {
  switch (label) {
    case 'Face':
      return SmartMaskKind.face;
    case 'Background':
      return SmartMaskKind.none;
    case 'Sky':
      return SmartMaskKind.sky;
    case 'Subject':
      return SmartMaskKind.subject;
    case 'Vegetation':
      return SmartMaskKind.vegetation;
    case 'Facade':
    case 'Windows':
    case 'Walls/Floor/Ceiling':
      return SmartMaskKind.facade;
    // Reference-aware region transfer isn't fully represented by the current engine masks,
    // so we map "From Reference" to a reasonable fallback mask kind.
    case 'From Reference':
      return SmartMaskKind.subject;
    default:
      return SmartMaskKind.subject;
  }
}

void _detailRecoveryLuma(
  im.Image out,
  im.Image original,
  double strength,
  List<double> edgeW,
  int w,
  int h,
) {
  if (strength <= 0.01) return;
  final blur = _boxBlurLuma(original, w, h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final o = out.getPixel(x, y);
      final b = blur.getPixel(x, y);
      final lO = _lumaD(o.r.toDouble(), o.g.toDouble(), o.b.toDouble());
      final lB = _lumaD(b.r.toDouble(), b.g.toDouble(), b.b.toDouble());
      var delta = (lO - lB) * strength * (1 - edgeW[i] * 0.65);
      delta = delta.clamp(-28, 28);
      var r = o.r.toDouble() + delta;
      var g = o.g.toDouble() + delta;
      var b2 = o.b.toDouble() + delta;
      out.setPixelRgb(
        x,
        y,
        r.round().clamp(0, 255),
        g.round().clamp(0, 255),
        b2.round().clamp(0, 255),
      );
    }
  }
}

double _lumaD(double r, double g, double b) => 0.2126 * r + 0.7152 * g + 0.0722 * b;

double _satD(double r, double g, double b) {
  final mx = math.max(r, math.max(g, b));
  final mn = math.min(r, math.min(g, b));
  if (mx < 1e-6) return 0;
  return (mx - mn) / mx;
}

double _hueD(double r, double g, double b) {
  final mx = math.max(r, math.max(g, b));
  final mn = math.min(r, math.min(g, b));
  final d = mx - mn;
  if (d < 1e-6) return 0;
  double hh = 0;
  if (mx == r) {
    hh = (g - b) / d + (g < b ? 6 : 0);
  } else if (mx == g) {
    hh = (b - r) / d + 2;
  } else {
    hh = (r - g) / d + 4;
  }
  return hh * 60;
}

List<double> _hslToRgb(double h, double s, double l) {
  h = h % 360;
  if (h < 0) h += 360;
  final c = (1 - (2 * (l / 255) - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = l / 255 - c / 2;
  double r1 = 0, g1 = 0, b1 = 0;
  final sec = (h / 60).floor();
  switch (sec) {
    case 0:
      r1 = c;
      g1 = x;
      break;
    case 1:
      r1 = x;
      g1 = c;
      break;
    case 2:
      g1 = c;
      b1 = x;
      break;
    case 3:
      g1 = x;
      b1 = c;
      break;
    case 4:
      r1 = x;
      b1 = c;
      break;
    default:
      r1 = c;
      b1 = x;
  }
  return [(r1 + m) * 255, (g1 + m) * 255, (b1 + m) * 255];
}

/// Style stealing: derive param deltas vs source mean.
StyleTransferParams styleStealDelta(im.Image source, im.Image reference) {
  final sm = _meanRgb(source);
  final rm = _meanRgb(reference);
  final dL = (rm[0] + rm[1] + rm[2]) / 3 - (sm[0] + sm[1] + sm[2]) / 3;
  final warm = (rm[0] - rm[2]) - (sm[0] - sm[2]);
  return StyleTransferParams(
    exposure: (dL / 255 * 0.8).clamp(-0.08, 0.08),
    warmth: (warm / 255 * 0.5).clamp(-0.12, 0.12),
    saturation: ((rm[3] - sm[3]) * 0.35 + 1.0).clamp(0.92, 1.12),
  );
}

List<double> _meanRgb(im.Image img) {
  double sr = 0, sg = 0, sb = 0, ss = 0;
  int n = 0;
  final step = math.max(1, img.width ~/ 64);
  for (var y = 0; y < img.height; y += step) {
    for (var x = 0; x < img.width; x += step) {
      final p = img.getPixel(x, y);
      final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
      sr += r;
      sg += g;
      sb += b;
      ss += _satD(r, g, b);
      n++;
    }
  }
  return [sr / n, sg / n, sb / n, ss / n];
}
