import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as im;

import 'engine/creative_pipeline.dart';
import 'engine/creative_types.dart';
import 'engine/image_analysis.dart';
import 'engine/style_registry.dart';
import 'ml_subject_mask_bridge.dart';

/// Values merged into [UnifiedEditorStatus] by the workspace (avoid import cycles).
class EngineStatusOverlay {
  final String sceneKindLabel;
  final String styleDnaDigest;
  final double maskConfidence;
  final double materialConfidence;
  final String diagnosticsSummary;
  final double compatibilityScore;

  const EngineStatusOverlay({
    required this.sceneKindLabel,
    required this.styleDnaDigest,
    required this.maskConfidence,
    required this.materialConfidence,
    required this.diagnosticsSummary,
    required this.compatibilityScore,
  });
}

/// Orchestrates scene analysis, preview (isolate), and full export.
class EditorEngineController extends ChangeNotifier {
  Uint8List? _source;
  Uint8List? _previewJpeg;
  Uint8List? _fullJpeg;
  SceneAnalysis? _scene;

  String _packId = 'natural_premium';
  String? _secondaryPackId;
  double _blendT = 0;
  List<String> _samplePackIds = [];
  List<double> _sampleWeights = [];
  double _sampleMix = 0.72;

  double _hueShift = 0;
  double _satMul = 0;
  double _lumMul = 0;
  double _curveShadow = 0.5;
  double _curveMid = 0.5;
  double _curveHi = 0.5;
  double _curveMaster = 0.5;

  double _localTransfer = 0;
  String _ltSource = 'Subject';
  String _ltTarget = 'Background';
  double _ltFeather = 0.32;

  SmartMaskKind _maskKind = SmartMaskKind.none;
  double _toneLock = 0;
  double _glassEnhance = 0;
  double _skyEnhance = 0;
  String? _quickProfile;
  Uint8List? _referenceStealBytes;

  // Style Steal PRO controls (reference-driven grading deltas).
  // These must be user-driven (via the UI panel) and persisted across sessions.
  double _styleStealStrength = 1.0; // 0..1 scales reference deltas
  bool _stealToneEnabled = true; // exposure (light/dark distribution)
  bool _stealMoodEnabled = true; // warmth (overall mood)
  bool _stealColorEnabled = true; // saturation (color mood)

  Uint8List? _mlMaskPng;
  bool _mlMaskRefreshing = false;
  int _pipelineGen = 0;
  bool _previewBusy = false;
  bool _exportBusy = false;

  Timer? _debounce;

  Uint8List? get sourceBytes => _source;
  Uint8List? get previewJpeg => _previewJpeg;
  Uint8List? get exportJpeg => _fullJpeg ?? _previewJpeg;

  SceneAnalysis? get sceneAnalysis => _scene;

  String get primaryPackId => _packId;
  SmartMaskKind get maskKind => _maskKind;

  bool get isBusy => _previewBusy || _exportBusy || _mlMaskRefreshing;
  bool get exportBusy => _exportBusy;
  bool get mlMaskRefreshing => _mlMaskRefreshing;

  /// Heavy work only (avoid flicker on fast previews).
  bool get showBlockingOverlay => _exportBusy || _mlMaskRefreshing;

  static const int previewMaxSide = 1280;
  static const int fullMaxSide = 4096;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void setSource(Uint8List? bytes) {
    _source = bytes;
    _previewJpeg = null;
    _fullJpeg = null;
    _mlMaskPng = null;
    _scene = null;
    if (bytes != null && bytes.isNotEmpty) {
      final dec = im.decodeImage(bytes);
      if (dec != null) {
        final maxD = math.max(dec.width, dec.height);
        final scale = maxD > 360 ? 360 / maxD : 1.0;
        final thumb = im.copyResize(
          dec,
          width: math.max(1, (dec.width * scale).round()),
          height: math.max(1, (dec.height * scale).round()),
          interpolation: im.Interpolation.linear,
        );
        _scene = analyzeScene(thumb);
      }
    }
    notifyListeners();
    _scheduleMlSubjectMask();
    schedulePreview();
  }

