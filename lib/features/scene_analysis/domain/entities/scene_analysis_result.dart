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

class SceneAnalysisResult {
  const SceneAnalysisResult({
    required this.scene,
    required this.faces,
    required this.skinMask,
    required this.hairMask,
    required this.backgroundMask,
    required this.skyMask,
    required this.foregroundMask,
  });

  final SceneAnalysis scene;
  final List<FaceRegion> faces;
  final SegmentationMask skinMask;
  final SegmentationMask hairMask;
  final SegmentationMask backgroundMask;
  final SegmentationMask skyMask;
  final SegmentationMask foregroundMask;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'scene': scene.toMap(),
      'faces': faces.map((face) => face.toMap()).toList(),
      'skinMask': skinMask.toMap(),
      'hairMask': hairMask.toMap(),
      'backgroundMask': backgroundMask.toMap(),
      'skyMask': skyMask.toMap(),
      'foregroundMask': foregroundMask.toMap(),
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
    );
  }
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}
