import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/i18n/t.dart';
import 'package:untitled2/core/monetization/domain/monetization_models.dart';
import 'package:untitled2/core/monetization/services/monetization_engine.dart';

import 'package:untitled2/core/ui/AppL10n.dart';
import 'package:untitled2/core/routing/app_routes.dart';
import 'package:untitled2/core/ui/cover_mapping.dart';
import 'package:untitled2/core/ui/mask_exporter.dart';
import 'package:untitled2/core/ui/mask_postprocess.dart';
import 'package:untitled2/inpainting/application/drawing/drawing_cubit.dart';
import 'package:untitled2/inpainting/application/drawing/drawing_state.dart';
import 'package:untitled2/inpainting/application/drawing/stroke.dart';
import 'package:untitled2/inpainting/application/image_pick_cubit.dart';
import 'package:untitled2/inpainting/application/inpainting_bloc/inpainting_bloc.dart';
import 'package:untitled2/inpainting/application/inpainting_bloc/inpainting_event.dart';
import 'package:untitled2/inpainting/presentation/widgets/ask_strokes_painter.dart';
import 'package:untitled2/inpainting/presentation/widgets/brush_cursor.dart';
import 'package:untitled2/inpainting/presentation/widgets/fixed_brush_magnifier.dart';
import 'package:untitled2/inpainting/presentation/widgets/image_painter.dart';
import 'package:untitled2/inpainting/presentation/widgets/inpainting_brush_controls.dart';
import 'package:untitled2/inpainting/presentation/widgets/inpainting_editor_toolbar.dart';
import 'package:untitled2/inpainting/presentation/widgets/inpainting_studio_chrome.dart';