  void setPrimaryStyleByDisplayName(String name) {
    final hit = CreativeStyleRegistry.byDisplayName(name);
    if (hit != null) {
      _packId = hit.id;
    } else {
      for (final p in CreativeStyleRegistry.corePacks) {
        if (p.displayName == name) _packId = p.id;
      }
      for (final p in CreativeStyleRegistry.architectPacks) {
        if (p.displayName == name) _packId = p.id;
      }
    }
    _quickProfile = null;
    schedulePreview();
  }

  void setPrimaryPackId(String id) {
    _packId = id;
    schedulePreview();
  }

  void setQuickProfile(String? profile) {
    _quickProfile = profile;
    schedulePreview();
  }

  void setStyleBlend({required String secondaryId, required double t}) {
    _secondaryPackId = secondaryId;
    _blendT = t;
    schedulePreview();
  }

  void clearStyleBlend() {
    _secondaryPackId = null;
    _blendT = 0;
    schedulePreview();
  }

  void setMultiSample({
    required List<String> packIds,
    required List<double> weights,
    double mix = 0.72,
  }) {
    _samplePackIds = List.from(packIds);
    _sampleWeights = List.from(weights);
    _sampleMix = mix;
    schedulePreview();
  }

  void clearMultiSample() {
    _samplePackIds = [];
    _sampleWeights = [];
    schedulePreview();
  }

  void setProColor({
    double? hueShift,
    double? satMul,
    double? lumMul,
    double? curveShadow,
    double? curveMid,
    double? curveHi,
    double? curveMaster,
  }) {
    if (hueShift != null) _hueShift = hueShift;
    if (satMul != null) _satMul = satMul;
    if (lumMul != null) _lumMul = lumMul;
    if (curveShadow != null) _curveShadow = curveShadow;
    if (curveMid != null) _curveMid = curveMid;
    if (curveHi != null) _curveHi = curveHi;
    if (curveMaster != null) _curveMaster = curveMaster;
    schedulePreview();
  }

  void setLocalTransfer({
    double? amount,
    String? sourceLabel,
    String? targetLabel,
    double? feather,
  }) {
    if (amount != null) _localTransfer = amount;
    if (sourceLabel != null) _ltSource = sourceLabel;
    if (targetLabel != null) _ltTarget = targetLabel;
    if (feather != null) _ltFeather = feather;
    schedulePreview();
  }

  void setMaskKind(SmartMaskKind k) {
    _maskKind = k;
    _scheduleMlSubjectMask();
    schedulePreview();
  }

  void setToneLock(double strength) {
    _toneLock = strength;
    schedulePreview();
  }

  void setArchitectExtras({double? glass, double? sky}) {
    if (glass != null) _glassEnhance = glass;
    if (sky != null) _skyEnhance = sky;
    schedulePreview();
  }

  void setReferenceSteal(Uint8List? ref) {
    _referenceStealBytes = ref;
    schedulePreview();
  }

  Map<String, dynamic> _buildCfg() {
    final m = <String, dynamic>{
      'packId': _packId,
      'hueShift': _hueShift,
      'satMul': _satMul,
      'lumMul': _lumMul,
      'curveShadow': _curveShadow,
      'curveMid': _curveMid,
      'curveHi': _curveHi,
      'curveMaster': _curveMaster,
      'localTransfer': _localTransfer,
      'ltSource': _ltSource,
      'ltTarget': _ltTarget,
      'ltFeather': _ltFeather,
      'maskKind': _maskKind.index,
      'toneLock': _toneLock,
      'glassEnhance': _glassEnhance,
      'skyEnhance': _skyEnhance,
      'quickProfile': _quickProfile,
    };
    if (_secondaryPackId != null && _blendT > 0.01) {
      m['secondaryPackId'] = _secondaryPackId;
      m['blendT'] = _blendT;
    }
    if (_samplePackIds.isNotEmpty) {
      m['samplePackIds'] = _samplePackIds;
      m['sampleWeights'] = _sampleWeights;
      m['sampleMixStrength'] = _sampleMix;
    }
    if (_mlMaskPng != null &&
        (_maskKind == SmartMaskKind.face || _maskKind == SmartMaskKind.subject)) {
      m['mlMaskPng'] = _mlMaskPng;
      m['mlSubjectBlend'] = 0.76;
    }
    return m;
  }

