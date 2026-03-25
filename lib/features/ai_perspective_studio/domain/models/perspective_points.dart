import 'dart:ui';

class PerspectivePoints {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;

  const PerspectivePoints({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  PerspectivePoints copyWith({
    Offset? topLeft,
    Offset? topRight,
    Offset? bottomLeft,
    Offset? bottomRight,
  }) {
    return PerspectivePoints(
      topLeft: topLeft ?? this.topLeft,
      topRight: topRight ?? this.topRight,
      bottomLeft: bottomLeft ?? this.bottomLeft,
      bottomRight: bottomRight ?? this.bottomRight,
    );
  }
}
