import 'package:equatable/equatable.dart';

/// Circle focus region geometry.
class AfCircleSettings extends Equatable {
  const AfCircleSettings({
    this.centerX = 0.5,
    this.centerY = 0.45,
    this.radiusX = 0.24,
    this.radiusY = 0.24,
    this.rotation = 0.0,
    this.allowEllipse = true,
  });

  final double centerX;
  final double centerY;
  final double radiusX;
  final double radiusY;
  final double rotation;
  final bool allowEllipse;

  AfCircleSettings copyWith({
    double? centerX,
    double? centerY,
    double? radiusX,
    double? radiusY,
    double? rotation,
    bool? allowEllipse,
  }) =>
      AfCircleSettings(
        centerX: centerX ?? this.centerX,
        centerY: centerY ?? this.centerY,
        radiusX: radiusX ?? this.radiusX,
        radiusY: radiusY ?? this.radiusY,
        rotation: rotation ?? this.rotation,
        allowEllipse: allowEllipse ?? this.allowEllipse,
      );

  Map<String, dynamic> toJson() => {
        'centerX': centerX,
        'centerY': centerY,
        'radiusX': radiusX,
        'radiusY': radiusY,
        'rotation': rotation,
        'allowEllipse': allowEllipse,
      };

  @override
  List<Object?> get props =>
      [centerX, centerY, radiusX, radiusY, rotation, allowEllipse];
}

/// Line (tilt-shift) focus strip geometry.
class AfLineSettings extends Equatable {
  const AfLineSettings({
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.angle = 0.0,
    this.width = 0.22,
    this.transition = 0.18,
  });

  final double centerX;
  final double centerY;
  final double angle;
  final double width;
  final double transition;

  AfLineSettings copyWith({
    double? centerX,
    double? centerY,
    double? angle,
    double? width,
    double? transition,
  }) =>
      AfLineSettings(
        centerX: centerX ?? this.centerX,
        centerY: centerY ?? this.centerY,
        angle: angle ?? this.angle,
        width: width ?? this.width,
        transition: transition ?? this.transition,
      );

  Map<String, dynamic> toJson() => {
        'centerX': centerX,
        'centerY': centerY,
        'angle': angle,
        'width': width,
        'transition': transition,
      };

  @override
  List<Object?> get props => [centerX, centerY, angle, width, transition];
}

/// Rectangle bounds in normalised [0..1] space.
class AfSegmentationBounds extends Equatable {
  const AfSegmentationBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  @override
  List<Object?> get props => [left, top, width, height];
}
