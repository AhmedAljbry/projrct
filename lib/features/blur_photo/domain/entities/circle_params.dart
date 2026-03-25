import 'package:equatable/equatable.dart';

/// Parameters defining the circular focus region.
/// All positional values are normalised [0..1] relative to image dimensions.
class CircleBlurParams extends Equatable {
  const CircleBlurParams({
    this.centerX = 0.50,
    this.centerY = 0.45,
    this.radiusX = 0.24,
    this.radiusY = 0.24,
    this.rotation = 0.0,
    this.feather = 0.18,
  });

  /// Horizontal center, normalised [0..1].
  final double centerX;

  /// Vertical center, normalised [0..1].
  final double centerY;

  /// Horizontal radius, normalised [0..1].
  final double radiusX;

  /// Vertical radius, normalised [0..1].
  final double radiusY;

  /// Rotation in radians.
  final double rotation;

  /// Soft edge feathering width, normalised [0..1].
  final double feather;

  CircleBlurParams copyWith({
    double? centerX,
    double? centerY,
    double? radiusX,
    double? radiusY,
    double? rotation,
    double? feather,
  }) {
    return CircleBlurParams(
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      radiusX: radiusX ?? this.radiusX,
      radiusY: radiusY ?? this.radiusY,
      rotation: rotation ?? this.rotation,
      feather: feather ?? this.feather,
    );
  }

  Map<String, dynamic> toJson() => {
        'centerX': centerX,
        'centerY': centerY,
        'radiusX': radiusX,
        'radiusY': radiusY,
        'rotation': rotation,
        'feather': feather,
      };

  factory CircleBlurParams.fromJson(Map<String, dynamic> json) {
    return CircleBlurParams(
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.50,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.45,
      radiusX: (json['radiusX'] as num?)?.toDouble() ?? 0.24,
      radiusY: (json['radiusY'] as num?)?.toDouble() ?? 0.24,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      feather: (json['feather'] as num?)?.toDouble() ?? 0.18,
    );
  }

  @override
  List<Object?> get props =>
      [centerX, centerY, radiusX, radiusY, rotation, feather];
}
