import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/i18n/t.dart';

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
      backgroundColor: InpaintingStudioTheme.background,
      body: StudioGlowBackground(
        animation: _glowController,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideLayout = constraints.maxWidth >= 1040;
              final compactToolbar = constraints.maxWidth < 720;
              final horizontalPadding =
                  constraints.maxWidth < 460 ? 12.0 : 20.0;
              final verticalPadding = constraints.maxHeight < 760 ? 10.0 : 16.0;
              final sidePanelWidth =
                  math.min(386.0, constraints.maxWidth * 0.31);

              return Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      math.max(verticalPadding, 12),
                    ),
                    child: Column(
                      children: [
                        BlocBuilder<DrawingCubit, DrawingState>(
                          buildWhen: (previous, current) =>
                              previous.canUndo != current.canUndo ||
                              previous.canRedo != current.canRedo ||
                              previous.strokes.length != current.strokes.length,
                          builder: (context, drawingState) {
                            return InpaintingEditorToolbar(
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
                              onClear: () =>
                                  context.read<DrawingCubit>().clear(),
                              onToggleCompare: _toggleComparePreview,
                              undoLabel: l10n.get('undo'),
                              redoLabel: l10n.get('redo'),
                              clearLabel: l10n.get('clear'),
                              compareLabel: l10n.get('compare'),
                              compareActiveLabel: l10n.get('compare_live'),
                            );
                          },
                        ),
                        SizedBox(height: 14),
                        Expanded(
                          child: isWideLayout
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _buildWorkspaceCard(
                                        context: context,
                                        l10n: l10n,
                                        image: image,
                                        compact: false,
                                      ),
                                    ),
                                    SizedBox(width: 18),
                                    SizedBox(
                                      width: sidePanelWidth,
                                      child: _buildControlsPanel(
                                        context: context,
                                        l10n: l10n,
                                        layout:
                                            InpaintingControlsLayout.sideDock,
                                      ),
                                    ),
                                  ],
                                )
                              : _buildNarrowLayout(
                                  context: context,
                                  l10n: l10n,
                                  image: image,
                                  horizontalPadding: horizontalPadding,
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (_isPreparing) _buildPreparingOverlay(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Narrow layout: canvas fills available space, compact toolbar below,
  /// pinned Run AI row at the very bottom, DraggableScrollableSheet overlays
  /// advanced settings on demand.
  Widget _buildNarrowLayout({
    required BuildContext context,
    required AppL10n l10n,
    required ui.Image image,
    required double horizontalPadding,
  }) {
    return BlocBuilder<DrawingCubit, DrawingState>(
      builder: (context, drawingState) {
        return Stack(
          children: [
            // ── Main column: canvas + compact toolbar + CTA ──────────
            Column(
              children: [
                // Canvas (fills all available space)
                Expanded(
                  child: _buildWorkspaceCard(
                    context: context,
                    l10n: l10n,
                    image: image,
                    compact: true,
                    drawingStateOverride: drawingState,
                  ),
                ),
                SizedBox(height: 10),

                // Compact toolbar pill
                InpaintingCompactToolbar(
                  isEraser: drawingState.brush.kind == BrushKind.eraser,
                  maskVisible: _showMaskOverlay,
                  compareEnabled: _showOriginalPreview,
                  canUndo: drawingState.canUndo,
                  canRedo: drawingState.canRedo,
                  hasMask: drawingState.strokes.isNotEmpty,
                  brushPx: drawingState.brushSize,
                  onBrushMode: () =>
                      context.read<DrawingCubit>().setBrushKind(BrushKind.solid),
                  onEraserMode: () =>
                      context.read<DrawingCubit>().setBrushKind(BrushKind.eraser),
                  onToggleMaskVisibility: _toggleMaskVisibility,
                  onToggleCompare: _toggleComparePreview,
                  onUndo: () => context.read<DrawingCubit>().undo(),
                  onRedo: () => context.read<DrawingCubit>().redo(),
                  onResetViewport: _resetViewport,
                  onClear: () => context.read<DrawingCubit>().clear(),
                  onBrushSizeChanged: (v) =>
                      context.read<DrawingCubit>().setBrush(v),
                ),
                SizedBox(height: 10),

                // Pinned Run AI row
                _buildNarrowRunRow(
                  context: context,
                  l10n: l10n,
                  hasMask: drawingState.strokes.isNotEmpty,
                  image: image,
                ),
                SizedBox(height: 6),

                // Hint: swipe up for advanced
                Center(
                  child: Text(
                    '↑  ${l10n.get('preview_tools')}',
                    style: TextStyle(
                      color: InpaintingStudioTheme.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                SizedBox(height: 6),
              ],
            ),

            // ── Draggable advanced settings sheet ───────────────────
            DraggableScrollableSheet(
              initialChildSize: 0.10,
              minChildSize: 0.10,
              maxChildSize: 0.78,
              snap: true,
              snapSizes: const [0.10, 0.55, 0.78],
              builder: (sheetContext, scrollController) {
                return ValueListenableBuilder<Matrix4>(
                  valueListenable: _viewportController,
                  builder: (context, matrix, child) {
                    return _buildControlsPanel(
                      context: context,
                      l10n: l10n,
                      layout: InpaintingControlsLayout.bottomDock,
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildNarrowRunRow({
    required BuildContext context,
    required AppL10n l10n,
    required bool hasMask,
    required ui.Image image,
  }) {
    return Opacity(
      opacity: hasMask ? 1.0 : 0.44,
      child: InkWell(
        onTap: hasMask
            ? () => _runMagicPipeline(context, image, l10n)
            : null,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: hasMask
                ? InpaintingStudioTheme.primaryGradient
                : null,
            color: hasMask
                ? null
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasMask
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: hasMask
                ? const [
                    BoxShadow(
                      color: Color(0x326DC6B0),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_fix_high_rounded,
                size: 20,
                color: hasMask
                    ? Colors.black
                    : InpaintingStudioTheme.textMuted,
              ),
              SizedBox(width: 9),
              Text(
                l10n.get('magic'),
                style: TextStyle(
                  color: hasMask
                      ? Colors.black
                      : InpaintingStudioTheme.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 15.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceCard({
    required BuildContext context,
    required AppL10n l10n,
    required ui.Image image,
    required bool compact,
    DrawingState? drawingStateOverride,
  }) {
    Widget buildContent(DrawingState drawingState) {
      return StudioGlassPanel(
        radius: compact ? 28 : 34,
        padding: EdgeInsets.all(compact ? 10 : 16),
        fillColor: InpaintingStudioTheme.surfaceSoft,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(
              constraints.maxWidth,
              constraints.maxHeight -
                  (compact ? 92 : 108), // مساحة للهيدر + الفوتر داخل الكارد
            );

            final isCompactHud = compact || constraints.biggest.shortestSide < 360;

            final magnifierDiameter = math.min(
              math.max(constraints.biggest.shortestSide * 0.34, 116.0),
              isCompactHud ? 128.0 : 168.0,
            );

            final brushWidthImagePx = _brushWidgetPxToImagePx(
              drawingState.brushSize,
              canvasSize,
              image.width,
              image.height,
            );

            return Column(
              children: [
                // ── Top HUD row (خارج الصورة) ──────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildEditorStatusCard(
                        l10n: l10n,
                        drawingState: drawingState,
                        imageWidth: image.width,
                        imageHeight: image.height,
                        compact: isCompactHud,
                      ),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ValueListenableBuilder<Matrix4>(
                          valueListenable: _viewportController,
                          builder: (context, matrix, child) {
                            return _buildZoomBadge(
                              scale: matrix.getMaxScaleOnAxis(),
                              accentColor: InpaintingStudioTheme.mint,
                              compact: isCompactHud,
                            );
                          },
                        ),
                        if (_showOriginalPreview || !_showMaskOverlay) ...[
                          SizedBox(height: 8),
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
                  ],
                ),
                SizedBox(height: 10),

                // ── Canvas only ────────────────────────────────────────
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(compact ? 26 : 30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 34,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(compact ? 26 : 30),
                          child: Listener(
                            onPointerDown: (_) => _handlePointerDown(context),
                            onPointerUp: (_) => _handlePointerEnd(),
                            onPointerCancel: (_) => _handlePointerEnd(),
                            onPointerSignal: (event) =>
                                _onPointerSignal(event, canvasSize),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onScaleStart: (details) =>
                                  _onScaleStart(context, details, canvasSize),
                              onScaleUpdate: (details) =>
                                  _onScaleUpdate(context, details, canvasSize),
                              onScaleEnd: (_) => _onScaleEnd(context),
                              onDoubleTap: _resetViewport,
                              child: ColoredBox(
                                color: const Color(0xFF061017),
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
                                                    duration: const Duration(
                                                      milliseconds: 180,
                                                    ),
                                                    opacity: _showMaskOverlay &&
                                                        !_showOriginalPreview
                                                        ? 1
                                                        : 0,
                                                    child: RepaintBoundary(
                                                      child: CustomPaint(
                                                        painter: MaskStrokesPainter(
                                                          strokes:
                                                          drawingState.strokes,
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

                                    if (_cursorPoint != null &&
                                        !_isViewportGestureActive &&
                                        !_showOriginalPreview)
                                      BrushCursor(
                                        point: _cursorPoint,
                                        size: drawingState.brushSize,
                                        visible: true,
                                        kind: drawingState.brush.kind,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_magnifierImagePoint != null &&
                          !_isViewportGestureActive &&
                          !_showOriginalPreview)
                        Positioned(
                          top: 16,
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

                SizedBox(height: 10),

                // ── Bottom HUD row (خارج الصورة) ───────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: _buildGestureHint(
                        l10n: l10n,
                        compact: isCompactHud,
                      ),
                    ),
                    SizedBox(width: 10),
                    _buildCanvasActionRail(
                      compact: isCompactHud,
                      onResetViewport: _resetViewport,
                      fitTooltip: l10n.get('editor_workspace_fit'),
                      onShowQa: !const bool.fromEnvironment('dart.vm.product')
                          ? _testMaskRendering
                          : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    if (drawingStateOverride != null) {
      return buildContent(drawingStateOverride);
    }
    return BlocBuilder<DrawingCubit, DrawingState>(
      builder: (context, drawingState) => buildContent(drawingState),
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
