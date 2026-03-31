import 'dart:typed_data';

import 'package:untitled2/features/scene_analysis/domain/entities/scene_analysis_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_settings.dart';

class StyleTransferState {
  const StyleTransferState({
    required this.referenceBytes,
    required this.referenceName,
    required this.targetBytes,
    required this.targetName,
    required this.styleProfile,
    required this.referenceAnalysis,
    required this.targetAnalysis,
    required this.settings,
    required this.previewResult,
    required this.exportResult,
    required this.trendingStyles,
    required this.library,
    required this.savedPresets,
    required this.isPreparing,
    required this.isRenderingPreview,
    required this.isRenderingExport,
    required this.errorMessage,
    required this.statusMessage,
  });

  factory StyleTransferState.initial({
    required List<StyleProfile> trendingStyles,
    required Map<String, List<StyleProfile>> library,
  }) {
    return StyleTransferState(
      referenceBytes: null,
      referenceName: null,
      targetBytes: null,
      targetName: null,
      styleProfile: null,
      referenceAnalysis: null,
      targetAnalysis: null,
      settings: StyleTransferSettings.defaults(),
      previewResult: null,
      exportResult: null,
      trendingStyles: trendingStyles,
      library: library,
      savedPresets: const <StyleProfile>[],
      isPreparing: false,
      isRenderingPreview: false,
      isRenderingExport: false,
      errorMessage: null,
      statusMessage: null,
    );
  }

  final Uint8List? referenceBytes;
  final String? referenceName;
  final Uint8List? targetBytes;
  final String? targetName;
  final StyleProfile? styleProfile;
  final SceneAnalysisResult? referenceAnalysis;
  final SceneAnalysisResult? targetAnalysis;
  final StyleTransferSettings settings;
  final StyleTransferResult? previewResult;
  final StyleTransferResult? exportResult;
  final List<StyleProfile> trendingStyles;
  final Map<String, List<StyleProfile>> library;
  final List<StyleProfile> savedPresets;
  final bool isPreparing;
  final bool isRenderingPreview;
  final bool isRenderingExport;
  final String? errorMessage;
  final String? statusMessage;

  bool get canStart => targetBytes != null && styleProfile != null;

  StyleTransferState copyWith({
    Uint8List? referenceBytes,
    Object? referenceName = _sentinel,
    Uint8List? targetBytes,
    Object? targetName = _sentinel,
    StyleProfile? styleProfile,
    Object? referenceAnalysis = _sentinel,
    Object? targetAnalysis = _sentinel,
    StyleTransferSettings? settings,
    Object? previewResult = _sentinel,
    Object? exportResult = _sentinel,
    List<StyleProfile>? trendingStyles,
    Map<String, List<StyleProfile>>? library,
    List<StyleProfile>? savedPresets,
    bool? isPreparing,
    bool? isRenderingPreview,
    bool? isRenderingExport,
    Object? errorMessage = _sentinel,
    Object? statusMessage = _sentinel,
  }) {
    return StyleTransferState(
      referenceBytes: referenceBytes ?? this.referenceBytes,
      referenceName: identical(referenceName, _sentinel)
          ? this.referenceName
          : referenceName as String?,
      targetBytes: targetBytes ?? this.targetBytes,
      targetName: identical(targetName, _sentinel)
          ? this.targetName
          : targetName as String?,
      styleProfile: styleProfile ?? this.styleProfile,
      referenceAnalysis: identical(referenceAnalysis, _sentinel)
          ? this.referenceAnalysis
          : referenceAnalysis as SceneAnalysisResult?,
      targetAnalysis: identical(targetAnalysis, _sentinel)
          ? this.targetAnalysis
          : targetAnalysis as SceneAnalysisResult?,
      settings: settings ?? this.settings,
      previewResult: identical(previewResult, _sentinel)
          ? this.previewResult
          : previewResult as StyleTransferResult?,
      exportResult: identical(exportResult, _sentinel)
          ? this.exportResult
          : exportResult as StyleTransferResult?,
      trendingStyles: trendingStyles ?? this.trendingStyles,
      library: library ?? this.library,
      savedPresets: savedPresets ?? this.savedPresets,
      isPreparing: isPreparing ?? this.isPreparing,
      isRenderingPreview: isRenderingPreview ?? this.isRenderingPreview,
      isRenderingExport: isRenderingExport ?? this.isRenderingExport,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      statusMessage: identical(statusMessage, _sentinel)
          ? this.statusMessage
          : statusMessage as String?,
    );
  }
}

const Object _sentinel = Object();
