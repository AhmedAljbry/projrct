import 'package:flutter/material.dart';

class ColorProfile {
  const ColorProfile({
    required this.temperature,
    required this.tint,
    required this.saturation,
    required this.vibrance,
    required this.palette,
  });

  const ColorProfile.neutral()
      : temperature = 0,
        tint = 0,
        saturation = 0,
        vibrance = 0,
        palette = const <Color>[];

  final double temperature;
  final double tint;
  final double saturation;
  final double vibrance;
  final List<Color> palette;

  ColorProfile copyWith({
    double? temperature,
    double? tint,
    double? saturation,
    double? vibrance,
    List<Color>? palette,
  }) {
    return ColorProfile(
      temperature: temperature ?? this.temperature,
      tint: tint ?? this.tint,
      saturation: saturation ?? this.saturation,
      vibrance: vibrance ?? this.vibrance,
      palette: palette ?? this.palette,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'temperature': temperature,
      'tint': tint,
      'saturation': saturation,
      'vibrance': vibrance,
      // ignore: deprecated_member_use
      // ignore: deprecated_member_use
      'palette': palette.map((color) => color.value).toList(),
    };
  }

  factory ColorProfile.fromMap(Map<String, dynamic> map) {
    final paletteValues =
        (map['palette'] as List<dynamic>? ?? const <dynamic>[])
            .map((value) => Color((value as num).toInt()))
            .toList(growable: false);
    return ColorProfile(
      temperature: _asDouble(map['temperature']),
      tint: _asDouble(map['tint']),
      saturation: _asDouble(map['saturation']),
      vibrance: _asDouble(map['vibrance']),
      palette: paletteValues,
    );
  }
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

