import 'package:equatable/equatable.dart';

class CircleFocusSettings extends Equatable {
  final double centerX;
  final double centerY;
  final double radiusX;
  final double radiusY;
  final double rotation;
  final bool allowEllipse;

  const CircleFocusSettings({
    this.centerX = 0.5,
    this.centerY = 0.45,
    this.radiusX = 0.24,
    this.radiusY = 0.24,
    this.rotation = 0.0,
    this.allowEllipse = true,
  });

  CircleFocusSettings copyWith({
    double? centerX,
    double? centerY,
    double? radiusX,
    double? radiusY,
    double? rotation,
    bool? allowEllipse,
  }) {
    return CircleFocusSettings(
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      radiusX: radiusX ?? this.radiusX,
      radiusY: radiusY ?? this.radiusY,
      rotation: rotation ?? this.rotation,
      allowEllipse: allowEllipse ?? this.allowEllipse,
    );
  }

  Map<String, dynamic> toJson() => {
        'centerX': centerX,
        'centerY': centerY,
        'radiusX': radiusX,
        'radiusY': radiusY,
        'rotation': rotation,
        'allowEllipse': allowEllipse,
      };

  factory CircleFocusSettings.fromJson(Map<String, dynamic> json) {
    return CircleFocusSettings(
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.5,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.45,
      radiusX: (json['radiusX'] as num?)?.toDouble() ?? 0.24,
      radiusY: (json['radiusY'] as num?)?.toDouble() ?? 0.24,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      allowEllipse: json['allowEllipse'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [centerX, centerY, radiusX, radiusY, rotation, allowEllipse];
}

class LineFocusSettings extends Equatable {
  final double centerX;
  final double centerY;
  final double angle;
  final double width;
  final double transition;

  const LineFocusSettings({
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.angle = 0.0,
    this.width = 0.22,
    this.transition = 0.18,
  });

  LineFocusSettings copyWith({
    double? centerX,
    double? centerY,
    double? angle,
    double? width,
    double? transition,
  }) {
    return LineFocusSettings(
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      angle: angle ?? this.angle,
      width: width ?? this.width,
      transition: transition ?? this.transition,
    );
  }

  Map<String, dynamic> toJson() => {
        'centerX': centerX,
        'centerY': centerY,
        'angle': angle,
        'width': width,
        'transition': transition,
      };

  factory LineFocusSettings.fromJson(Map<String, dynamic> json) {
    return LineFocusSettings(
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.5,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.5,
      angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.22,
      transition: (json['transition'] as num?)?.toDouble() ?? 0.18,
    );
  }

  @override
  List<Object?> get props => [centerX, centerY, angle, width, transition];
}