  void _scheduleMlSubjectMask() {
    _mlMaskPng = null;
    final src = _source;
    if (src == null || src.isEmpty) return;
    if (_maskKind != SmartMaskKind.face && _maskKind != SmartMaskKind.subject) {
      return;
    }
    unawaited(_runMlSubjectMask(src));
  }

  Future<void> _runMlSubjectMask(Uint8List src) async {
    _mlMaskRefreshing = true;
    notifyListeners();
    try {
      _mlMaskPng = await buildMlSubjectMaskPng(src);
    } finally {
      _mlMaskRefreshing = false;
      notifyListeners();
      schedulePreview();
    }
  }

  /// Merges reference statistics when [\_referenceStealBytes] set.
  Map<String, dynamic> _cfgWithSteal(Map<String, dynamic> base, im.Image working) {
    final refBytes = _referenceStealBytes;
    if (refBytes == null || refBytes.isEmpty) return base;
    final r0 = im.decodeImage(refBytes);
    if (r0 == null) return base;
    final ref = im.copyResize(
      r0,
      width: math.max(1, (r0.width * (320 / math.max(r0.width, r0.height))).round()),
      height: math.max(1, (r0.height * (320 / math.max(r0.width, r0.height))).round()),
      interpolation: im.Interpolation.linear,
    );
    final delta = styleStealDelta(working, ref);
    // Apply only the selected components and scale by the chosen PRO strength.
    final s = _styleStealStrength.clamp(0.0, 1.0);
    if (_stealToneEnabled) base['exposure'] = delta.exposure * s;
    if (_stealMoodEnabled) base['warmth'] = delta.warmth * s;
    if (_stealColorEnabled) base['saturation'] = delta.saturation * s;
    return base;
  }

  void setStyleStealProOptions({
    double? strength,
    bool? toneEnabled,
    bool? moodEnabled,
    bool? colorEnabled,
  }) {
    if (strength != null) _styleStealStrength = strength.clamp(0.0, 1.0);
    if (toneEnabled != null) _stealToneEnabled = toneEnabled;
    if (moodEnabled != null) _stealMoodEnabled = moodEnabled;
    if (colorEnabled != null) _stealColorEnabled = colorEnabled;
    schedulePreview();
  }

