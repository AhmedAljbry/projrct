part of 'editor_page.dart';

Widget _qaLine(String tag, String text) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Text(
      '[$tag] $text',
      style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
    ),
  );
}

void _toast(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor:
          isError ? InpaintingStudioTheme.danger : InpaintingStudioTheme.mint,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.only(bottom: 100, left: 16, right: 16),
    ),
  );
}

extension _EditorPageUIHelpers on _EditorPageState {
  Future<void> _runMagicPipeline(
    BuildContext context,
    ui.Image image,
    AppL10n l10n,
  ) async {
    final monetizationEngine = getIt<MonetizationEngine>();
    final inpaintingBloc = context.read<InpaintingBloc>();
    final router = GoRouter.of(context);
    final drawingState = context.read<DrawingCubit>().state;
    if (drawingState.strokes.isEmpty) {
      _toast(context, l10n.get('draw_first'), isError: true);
      return;
    }

    _updateEditorUi(() => _isPreparing = true);
    try {
      final decision = await monetizationEngine.guardPlacement(
        placement: MonetizationPlacement.processStart,
        operation: MonetizationOperationContext(
          operationId: 'magic_pipeline_${DateTime.now().millisecondsSinceEpoch}',
          operationType: 'magic_inpainting',
          estimatedApiCostUnits: 1.5,
          sessionDepth: context.read<InpaintingBloc>().state.pollCount,
          metadata: <String, Object?>{
            'stroke_count': drawingState.strokes.length,
          },
        ),
        uiState: MonetizationUiState(
          routeName: AppRoutes.editor,
          isEditingGestureActive:
              _isDrawingStroke || _isViewportGestureActive || _activePointers > 0,
          allowFullScreenAds: true,
        ),
      );
      await monetizationEngine.maybeShow(
        decision: decision,
        operation: MonetizationOperationContext(
          operationId: 'magic_pipeline_${DateTime.now().millisecondsSinceEpoch}',
          operationType: 'magic_inpainting',
          estimatedApiCostUnits: 1.5,
        ),
      );

      inpaintingBloc.add(
        InpaintingPrepare(message: 'Preparing image and mask'),
      );
      router.go(AppRoutes.processing);

      final raw = await _renderBinaryMask(image, drawingState);
      final maskBytes = await prepareMaskForLama(raw);
      final originalBytes = await _uiToBytes(image);

      inpaintingBloc.add(
        InpaintingStart(
          imageBytes: originalBytes,
          maskBytes: maskBytes,
        ),
      );
    } catch (e) {
      inpaintingBloc.add(
        InpaintingPreparationFailed('Preparation failed: $e'),
      );
    } finally {
      _updateEditorUi(() => _isPreparing = false);
    }
  }

