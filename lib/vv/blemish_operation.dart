import 'dart:ui';
import 'package:meta/meta.dart';
import 'brush_settings.dart';
import 'mask_data.dart';

/// Type of blemish stroke interaction.
enum StrokeType {
  /// Single-tap spot heal — target one small blemish.
  spotHeal,

  /// Drag stroke — multiple dabs along a path.
  dragHeal,
}

/// Immutable record of a single blemish removal operation.
/// This is the fundamental unit stored in the history stack and
/// serialised into a project file.
@immutable
class BlemishOperation {
  /// Unique identifier for this operation.
  final String id;

  /// Wall-clock timestamp of creation (for serialization ordering).
  final DateTime createdAt;

  /// The brush configuration active when this operation was applied.
  final BrushSettings brushSettings;

  /// All touch points recorded during the stroke, in image coordinate space.
  final List<Offset> strokePoints;

  /// Type of interaction that generated this operation.
  final StrokeType strokeType;

  /// The generated mask covering the blemish region.
  final MaskData mask;

  /// Optional: the patch source position chosen by the engine, in image space.
  /// Null if the engine picks it automatically.
  final Offset? sourcePatchOrigin;

  /// Whether this operation has been processed (healing result computed).
  final bool isProcessed;

  const BlemishOperation({
    required this.id,
    required this.createdAt,
    required this.brushSettings,
    required this.strokePoints,
    required this.strokeType,
    required this.mask,
    this.sourcePatchOrigin,
    this.isProcessed = false,
  }) : assert(strokePoints.length > 0);

  BlemishOperation copyWith({
    String? id,
    DateTime? createdAt,
    BrushSettings? brushSettings,
    List<Offset>? strokePoints,
    StrokeType? strokeType,
    MaskData? mask,
    Offset? sourcePatchOrigin,
    bool? isProcessed,
  }) {
    return BlemishOperation(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      brushSettings: brushSettings ?? this.brushSettings,
      strokePoints: strokePoints ?? this.strokePoints,
      strokeType: strokeType ?? this.strokeType,
      mask: mask ?? this.mask,
      sourcePatchOrigin: sourcePatchOrigin ?? this.sourcePatchOrigin,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }

  /// Axis-aligned bounding box of all stroke points expanded by brush radius.
  MaskBounds get strokeBounds {
    if (strokePoints.isEmpty) return MaskBounds.zero;
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in strokePoints) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    final r = brushSettings.radius.ceil();
    return MaskBounds(
      left: (minX - r).floor(),
      top: (minY - r).floor(),
      right: (maxX + r).ceil(),
      bottom: (maxY + r).ceil(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'brushSettings': brushSettings.toJson(),
        'strokePoints': strokePoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'strokeType': strokeType.name,
        'mask': mask.toJson(),
        'sourcePatchOrigin': sourcePatchOrigin != null
            ? {'x': sourcePatchOrigin!.dx, 'y': sourcePatchOrigin!.dy}
            : null,
        'isProcessed': isProcessed,
      };

  factory BlemishOperation.fromJson(Map<String, dynamic> json) {
    final pts = (json['strokePoints'] as List)
        .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
        .toList();
    final srcRaw = json['sourcePatchOrigin'] as Map<String, dynamic>?;
    return BlemishOperation(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      brushSettings: BrushSettings.fromJson(json['brushSettings'] as Map<String, dynamic>),
      strokePoints: pts,
      strokeType: StrokeType.values.firstWhere((e) => e.name == json['strokeType']),
      mask: MaskData.fromJson(json['mask'] as Map<String, dynamic>),
      sourcePatchOrigin: srcRaw != null
          ? Offset((srcRaw['x'] as num).toDouble(), (srcRaw['y'] as num).toDouble())
          : null,
      isProcessed: json['isProcessed'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'BlemishOperation(id=$id, type=$strokeType, pts=${strokePoints.length}, processed=$isProcessed)';
}
