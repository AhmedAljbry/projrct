import 'package:flutter/widgets.dart';

class VerticalSplitClipper extends CustomClipper<Rect> {
  final double position; // 0..1
  VerticalSplitClipper(this.position);

  @override
  Rect getClip(Size size) {
    final w = (size.width * position).clamp(0.0, size.width);
    return Rect.fromLTWH(0, 0, w, size.height);
  }

  @override
  bool shouldReclip(covariant VerticalSplitClipper oldClipper) {
    return oldClipper.position != position;
  }
}