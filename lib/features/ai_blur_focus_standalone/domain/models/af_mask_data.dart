import 'package:equatable/equatable.dart';
import 'af_focus_geometry.dart';

/// AI segmentation result — a flat confidence float mask.
class AfMaskData extends Equatable {
  const AfMaskData({
    required this.width,
    required this.height,
    required this.confidenceMask,
    this.primaryBounds,
    this.faceBounds = const [],
    this.usedFallback = false,
  });

  final int width;
  final int height;

  /// Float list, length == width * height, values in [0..1].
  final List<double> confidenceMask;
  final AfSegmentationBounds? primaryBounds;
  final List<AfSegmentationBounds> faceBounds;
  final bool usedFallback;

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'confidenceMask': confidenceMask,
        'primaryBounds': primaryBounds == null
            ? null
            : {
                'left': primaryBounds!.left,
                'top': primaryBounds!.top,
                'width': primaryBounds!.width,
                'height': primaryBounds!.height,
              },
        'faceBounds': faceBounds
            .map((f) => {
                  'left': f.left,
                  'top': f.top,
                  'width': f.width,
                  'height': f.height,
                })
            .toList(),
        'usedFallback': usedFallback,
      };

  static AfMaskData fromJson(Map<String, dynamic> json) {
    final boundsMap = json['primaryBounds'] as Map?;
    final faceList = json['faceBounds'] as List?;
    return AfMaskData(
      width: json['width'] as int,
      height: json['height'] as int,
      confidenceMask: ((json['confidenceMask'] as List?) ?? [])
          .map((v) => (v as num).toDouble())
          .toList(),
      primaryBounds: boundsMap == null
          ? null
          : AfSegmentationBounds(
              left: (boundsMap['left'] as num).toDouble(),
              top: (boundsMap['top'] as num).toDouble(),
              width: (boundsMap['width'] as num).toDouble(),
              height: (boundsMap['height'] as num).toDouble(),
            ),
      faceBounds: faceList == null
          ? []
          : faceList
              .map((f) => AfSegmentationBounds(
                    left: (f['left'] as num).toDouble(),
                    top: (f['top'] as num).toDouble(),
                    width: (f['width'] as num).toDouble(),
                    height: (f['height'] as num).toDouble(),
                  ))
              .toList(),
      usedFallback: json['usedFallback'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [width, height, confidenceMask, primaryBounds, faceBounds, usedFallback];
}

/// A manual brush stroke applied over the AI mask.
class AfManualStroke extends Equatable {
  const AfManualStroke({
    required this.points,
    required this.radius,
    required this.hardness,
    required this.add, // true = add to focus, false = erase from focus
  });

  final List<AfStrokePoint> points;
  final double radius;
  final double hardness;
  final bool add;

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => {'x': p.x, 'y': p.y}).toList(),
        'radius': radius,
        'hardness': hardness,
        'add': add,
      };

  @override
  List<Object?> get props => [points, radius, hardness, add];
}

class AfStrokePoint extends Equatable {
  const AfStrokePoint(this.x, this.y);
  final double x;
  final double y;
  @override
  List<Object?> get props => [x, y];
}
