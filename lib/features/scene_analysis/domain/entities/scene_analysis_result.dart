import 'dart:typed_data';

class SceneAnalysis {
  const SceneAnalysis({
    required this.sceneType,
    required this.faceCount,
    required this.hasSkin,
    required this.hasHair,
    required this.hasSky,
    required this.hasForegroundSubject,
    required this.averageBrightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.segmentationConfidence,
  });

  final String sceneType;
  final int faceCount;
  final bool hasSkin;
  final bool hasHair;
  final bool hasSky;
  final bool hasForegroundSubject;
  final double averageBrightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double segmentationConfidence;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sceneType': sceneType,
      'faceCount': faceCount,
      'hasSkin': hasSkin,
      'hasHair': hasHair,
      'hasSky': hasSky,
      'hasForegroundSubject': hasForegroundSubject,
      'averageBrightness': averageBrightness,
      'contrast': contrast,
      'saturation': saturation,
      'warmth': warmth,
      'segmentationConfidence': segmentationConfidence,
    };
  }

  factory SceneAnalysis.fromMap(Map<String, dynamic> map) {
    return SceneAnalysis(
      sceneType: map['sceneType']?.toString() ?? 'editorial',
      faceCount: (map['faceCount'] as num?)?.toInt() ?? 0,
      hasSkin: map['hasSkin'] as bool? ?? false,
      hasHair: map['hasHair'] as bool? ?? false,
      hasSky: map['hasSky'] as bool? ?? false,
      hasForegroundSubject: map['hasForegroundSubject'] as bool? ?? false,
      averageBrightness: _asDouble(map['averageBrightness']),
      contrast: _asDouble(map['contrast']),
      saturation: _asDouble(map['saturation']),
      warmth: _asDouble(map['warmth']),
      segmentationConfidence: _asDouble(map['segmentationConfidence']),
    );
  }
}

class FaceRegion {
  const FaceRegion({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.confidence,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double confidence;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'left': left,
      'top': top,
      'width': width,
      'height': height,
      'confidence': confidence,
    };
  }

  factory FaceRegion.fromMap(Map<String, dynamic> map) {
    return FaceRegion(
      left: _asDouble(map['left']),
      top: _asDouble(map['top']),
      width: _asDouble(map['width']),
      height: _asDouble(map['height']),
      confidence: _asDouble(map['confidence']),
    );
  }
}

class SegmentationMask {
  const SegmentationMask({
    required this.width,
    required this.height,
    required this.values,
  });

  final int width;
  final int height;
  final Uint8List values;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': width,
      'height': height,
      'values': values,
    };
  }

  factory SegmentationMask.fromMap(Map<String, dynamic> map) {
    final rawValues = map['values'];
    final values = rawValues is Uint8List
        ? rawValues
        : Uint8List.fromList(
            (rawValues as List<dynamic>? ?? const <dynamic>[])
                .map((value) => (value as num).toInt())
                .toList(growable: false),
          );
    return SegmentationMask(
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      values: values,
    );
  }
}

class SceneStatistics {
  const SceneStatistics({
    required this.averageLuminance,
    required this.contrast,
    required this.averageSaturation,
    required this.temperature,
    required this.brightPixelRatio,
    required this.darkPixelRatio,
    required this.skinLikelihood,
    required this.skyLikelihood,
    required this.neutralLikelihood,
    required this.organicLikelihood,
    required this.furLikelihood,
    required this.edgeEnergy,
    required this.highlightHeadroom,
    required this.shadowHeadroom,
    required this.palette,
    required this.luminanceHistogram,
    required this.saturationHistogram,
  });

