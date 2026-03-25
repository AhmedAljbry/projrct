import 'package:equatable/equatable.dart';

/// Parameters defining the linear / tilt-shift focus band.
/// All positional values are normalised [0..1] relative to image dimensions.
class LineBlurParams extends Equatable {
  const LineBlurParams({
    this.centerX = 0.50,
    this.centerY = 0.50,
    this.angle = 0.0,
    this.bandWidth = 0.22,
    this.feather = 0.18,
  });

  /// Horizontal position of the band centre, normalised [0..1].
  final double centerX;

  /// Vertical position of the band centre, normalised [0..1].
  final double centerY;

  /// Rotation angle in radians. 0 = horizontal band.
  final double angle;

  /// Half-width of the in-focus band, normalised [0..1].
  final double bandWidth;

  /// Soft edge feathering width, normalised [0..1].
  final double feather;

  LineBlurParams copyWith({
    double? centerX,
    double? centerY,
    double? angle,
    double? bandWidth,
    double? feather,
  }) {
    return LineBlurParams(
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      angle: angle ?? this.angle,
      bandWidth: bandWidth ?? this.bandWidth,
      feather: feather ?? this.feather,
    );
  }

  Map<String, dynamic> toJson() => {
        'centerX': centerX,
        'centerY': centerY,
        'angle': angle,
        'bandWidth': bandWidth,
        'feather': feather,
      };

  factory LineBlurParams.fromJson(Map<String, dynamic> json) {
    return LineBlurParams(
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.50,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.50,
      angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
      bandWidth: (json['bandWidth'] as num?)?.toDouble() ?? 0.22,
      feather: (json['feather'] as num?)?.toDouble() ?? 0.18,
    );
  }

  @override
  List<Object?> get props => [centerX, centerY, angle, bandWidth, feather];
}
