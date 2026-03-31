import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:untitled2/core/ui/AppL10n.dart';
import 'package:untitled2/core/i18n/t.dart';
import 'inpainting_studio_chrome.dart';

enum InpaintingControlsLayout { sideDock, bottomDock }

class InpaintingBrushControls extends StatelessWidget {
  final AppL10n l10n;
  final T t;
  final InpaintingControlsLayout layout;
  final bool isEraser;
  final bool hasMask;
  final bool canUndo;
  final bool canRedo;
  final bool maskVisible;
  final bool compareEnabled;
  final double brushPx;
  final double currentZoom;
  final int strokeCount;
  final VoidCallback onBrushMode;
  final VoidCallback onEraserMode;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onResetWorkspace;
  final VoidCallback onResetViewport;
  final VoidCallback onMagic;
  final VoidCallback onToggleMaskVisibility;
  final VoidCallback onToggleCompare;
  final ValueChanged<double> onBrushSizeChanged;

  const InpaintingBrushControls({
    super.key,
    required this.l10n,
    required this.t,
    required this.layout,
    required this.isEraser,
    required this.hasMask,
    required this.canUndo,
    required this.canRedo,
    required this.maskVisible,
    required this.compareEnabled,
    required this.brushPx,
    required this.currentZoom,
    required this.strokeCount,
    required this.onBrushMode,
    required this.onEraserMode,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onResetWorkspace,
    required this.onResetViewport,
    required this.onMagic,
    required this.onToggleMaskVisibility,
    required this.onToggleCompare,
    required this.onBrushSizeChanged,
  });

  bool get _isSideDock => layout == InpaintingControlsLayout.sideDock;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isCompact = constraints.maxHeight < 280 && !_isSideDock;

