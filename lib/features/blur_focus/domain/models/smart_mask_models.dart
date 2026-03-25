import 'package:equatable/equatable.dart';

class SmartBlurSettings extends Equatable {
  final bool protectFace;
  final bool protectHands;
  final double antiHalo;
  final double holeFill;
  final double contourCleanup;
  final double falloffStrength;

  const SmartBlurSettings({
    this.protectFace = true,
    this.protectHands = false,
    this.antiHalo = 0.55,
    this.holeFill = 0.45,
    this.contourCleanup = 0.5,
    this.falloffStrength = 0.7,
  });

  SmartBlurSettings copyWith({
    bool? protectFace,
    bool? protectHands,
    double? antiHalo,
    double? holeFill,
    double? contourCleanup,
    double? falloffStrength,
  }) {
    return SmartBlurSettings(
      protectFace: protectFace ?? this.protectFace,
      protectHands: protectHands ?? this.protectHands,
      antiHalo: antiHalo ?? this.antiHalo,
      holeFill: holeFill ?? this.holeFill,
      contourCleanup: contourCleanup ?? this.contourCleanup,
      falloffStrength: falloffStrength ?? this.falloffStrength,
    );
  }

  Map<String, dynamic> toJson() => {
        'protectFace': protectFace,
        'protectHands': protectHands,
        'antiHalo': antiHalo,
        'holeFill': holeFill,
        'contourCleanup': contourCleanup,
        'falloffStrength': falloffStrength,
      };

  factory SmartBlurSettings.fromJson(Map<String, dynamic> json) {
    return SmartBlurSettings(
      protectFace: json['protectFace'] as bool? ?? true,
      protectHands: json['protectHands'] as bool? ?? false,
      antiHalo: (json['antiHalo'] as num?)?.toDouble() ?? 0.55,
      holeFill: (json['holeFill'] as num?)?.toDouble() ?? 0.45,
      contourCleanup: (json['contourCleanup'] as num?)?.toDouble() ?? 0.5,
      falloffStrength: (json['falloffStrength'] as num?)?.toDouble() ?? 0.7,
    );
  }

  @override
  List<Object?> get props => [protectFace, protectHands, antiHalo, holeFill, contourCleanup, falloffStrength];
}

class ManualMaskPoint extends Equatable {
  final double x;
  final double y;

  const ManualMaskPoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory ManualMaskPoint.fromJson(Map<String, dynamic> json) {
    return ManualMaskPoint(
      (json['x'] as num?)?.toDouble() ?? 0.0,
      (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [x, y];
}

enum ManualMaskBlendMode { include, exclude }

class ManualMaskStroke extends Equatable {
  final ManualMaskBlendMode blendMode;
  final double radius;
  final double hardness;
  final List<ManualMaskPoint> points;

  const ManualMaskStroke({
    required this.blendMode,
    required this.radius,
    required this.hardness,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'blendMode': blendMode.name,
        'radius': radius,
        'hardness': hardness,
        'points': points.map((point) => point.toJson()).toList(),
      };

  factory ManualMaskStroke.fromJson(Map<String, dynamic> json) {
    return ManualMaskStroke(
      blendMode: ManualMaskBlendMode.values.firstWhere(
        (mode) => mode.name == json['blendMode'],
        orElse: () => ManualMaskBlendMode.include,
      ),
      radius: (json['radius'] as num?)?.toDouble() ?? 0.05,
      hardness: (json['hardness'] as num?)?.toDouble() ?? 0.8,
      points: ((json['points'] as List?) ?? const [])
          .map((point) => ManualMaskPoint.fromJson(Map<String, dynamic>.from(point as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [blendMode, radius, hardness, points];
}

class SegmentationBounds extends Equatable {
  final double left;
  final double top;
  final double width;
  final double height;

  const SegmentationBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
      };

  factory SegmentationBounds.fromJson(Map<String, dynamic> json) {
    return SegmentationBounds(
      left: (json['left'] as num?)?.toDouble() ?? 0,
      top: (json['top'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 1,
      height: (json['height'] as num?)?.toDouble() ?? 1,
    );
  }

  @override
  List<Object?> get props => [left, top, width, height];
}

class SegmentationResultData extends Equatable {
  final int width;
  final int height;
  final List<double> confidenceMask;
  final SegmentationBounds? primaryBounds;
  final List<SegmentationBounds> faceBounds;
  final bool usedFallback;
  final DateTime createdAt;

  const SegmentationResultData({
    required this.width,
    required this.height,
    required this.confidenceMask,
    this.primaryBounds,
    this.faceBounds = const [],
    this.usedFallback = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'confidenceMask': confidenceMask,
        'primaryBounds': primaryBounds?.toJson(),
        'faceBounds': faceBounds.map((v) => v.toJson()).toList(),
        'usedFallback': usedFallback,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SegmentationResultData.fromJson(Map<String, dynamic> json) {
    return SegmentationResultData(
      width: json['width'] as int? ?? 1,
      height: json['height'] as int? ?? 1,
      confidenceMask: ((json['confidenceMask'] as List?) ?? const []).map((value) => (value as num).toDouble()).toList(),
      primaryBounds: json['primaryBounds'] == null
          ? null
          : SegmentationBounds.fromJson(Map<String, dynamic>.from(json['primaryBounds'] as Map)),
      faceBounds: ((json['faceBounds'] as List?) ?? const [])
          .map((v) => SegmentationBounds.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
      usedFallback: json['usedFallback'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [width, height, confidenceMask, primaryBounds, faceBounds, usedFallback, createdAt];
}
