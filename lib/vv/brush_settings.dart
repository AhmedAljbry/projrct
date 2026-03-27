import 'package:meta/meta.dart';

/// Immutable brush configuration for blemish removal strokes.
/// Controls the size, softness, and strength of the healing brush.
@immutable
class BrushSettings {
  /// Brush radius in logical pixels (pre-zoom).
  final double radius;

  /// Feather/softness factor in [0.0, 1.0].
  /// 0 = hard edge, 1 = fully soft gaussian falloff.
  final double softness;

  /// Healing strength in [0.0, 1.0].
  /// Controls how aggressively the blemish region is replaced.
  final double strength;

  /// Spacing between dabs when dragging (0.0–1.0 as fraction of radius).
  /// Lower = denser stroke, higher = more separated dabs.
  final double spacing;

  /// Whether to simulate pressure variation from touch velocity.
  final bool velocityPressure;

  const BrushSettings({
    this.radius = 34.0,
    this.softness = 0.7,
    this.strength = 0.90,
    this.spacing = 0.25,
    this.velocityPressure = false,
  })  : assert(radius > 0.0),
        assert(softness >= 0.0 && softness <= 1.0),
        assert(strength >= 0.0 && strength <= 1.0),
        assert(spacing >= 0.0 && spacing <= 1.0);

  BrushSettings copyWith({
    double? radius,
    double? softness,
    double? strength,
    double? spacing,
    bool? velocityPressure,
  }) {
    return BrushSettings(
      radius: radius ?? this.radius,
      softness: softness ?? this.softness,
      strength: strength ?? this.strength,
      spacing: spacing ?? this.spacing,
      velocityPressure: velocityPressure ?? this.velocityPressure,
    );
  }

  Map<String, dynamic> toJson() => {
        'radius': radius,
        'softness': softness,
        'strength': strength,
        'spacing': spacing,
        'velocityPressure': velocityPressure,
      };

  factory BrushSettings.fromJson(Map<String, dynamic> json) => BrushSettings(
        radius: (json['radius'] as num).toDouble(),
        softness: (json['softness'] as num).toDouble(),
        strength: (json['strength'] as num).toDouble(),
        spacing: (json['spacing'] as num).toDouble(),
        velocityPressure: json['velocityPressure'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrushSettings &&
          radius == other.radius &&
          softness == other.softness &&
          strength == other.strength &&
          spacing == other.spacing &&
          velocityPressure == other.velocityPressure;

  @override
  int get hashCode => Object.hash(radius, softness, strength, spacing, velocityPressure);

  @override
  String toString() =>
      'BrushSettings(r=$radius, soft=$softness, str=$strength, sp=$spacing)';
}