      final radius = _isSideDock
          ? BorderRadius.circular(36)
          : const BorderRadius.vertical(top: Radius.circular(36));

      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: InpaintingStudioTheme.surfaceStrong.withValues(alpha: 0.75),
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isSideDock)
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 4),
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                if (isCompact) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildCompactRow(context),
                  ),
                  const Spacer(),
                ] else
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(18, _isSideDock ? 24 : 12, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildToolToggle(),
                          const SizedBox(height: 18),
                          _buildBrushSizeSection(context),
                          const SizedBox(height: 18),
                          _buildViewSection(),
                          const SizedBox(height: 18),
                          _buildActionsSection(),
                        ],
                      ),
                    ),
                  ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCompactRow(BuildContext context) {
    final accent = isEraser ? InpaintingStudioTheme.rose : InpaintingStudioTheme.mint;
    return StudioGlassPanel(
      radius: 24,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      fillColor: Colors.white.withValues(alpha: 0.04),
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: Row(
        children: [
          _MiniToggle(
            iconLeft: Icons.brush_rounded,
            iconRight: Icons.auto_fix_off_rounded,
            isLeftActive: !isEraser,
            leftAccent: InpaintingStudioTheme.mint,
            rightAccent: InpaintingStudioTheme.rose,
            onLeft: onBrushMode,
            onRight: onEraserMode,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: accent,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                thumbColor: Colors.white,
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: brushPx.clamp(8.0, 120.0),
                min: 8,
                max: 120,
                onChanged: onBrushSizeChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ActionCircle(
            icon: maskVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: InpaintingStudioTheme.cyan,
            isActive: maskVisible,
            onTap: hasMask ? onToggleMaskVisibility : null,
          ),
          const SizedBox(width: 6),
          _ActionCircle(
            icon: compareEnabled ? Icons.compare_rounded : Icons.image_search_rounded,
            color: InpaintingStudioTheme.violet,
            isActive: compareEnabled,
            onTap: hasMask ? onToggleCompare : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolToggle() {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeSwitch(
              icon: Icons.brush_rounded,
              label: l10n.get('brush'),
              isActive: !isEraser,
              activeColor: InpaintingStudioTheme.mint,
              onTap: onBrushMode,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ModeSwitch(
              icon: Icons.auto_fix_off_rounded,
              label: l10n.get('eraser'),
              isActive: isEraser,
              activeColor: InpaintingStudioTheme.rose,
              onTap: onEraserMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrushSizeSection(BuildContext context) {
    final accent = isEraser ? InpaintingStudioTheme.rose : InpaintingStudioTheme.mint;
    return StudioGlassPanel(
      radius: 28,
      padding: const EdgeInsets.all(20),
      fillColor: Colors.white.withValues(alpha: 0.02),
      borderColor: Colors.white.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.get('brush_size'),
                style: const TextStyle(
                  color: InpaintingStudioTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${brushPx.round()} px',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              thumbColor: Colors.white,
              overlayColor: accent.withValues(alpha: 0.25),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: brushPx.clamp(8.0, 120.0),
              min: 8,
              max: 120,
              onChanged: onBrushSizeChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSection() {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: maskVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            label: t.of('workflow_mask'),
            isActive: maskVisible,
            activeColor: InpaintingStudioTheme.cyan,
            onTap: hasMask ? onToggleMaskVisibility : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionTile(
            icon: compareEnabled ? Icons.compare_rounded : Icons.image_search_rounded,
            label: t.of('compare'),
            isActive: compareEnabled,
            activeColor: InpaintingStudioTheme.violet,
            onTap: hasMask ? onToggleCompare : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return StudioGlassPanel(
      radius: 28,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      fillColor: Colors.white.withValues(alpha: 0.02),
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _IconButton(
            icon: Icons.delete_outline_rounded,
            color: InpaintingStudioTheme.danger,
            onTap: hasMask ? onClear : null,
            label: l10n.get('clear'),
          ),
          _VerticalDivider(),
          _IconButton(
            icon: Icons.center_focus_strong_rounded,
            color: InpaintingStudioTheme.amber,
            onTap: onResetViewport,
            label: l10n.get('editor_workspace_fit'),
          ),
          _VerticalDivider(),
          _IconButton(
            icon: Icons.restart_alt_rounded,
            color: InpaintingStudioTheme.textSecondary,
            onTap: onResetWorkspace,
            label: l10n.get('reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
      decoration: BoxDecoration(
        color: InpaintingStudioTheme.backgroundDeep.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: _RunMagicButton(
        label: l10n.get('magic'),
        hasMask: hasMask,
        onTap: onMagic,
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final IconData iconLeft;
  final IconData iconRight;
  final bool isLeftActive;
  final Color leftAccent;
  final Color rightAccent;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _MiniToggle({
    required this.iconLeft,
    required this.iconRight,
    required this.isLeftActive,
    required this.leftAccent,
    required this.rightAccent,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    final active = isLeftActive ? leftAccent : rightAccent;
    return Container(
      decoration: BoxDecoration(
        color: active.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleHalf(
            icon: iconLeft,
            isActive: isLeftActive,
            color: leftAccent,
            onTap: onLeft,
            isLeft: true,
          ),
          Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _ToggleHalf(
            icon: iconRight,
            isActive: !isLeftActive,
            color: rightAccent,
            onTap: onRight,
            isLeft: false,
          ),
        ],
      ),
    );
  }
}

class _ToggleHalf extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  final bool isLeft;

  const _ToggleHalf({
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.horizontal(
        left: isLeft ? const Radius.circular(16) : Radius.zero,
        right: !isLeft ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? color : InpaintingStudioTheme.textSecondary,
        ),
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;

  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isActive ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? color : InpaintingStudioTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeSwitch({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? activeColor : InpaintingStudioTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : InpaintingStudioTheme.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive ? activeColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : Colors.white,
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String label;

  const _IconButton({
    required this.icon,
    required this.color,
    this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}

class _RunMagicButton extends StatelessWidget {
  final String label;
  final bool hasMask;
  final VoidCallback onTap;

  const _RunMagicButton({
    required this.label,
    required this.hasMask,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: hasMask ? 1.0 : 0.5,
      child: InkWell(
        onTap: hasMask ? onTap : null,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: hasMask ? InpaintingStudioTheme.primaryGradient : null,
            color: hasMask ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(28),
            boxShadow: hasMask
                ? const [
                    BoxShadow(
                      color: Color(0x406DC6B0),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_fix_high_rounded,
                color: hasMask ? Colors.black : InpaintingStudioTheme.textMuted,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: hasMask ? Colors.black : InpaintingStudioTheme.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
