import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled2/core/ui/AppTheme.dart';

import 'editor_engine_controller.dart';
import 'editor_scope.dart';
import 'export_support.dart';
import 'reference_image_processor.dart';
import 'reference_image_state.dart';
import 'session_store.dart';
import 'workspace_scaffold.dart';

/// Unified premium editor workspace (Progressive Disclosure + Adaptive Layout).
///
/// Uses [sourceImageBytes] for gallery save/share (Gal + Share Plus).
/// Other panels are ready to wire to your existing processing engines.
class UnifiedEditorWorkspace extends StatefulWidget {
  /// Display title in the top bar.
  final String title;

  /// Raw bytes from picker — enables Save / Share to gallery.
  final Uint8List? sourceImageBytes;

  /// Optional preview images used by the canvas.
  /// If provided, `beforeImage` is the “original” and `afterImage` is the “result”.
  final ImageProvider? beforeImage;
  final ImageProvider? afterImage;

  /// Optional placeholder when no images are available.
  final Widget? emptyCanvas;

  const UnifiedEditorWorkspace({
    super.key,
    this.title = 'Unified Editor',
    this.sourceImageBytes,
    this.beforeImage,
    this.afterImage,
    this.emptyCanvas,
  });

  @override
  State<UnifiedEditorWorkspace> createState() => _UnifiedEditorWorkspaceState();
}

enum UnifiedEditorMode { quick, pro, architect }

/// Contextual actions exposed in the adaptive command dock.
///
/// Some actions “apply” instantly (presets), others open tool panels.
enum UnifiedDockAction {
  // Quick
  viral,
  natural,
  fix,
  styles,
  compare,

  // Pro
  regions,
  transfer,
  masks,
  lock,
  blend,
  refine,

  // Architect
  realism,
  materials,
  sky,
  light,
  glass,
  batch,

  // Shared
  export,
}

/// Which contextual panel should be shown in the side/bottom inspector.
enum UnifiedContextPanel {
  localColorTransfer,
  regionControl,
  smartMask,
  toneLock,
  styleBlend,
  multiSample,
  /// Pro: HSL + Curves + Multi-sample (single entry from Refine dock).
  proRefine,
  architectMaterials,
  sky,
  lighting,
  export,
  none,
}

class UnifiedEditorStatus {
  final String activeStyle;
  final double compatibilityScore; // 0..1

  final bool maskReady;
  final bool toneLockActive;
  final bool architectAssistActive;
  final bool regionSelected;
  final bool materialDetected;
  final bool compareActive;

  /// Scene routing label from imaging engine (e.g. "Portrait · 82%").
  final String sceneKindLabel;

  /// Compact style / pack signature for inspector.
  final String styleDnaDigest;

  /// Estimated mask reliability 0..1.
  final double maskConfidence;

  /// Material / structure detection confidence 0..1.
  final double materialConfidence;

  /// Short diagnostics line (histogram / night / edges).
  final String diagnosticsSummary;

  /// Preview / export / ML mask work in flight.
  final bool engineBusy;

  /// Whether a reference image is loaded and active.
  final bool referenceActive;

  /// Short label for the reference status chip (e.g. "Warm · Sat 62%").
  final String referenceLabel;

  const UnifiedEditorStatus({
    required this.activeStyle,
    required this.compatibilityScore,
    required this.maskReady,
    required this.toneLockActive,
    required this.architectAssistActive,
    required this.regionSelected,
    required this.materialDetected,
    required this.compareActive,
    this.sceneKindLabel = '',
    this.styleDnaDigest = '',
    this.maskConfidence = 0,
    this.materialConfidence = 0,
    this.diagnosticsSummary = '',
    this.engineBusy = false,
    this.referenceActive = false,
    this.referenceLabel = '',
  });

  UnifiedEditorStatus copyWith({
    String? activeStyle,
    double? compatibilityScore,
    bool? maskReady,
    bool? toneLockActive,
    bool? architectAssistActive,
    bool? regionSelected,
    bool? materialDetected,
    bool? compareActive,
    String? sceneKindLabel,
    String? styleDnaDigest,
    double? maskConfidence,
    double? materialConfidence,
    String? diagnosticsSummary,
    bool? engineBusy,
    bool? referenceActive,
    String? referenceLabel,
  }) {
    return UnifiedEditorStatus(
      activeStyle: activeStyle ?? this.activeStyle,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      maskReady: maskReady ?? this.maskReady,
      toneLockActive: toneLockActive ?? this.toneLockActive,
      architectAssistActive: architectAssistActive ?? this.architectAssistActive,
      regionSelected: regionSelected ?? this.regionSelected,
      materialDetected: materialDetected ?? this.materialDetected,
      compareActive: compareActive ?? this.compareActive,
      sceneKindLabel: sceneKindLabel ?? this.sceneKindLabel,
      styleDnaDigest: styleDnaDigest ?? this.styleDnaDigest,
      maskConfidence: maskConfidence ?? this.maskConfidence,
      materialConfidence: materialConfidence ?? this.materialConfidence,
      diagnosticsSummary: diagnosticsSummary ?? this.diagnosticsSummary,
      engineBusy: engineBusy ?? this.engineBusy,
      referenceActive: referenceActive ?? this.referenceActive,
      referenceLabel: referenceLabel ?? this.referenceLabel,
    );
  }
}

