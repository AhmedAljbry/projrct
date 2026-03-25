import 'dart:collection';
import 'package:flutter/material.dart';

enum StrokeMode { brush, eraser }

@immutable
class Stroke {
  /// Points stored in IMAGE-PIXEL coordinates (not screen/widget pixels).
  final UnmodifiableListView<Offset> pts;

  /// Stroke width in IMAGE pixels.
  final double width;

  final StrokeMode mode;

  Stroke({
    required List<Offset> pts,
    required this.width,
    required this.mode,
  }) : pts = UnmodifiableListView(pts);

  Stroke copyWith({
    List<Offset>? pts,
    double? width,
    StrokeMode? mode,
  }) =>
      Stroke(
        pts: pts ?? this.pts,
        width: width ?? this.width,
        mode: mode ?? this.mode,
      );
}

enum BrushKind { solid, soft, calligraphy, eraser }

@immutable
class BrushSettings {
  final BrushKind kind;
  final double width01; // 0..1 relative to image dimension
  final Color color;
  final double softness; // 0..1
  final double angleRad; // 0..pi
  final bool taper;

  const BrushSettings({
    required this.kind,
    required this.width01,
    required this.color,
    this.softness = 0.0,
    this.angleRad = 0.0,
    this.taper = false,
  });

  bool get isEraser => kind == BrushKind.eraser;

  BrushSettings copyWith({
    BrushKind? kind,
    double? width01,
    Color? color,
    double? softness,
    double? angleRad,
    bool? taper,
  }) =>
      BrushSettings(
        kind: kind ?? this.kind,
        width01: width01 ?? this.width01,
        color: color ?? this.color,
        softness: softness ?? this.softness,
        angleRad: angleRad ?? this.angleRad,
        taper: taper ?? this.taper,
      );
}
