import 'package:equatable/equatable.dart';
import 'af_blur_mode.dart';
import 'af_focus_geometry.dart';

/// Immutable settings snapshot driving one render pass.
class AfBlurSettings extends Equatable {
  const AfBlurSettings({
    this.mode = AfBlurMode.smart,
    this.blurAmount = 16.0,
    this.transitionAmount = 0.42,
    this.subjectProtection = 0.92,
    this.edgeRefinement = 0.60,
    this.focusBoost = 0.08,
    this.invertMask = false,
    this.depthFalloff = 0.72,
    this.previewExposure = 0.0,
    this.circleSettings = const AfCircleSettings(),
    this.lineSettings = const AfLineSettings(),
    this.smartSettings = const AfSmartSettings(),
    this.brushRadius = 0.055,
    this.brushHardness = 0.85,
  });

  final AfBlurMode mode;
  final double blurAmount;
  final double transitionAmount;
  final double subjectProtection;
  final double edgeRefinement;
  final double focusBoost;
  final bool invertMask;
  final double depthFalloff;
  final double previewExposure;
  final AfCircleSettings circleSettings;
  final AfLineSettings lineSettings;
  final AfSmartSettings smartSettings;
  final double brushRadius;
  final double brushHardness;

  AfBlurSettings copyWith({
    AfBlurMode? mode,
    double? blurAmount,
    double? transitionAmount,
    double? subjectProtection,
    double? edgeRefinement,
    double? focusBoost,
    bool? invertMask,
    double? depthFalloff,
    double? previewExposure,
    AfCircleSettings? circleSettings,
    AfLineSettings? lineSettings,
    AfSmartSettings? smartSettings,
    double? brushRadius,
    double? brushHardness,
  }) {
    return AfBlurSettings(
      mode: mode ?? this.mode,
      blurAmount: blurAmount ?? this.blurAmount,
      transitionAmount: transitionAmount ?? this.transitionAmount,
      subjectProtection: subjectProtection ?? this.subjectProtection,
      edgeRefinement: edgeRefinement ?? this.edgeRefinement,
      focusBoost: focusBoost ?? this.focusBoost,
      invertMask: invertMask ?? this.invertMask,
      depthFalloff: depthFalloff ?? this.depthFalloff,
      previewExposure: previewExposure ?? this.previewExposure,
      circleSettings: circleSettings ?? this.circleSettings,
      lineSettings: lineSettings ?? this.lineSettings,
      smartSettings: smartSettings ?? this.smartSettings,
      brushRadius: brushRadius ?? this.brushRadius,
      brushHardness: brushHardness ?? this.brushHardness,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'blurAmount': blurAmount,
        'transitionAmount': transitionAmount,
        'subjectProtection': subjectProtection,
        'edgeRefinement': edgeRefinement,
        'focusBoost': focusBoost,
        'invertMask': invertMask,
        'depthFalloff': depthFalloff,
        'previewExposure': previewExposure,
        'circleSettings': circleSettings.toJson(),
        'lineSettings': lineSettings.toJson(),
        'smartSettings': smartSettings.toJson(),
        'brushRadius': brushRadius,
        'brushHardness': brushHardness,
      };

  @override
  List<Object?> get props => [
        mode,
        blurAmount,
        transitionAmount,
        subjectProtection,
        edgeRefinement,
        focusBoost,
        invertMask,
        depthFalloff,
        previewExposure,
        circleSettings,
        lineSettings,
        smartSettings,
        brushRadius,
        brushHardness,
      ];
}

/// Smart mode extra options.
class AfSmartSettings extends Equatable {
  const AfSmartSettings({
    this.protectFace = true,
    this.protectHands = false,
    this.antiHalo = 0.5,
    this.holeFill = 0.5,
  });

  final bool protectFace;
  final bool protectHands;
  final double antiHalo;
  final double holeFill;

  AfSmartSettings copyWith({
    bool? protectFace,
    bool? protectHands,
    double? antiHalo,
    double? holeFill,
  }) =>
      AfSmartSettings(
        protectFace: protectFace ?? this.protectFace,
        protectHands: protectHands ?? this.protectHands,
        antiHalo: antiHalo ?? this.antiHalo,
        holeFill: holeFill ?? this.holeFill,
      );

  Map<String, dynamic> toJson() => {
        'protectFace': protectFace,
        'protectHands': protectHands,
        'antiHalo': antiHalo,
        'holeFill': holeFill,
      };

  @override
  List<Object?> get props => [protectFace, protectHands, antiHalo, holeFill];
}