class _UnifiedEditorWorkspaceState extends State<UnifiedEditorWorkspace> {
  late final EditorEngineController _engine;

  UnifiedEditorMode _mode = UnifiedEditorMode.quick;
  UnifiedDockAction _activeDock = UnifiedDockAction.viral;
  UnifiedContextPanel _activePanel = UnifiedContextPanel.none;

  bool _compareEnabled = true;
  double _compareSplit = 0.56;
  bool _showAdvancedInspector = false;

  // ── Reference Image ──────────────────────────────────────────────────────
  ReferenceImageState _reference = ReferenceImageState.none;
  final _imagePicker = ImagePicker();

  /// UX / mode state; engine overlay merges scene + diagnostics for display.
  UnifiedEditorStatus _status = const UnifiedEditorStatus(
    activeStyle: 'Natural Premium',
    compatibilityScore: 0.74,
    maskReady: false,
    toneLockActive: false,
    architectAssistActive: false,
    regionSelected: false,
    materialDetected: false,
    compareActive: true,
  );

  @override
  void initState() {
    super.initState();
    _engine = EditorEngineController();
    _engine.addListener(_onEngineTick);
    unawaited(_bootstrapWorkspace());
  }

  Future<void> _bootstrapWorkspace() async {
    await UnifiedEditorSessionStore.restore(_engine);
    if (!mounted) return;
    if (widget.sourceImageBytes != null && widget.sourceImageBytes!.isNotEmpty) {
      _engine.setSource(widget.sourceImageBytes);
    }
  }