part 'editor_page_ui_helpers.part.dart';
part 'editor_page_gestures.part.dart';
part 'editor_page_mask_render.part.dart';
part 'editor_page_mask_qa.part.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage>
    with SingleTickerProviderStateMixin {
  static const double _minViewportScale = 1.0;
  static const double _maxViewportScale = 6.0;

  final GlobalKey _stackKey = GlobalKey();
  final TransformationController _viewportController =
      TransformationController();

  bool _isPreparing = false;
  bool _showMaskOverlay = true;
  bool _showOriginalPreview = false;
  late AnimationController _glowController;

  Offset? _cursorPoint;
  Offset? _magnifierImagePoint;
  bool _isDrawingStroke = false;
  bool _isViewportGestureActive = false;
  int _activePointers = 0;
  double _gestureBaseScale = 1.0;
  Offset? _gestureSceneFocalPoint;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _viewportController.dispose();
    super.dispose();
  }

  void _updateEditorUi(VoidCallback updates) {
    if (!mounted) {
      return;
    }
    setState(updates);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final pickState = context.watch<ImagePickCubit>().state;

    if (pickState is! ImagePickReady) {
      return _buildErrorState(
        InpaintingStudioTheme.background,
        InpaintingStudioTheme.textPrimary,
        l10n,
        InpaintingStudioTheme.mint,
      );
    }

    final image = pickState.uiImage;

    return Scaffold(
      backgroundColor: const Color(0xFF061017),
      body: SafeArea(
        child: BlocBuilder<DrawingCubit, DrawingState>(
          builder: (context, drawingState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWideLayout = constraints.maxWidth >= 1040;
                final compactToolbar = constraints.maxWidth < 720;

                // For wide layouts, use a row-based structure.
                if (isWideLayout) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _buildTopSectionRow(l10n, drawingState, compactToolbar, image),
                                ),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, canvasConstraints) {
                                      final canvasSize = Size(canvasConstraints.maxWidth, canvasConstraints.maxHeight);
                                      return _buildCanvasWrapper(context, image, drawingState, canvasSize);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: math.min(386.0, constraints.maxWidth * 0.31),
                            decoration: const BoxDecoration(
                              border: Border(left: BorderSide(color: Colors.white12)),
                            ),
                            child: _buildControlsPanel(
                              context: context,
                              l10n: l10n,
                              layout: InpaintingControlsLayout.sideDock,
                            ),
                          ),
                        ],
                      ),
                      if (_isPreparing) _buildPreparingOverlay(),
                    ],
                  );
                }

                // ── Narrow layout: Column-based (Top → Image → Bottom) ──
                //
                // The bottom workspace height is adaptive:
                //  • landscape short screens  → compact 1-row ~72dp
                //  • portrait phones          → ~240-300dp via intrinsic
                //  • the canvas takes all remaining space
                final isLandscape = constraints.maxWidth > constraints.maxHeight;
                final bottomMaxHeight = isLandscape
                    ? math.min(88.0,  constraints.maxHeight * 0.38)
                    : math.min(300.0, constraints.maxHeight * 0.38);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Zone 1: Top Bar ──────────────────────────────
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            14, compactToolbar ? 10 : 14, 14, 6),
                          child: InpaintingEditorToolbar(
                            l10n: l10n,
                            title: l10n.get('magic_title'),
                            subtitle: drawingState.strokes.isEmpty
                                ? l10n.get('editor_tip_run')
                                : l10n.get('editor_tip_precision'),
                            statusLabel: drawingState.strokes.isEmpty
                                ? l10n.get('editor_mask_pending')
                                : l10n.get('editor_mask_ready'),
                            hasMask: drawingState.strokes.isNotEmpty,
                            compareEnabled: _showOriginalPreview,
                            canUndo: drawingState.canUndo,
                            canRedo: drawingState.canRedo,
                            compact: compactToolbar,
                            onBack: _handleBackNavigation,
                            onHelp: () => _showEditorHelpSheet(context, l10n),
                            onUndo: () => context.read<DrawingCubit>().undo(),
                            onRedo: () => context.read<DrawingCubit>().redo(),
                            onClear: () => context.read<DrawingCubit>().clear(),
                            onToggleCompare: _toggleComparePreview,
                            undoLabel: l10n.get('undo'),
                            redoLabel: l10n.get('redo'),
                            clearLabel: l10n.get('clear'),
                            compareLabel: l10n.get('compare'),
                            compareActiveLabel: l10n.get('compare_live'),
                          ),
                        ),

                        // ── Zone 2: Compact Status / Info Bar ───────────
                        if (!isLandscape)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                            child: _buildCompactInfoBar(
                              l10n: l10n,
                              drawingState: drawingState,
                              imageWidth: image.width,
                              imageHeight: image.height,
                              compact: compactToolbar,
                            ),
                          ),

                        // ── Zone 3: Canvas viewport (maximum flex) ──────
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, canvasConstraints) {
                              final canvasSize = Size(
                                canvasConstraints.maxWidth,
                                canvasConstraints.maxHeight,
                              );
                              return Stack(
                                children: [
                                  _buildCanvasWrapper(context, image, drawingState, canvasSize),

                                  // Zoom badge + active-mode pill (top-right)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        ValueListenableBuilder<Matrix4>(
                                          valueListenable: _viewportController,
                                          builder: (context, matrix, child) {
                                            return _buildZoomBadge(
                                              scale: matrix.getMaxScaleOnAxis(),
                                              accentColor: InpaintingStudioTheme.mint,
                                              compact: compactToolbar,
                                            );
                                          },
                                        ),
                                        if (_showOriginalPreview || !_showMaskOverlay) ...[
                                          const SizedBox(height: 6),
                                          StudioPill(
                                            icon: _showOriginalPreview
                                                ? Icons.compare_rounded
                                                : Icons.visibility_off_rounded,
                                            label: _showOriginalPreview
                                                ? l10n.get('original_label')
                                                : l10n.get('workflow_mask'),
                                            accent: _showOriginalPreview
                                                ? InpaintingStudioTheme.cyan
                                                : InpaintingStudioTheme.amber,
                                            filled: true,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // ── Zone 4: Bottom Tool Workspace ────────────────
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: bottomMaxHeight),
                          child: ValueListenableBuilder<Matrix4>(
                            valueListenable: _viewportController,
                            builder: (context, matrix, child) {
                              return _buildControlsPanel(
                                context: context,
                                l10n: l10n,
                                layout: InpaintingControlsLayout.bottomDock,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_isPreparing) _buildPreparingOverlay(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopSectionRow(AppL10n l10n, DrawingState drawingState, bool compactToolbar, ui.Image image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InpaintingEditorToolbar(
          l10n: l10n,
          title: l10n.get('magic_title'),
          subtitle: drawingState.strokes.isEmpty
              ? l10n.get('editor_tip_run')
              : l10n.get('editor_tip_precision'),
          statusLabel: drawingState.strokes.isEmpty
              ? l10n.get('editor_mask_pending')
              : l10n.get('editor_mask_ready'),
          hasMask: drawingState.strokes.isNotEmpty,
          compareEnabled: _showOriginalPreview,
          canUndo: drawingState.canUndo,
          canRedo: drawingState.canRedo,
          compact: compactToolbar,
          onBack: _handleBackNavigation,
          onHelp: () => _showEditorHelpSheet(context, l10n),
          onUndo: () => context.read<DrawingCubit>().undo(),
          onRedo: () => context.read<DrawingCubit>().redo(),
          onClear: () => context.read<DrawingCubit>().clear(),
          onToggleCompare: _toggleComparePreview,
          undoLabel: l10n.get('undo'),
          redoLabel: l10n.get('redo'),
          clearLabel: l10n.get('clear'),
          compareLabel: l10n.get('compare'),
          compareActiveLabel: l10n.get('compare_live'),
        ),
        const SizedBox(height: 8),
        _buildCompactInfoBar(
          l10n: l10n,
          drawingState: drawingState,
          imageWidth: image.width,
          imageHeight: image.height,
          compact: compactToolbar,
        ),
      ],
    );
  }

  Widget _buildCanvasWrapper(
    BuildContext context,
    ui.Image image,
    DrawingState drawingState,
    Size canvasSize,
  ) {
    // Adds a subtle border and clips the full screen canvas inside the available flex area
    return Container(
      width: canvasSize.width,
      height: canvasSize.height,
      decoration: BoxDecoration(
        color: const Color(0xFF040A10),
        border: Border.symmetric(
          horizontal: BorderSide(color: InpaintingStudioTheme.mint.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: ClipRect(
        child: _buildFullScreenCanvas(context, image, drawingState, canvasSize),
      ),
    );
  }

  Widget _buildFullScreenCanvas(
    BuildContext context,
    ui.Image image,
    DrawingState drawingState,
    Size canvasSize,
  ) {
    final brushWidthImagePx = _brushWidgetPxToImagePx(
      drawingState.brushSize,
      canvasSize,
      image.width,
      image.height,
    );

    final isCompactHud = canvasSize.shortestSide < 360;
    final magnifierDiameter = math.min(
      math.max(canvasSize.shortestSide * 0.42, 142.0),
      isCompactHud ? 160.0 : 212.0,
    );

    return Listener(
      onPointerDown: (_) => _handlePointerDown(context),
      onPointerUp: (_) => _handlePointerEnd(),
      onPointerCancel: (_) => _handlePointerEnd(),
      onPointerSignal: (event) => _onPointerSignal(event, canvasSize),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (details) => _onScaleStart(context, details, canvasSize),
        onScaleUpdate: (details) => _onScaleUpdate(context, details, canvasSize),
        onScaleEnd: (_) => _onScaleEnd(context),
        onDoubleTap: _resetViewport,
        child: Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<Matrix4>(
                valueListenable: _viewportController,
                builder: (context, matrix, child) {
                  return ClipRect(
                    child: Transform(
                      transform: matrix,
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  key: _stackKey,
                  width: canvasSize.width,
                  height: canvasSize.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: ImagePainter(
                            image,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _showMaskOverlay && !_showOriginalPreview ? 1 : 0,
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: MaskStrokesPainter(
                                  strokes: drawingState.strokes,
                                  isPreview: true,
                                  imageW: image.width,
                                  imageH: image.height,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_cursorPoint != null && !_isViewportGestureActive && !_showOriginalPreview)
              BrushCursor(
                point: _cursorPoint,
                size: drawingState.brushSize,
                visible: true,
                kind: drawingState.brush.kind,
              ),
            if (_magnifierImagePoint != null && !_isViewportGestureActive && !_showOriginalPreview)
              Positioned(
                top: 140, // Below top HUD elements
                left: 16,
                child: IgnorePointer(
                  child: FixedBrushMagnifier(
                    image: image,
                    strokes: drawingState.strokes,
                    focusImagePoint: _magnifierImagePoint!,
                    brushWidthImagePx: brushWidthImagePx,
                    brushKind: drawingState.brush.kind,
                    diameter: magnifierDiameter,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsPanel({
    required BuildContext context,
    required AppL10n l10n,
    required InpaintingControlsLayout layout,
  }) {
    return ValueListenableBuilder<Matrix4>(
      valueListenable: _viewportController,
      builder: (context, matrix, child) {
        return BlocBuilder<DrawingCubit, DrawingState>(
          builder: (context, drawingState) {
            return InpaintingBrushControls(
              l10n: l10n,
              t: T.from(context),
              layout: layout,
              isEraser: drawingState.brush.kind == BrushKind.eraser,
              hasMask: drawingState.strokes.isNotEmpty,
              canUndo: drawingState.canUndo,
              canRedo: drawingState.canRedo,
              maskVisible: _showMaskOverlay,
              compareEnabled: _showOriginalPreview,
              brushPx: drawingState.brushSize,
              currentZoom: matrix.getMaxScaleOnAxis(),
              strokeCount: drawingState.strokes.length,
              onBrushMode: () =>
                  context.read<DrawingCubit>().setBrushKind(BrushKind.solid),
              onEraserMode: () =>
                  context.read<DrawingCubit>().setBrushKind(BrushKind.eraser),
              onUndo: () => context.read<DrawingCubit>().undo(),
              onRedo: () => context.read<DrawingCubit>().redo(),
              onClear: () => context.read<DrawingCubit>().clear(),
              onResetWorkspace: () => _resetWorkspace(context),
              onResetViewport: _resetViewport,
              onMagic: () =>
                  _runMagicPipeline(context, _imageFromPick(context), l10n),
              onToggleMaskVisibility: _toggleMaskVisibility,
              onToggleCompare: _toggleComparePreview,
              onBrushSizeChanged: (value) =>
                  context.read<DrawingCubit>().setBrush(value),
            );
          },
        );
      },
    );
  }

  ui.Image _imageFromPick(BuildContext context) {
    final pickState = context.read<ImagePickCubit>().state;
    return (pickState as ImagePickReady).uiImage;
  }

  void _toggleMaskVisibility() {
    _updateEditorUi(() {
      _showMaskOverlay = !_showMaskOverlay;
    });
  }

  void _toggleComparePreview() {
    if (_isDrawingStroke) {
      context.read<DrawingCubit>().endStroke();
    }
    _updateEditorUi(() {
      _showOriginalPreview = !_showOriginalPreview;
      _cursorPoint = null;
      _magnifierImagePoint = null;
      _isDrawingStroke = false;
    });
  }

  void _resetWorkspace(BuildContext context) {
    context.read<DrawingCubit>().clear();
    _resetViewport();
    _updateEditorUi(() {
      _showMaskOverlay = true;
      _showOriginalPreview = false;
      _cursorPoint = null;
      _magnifierImagePoint = null;
      _isDrawingStroke = false;
    });
  }

  void _handleBackNavigation() {
    context.read<ImagePickCubit>().reset();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.magicEraser);
    }
  }

  Future<void> _showEditorHelpSheet(BuildContext context, AppL10n l10n) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: StudioGlassPanel(
            radius: 30,
            padding: EdgeInsets.all(20),
            fillColor: InpaintingStudioTheme.surfaceSoft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: InpaintingStudioTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_fix_high_rounded,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.get('magic_title'),
                        style: TextStyle(
                          color: InpaintingStudioTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                _HelpStep(
                  index: '01',
                  accent: InpaintingStudioTheme.cyan,
                  title: l10n.get('workflow_upload'),
                  body: l10n.get('pick_hint'),
                ),
                SizedBox(height: 12),
                _HelpStep(
                  index: '02',
                  accent: InpaintingStudioTheme.violet,
                  title: l10n.get('workflow_mask'),
                  body: l10n.get('editor_tip_precision'),
                ),
                SizedBox(height: 12),
                _HelpStep(
                  index: '03',
                  accent: InpaintingStudioTheme.mint,
                  title: l10n.get('workflow_render'),
                  body: l10n.get('magic_pick_feature_quality'),
                ),
                SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: StudioSecondaryButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: Icons.check_rounded,
                    label: l10n.get('cancel'),
                    accent: InpaintingStudioTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreparingOverlay() {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InpaintingStudioTheme.background.withValues(alpha: 0.52),
            ),
            child: Center(
              child: StudioGlassPanel(
                radius: 999,
                padding: EdgeInsets.all(24),
                gradient: InpaintingStudioTheme.accentGradient,
                borderColor: Colors.transparent,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  final String index;
  final Color accent;
  final String title;
  final String body;

  const _HelpStep({
    required this.index,
    required this.accent,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                index,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: InpaintingStudioTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: InpaintingStudioTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
