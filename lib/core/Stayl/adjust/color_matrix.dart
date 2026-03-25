import 'dart:math' as math;
import 'adjust_params.dart';

class ColorMatrixBuilder {
  static List<double> fromParams(AdjustParams p) {
    // ملاحظة: هنا فقط Preview سريع وعملي.
    // contrast + saturation + brightness + warmth
    final c = p.contrast.clamp(0.0, 3.0);
    final s = p.saturation.clamp(0.0, 3.0);
    final b = (p.brightness + (p.exposure * 0.18)).clamp(-1.0, 1.0);
    final w = p.warmth.clamp(-1.0, 1.0);

    final mContrast = _contrast(c);
    final mSaturation = _saturation(s);
    final mBrightness = _brightness(b);
    final mWarmth = _warmth(w);

    // multiply: warmth -> brightness -> saturation -> contrast
    return _multiply(_multiply(_multiply(mWarmth, mBrightness), mSaturation), mContrast);
  }

  static List<double> _identity() => <double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static List<double> _contrast(double v) {
    // standard contrast around 128
    final t = (1.0 - v) * 128.0;
    return <double>[
      v, 0, 0, 0, t,
      0, v, 0, 0, t,
      0, 0, v, 0, t,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> _brightness(double v) {
    // v in [-1..1] -> offset [-255..255]
    final o = v * 255.0;
    return <double>[
      1, 0, 0, 0, o,
      0, 1, 0, 0, o,
      0, 0, 1, 0, o,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> _saturation(double s) {
    // luminance weights
    const rw = 0.2126;
    const gw = 0.7152;
    const bw = 0.0722;

    final a = (1 - s) * rw + s;
    final b = (1 - s) * rw;
    final c = (1 - s) * rw;

    final d = (1 - s) * gw;
    final e = (1 - s) * gw + s;
    final f = (1 - s) * gw;

    final g = (1 - s) * bw;
    final h = (1 - s) * bw;
    final i = (1 - s) * bw + s;

    return <double>[
      a, d, g, 0, 0,
      b, e, h, 0, 0,
      c, f, i, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> _warmth(double w) {
    // trick: warm up = increase R, decrease B slightly.
    // w in [-1..1]
    final r = 1.0 + (0.10 * w);
    final b = 1.0 - (0.10 * w);
    final g = 1.0;

    return <double>[
      r, 0, 0, 0, 0,
      0, g, 0, 0, 0,
      0, 0, b, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> _multiply(List<double> a, List<double> b) {
    // both 4x5
    final out = List<double>.filled(20, 0.0);

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 5; col++) {
        out[row * 5 + col] =
            a[row * 5 + 0] * _get(b, 0, col) +
                a[row * 5 + 1] * _get(b, 1, col) +
                a[row * 5 + 2] * _get(b, 2, col) +
                a[row * 5 + 3] * _get(b, 3, col) +
                (col == 4 ? a[row * 5 + 4] : 0.0);
      }
    }

    // clamp tiny floats
    for (int i = 0; i < out.length; i++) {
      if (out[i].abs() < 1e-12) out[i] = 0.0;
      if (out[i].isNaN || out[i].isInfinite) out[i] = 0.0;
      out[i] = out[i].clamp(-math.pow(10, 6).toDouble(), math.pow(10, 6).toDouble());
    }
    return out;
  }

  static double _get(List<double> m, int r, int c) {
    // treat 4x5, last column offset
    return m[r * 5 + c];
  }
}