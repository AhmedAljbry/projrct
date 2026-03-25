import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/AppL10n.dart';
import '../../application/drawing/drawing_cubit.dart';
import '../../application/drawing/drawing_state.dart';
import '../../application/drawing/stroke.dart';
import 'inpainting_studio_chrome.dart';

const _surface1 = InpaintingStudioTheme.surface;
const _surface2 = InpaintingStudioTheme.surfaceStrong;
const _border = Color(0x22FFFFFF);
const _accent = InpaintingStudioTheme.mint;
const _eraser = InpaintingStudioTheme.rose;
const _textPri = InpaintingStudioTheme.textPrimary;
const _textSec = InpaintingStudioTheme.textSecondary;
const _danger = InpaintingStudioTheme.danger;

const _slMin = 8.0;
const _slMax = 120.0;
const _w01Min = 0.01;
const _w01Max = 0.25;

enum ToolPanelLayout { bottomSheet, sideDock }

double _pxToW01(double px) {
  final t = ((px - _slMin) / (_slMax - _slMin)).clamp(0.0, 1.0);
  return (_w01Min + (_w01Max - _w01Min) * t).clamp(_w01Min, _w01Max);
}

double _w01ToPx(double w01) {
  final t = ((w01 - _w01Min) / (_w01Max - _w01Min)).clamp(0.0, 1.0);
  return (_slMin + (_slMax - _slMin) * t).clamp(_slMin, _slMax);
}

class ProToolPanel extends StatelessWidget {
  final AppL10n l10n;
  final VoidCallback onMagic;
  final VoidCallback onResetViewport;
  final double currentZoom;
  final ToolPanelLayout layout;

