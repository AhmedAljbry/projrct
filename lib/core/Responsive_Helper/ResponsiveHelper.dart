import 'dart:math' as math;
import 'package:flutter/material.dart';

class R {
  static double w(BuildContext c) => MediaQuery.sizeOf(c).width;
  static double h(BuildContext c) => MediaQuery.sizeOf(c).height;
  static double s(BuildContext c) => math.min(w(c), h(c));

  /// scale based on shortest side (phones/tablets)
  static double sp(BuildContext c, double v) {
    final base = 390.0; // iPhone 12 width baseline
    final scale = (s(c) / base).clamp(0.85, 1.25);
    return v * scale;
  }

  static double pad(BuildContext c, [double v = 16]) => sp(c, v);
  static double radius(BuildContext c, [double v = 20]) => sp(c, v);

  static TextStyle t(BuildContext c, double size,
      {FontWeight w = FontWeight.w600, double? height, Color? color}) {
    return TextStyle(
      fontSize: sp(c, size),
      fontWeight: w,
      height: height,
      color: color,
    );
  }
}