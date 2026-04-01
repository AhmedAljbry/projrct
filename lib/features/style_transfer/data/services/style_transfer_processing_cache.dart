import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:untitled2/features/scene_analysis/domain/entities/scene_analysis_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_settings.dart';

class StyleTransferProcessingCache {
  final Map<String, StyleProfile> _styleProfiles = <String, StyleProfile>{};
  final Map<String, SceneAnalysisResult> _sceneAnalyses =
      <String, SceneAnalysisResult>{};
  final Map<String, SceneStatistics> _sceneStatistics =
      <String, SceneStatistics>{};
  final Map<String, SceneAnalysisResult> _maskBundles =
      <String, SceneAnalysisResult>{};
  final Map<String, StyleTransferResult> _previewResults =
      <String, StyleTransferResult>{};

  String bytesKey(Uint8List bytes) => sha1.convert(bytes).toString();

  String previewKey({
    required Uint8List targetBytes,
    required StyleProfile styleProfile,
    required StyleTransferSettings settings,
  }) {
    final digest = sha1.convert(
      utf8.encode(
        '${bytesKey(targetBytes)}:${styleProfile.id}:${jsonEncode(_normalizedSettingsMap(settings.toMap()))}',
      ),
    );
    return digest.toString();
  }

  StyleProfile? readStyle(Uint8List bytes) => _styleProfiles[bytesKey(bytes)];

  void writeStyle(Uint8List bytes, StyleProfile profile) {
    _styleProfiles[bytesKey(bytes)] = profile;
  }

  SceneAnalysisResult? readScene(Uint8List bytes) =>
      _sceneAnalyses[bytesKey(bytes)];

  void writeScene(Uint8List bytes, SceneAnalysisResult analysis) {
    _sceneAnalyses[bytesKey(bytes)] = analysis;
    _sceneStatistics[bytesKey(bytes)] = analysis.statistics;
    _maskBundles[bytesKey(bytes)] = analysis;
  }

  SceneStatistics? readStatistics(Uint8List bytes) =>
      _sceneStatistics[bytesKey(bytes)];

  SceneAnalysisResult? readMaskBundle(Uint8List bytes) =>
      _maskBundles[bytesKey(bytes)];

  StyleTransferResult? readPreview({
    required Uint8List targetBytes,
    required StyleProfile styleProfile,
    required StyleTransferSettings settings,
  }) {
    return _previewResults[previewKey(
        targetBytes: targetBytes,
        styleProfile: styleProfile,
        settings: settings)];
  }

  void writePreview({
    required Uint8List targetBytes,
    required StyleProfile styleProfile,
    required StyleTransferSettings settings,
    required StyleTransferResult result,
  }) {
    _previewResults[previewKey(
        targetBytes: targetBytes,
        styleProfile: styleProfile,
        settings: settings)] = result;
  }
}

Map<String, dynamic> _normalizedSettingsMap(Map<String, dynamic> source) {
  final output = <String, dynamic>{};
  for (final entry in source.entries) {
    output[entry.key] = _normalizeValue(entry.value);
  }
  return output;
}

dynamic _normalizeValue(dynamic value) {
  if (value is double) {
    return (value * 50).round() / 50;
  }
  if (value is num) {
    return value;
  }
  if (value is Map<String, dynamic>) {
    return _normalizedSettingsMap(value);
  }
  if (value is List<dynamic>) {
    return value.map(_normalizeValue).toList(growable: false);
  }
  return value;
}
