import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:untitled2/core/ui/AppL10n.dart';
import 'package:untitled2/core/i18n/t.dart';
import 'inpainting_studio_chrome.dart';

enum InpaintingControlsLayout { sideDock, bottomDock }

// ─────────────────────────────────────────────────────────────────────────────
// InpaintingBrushControls
// Zone 4: Responsive bottom workspace
//
// Layout priorities (bottomDock):
//   Row 1  – Tool toggle (Brush / Erase)
//   Row 2  – Brush size slider
//   Row 3  – View controls (mask visibility, compare)
//   Row 4  – Quick actions (clear, fit, reset)   ← inside a glass panel
//   Footer – Magic / Run button  (always visible, visually dominant)
//
// Heights are adaptive:
//  • On very short screens (e.g. landscape phones) → compact 1-row mode
//  • Normal phones        → standard stacked mode  (~240-280 dp)
//  • Large phones/tablets → side dock uses same sections vertically
// ─────────────────────────────────────────────────────────────────────────────

// ── Spacing tokens ────────────────────────────────────────────────────────────
const double _sOuter = 16.0;  // outer horizontal padding
const double _sInner = 14.0;  // inner card padding
const double _sGap   = 12.0;  // gap between sections
const double _sSm    =  8.0;  // small gap between controls

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
      // Treat very-short heights (landscape phones) as compact:
      final isCompact = constraints.maxHeight < 230 && !_isSideDock;

      final radius = _isSideDock
          ? BorderRadius.circular(32)
          : const BorderRadius.vertical(top: Radius.circular(28));

      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              color: InpaintingStudioTheme.surfaceStrong.withValues(alpha: 0.82),
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle (bottom dock only)
                if (!_isSideDock) _DragHandle(),

                // ── Content area
                if (isCompact)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_sOuter, _sSm, _sOuter, _sSm),
                    child: _buildCompactRow(context),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        _sOuter,
                        _isSideDock ? 20 : 4,
                        _sOuter,
                        _sSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Tool selector
                          _ToolToggle(
                            isEraser: isEraser,
                            brushLabel: l10n.get('brush'),
                            eraserLabel: l10n.get('eraser'),
                            onBrushMode: onBrushMode,
                            onEraserMode: onEraserMode,
                          ),
                          const SizedBox(height: _sGap),

                          // 2. Brush size
                          _BrushSizeCard(
                            context: context,
                            isEraser: isEraser,
                            brushPx: brushPx,
                            brushSizeLabel: l10n.get('brush_size'),
                            onChanged: onBrushSizeChanged,
                          ),
                          const SizedBox(height: _sGap),

                          // 3. View controls row
                          _ViewControls(
                            maskVisible: maskVisible,
                            compareEnabled: compareEnabled,
                            hasMask: hasMask,
                            maskLabel: t.of('workflow_mask'),
                            compareLabel: t.of('compare'),
                            onToggleMask: onToggleMaskVisibility,
                            onToggleCompare: onToggleCompare,
                          ),
                          const SizedBox(height: _sGap),

                          // 4. Quick action cluster
                          _QuickActions(
                            hasMask: hasMask,
                            clearLabel: l10n.get('clear'),
                            fitLabel: l10n.get('editor_workspace_fit'),
                            resetLabel: l10n.get('reset'),
                            onClear: onClear,
                            onResetViewport: onResetViewport,
                            onResetWorkspace: onResetWorkspace,
                          ),

                          // MAGIC RUN BUTTON (Integrated into bottom sheet)
                          if (!_isSideDock) ...[
                            const SizedBox(height: _sGap),
                            _MagicRunButton(
                              label: l10n.get('magic'),
                              hasMask: hasMask,
                              onTap: onMagic,
                            ),
                          ],

                          // Side dock: magic button lives inside scroll area
                          if (_isSideDock) ...[
                            const SizedBox(height: _sGap),
                            _MagicRunButton(
                              label: l10n.get('magic'),
                              hasMask: hasMask,
                              onTap: onMagic,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }

  /// Landscape / very compact mode: single horizontal row.
  Widget _buildCompactRow(BuildContext context) {
    final accent = isEraser ? InpaintingStudioTheme.rose : InpaintingStudioTheme.mint;
    return Row(
      children: [
        // Tool mini toggle
        _MiniToggle(
          iconLeft: Icons.brush_rounded,
          iconRight: Icons.auto_fix_off_rounded,
          isLeftActive: !isEraser,
          leftAccent: InpaintingStudioTheme.mint,
          rightAccent: InpaintingStudioTheme.rose,
          onLeft: onBrushMode,
          onRight: onEraserMode,
        ),
        const SizedBox(width: _sSm),

        // Brush slider
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
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
        const SizedBox(width: _sSm),

        // Mask toggle
        _ActionCircle(
          icon: maskVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          color: InpaintingStudioTheme.cyan,
          isActive: maskVisible,
          onTap: hasMask ? onToggleMaskVisibility : null,
        ),
        const SizedBox(width: 6),

        // Compare toggle
        _ActionCircle(
          icon: compareEnabled ? Icons.compare_rounded : Icons.image_search_rounded,
          color: InpaintingStudioTheme.violet,
          isActive: compareEnabled,
          onTap: hasMask ? onToggleCompare : null,
        ),
        const SizedBox(width: 10),

        // Magic button inline (compact)
        _CompactMagicButton(hasMask: hasMask, onTap: onMagic),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

/// Zone 4 – Row 1: brush / eraser segmented control.
class _ToolToggle extends StatelessWidget {
  final bool isEraser;
  final String brushLabel;
  final String eraserLabel;
  final VoidCallback onBrushMode;
  final VoidCallback onEraserMode;

  const _ToolToggle({
    required this.isEraser,
    required this.brushLabel,
    required this.eraserLabel,
    required this.onBrushMode,
    required this.onEraserMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              icon: Icons.brush_rounded,
              label: brushLabel,
              isActive: !isEraser,
              activeColor: InpaintingStudioTheme.mint,
              onTap: onBrushMode,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _ModeChip(
              icon: Icons.auto_fix_off_rounded,
              label: eraserLabel,
              isActive: isEraser,
              activeColor: InpaintingStudioTheme.rose,
              onTap: onEraserMode,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single chip inside the tool toggle.
class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeChip({
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
      borderRadius: BorderRadius.circular(19),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.38) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17,
                color: isActive ? activeColor : InpaintingStudioTheme.textSecondary),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : InpaintingStudioTheme.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zone 4 – Row 2: brush size card with compact label + slider.
class _BrushSizeCard extends StatelessWidget {
  final BuildContext context;
  final bool isEraser;
  final double brushPx;
  final String brushSizeLabel;
  final ValueChanged<double> onChanged;

  const _BrushSizeCard({
    required this.context,
    required this.isEraser,
    required this.brushPx,
    required this.brushSizeLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext _) {
    final accent = isEraser ? InpaintingStudioTheme.rose : InpaintingStudioTheme.mint;
    return Container(
      padding: const EdgeInsets.fromLTRB(_sInner, 12, _sInner, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Label
          Text(
            brushSizeLabel,
            style: const TextStyle(
              color: InpaintingStudioTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),

          // Slider
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                activeTrackColor: accent,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
                thumbColor: Colors.white,
                overlayColor: accent.withValues(alpha: 0.20),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: brushPx.clamp(8.0, 120.0),
                min: 8,
                max: 120,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Value badge
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Text(
              '${brushPx.round()}px',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Zone 4 – Row 3: mask visibility + compare view toggle.
class _ViewControls extends StatelessWidget {
  final bool maskVisible;
  final bool compareEnabled;
  final bool hasMask;
  final String maskLabel;
  final String compareLabel;
  final VoidCallback onToggleMask;
  final VoidCallback onToggleCompare;

  const _ViewControls({
    required this.maskVisible,
    required this.compareEnabled,
    required this.hasMask,
    required this.maskLabel,
    required this.compareLabel,
    required this.onToggleMask,
    required this.onToggleCompare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ViewChip(
            icon: maskVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            label: maskLabel,
            isActive: maskVisible,
            activeColor: InpaintingStudioTheme.cyan,
            onTap: hasMask ? onToggleMask : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ViewChip(
            icon: compareEnabled ? Icons.compare_rounded : Icons.image_search_rounded,
            label: compareLabel,
            isActive: compareEnabled,
            activeColor: InpaintingStudioTheme.violet,
            onTap: hasMask ? onToggleCompare : null,
          ),
        ),
      ],
    );
  }
}

class _ViewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _ViewChip({
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
      opacity: enabled ? 1.0 : 0.38,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: isActive ? activeColor : InpaintingStudioTheme.textSecondary),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? activeColor : InpaintingStudioTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zone 4 – Row 4: quick action cluster (clear, fit, reset).
class _QuickActions extends StatelessWidget {
  final bool hasMask;
  final String clearLabel;
  final String fitLabel;
  final String resetLabel;
  final VoidCallback onClear;
  final VoidCallback onResetViewport;
  final VoidCallback onResetWorkspace;

  const _QuickActions({
    required this.hasMask,
    required this.clearLabel,
    required this.fitLabel,
    required this.resetLabel,
    required this.onClear,
    required this.onResetViewport,
    required this.onResetWorkspace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionBtn(
            icon: Icons.delete_outline_rounded,
            label: clearLabel,
            color: InpaintingStudioTheme.danger,
            onTap: hasMask ? onClear : null,
          ),
          _QaSeparator(),
          _QuickActionBtn(
            icon: Icons.center_focus_strong_rounded,
            label: fitLabel,
            color: InpaintingStudioTheme.amber,
            onTap: onResetViewport,
          ),
          _QaSeparator(),
          _QuickActionBtn(
            icon: Icons.restart_alt_rounded,
            label: resetLabel,
            color: InpaintingStudioTheme.textSecondary,
            onTap: onResetWorkspace,
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.38,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QaSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.08));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer: Magic Run Button (bottom dock)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomFooter extends StatelessWidget {
  final String label;
  final bool hasMask;
  final VoidCallback onMagic;

  const _BottomFooter({
    required this.label,
    required this.hasMask,
    required this.onMagic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(_sOuter, 12, _sOuter, 20),
      decoration: BoxDecoration(
        color: InpaintingStudioTheme.backgroundDeep.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: _MagicRunButton(label: label, hasMask: hasMask, onTap: onMagic),
    );
  }
}

/// Full-width magic button (side-dock + bottom-dock standard mode).
class _MagicRunButton extends StatelessWidget {
  final String label;
  final bool hasMask;
  final VoidCallback onTap;

  const _MagicRunButton({
    required this.label,
    required this.hasMask,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: hasMask ? 1.0 : 0.48,
      child: InkWell(
        onTap: hasMask ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: hasMask ? InpaintingStudioTheme.magicGradient : null,
            color: hasMask ? null : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(24),
            boxShadow: hasMask
                ? const [
                    BoxShadow(
                      color: Color(0x40FF6F00),
                      blurRadius: 20,
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
                color: hasMask ? Colors.black : InpaintingStudioTheme.textMuted,
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: TextStyle(
                  color: hasMask ? Colors.black : InpaintingStudioTheme.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
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

/// Compact inline magic button (landscape compact row).
class _CompactMagicButton extends StatelessWidget {
  final bool hasMask;
  final VoidCallback onTap;

  const _CompactMagicButton({required this.hasMask, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: hasMask ? 1.0 : 0.45,
      child: InkWell(
        onTap: hasMask ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: hasMask ? InpaintingStudioTheme.primaryGradient : null,
            color: hasMask ? null : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            boxShadow: hasMask
                ? const [
                    BoxShadow(
                        color: Color(0x306DC6B0), blurRadius: 12, offset: Offset(0, 4)),
                  ]
                : null,
          ),
          child: Icon(
            Icons.auto_fix_high_rounded,
            color: hasMask ? Colors.black : InpaintingStudioTheme.textMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared micro-widgets (referenced from compact row)
// ─────────────────────────────────────────────────────────────────────────────

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
        color: active.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleHalf(icon: iconLeft, isActive: isLeftActive, color: leftAccent, onTap: onLeft, isLeft: true),
          Container(width: 1, height: 22, color: Colors.white.withValues(alpha: 0.08)),
          _ToggleHalf(icon: iconRight, isActive: !isLeftActive, color: rightAccent, onTap: onRight, isLeft: false),
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
        left: isLeft ? const Radius.circular(14) : Radius.zero,
        right: !isLeft ? const Radius.circular(14) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
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
      opacity: enabled ? 1.0 : 0.38,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.30) : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Icon(icon, size: 16, color: isActive ? color : InpaintingStudioTheme.textSecondary),
        ),
      ),
    );
  }
}

// Keep for backward compat (used elsewhere via chrome imports)
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.40) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? activeColor : InpaintingStudioTheme.textSecondary),
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
