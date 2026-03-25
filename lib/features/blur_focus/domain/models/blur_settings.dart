import 'package:equatable/equatable.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_mode.dart';
import 'package:untitled2/features/blur_focus/domain/models/focus_geometry.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';

class BlurSettings extends Equatable {
  final BlurMode mode;
  final double blurAmount;
  final double transitionAmount;
  final double subjectProtection;
  final double edgeRefinement;
  final double focusBoost;
  final bool invertMask;
  final double depthFalloff;
  final double previewExposure;
  final CircleFocusSettings circleSettings;
  final LineFocusSettings lineSettings;
  final SmartBlurSettings smartSettings;
  final double manualBrushRadius;
  final double manualBrushHardness;

  const BlurSettings({
    this.mode = BlurMode.smart,
    this.blurAmount = 12.0,
    this.transitionAmount = 0.42,
    this.subjectProtection = 0.88,
    this.edgeRefinement = 0.6,
    this.focusBoost = 0.08,
    this.invertMask = false,
    this.depthFalloff = 0.72,
    this.previewExposure = 0.0,
    this.circleSettings = const CircleFocusSettings(),
    this.lineSettings = const LineFocusSettings(),
    this.smartSettings = const SmartBlurSettings(),
    this.manualBrushRadius = 0.055,
    this.manualBrushHardness = 0.85,
  });

  BlurSettings copyWith({
    BlurMode? mode,
    double? blurAmount,
    double? transitionAmount,
    double? subjectProtection,
    double? edgeRefinement,
    double? focusBoost,
    bool? invertMask,
    double? depthFalloff,
    double? previewExposure,
    CircleFocusSettings? circleSettings,
    LineFocusSettings? lineSettings,
    SmartBlurSettings? smartSettings,
    double? manualBrushRadius,
    double? manualBrushHardness,
  }) {
    return BlurSettings(
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
      manualBrushRadius: manualBrushRadius ?? this.manualBrushRadius,
      manualBrushHardness: manualBrushHardness ?? this.manualBrushHardness,
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
        'manualBrushRadius': manualBrushRadius,
        'manualBrushHardness': manualBrushHardness,
      };

  factory BlurSettings.fromJson(Map<String, dynamic> json) {
    return BlurSettings(
      mode: BlurMode.values.firstWhere(
        (mode) => mode.name == json['mode'],
        orElse: () => BlurMode.smart,
      ),
      blurAmount: (json['blurAmount'] as num?)?.toDouble() ?? 12.0,
      transitionAmount: (json['transitionAmount'] as num?)?.toDouble() ?? 0.42,
      subjectProtection: (json['subjectProtection'] as num?)?.toDouble() ?? 0.88,
      edgeRefinement: (json['edgeRefinement'] as num?)?.toDouble() ?? 0.6,
      focusBoost: (json['focusBoost'] as num?)?.toDouble() ?? 0.08,
      invertMask: json['invertMask'] as bool? ?? false,
      depthFalloff: (json['depthFalloff'] as num?)?.toDouble() ?? 0.72,
      previewExposure: (json['previewExposure'] as num?)?.toDouble() ?? 0.0,
      circleSettings: json['circleSettings'] == null
          ? const CircleFocusSettings()
          : CircleFocusSettings.fromJson(Map<String, dynamic>.from(json['circleSettings'] as Map)),
      lineSettings: json['lineSettings'] == null
          ? const LineFocusSettings()
          : LineFocusSettings.fromJson(Map<String, dynamic>.from(json['lineSettings'] as Map)),
      smartSettings: json['smartSettings'] == null
          ? const SmartBlurSettings()
          : SmartBlurSettings.fromJson(Map<String, dynamic>.from(json['smartSettings'] as Map)),
      manualBrushRadius: (json['manualBrushRadius'] as num?)?.toDouble() ?? 0.055,
      manualBrushHardness: (json['manualBrushHardness'] as num?)?.toDouble() ?? 0.85,
    );
  }

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
        manualBrushRadius,
        manualBrushHardness,
      ];
}
