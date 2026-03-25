import 'dart:typed_data';
import 'package:flutter/material.dart';

class MaskData {
  final Uint8List bytes;
  final int width;
  final int height;
  final Rect bounds;

  MaskData({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bounds,
  });
}

class ClonedObject {
  final String id;
  final Uint8List imageBytes;
  final MaskData mask;
  final Size originalSize;

  ClonedObject({
    required this.id,
    required this.imageBytes,
    required this.mask,
    required this.originalSize,
  });
}

class TransformState {
  final Offset position;
  final double scale;
  final double rotation; // in radians
  final bool flipX;
  final bool flipY;

  TransformState({
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.flipX = false,
    this.flipY = false,
  });

  TransformState copyWith({
    Offset? position,
    double? scale,
    double? rotation,
    bool? flipX,
    bool? flipY,
  }) {
    return TransformState(
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
    );
  }
}

class HarmonizationSettings {
  final double colorMatch;
  final double blendStrength;
  final double luminanceMatch;
  final double edgeFeather;
  final ShadowSettings shadow;

  HarmonizationSettings({
    this.colorMatch = 0.5,
    this.blendStrength = 0.5,
    this.luminanceMatch = 0.5,
    this.edgeFeather = 5.0,
    shadow,
  }) : shadow = shadow ?? ShadowSettings();

  HarmonizationSettings copyWith({
    double? colorMatch,
    double? blendStrength,
    double? luminanceMatch,
    double? edgeFeather,
    ShadowSettings? shadow,
  }) {
    return HarmonizationSettings(
      colorMatch: colorMatch ?? this.colorMatch,
      blendStrength: blendStrength ?? this.blendStrength,
      luminanceMatch: luminanceMatch ?? this.luminanceMatch,
      edgeFeather: edgeFeather ?? this.edgeFeather,
      shadow: shadow ?? this.shadow,
    );
  }
}

class ShadowSettings {
  final bool enabled;
  final double opacity;
  final double blur;
  final Offset offset;

  ShadowSettings({
    this.enabled = false,
    this.opacity = 0.3,
    this.blur = 10.0,
    this.offset = const Offset(5, 5),
  });

  ShadowSettings copyWith({
    bool? enabled,
    double? opacity,
    double? blur,
    Offset? offset,
  }) {
    return ShadowSettings(
      enabled: enabled ?? this.enabled,
      opacity: opacity ?? this.opacity,
      blur: blur ?? this.blur,
      offset: offset ?? this.offset,
    );
  }
}

class EditLayer {
  final String id;
  final ClonedObject object;
  final TransformState transform;
  final HarmonizationSettings harmonization;
  final bool isVisible;
  final int zIndex;

  EditLayer({
    required this.id,
    required this.object,
    required this.transform,
    required this.harmonization,
    this.isVisible = true,
    this.zIndex = 0,
  });

  EditLayer copyWith({
    TransformState? transform,
    HarmonizationSettings? harmonization,
    bool? isVisible,
    int? zIndex,
  }) {
    return EditLayer(
      id: id,
      object: object,
      transform: transform ?? this.transform,
      harmonization: harmonization ?? this.harmonization,
      isVisible: isVisible ?? this.isVisible,
      zIndex: zIndex ?? this.zIndex,
    );
  }
}