  const ProToolPanel({
    super.key,
    required this.l10n,
    required this.onMagic,
    required this.onResetViewport,
    required this.currentZoom,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrawingCubit, DrawingState>(
      builder: (context, state) {
        final brushPx = _w01ToPx(state.brush.width01);
        final isEraser = state.brush.kind == BrushKind.eraser;
        final content = _ToolPanelContent(
          l10n: l10n,
          state: state,
          brushPx: brushPx,
          isEraser: isEraser,
          currentZoom: currentZoom,
          onMagic: onMagic,
          onResetViewport: onResetViewport,
        );

        if (layout == ToolPanelLayout.sideDock) {
          return _ToolPanelShell(
            layout: layout,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: content,
            ),
          );
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.25,
          minChildSize: 0.17,
          maxChildSize: 0.62,
          snap: true,
          snapSizes: const [0.25, 0.42, 0.62],
          builder: (context, scrollController) {
            return _ToolPanelShell(
              layout: layout,
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(18, 0, 18, 38),
                children: [
                  SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  content,
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ToolPanelShell extends StatelessWidget {
  final ToolPanelLayout layout;
  final Widget child;

  const _ToolPanelShell({
    required this.layout,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final radius = layout == ToolPanelLayout.sideDock
        ? BorderRadius.circular(30)
        : BorderRadius.vertical(top: Radius.circular(30));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: InpaintingStudioTheme.surfaceSoft,
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ToolPanelContent extends StatelessWidget {
  final AppL10n l10n;
  final DrawingState state;
  final double brushPx;
  final bool isEraser;
  final double currentZoom;
  final VoidCallback onMagic;
  final VoidCallback onResetViewport;

  const _ToolPanelContent({
    required this.l10n,
    required this.state,
    required this.brushPx,
    required this.isEraser,
    required this.currentZoom,
    required this.onMagic,
    required this.onResetViewport,
  });

  @override
  Widget build(BuildContext context) {
    final brushAccent = isEraser ? _eraser : _accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeader(
          title: l10n.get('magic_title'),
          l10n: l10n,
          zoomLabel: 'x${currentZoom.toStringAsFixed(currentZoom < 2 ? 1 : 2)}',
          strokeCount: state.strokes.length,
          isMaskReady: state.strokes.isNotEmpty,
        ),
        SizedBox(height: 18),
        _MagicCTA(
          label: state.strokes.isEmpty ? l10n.get('workflow_mask') : l10n.get('magic'),
          hasStrokes: state.strokes.isNotEmpty,
          onTap: onMagic,
        ),
        SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ModeToggle(
                isBrush: !isEraser,
                brushLabel: l10n.get('brush'),
                eraserLabel: l10n.get('eraser'),
                onBrush: () =>
                    context.read<DrawingCubit>().setBrushKind(BrushKind.solid),
                onEraser: () =>
                    context.read<DrawingCubit>().setBrushKind(BrushKind.eraser),
              ),
            ),
            SizedBox(width: 12),
            _UndoRedo(
              canUndo: state.canUndo,
              canRedo: state.canRedo,
              onUndo: () => context.read<DrawingCubit>().undo(),
              onRedo: () => context.read<DrawingCubit>().redo(),
            ),
          ],
        ),
        SizedBox(height: 18),
        _InfoSection(
          title: l10n.get('brush_size'),
          child: _BrushPresetWrap(
            selectedPx: brushPx,
            accent: brushAccent,
            presets: const [14, 24, 36, 56, 84, 112],
            onSelect: (value) => context.read<DrawingCubit>().setBrush(value),
          ),
        ),
        SizedBox(height: 18),
        _InfoSection(
          title: l10n.get('brush_size'),
          child: _BrushSizeRow(
            label: l10n.get('brush_size'),
            px: brushPx,
            isEraser: isEraser,
            onChanged: (value) =>
                context.read<DrawingCubit>().setBrushWidth01(_pxToW01(value)),
          ),
        ),
        SizedBox(height: 18),
        _InfoSection(
          title: l10n.get('editor_workspace_fit'),
          child: _ViewportTools(
            zoomLabel:
                'x${currentZoom.toStringAsFixed(currentZoom < 2 ? 1 : 2)}',
            onResetViewport: onResetViewport,
            l10n: l10n,
          ),
        ),
        SizedBox(height: 18),
        _InfoSection(
          title: l10n.get('studio_quality'),
          child: _WorkspaceNotes(
            isEraser: isEraser,
            strokeCount: state.strokes.length,
            l10n: l10n,
          ),
        ),
        if (state.strokes.isNotEmpty) ...[
          SizedBox(height: 18),
          _ClearButton(
            label: l10n.get('clear'),
            onTap: () => context.read<DrawingCubit>().clear(),
          ),
        ],
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final String zoomLabel;
  final int strokeCount;
  final bool isMaskReady;
  final AppL10n l10n;

  const _PanelHeader({
    required this.title,
    required this.l10n,
    required this.zoomLabel,
    required this.strokeCount,
    required this.isMaskReady,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: InpaintingStudioTheme.primaryGradient,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _textPri,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniBadge(
              icon: Icons.zoom_in_map_rounded,
              label: zoomLabel,
              color: _accent,
            ),
            _MiniBadge(
              icon: Icons.gesture_rounded,
              label: '$strokeCount ${l10n.get('strokes')}',
              color: InpaintingStudioTheme.violet,
            ),
            _MiniBadge(
              icon:
                  isMaskReady ? Icons.check_circle_rounded : Icons.edit_rounded,
              label: isMaskReady ? l10n.get('ready') : l10n.get('mask'),
              color: isMaskReady ? _accent : InpaintingStudioTheme.amber,
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface2.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _textSec,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MagicCTA extends StatefulWidget {
  final String label;
  final bool hasStrokes;
  final VoidCallback onTap;

  const _MagicCTA({
    required this.label,
    required this.hasStrokes,
    required this.onTap,
  });

  @override
  State<_MagicCTA> createState() => _MagicCTAState();
}

class _MagicCTAState extends State<_MagicCTA>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.hasStrokes;

    return AnimatedOpacity(
      opacity: active ? 1.0 : 0.42,
      duration: const Duration(milliseconds: 280),
      child: GestureDetector(
        onTap: active ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (_, __) {
            return Container(
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: InpaintingStudioTheme.primaryGradient,
                boxShadow: active
                    ? const [
                        BoxShadow(
                          color: Color(0x4438E7B5),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ]
                    : const [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (active)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Transform.translate(
                          offset: Offset(
                            (_shimmer.value * 2 - 0.5) *
                                MediaQuery.sizeOf(context).width,
                            0,
                          ),
                          child: Container(
                            width: 84,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.18),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_fix_high_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isBrush;
  final String brushLabel;
  final String eraserLabel;
  final VoidCallback onBrush;
  final VoidCallback onEraser;

  const _ModeToggle({
    required this.isBrush,
    required this.brushLabel,
    required this.eraserLabel,
    required this.onBrush,
    required this.onEraser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Seg(
              label: brushLabel,
              active: isBrush,
              accent: _accent,
              icon: Icons.brush_rounded,
              onTap: onBrush,
            ),
          ),
          Expanded(
            child: _Seg(
              label: eraserLabel,
              active: !isBrush,
              accent: _eraser,
              icon: Icons.auto_fix_off_rounded,
              onTap: onEraser,
            ),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  const _Seg({
    required this.label,
    required this.active,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border:
              active ? Border.all(color: accent.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: active ? accent : _textSec),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? accent : _textSec,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UndoRedo extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const _UndoRedo({
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HistoryBtn(
          icon: Icons.undo_rounded,
          enabled: canUndo,
          onTap: onUndo,
        ),
        SizedBox(width: 8),
        _HistoryBtn(
          icon: Icons.redo_rounded,
          enabled: canRedo,
          onTap: onRedo,
        ),
      ],
    );
  }
}

class _HistoryBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _HistoryBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.25,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Icon(icon, color: _textPri, size: 20),
        ),
      ),
    );
  }
}

class _BrushPresetWrap extends StatelessWidget {
  final double selectedPx;
  final Color accent;
  final List<int> presets;
  final ValueChanged<double> onSelect;

  const _BrushPresetWrap({
    required this.selectedPx,
    required this.accent,
    required this.presets,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((preset) {
        final isSelected = (selectedPx - preset).abs() < 5;
        return GestureDetector(
          onTap: () => onSelect(preset.toDouble()),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.16)
                  : _surface1.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accent.withValues(alpha: 0.3) : _border,
              ),
            ),
            child: Text(
              '$preset px',
              style: TextStyle(
                color: isSelected ? accent : _textPri,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BrushSizeRow extends StatelessWidget {
  final String label;
  final double px;
  final bool isEraser;
  final ValueChanged<double> onChanged;

  const _BrushSizeRow({
    required this.label,
    required this.px,
    required this.isEraser,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isEraser ? _eraser : _accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: _textSec,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Text(
                '${px.toInt()} px',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.0,
            activeTrackColor: accent,
            inactiveTrackColor: _border,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: SliderComponentShape.noOverlay,
            valueIndicatorColor: accent,
          ),
          child: Slider(
            value: px,
            min: _slMin,
            max: _slMax,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('S', style: TextStyle(color: _textSec, fontSize: 10)),
              Text('M', style: TextStyle(color: _textSec, fontSize: 10)),
              Text('L', style: TextStyle(color: _textSec, fontSize: 10)),
              Text('XL', style: TextStyle(color: _textSec, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewportTools extends StatelessWidget {
  final String zoomLabel;
  final VoidCallback onResetViewport;
  final AppL10n l10n;

  const _ViewportTools({
    required this.zoomLabel,
    required this.onResetViewport,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _surface1.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fit_screen_rounded,
                  size: 18,
                  color: _accent,
                ),
                SizedBox(width: 10),
                Text(
                  zoomLabel,
                  style: TextStyle(
                    color: _textPri,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: onResetViewport,
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPri,
              side: BorderSide(color: _border.withValues(alpha: 1)),
              backgroundColor: _surface1.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Icon(Icons.center_focus_strong_rounded, size: 18),
            label: Text(l10n.get('editor_workspace_fit')),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceNotes extends StatelessWidget {
  final bool isEraser;
  final int strokeCount;
  final AppL10n l10n;

  const _WorkspaceNotes({
    required this.isEraser,
    required this.strokeCount,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isEraser ? _eraser : _accent;
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isEraser ? Icons.auto_fix_off_rounded : Icons.tune_rounded,
            size: 18,
            color: accent,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              strokeCount == 0
                  ? l10n.get('editor_tip_run')
                  : l10n.get('editor_tip_precision'),
              style: TextStyle(
                color: _textPri,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ClearButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _danger.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _danger.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: _danger.withValues(alpha: 0.8),
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: _danger.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