  void schedulePreview() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      unawaited(runPreview());
    });
  }

  Future<void> runPreview() async {
    final src = _source;
    if (src == null || src.isEmpty) return;
    final gen = ++_pipelineGen;
    _previewBusy = true;
    notifyListeners();
    try {
      var cfg = _buildCfg();
      final dec = im.decodeImage(src);
      if (dec != null) {
        final wIm = im.copyResize(
          dec,
          width: math.max(1, (dec.width * (480 / math.max(dec.width, dec.height))).round()),
          height: math.max(1, (dec.height * (480 / math.max(dec.width, dec.height))).round()),
          interpolation: im.Interpolation.linear,
        );
        cfg = _cfgWithSteal(cfg, wIm);
      }

      final out = await compute<Map<String, dynamic>, Uint8List>(
        runCreativePipelineIsolate,
        {
          'bytes': src,
          'maxSide': previewMaxSide,
          'jpegQuality': 88,
          'cfg': cfg,
        },
      );
      if (gen == _pipelineGen) {
        _previewJpeg = out;
      }
    } catch (_) {
      // Preserve last good preview; UI may show snackbar from workspace.
    } finally {
      if (gen == _pipelineGen) {
        _previewBusy = false;
      }
      notifyListeners();
    }
  }

  Future<void> runFullExport() async {
    final src = _source;
    if (src == null || src.isEmpty) return;
    final gen = ++_pipelineGen;
    _exportBusy = true;
    notifyListeners();
    try {
      var cfg = _buildCfg();
      final dec = im.decodeImage(src);
      if (dec != null) {
        final wIm = im.copyResize(
          dec,
          width: math.max(1, (dec.width * (480 / math.max(dec.width, dec.height))).round()),
          height: math.max(1, (dec.height * (480 / math.max(dec.width, dec.height))).round()),
          interpolation: im.Interpolation.linear,
        );
        cfg = _cfgWithSteal(cfg, wIm);
      }
      final out = await compute<Map<String, dynamic>, Uint8List>(
        runCreativePipelineIsolate,
        {
          'bytes': src,
          'maxSide': fullMaxSide,
          'jpegQuality': 93,
          'cfg': cfg,
        },
      );
      if (gen == _pipelineGen) {
        _fullJpeg = out;
      }
    } catch (_) {
      rethrow;
    } finally {
      if (gen == _pipelineGen) {
        _exportBusy = false;
      }
      notifyListeners();
    }
  }

  /// One-tap recovery: gentle contrast + detail, scene-aware via pipeline.
  void applyOneTapFix() {
    _quickProfile = 'fix';
    _curveMaster = 0.58;
    _curveShadow = 0.42;
    _curveHi = 0.55;
    _hueShift = 0;
    _satMul = -0.06;
    schedulePreview();
  }

  void resetProCurves() {
    _hueShift = 0;
    _satMul = 0;
    _lumMul = 0;
    _curveShadow = 0.5;
    _curveMid = 0.5;
    _curveHi = 0.5;
    _curveMaster = 0.5;
    _localTransfer = 0;
    _toneLock = 0;
    _glassEnhance = 0;
    _skyEnhance = 0;
    _quickProfile = null;
    schedulePreview();
  }

  EngineStatusOverlay buildStatusOverlay({
    required String activeStyleName,
    required bool materialDetected,
    required double uiCompatibility,
  }) {
    final s = _scene;
    if (s == null) {
      return EngineStatusOverlay(
        sceneKindLabel: '—',
        styleDnaDigest:
            CreativeStyleRegistry.byDisplayName(activeStyleName)?.id ?? 'custom',
        maskConfidence: _maskKind == SmartMaskKind.none
            ? 0.35
            : 0.72 + (_mlMaskPng != null ? 0.12 : 0),
        materialConfidence: materialDetected ? 0.78 : 0.4,
        diagnosticsSummary: _source == null ? 'No image' : 'Ready',
        compatibilityScore: uiCompatibility,
      );
    }

    final compat = (s.confidence * 0.55 + (uiCompatibility * 0.45)).clamp(0.2, 0.95);
    final sceneLabel = '${_labelScene(s.kind)} · ${(s.confidence * 100).round()}%';
    final dna = '$_packId · ${_quickProfile ?? 'graded'} · sky=${s.skyScore.toStringAsFixed(2)}';

    return EngineStatusOverlay(
      compatibilityScore: compat,
      sceneKindLabel: sceneLabel,
      styleDnaDigest: dna,
      maskConfidence: ((_maskKind == SmartMaskKind.none ? 0.38 : 0.68 + s.skinScore * 0.2) +
              (_mlMaskPng != null ? 0.1 : 0))
          .clamp(0.0, 1.0),
      materialConfidence: s.kind == SceneKind.architecture
          ? (0.72 + s.edgeDensity * 0.2).clamp(0, 1)
          : (0.45 + s.greenScore * 0.15).clamp(0, 1),
      diagnosticsSummary:
          'σ=${s.colorVariance.toStringAsFixed(2)} night=${s.nightScore.toStringAsFixed(2)} eg=${s.edgeDensity.toStringAsFixed(2)}',
    );
  }

  String _labelScene(SceneKind k) {
    switch (k) {
      case SceneKind.portrait:
        return 'Portrait';
      case SceneKind.wildlife:
        return 'Wildlife';
      case SceneKind.landscape:
        return 'Landscape';
      case SceneKind.product:
        return 'Product';
      case SceneKind.night:
        return 'Night';
      case SceneKind.architecture:
        return 'Architecture';
      case SceneKind.general:
        return 'Scene';
    }
  }

  void applyQuickViral() {
    _packId = 'clean_influencer';
    _quickProfile = 'viral';
    schedulePreview();
  }

  void applyQuickNatural() {
    _packId = 'natural_premium';
    _quickProfile = 'natural';
    schedulePreview();
  }

  void clearQuickProfile() {
    _quickProfile = null;
    schedulePreview();
  }

  Map<String, dynamic> toSessionMap() {
    return {
      'packId': _packId,
      'hueShift': _hueShift,
      'satMul': _satMul,
      'lumMul': _lumMul,
      'curveShadow': _curveShadow,
      'curveMid': _curveMid,
      'curveHi': _curveHi,
      'curveMaster': _curveMaster,
      'quickProfile': _quickProfile,
      'maskKind': _maskKind.index,
      'localTransfer': _localTransfer,
      'ltSource': _ltSource,
      'ltTarget': _ltTarget,
      'ltFeather': _ltFeather,
      'toneLock': _toneLock,
      'glass': _glassEnhance,
      'sky': _skyEnhance,
      'blendT': _blendT,
      'secondaryPackId': _secondaryPackId,
      'samplePackIds': _samplePackIds,
      'sampleWeights': _sampleWeights,
      'sampleMixStrength': _sampleMix,
      'styleStealStrength': _styleStealStrength,
      'stealToneEnabled': _stealToneEnabled,
      'stealMoodEnabled': _stealMoodEnabled,
      'stealColorEnabled': _stealColorEnabled,
    };
  }

  void restoreSessionMap(Map<String, dynamic> m) {
    _packId = m['packId'] as String? ?? _packId;
    _hueShift = (m['hueShift'] as num?)?.toDouble() ?? _hueShift;
    _satMul = (m['satMul'] as num?)?.toDouble() ?? _satMul;
    _lumMul = (m['lumMul'] as num?)?.toDouble() ?? _lumMul;
    _curveShadow = (m['curveShadow'] as num?)?.toDouble() ?? _curveShadow;
    _curveMid = (m['curveMid'] as num?)?.toDouble() ?? _curveMid;
    _curveHi = (m['curveHi'] as num?)?.toDouble() ?? _curveHi;
    _curveMaster = (m['curveMaster'] as num?)?.toDouble() ?? _curveMaster;
    _quickProfile = m['quickProfile'] as String? ?? _quickProfile;
    final mk = (m['maskKind'] as num?)?.toInt();
    if (mk != null && mk >= 0 && mk < SmartMaskKind.values.length) {
      _maskKind = SmartMaskKind.values[mk];
    }
    _localTransfer = (m['localTransfer'] as num?)?.toDouble() ?? _localTransfer;
    _ltSource = m['ltSource'] as String? ?? _ltSource;
    _ltTarget = m['ltTarget'] as String? ?? _ltTarget;
    _ltFeather = (m['ltFeather'] as num?)?.toDouble() ?? _ltFeather;
    _toneLock = (m['toneLock'] as num?)?.toDouble() ?? _toneLock;
    _glassEnhance = (m['glass'] as num?)?.toDouble() ?? _glassEnhance;
    _skyEnhance = (m['sky'] as num?)?.toDouble() ?? _skyEnhance;
    _blendT = (m['blendT'] as num?)?.toDouble() ?? _blendT;
    _secondaryPackId = m['secondaryPackId'] as String?;

    final sp = m['samplePackIds'];
    final sw = m['sampleWeights'];
    if (sp is List && sw is List) {
      final packs = sp.whereType<String>().toList();
      final weights = sw
          .map((e) => (e as num).toDouble())
          .toList(growable: false);
      final count = math.min(packs.length, weights.length);
      _samplePackIds = packs.take(count).toList(growable: false);
      _sampleWeights = weights.take(count).toList(growable: false);
    }
    _sampleMix = (m['sampleMixStrength'] as num?)?.toDouble() ?? _sampleMix;

    _styleStealStrength =
        (m['styleStealStrength'] as num?)?.toDouble() ?? _styleStealStrength;
    _stealToneEnabled =
        m['stealToneEnabled'] as bool? ?? _stealToneEnabled;
    _stealMoodEnabled =
        m['stealMoodEnabled'] as bool? ?? _stealMoodEnabled;
    _stealColorEnabled =
        m['stealColorEnabled'] as bool? ?? _stealColorEnabled;
    notifyListeners();
    schedulePreview();
  }
}