  final double averageLuminance;
  final double contrast;
  final double averageSaturation;
  final double temperature;
  final double brightPixelRatio;
  final double darkPixelRatio;
  final double skinLikelihood;
  final double skyLikelihood;
  final double neutralLikelihood;
  final double organicLikelihood;
  final double furLikelihood;
  final double edgeEnergy;
  final double highlightHeadroom;
  final double shadowHeadroom;
  final List<int> palette;
  final List<double> luminanceHistogram;
  final List<double> saturationHistogram;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'averageLuminance': averageLuminance,
      'contrast': contrast,
      'averageSaturation': averageSaturation,
      'temperature': temperature,
      'brightPixelRatio': brightPixelRatio,
      'darkPixelRatio': darkPixelRatio,
      'skinLikelihood': skinLikelihood,
      'skyLikelihood': skyLikelihood,
      'neutralLikelihood': neutralLikelihood,
      'organicLikelihood': organicLikelihood,
      'furLikelihood': furLikelihood,
      'edgeEnergy': edgeEnergy,
      'highlightHeadroom': highlightHeadroom,
      'shadowHeadroom': shadowHeadroom,
      'palette': palette,
      'luminanceHistogram': luminanceHistogram,
      'saturationHistogram': saturationHistogram,
    };
  }

  factory SceneStatistics.fromMap(Map<String, dynamic> map) {
    return SceneStatistics(
      averageLuminance: _asDouble(map['averageLuminance']),
      contrast: _asDouble(map['contrast']),
      averageSaturation: _asDouble(map['averageSaturation']),
      temperature: _asDouble(map['temperature']),
      brightPixelRatio: _asDouble(map['brightPixelRatio']),
      darkPixelRatio: _asDouble(map['darkPixelRatio']),
      skinLikelihood: _asDouble(map['skinLikelihood']),
      skyLikelihood: _asDouble(map['skyLikelihood']),
      neutralLikelihood: _asDouble(map['neutralLikelihood']),
      organicLikelihood: _asDouble(map['organicLikelihood']),
      furLikelihood: _asDouble(map['furLikelihood']),
      edgeEnergy: _asDouble(map['edgeEnergy']),
      highlightHeadroom: _asDouble(map['highlightHeadroom']),
      shadowHeadroom: _asDouble(map['shadowHeadroom']),
      palette: (map['palette'] as List<dynamic>? ?? const <dynamic>[])
          .map((entry) => (entry as num).toInt())
          .toList(growable: false),
      luminanceHistogram:
          _toDoubleList(map['luminanceHistogram'], fallbackLength: 16),
      saturationHistogram:
          _toDoubleList(map['saturationHistogram'], fallbackLength: 16),
    );
  }
}

class SceneAnalysisResult {
  const SceneAnalysisResult({
    required this.scene,
    required this.faces,
    required this.skinMask,
    required this.neutralMask,
    required this.hairMask,
    required this.backgroundMask,
    required this.skyMask,
    required this.foregroundMask,
    required this.statistics,
  });

  final SceneAnalysis scene;
  final List<FaceRegion> faces;
  final SegmentationMask skinMask;
  final SegmentationMask neutralMask;
  final SegmentationMask hairMask;
  final SegmentationMask backgroundMask;
  final SegmentationMask skyMask;
  final SegmentationMask foregroundMask;
  final SceneStatistics statistics;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'scene': scene.toMap(),
      'faces': faces.map((face) => face.toMap()).toList(),
      'skinMask': skinMask.toMap(),
      'neutralMask': neutralMask.toMap(),
      'hairMask': hairMask.toMap(),
      'backgroundMask': backgroundMask.toMap(),
      'skyMask': skyMask.toMap(),
      'foregroundMask': foregroundMask.toMap(),
      'statistics': statistics.toMap(),
    };
  }

  factory SceneAnalysisResult.fromMap(Map<String, dynamic> map) {
    return SceneAnalysisResult(
      scene: SceneAnalysis.fromMap(
        (map['scene'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      faces: (map['faces'] as List<dynamic>? ?? const <dynamic>[])
          .map((entry) => FaceRegion.fromMap(entry as Map<String, dynamic>))
          .toList(growable: false),
      skinMask: SegmentationMask.fromMap(
        (map['skinMask'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      neutralMask: SegmentationMask.fromMap(
        (map['neutralMask'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      hairMask: SegmentationMask.fromMap(
        (map['hairMask'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      backgroundMask: SegmentationMask.fromMap(
        (map['backgroundMask'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      skyMask: SegmentationMask.fromMap(
        (map['skyMask'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      foregroundMask: SegmentationMask.fromMap(
        (map['foregroundMask'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      statistics: SceneStatistics.fromMap(
        (map['statistics'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
    );
  }
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

List<double> _toDoubleList(dynamic value, {required int fallbackLength}) {
  final list = (value as List<dynamic>? ?? const <dynamic>[])
      .map((entry) => (entry as num).toDouble())
      .toList(growable: false);
  if (list.isNotEmpty) {
    return list;
  }
  return List<double>.filled(fallbackLength, 0);
}
