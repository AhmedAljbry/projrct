import 'package:equatable/equatable.dart';

enum BlurShapeType { ellipse, rectangle }

class CircleBlurParams extends Equatable {
  const CircleBlurParams({
    this.centerX = 0.50,
    this.centerY = 0.45,
    this.radiusX = 0.24,
    this.radiusY = 0.24,
    this.rotation = 0.0,
    this.feather = 0.18,
    this.shapeType = BlurShapeType.ellipse,
  });

  final double centerX;
  final double centerY;
  final double radiusX;
  final double radiusY;
  final double rotation;
  final double feather;
  final BlurShapeType shapeType;

  CircleBlurParams copyWith({
    double? centerX,
    double? centerY,
    double? radiusX,
    double? radiusY,
    double? rotation,
    double? feather,
    BlurShapeType? shapeType,
  }) {
    return CircleBlurParams(
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      radiusX: radiusX ?? this.radiusX,
      radiusY: radiusY ?? this.radiusY,
      rotation: rotation ?? this.rotation,
      feather: feather ?? this.feather,
      shapeType: shapeType ?? this.shapeType,
    );
  }

  Map<String, dynamic> toJson() => {
        'centerX': centerX,
        'centerY': centerY,
        'radiusX': radiusX,
        'radiusY': radiusY,
        'rotation': rotation,
        'feather': feather,
        'shapeType': shapeType.name,
      };

  factory CircleBlurParams.fromJson(Map<String, dynamic> json) {
    return CircleBlurParams(
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.50,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.45,
      radiusX: (json['radiusX'] as num?)?.toDouble() ?? 0.24,
      radiusY: (json['radiusY'] as num?)?.toDouble() ?? 0.24,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      feather: (json['feather'] as num?)?.toDouble() ?? 0.18,
      shapeType: BlurShapeType.values.firstWhere(
        (shape) => shape.name == json['shapeType'],
        orElse: () => BlurShapeType.ellipse,
      ),
    );
  }

  @override
  List<Object?> get props => [
        centerX,
        centerY,
        radiusX,
        radiusY,
        rotation,
        feather,
        shapeType,
      ];
}
