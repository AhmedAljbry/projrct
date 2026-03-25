import 'package:equatable/equatable.dart';

import 'blur_mode.dart';
import 'circle_params.dart';
import 'line_params.dart';

/// Immutable settings snapshot driving one render pass.
class BlurPhotoSettings extends Equatable {
  const BlurPhotoSettings({
    this.mode = BlurPhotoMode.full,
    this.blurIntensity = 16.0,
    this.transitionSoftness = 0.34,
    this.circle = const CircleBlurParams(),
    this.line = const LineBlurParams(),
  });

  /// Active blur mode.
  final BlurPhotoMode mode;

  /// Blur strength [2..30].
  final double blurIntensity;

  /// Softness of the edge transition [0..1].
  final double transitionSoftness;

  /// Circle geometry (used when mode == circle).
  final CircleBlurParams circle;

  /// Line geometry (used when mode == line).
  final LineBlurParams line;

  BlurPhotoSettings copyWith({
    BlurPhotoMode? mode,
    double? blurIntensity,
    double? transitionSoftness,
    CircleBlurParams? circle,
    LineBlurParams? line,
  }) {
    return BlurPhotoSettings(
      mode: mode ?? this.mode,
      blurIntensity: blurIntensity ?? this.blurIntensity,
      transitionSoftness: transitionSoftness ?? this.transitionSoftness,
      circle: circle ?? this.circle,
      line: line ?? this.line,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'blurIntensity': blurIntensity,
        'transitionSoftness': transitionSoftness,
        'circle': circle.toJson(),
        'line': line.toJson(),
      };

  factory BlurPhotoSettings.fromJson(Map<String, dynamic> json) {
    return BlurPhotoSettings(
      mode: BlurPhotoMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => BlurPhotoMode.full,
      ),
      blurIntensity: (json['blurIntensity'] as num?)?.toDouble() ?? 16.0,
      transitionSoftness:
          (json['transitionSoftness'] as num?)?.toDouble() ?? 0.34,
      circle: json['circle'] != null
          ? CircleBlurParams.fromJson(
              Map<String, dynamic>.from(json['circle'] as Map))
          : const CircleBlurParams(),
      line: json['line'] != null
          ? LineBlurParams.fromJson(
              Map<String, dynamic>.from(json['line'] as Map))
          : const LineBlurParams(),
    );
  }

  @override
  List<Object?> get props =>
      [mode, blurIntensity, transitionSoftness, circle, line];
}
