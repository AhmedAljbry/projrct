import 'package:flutter/material.dart';

class FilterParams {
  // UI
  final int selectedTabIndex;

  // ===== Adjust =====
  final double contrast;         // 0.5..1.5
  final double saturation;       // 0..2
  final bool replaceBackground;

  // NEW adjust (used by your new UI)
  final double exposure;         // -1..1
  final double brightness;       // -0.5..0.5
  final double warmth;           // -1..1
  final double tint;             // -1..1
  final double highlights;       // -1..1
  final double shadows;          // -1..1
  final double clarity;          // -1..1
  final double dehaze;           // -1..1
  final double sharpen;          // 0..1
  final double vignetteSize;     // 0..1

  // ===== Effects =====
  final double blur;
  final double aura;
  final Color auraColor;
  final double grain;
  final double scanlines;
  final double glitch;
  final bool ghost;
  final bool colorPop;

  // Overlay color (your artistic layer)
  final Color? overlayColor;

  // ===== Overlays =====
  final bool showDateStamp;
  final bool cinemaMode;
  final bool polaroidFrame;
  final double vignette;         // 0..0.8
  final int lightLeakIndex;

  const FilterParams({
    this.selectedTabIndex = 0,

    // Adjust defaults
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.replaceBackground = false,

    // NEW adjust defaults
    this.exposure = 0.0,
    this.brightness = 0.0,
    this.warmth = 0.0,
    this.tint = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.clarity = 0.0,
    this.dehaze = 0.0,
    this.sharpen = 0.0,
    this.vignetteSize = 0.5,

    // Effects defaults
    this.blur = 0.0,
    this.aura = 0.0,
    this.auraColor = Colors.white,
    this.grain = 0.0,
    this.scanlines = 0.0,
    this.glitch = 0.0,
    this.ghost = false,
    this.colorPop = false,

    this.overlayColor,

    // Overlays defaults
    this.showDateStamp = false,
    this.cinemaMode = false,
    this.polaroidFrame = false,
    this.vignette = 0.0,
    this.lightLeakIndex = 0,
  });

  FilterParams copyWith({
    int? selectedTabIndex,

    double? contrast,
    double? saturation,
    bool? replaceBackground,

    double? exposure,
    double? brightness,
    double? warmth,
    double? tint,
    double? highlights,
    double? shadows,
    double? clarity,
    double? dehaze,
    double? sharpen,
    double? vignetteSize,

    double? blur,
    double? aura,
    Color? auraColor,
    double? grain,
    double? scanlines,
    double? glitch,
    bool? ghost,
    bool? colorPop,

    Color? overlayColor,

    bool? showDateStamp,
    bool? cinemaMode,
    bool? polaroidFrame,
    double? vignette,
    int? lightLeakIndex,
  }) {
    return FilterParams(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,

      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      replaceBackground: replaceBackground ?? this.replaceBackground,

      exposure: exposure ?? this.exposure,
      brightness: brightness ?? this.brightness,
      warmth: warmth ?? this.warmth,
      tint: tint ?? this.tint,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      clarity: clarity ?? this.clarity,
      dehaze: dehaze ?? this.dehaze,
      sharpen: sharpen ?? this.sharpen,
      vignetteSize: vignetteSize ?? this.vignetteSize,

      blur: blur ?? this.blur,
      aura: aura ?? this.aura,
      auraColor: auraColor ?? this.auraColor,
      grain: grain ?? this.grain,
      scanlines: scanlines ?? this.scanlines,
      glitch: glitch ?? this.glitch,
      ghost: ghost ?? this.ghost,
      colorPop: colorPop ?? this.colorPop,

      overlayColor: overlayColor ?? this.overlayColor,

      showDateStamp: showDateStamp ?? this.showDateStamp,
      cinemaMode: cinemaMode ?? this.cinemaMode,
      polaroidFrame: polaroidFrame ?? this.polaroidFrame,
      vignette: vignette ?? this.vignette,
      lightLeakIndex: lightLeakIndex ?? this.lightLeakIndex,
    );
  }
}