  @override
  void didUpdateWidget(covariant UnifiedEditorWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sourceImageBytes != oldWidget.sourceImageBytes &&
        widget.sourceImageBytes != null) {
      _engine.setSource(widget.sourceImageBytes);
    }
  }

  void _onEngineTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineTick);
    unawaited(UnifiedEditorSessionStore.save(_engine));
    _engine.dispose();
    super.dispose();
  }

  UnifiedEditorStatus get _displayStatus {
    final o = _engine.buildStatusOverlay(
      activeStyleName: _status.activeStyle,
      materialDetected: _status.materialDetected,
      uiCompatibility: _status.compatibilityScore,
    );
    return _status.copyWith(
      compatibilityScore: o.compatibilityScore,
      sceneKindLabel: o.sceneKindLabel,
      styleDnaDigest: o.styleDnaDigest,
      maskConfidence: o.maskConfidence,
      materialConfidence: o.materialConfidence,
      diagnosticsSummary: o.diagnosticsSummary,
      engineBusy: _engine.isBusy,
    );
  }

  void _setMode(UnifiedEditorMode nextMode) {
    if (_mode == nextMode) return;

    setState(() {
      _mode = nextMode;
      // Keep canvas context (compare split + overlay states), but reset tool focus.
      _activeDock = _dockDefaultForMode(nextMode);
      _activePanel = _panelForDock(_activeDock);
      // Progressive disclosure: keep expert content compact until requested.
      _showAdvancedInspector = false;
      _status = _status.copyWith(
        compareActive: _compareEnabled,
        // Mode implies intent; we keep score and style for continuity.
        architectAssistActive: nextMode == UnifiedEditorMode.architect,
      );
    });
  }

  UnifiedDockAction _dockDefaultForMode(UnifiedEditorMode mode) {
    switch (mode) {
      case UnifiedEditorMode.quick:
        return UnifiedDockAction.viral;
      case UnifiedEditorMode.pro:
        return UnifiedDockAction.regions;
      case UnifiedEditorMode.architect:
        return UnifiedDockAction.realism;
    }
  }

  UnifiedContextPanel _panelForDock(UnifiedDockAction dockAction) {
    switch (dockAction) {
      // Quick
      case UnifiedDockAction.viral:
      case UnifiedDockAction.natural:
        return UnifiedContextPanel.none;
      case UnifiedDockAction.fix:
        return UnifiedContextPanel.smartMask;
      case UnifiedDockAction.styles:
        return UnifiedContextPanel.none;
      case UnifiedDockAction.compare:
        return UnifiedContextPanel.none;

      // Pro
      case UnifiedDockAction.regions:
        return UnifiedContextPanel.regionControl;
      case UnifiedDockAction.transfer:
        return UnifiedContextPanel.localColorTransfer;
      case UnifiedDockAction.masks:
        return UnifiedContextPanel.smartMask;
      case UnifiedDockAction.lock:
        return UnifiedContextPanel.toneLock;
      case UnifiedDockAction.blend:
        return UnifiedContextPanel.styleBlend;
      case UnifiedDockAction.refine:
        return UnifiedContextPanel.proRefine;

      // Architect
      case UnifiedDockAction.realism:
        return UnifiedContextPanel.none;
      case UnifiedDockAction.materials:
        return UnifiedContextPanel.architectMaterials;
      case UnifiedDockAction.sky:
        return UnifiedContextPanel.sky;
      case UnifiedDockAction.light:
        return UnifiedContextPanel.lighting;
      case UnifiedDockAction.glass:
        return UnifiedContextPanel.architectMaterials;
      case UnifiedDockAction.batch:
        return UnifiedContextPanel.export;

      // Shared
      case UnifiedDockAction.export:
        return UnifiedContextPanel.export;
    }
  }

  void _onDockTapped(UnifiedDockAction action) {
    setState(() {
      _activeDock = action;
      _activePanel = _panelForDock(action);

      // Engine-backed quick intents + UI state.
      switch (action) {
        case UnifiedDockAction.viral:
          _engine.applyQuickViral();
          _status = _status.copyWith(activeStyle: 'Clean Influencer', compatibilityScore: 0.78);
          break;
        case UnifiedDockAction.natural:
          _engine.applyQuickNatural();
          _status = _status.copyWith(activeStyle: 'Natural Premium', compatibilityScore: 0.74);
          break;
        case UnifiedDockAction.fix:
          _engine.applyOneTapFix();
          _status = _status.copyWith(maskReady: true, activeStyle: 'Fix My Photo');
          break;
        case UnifiedDockAction.styles:
          _engine.clearQuickProfile();
          _status = _status.copyWith(activeStyle: 'Styles');
          break;
        case UnifiedDockAction.compare:
          _compareEnabled = !_compareEnabled;
          _status = _status.copyWith(compareActive: _compareEnabled);
          break;

        case UnifiedDockAction.regions:
          _status = _status.copyWith(regionSelected: true);
          break;
        case UnifiedDockAction.transfer:
          _status = _status.copyWith(compatibilityScore: (_status.compatibilityScore + 0.04).clamp(0, 1));
          break;
        case UnifiedDockAction.masks:
          _status = _status.copyWith(maskReady: true);
          break;
        case UnifiedDockAction.lock:
          _status = _status.copyWith(toneLockActive: true);
          break;
        case UnifiedDockAction.blend:
          _status = _status.copyWith(compatibilityScore: (_status.compatibilityScore + 0.03).clamp(0, 1));
          break;
        case UnifiedDockAction.refine:
          _status = _status.copyWith(compatibilityScore: (_status.compatibilityScore + 0.02).clamp(0, 1));
          break;

        case UnifiedDockAction.realism:
          _status = _status.copyWith(architectAssistActive: true, compatibilityScore: 0.81);
          break;
        case UnifiedDockAction.materials:
          _status = _status.copyWith(materialDetected: true, architectAssistActive: true);
          break;
        case UnifiedDockAction.sky:
          _status = _status.copyWith(compatibilityScore: (_status.compatibilityScore + 0.03).clamp(0, 1));
          break;
        case UnifiedDockAction.light:
          _status = _status.copyWith(compatibilityScore: (_status.compatibilityScore + 0.02).clamp(0, 1));
          break;
        case UnifiedDockAction.glass:
          _status = _status.copyWith(materialDetected: true, toneLockActive: true);
          break;
        case UnifiedDockAction.batch:
          _status = _status.copyWith(architectAssistActive: true);
          break;
        case UnifiedDockAction.export:
          _status = _status.copyWith(architectAssistActive: true);
          break;
      }
    });
  }

  void _onCompareToggled() {
    setState(() {
      _compareEnabled = !_compareEnabled;
      _status = _status.copyWith(compareActive: _compareEnabled);
    });
  }

  void _toggleAdvancedInspector() {
    setState(() {
      if (_mode == UnifiedEditorMode.quick) {
        // Quick mode stays calm: open advanced only when explicitly requested.
        _showAdvancedInspector = !_showAdvancedInspector;
      } else {
        _showAdvancedInspector = !_showAdvancedInspector;
      }
    });
  }

  Future<void> _runFullExportPipeline() async {
    try {
      await _engine.runFullExport();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full resolution render complete.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export render failed: $e')),
      );
    }
  }

  // ── Reference Image Callbacks ─────────────────────────────────────────────
  Future<void> _pickReference() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _reference = _reference.copyWith(
          bytes: bytes,
          active: true,
          label: picked.name,
        );
        _status = _status.copyWith(
          referenceActive: true,
          referenceLabel: 'Analysing…',
          compatibilityScore: (_status.compatibilityScore - 0.05).clamp(0.0, 1.0),
        );
      });
      // Analyse in background
      final profile = await ReferenceImageProcessor.analyze(bytes);
      if (!mounted) return;
      setState(() {
        _reference = _reference.copyWith(profile: profile);
        _status = _status.copyWith(
          referenceLabel: profile.shortSummary,
          compatibilityScore:
              (_status.compatibilityScore * 0.6 + profile.compatibilityBias * 0.4).clamp(0.0, 1.0),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load reference: $e')),
      );
    }
  }

  void _clearReference() {
    setState(() {
      _reference = ReferenceImageState.none;
      _status = _status.copyWith(
        referenceActive: false,
        referenceLabel: '',
      );
    });
  }

  void _requestExport() {
    setState(() {
      _activeDock = UnifiedDockAction.export;
      _activePanel = UnifiedContextPanel.export;
      _status = _status.copyWith(architectAssistActive: true);
    });
    unawaited(_runFullExportPipeline());
  }

  Future<void> _requestSave() async {
    final bytes = _engine.exportJpeg ?? widget.sourceImageBytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a photo first (open studio from home with image).')),
      );
      return;
    }
    final name = 'unified_studio_${DateTime.now().millisecondsSinceEpoch}';
    final err = await saveJpegToGallery(bytes, name: name);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $err')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to gallery')),
      );
    }
  }

  Future<void> _requestShare() async {
    final bytes = _engine.exportJpeg ?? widget.sourceImageBytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to share yet — pick an image first.')),
      );
      return;
    }
    try {
      await Share.shareXFiles([
        XFile.fromData(bytes, mimeType: 'image/jpeg', name: 'studio_share.jpg'),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  void _onStyleSelected(String styleName) {
    setState(() {
      if (styleName == 'Style Steal PRO') {
        _activePanel = UnifiedContextPanel.styleBlend;
        _activeDock = UnifiedDockAction.blend;
        _status = _status.copyWith(
          activeStyle: styleName,
          compatibilityScore: (_status.compatibilityScore + 0.02).clamp(0, 1),
        );
        return;
      }
      _engine.setPrimaryStyleByDisplayName(styleName);
      _status = _status.copyWith(
        activeStyle: styleName,
        compatibilityScore: (_status.compatibilityScore + 0.02).clamp(0, 1),
      );
      if (_mode == UnifiedEditorMode.quick) {
        _activeDock = UnifiedDockAction.styles;
        _activePanel = UnifiedContextPanel.none;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mem = widget.sourceImageBytes != null
        ? MemoryImage(widget.sourceImageBytes!)
        : null;
    final before = widget.beforeImage ?? mem;
    final preview = _engine.previewJpeg;
    final after = widget.afterImage ??
        (preview != null ? MemoryImage(preview) : mem);

    return EditorScope(
      controller: _engine,
      child: Stack(
        children: [
          Theme(
            data: AppTheme.dark,
            child: WorkspaceScaffold(
              mode: _mode,
              onModeChanged: _setMode,
              title: widget.title,
              status: _displayStatus,
              activeDock: _activeDock,
              activePanel: _activePanel,
              showAdvancedInspector: _showAdvancedInspector,
              compareEnabled: _compareEnabled,
              compareSplit: _compareSplit,
              beforeImage: before,
              afterImage: after,
              emptyCanvas: widget.emptyCanvas,
              onDockTapped: _onDockTapped,
              onStyleSelected: _onStyleSelected,
              onCompareToggled: _onCompareToggled,
              onAdvancedInspectorToggle: _toggleAdvancedInspector,
              onCompareSplitChanged: (v) {
                setState(() => _compareSplit = v);
              },
              onRequestExport: _requestExport,
              onRequestSave: _requestSave,
              onRequestShare: _requestShare,
              onActivePanelChanged: (p) => setState(() => _activePanel = p),
              referenceState: _reference,
              onAddReference: _pickReference,
              onClearReference: _clearReference,
            ),
          ),
          if (_engine.showBlockingOverlay)
            Positioned.fill(
              child: AbsorbPointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45)),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF56E39F)),
                        SizedBox(height: 14),
                        Text(
                          'Processing…',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

