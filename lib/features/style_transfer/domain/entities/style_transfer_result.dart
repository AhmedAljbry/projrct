import 'dart:typed_data';

import 'package:untitled2/features/face_protection/domain/entities/style_safety_report.dart';
import 'package:untitled2/features/scene_analysis/domain/entities/scene_analysis_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';

class StyleTransferResult {
  const StyleTransferResult({
    required this.previewBytes,
    required this.exportBytes,
    required this.appliedProfile,
    required this.sceneAnalysis,
    required this.safetyReport,
    required this.compatibility,
    required this.appliedStrength,
    required this.previewRenderMs,
    required this.exportRenderMs,
    required this.exportReady,
    required this.warnings,
    required this.viralScore,
    required this.usedCachedPreview,
    required this.usedCachedAnalysis,
    required this.usedFallback,
    required this.watermarkApplied,
  });

  final Uint8List previewBytes;
  final Uint8List? exportBytes;
  final StyleProfile appliedProfile;
  final SceneAnalysisResult sceneAnalysis;
  final StyleSafetyReport safetyReport;
  final double compatibility;
  final double appliedStrength;
  final int previewRenderMs;
  final int exportRenderMs;
  final bool exportReady;
  final List<String> warnings;
  final double viralScore;
  final bool usedCachedPreview;
  final bool usedCachedAnalysis;
  final bool usedFallback;
  final bool watermarkApplied;

  StyleTransferResult copyWith({
    Uint8List? previewBytes,
    Uint8List? exportBytes,
    StyleProfile? appliedProfile,
    SceneAnalysisResult? sceneAnalysis,
    StyleSafetyReport? safetyReport,
    double? compatibility,
    double? appliedStrength,
    int? previewRenderMs,
    int? exportRenderMs,
    bool? exportReady,
    List<String>? warnings,
    double? viralScore,
    bool? usedCachedPreview,
    bool? usedCachedAnalysis,
    bool? usedFallback,
    bool? watermarkApplied,
  }) {
    return StyleTransferResult(
      previewBytes: previewBytes ?? this.previewBytes,
      exportBytes: exportBytes ?? this.exportBytes,
      appliedProfile: appliedProfile ?? this.appliedProfile,
      sceneAnalysis: sceneAnalysis ?? this.sceneAnalysis,
      safetyReport: safetyReport ?? this.safetyReport,
      compatibility: compatibility ?? this.compatibility,
      appliedStrength: appliedStrength ?? this.appliedStrength,
      previewRenderMs: previewRenderMs ?? this.previewRenderMs,
      exportRenderMs: exportRenderMs ?? this.exportRenderMs,
      exportReady: exportReady ?? this.exportReady,
      warnings: warnings ?? this.warnings,
      viralScore: viralScore ?? this.viralScore,
      usedCachedPreview: usedCachedPreview ?? this.usedCachedPreview,
      usedCachedAnalysis: usedCachedAnalysis ?? this.usedCachedAnalysis,
      usedFallback: usedFallback ?? this.usedFallback,
      watermarkApplied: watermarkApplied ?? this.watermarkApplied,
    );
  }
}