  Widget _buildZoomBadge({
    required double scale,
    required Color accentColor,
    bool compact = false,
  }) {
    final label = 'x${scale.toStringAsFixed(scale < 2 ? 1 : 2)}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: InpaintingStudioTheme.surfaceSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.zoom_in_map_rounded, color: accentColor, size: 16),
              SizedBox(width: compact ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  color: InpaintingStudioTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  fontSize: compact ? 11.5 : 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestureHint({
    required AppL10n l10n,
    bool compact = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: InpaintingStudioTheme.surfaceSoft,
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HudLine(
                icon: Icons.draw_rounded,
                label: l10n.get('brush'),
                color: InpaintingStudioTheme.mint,
                compact: compact,
              ),
              SizedBox(height: compact ? 6 : 8),
              _HudLine(
                icon: Icons.zoom_in_map_rounded,
                label: l10n.get('editor_workspace_fit'),
                color: InpaintingStudioTheme.violet,
                compact: compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildCanvasActionRail({
    required VoidCallback onResetViewport,
    required String fitTooltip,
    VoidCallback? onShowQa,
    bool compact = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(compact ? 6 : 8),
          decoration: BoxDecoration(
            color: InpaintingStudioTheme.surfaceSoft,
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CanvasActionButton(
                icon: Icons.center_focus_strong_rounded,
                tooltip: fitTooltip,
                compact: compact,
                onTap: onResetViewport,
              ),
              if (onShowQa != null) ...[
                SizedBox(height: compact ? 6 : 8),
                _CanvasActionButton(
                  icon: Icons.bug_report_rounded,
                  tooltip: 'QA',
                  compact: compact,
                  onTap: onShowQa,
                  accent: InpaintingStudioTheme.amber,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorStatusCard({
    required AppL10n l10n,
    required DrawingState drawingState,
    required int imageWidth,
    required int imageHeight,
    bool compact = false,
  }) {
    final hasMask = drawingState.strokes.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 18 : 20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: InpaintingStudioTheme.surfaceSoft,
            borderRadius: BorderRadius.circular(compact ? 18 : 20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 28 : 32,
                    height: compact ? 28 : 32,
                    decoration: BoxDecoration(
                      color: (hasMask
                              ? InpaintingStudioTheme.mint
                              : InpaintingStudioTheme.amber)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasMask
                          ? Icons.auto_fix_high_rounded
                          : Icons.edit_rounded,
                      size: compact ? 15 : 18,
                      color: hasMask
                          ? InpaintingStudioTheme.mint
                          : InpaintingStudioTheme.amber,
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  Expanded(
                    child: Text(
                      hasMask
                          ? l10n.get('editor_mask_ready')
                          : l10n.get('editor_mask_pending'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InpaintingStudioTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 12.5 : 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniMetric(
                    label: l10n.get('workflow_mask'),
                    value: '${drawingState.strokes.length}',
                  ),
                  _MiniMetric(
                    label: l10n.get('brush'),
                    value: '${drawingState.brushSize.toInt()} px',
                  ),
                  _MiniMetric(
                    label: l10n.get('resolution'),
                    value: '$imageWidth x $imageHeight',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Zone 2 – Compact horizontal info bar under the top bar.
  /// Replaces the tall status-card with a lightweight single-row chip strip.
  Widget _buildCompactInfoBar({
    required AppL10n l10n,
    required DrawingState drawingState,
    required int imageWidth,
    required int imageHeight,
    bool compact = false,
  }) {
    final hasMask = drawingState.strokes.isNotEmpty;
    final statusColor = hasMask ? InpaintingStudioTheme.mint : InpaintingStudioTheme.amber;
    final statusIcon  = hasMask ? Icons.auto_fix_high_rounded : Icons.edit_rounded;
    final statusText  = hasMask
        ? l10n.get('editor_mask_ready')
        : l10n.get('editor_mask_pending');

    return SizedBox(
      height: compact ? 34 : 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _InfoChip(icon: statusIcon, label: statusText, accent: statusColor, prominent: true),
            const SizedBox(width: 6),
            _InfoChip(label: '${drawingState.strokes.length} ${l10n.get('workflow_mask')}',
                accent: InpaintingStudioTheme.textMuted),
            const SizedBox(width: 6),
            _InfoChip(label: '${drawingState.brushSize.toInt()} px',
                accent: InpaintingStudioTheme.textMuted),
            const SizedBox(width: 6),
            _InfoChip(label: '$imageWidth × $imageHeight',
                accent: InpaintingStudioTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    Color bgColor,
    Color textColor,
    AppL10n l10n,
    Color primaryColor,
  ) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_rounded,
              size: 64,
              color: textColor.withValues(alpha: 0.2),
            ),
            SizedBox(height: 16),
            Text(
              l10n.get('pick_hint'),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_rounded, color: Colors.black),
              label: Text(
                l10n.get('cancel'),
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  const _HudLine({
    required this.icon,
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 13 : 15, color: color),
        SizedBox(width: compact ? 6 : 8),
        Text(
          label,
          style: TextStyle(
            color: InpaintingStudioTheme.textPrimary,
            fontSize: compact ? 10.5 : 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }
}

class _CanvasActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool compact;
  final Color accent;

  const _CanvasActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.compact = false,
    this.accent = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: compact ? 34 : 38,
          height: compact ? 34 : 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, size: compact ? 17 : 19, color: accent),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: InpaintingStudioTheme.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: InpaintingStudioTheme.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InfoChip – compact pill chip for the horizontal Zone-2 info bar
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color accent;
  final bool prominent;

  const _InfoChip({
    this.icon,
    required this.label,
    required this.accent,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: prominent
            ? accent.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: prominent
              ? accent.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: accent),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: prominent ? accent : InpaintingStudioTheme.textSecondary,
              fontSize: 12,
              fontWeight: prominent ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
