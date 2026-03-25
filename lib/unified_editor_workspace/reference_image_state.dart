import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Extracted visual characteristics of a reference image.
class ReferenceProfile {
  /// Top dominant colors sampled from the reference (up to 6).
  final List<Color> palette;

  /// Average perceived luminance 0..1 (0 = very dark, 1 = very bright).
  final double avgLuminance;

  /// Average HSL saturation 0..1.
  final double avgSaturation;

  /// Contrast spread (std-dev of luminance across pixels) 0..1.
  final double contrast;

  /// Human-readable tone curve hint: 'bright', 'dark', 'balanced', 'warm', 'cool'.
  final String toneCurveHint;

  /// Warm/cool bias: positive = warm, negative = cool (-1..1).
  final double warmthBias;

  /// Shadow/highlight balance 0..1 (0 = crushed shadows, 1 = blown highlights).
  final double shadowHighlightRatio;

  /// Computed compatibility bias: how well this reference could match a typical target.
  /// Used to attenuate effect strength when mismatch is high.
  final double compatibilityBias; // 0..1, higher = better match

  const ReferenceProfile({
    required this.palette,
    required this.avgLuminance,
    required this.avgSaturation,
    required this.contrast,
    required this.toneCurveHint,
    required this.warmthBias,
    required this.shadowHighlightRatio,
    required this.compatibilityBias,
  });

  factory ReferenceProfile.empty() => const ReferenceProfile(
        palette: [],
        avgLuminance: 0.5,
        avgSaturation: 0.5,
        contrast: 0.5,
        toneCurveHint: 'balanced',
        warmthBias: 0.0,
        shadowHighlightRatio: 0.5,
        compatibilityBias: 0.75,
      );

  /// Compact display label for status chips.
  String get shortSummary =>
      '${toneCurveHint[0].toUpperCase()}${toneCurveHint.substring(1)} · '
      'Sat ${(avgSaturation * 100).round()}% · '
      'Luma ${(avgLuminance * 100).round()}%';
}

/// Holds the full reference image state across the editing session.
class ReferenceImageState {
  /// Raw bytes of the picked reference image (null = no reference loaded).
  final Uint8List? bytes;

  /// Analysed style profile derived from [bytes].
  final ReferenceProfile? profile;

  /// Whether the reference is currently active / enabled.
  final bool active;

  /// User-facing file / source label (e.g. "reference_01.jpg").
  final String label;

  const ReferenceImageState({
    this.bytes,
    this.profile,
    this.active = false,
    this.label = '',
  });

  bool get hasReference => bytes != null && active;

  ReferenceImageState copyWith({
    Uint8List? bytes,
    ReferenceProfile? profile,
    bool? active,
    String? label,
  }) {
    return ReferenceImageState(
      bytes: bytes ?? this.bytes,
      profile: profile ?? this.profile,
      active: active ?? this.active,
      label: label ?? this.label,
    );
  }

  static const ReferenceImageState none = ReferenceImageState(active: false);
}
