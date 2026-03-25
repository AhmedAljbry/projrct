import 'package:equatable/equatable.dart';

class BrushSettings extends Equatable {
  final double size;
  final double opacity;
  final double hardness; // 0.0 to 1.0 (soft to hard)
  final double flow; // 0.0 to 1.0
  final double spacing;
  final bool edgeProtect;
  final bool skinSafe;
  final bool faceSafe;
  final double adaptiveBlendStrength;

  const BrushSettings({
    this.size = 30.0,
    this.opacity = 1.0,
    this.hardness = 0.5,
    this.flow = 1.0,
    this.spacing = 0.1,
    this.edgeProtect = false,
    this.skinSafe = false,
    this.faceSafe = false,
    this.adaptiveBlendStrength = 0.5,
  });

  BrushSettings copyWith({
    double? size,
    double? opacity,
    double? hardness,
    double? flow,
    double? spacing,
    bool? edgeProtect,
    bool? skinSafe,
    bool? faceSafe,
    double? adaptiveBlendStrength,
  }) {
    return BrushSettings(
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      hardness: hardness ?? this.hardness,
      flow: flow ?? this.flow,
      spacing: spacing ?? this.spacing,
      edgeProtect: edgeProtect ?? this.edgeProtect,
      skinSafe: skinSafe ?? this.skinSafe,
      faceSafe: faceSafe ?? this.faceSafe,
      adaptiveBlendStrength: adaptiveBlendStrength ?? this.adaptiveBlendStrength,
    );
  }

  @override
  List<Object?> get props => [
        size,
        opacity,
        hardness,
        flow,
        spacing,
        edgeProtect,
        skinSafe,
        faceSafe,
        adaptiveBlendStrength,
      ];
}
