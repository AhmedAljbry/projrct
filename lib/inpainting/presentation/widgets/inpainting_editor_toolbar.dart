import 'package:flutter/material.dart';

import 'package:untitled2/core/ui/AppL10n.dart';

import 'inpainting_studio_chrome.dart';

/// Slim single-row top bar for the Magic Eraser editor.
///
/// Contains: back ← | title + breadcrumb | undo ↩ | redo ↪ | help ?
///
/// All previous action-chips (undo/redo/clear/compare rows) have been removed
/// from the top bar — those controls now live exclusively in the brush-controls
/// panel to avoid duplication and reclaim vertical space.
class InpaintingEditorToolbar extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusLabel;
  final bool hasMask;
  final bool compareEnabled;
  final bool canUndo;
  final bool canRedo;
  final bool compact;
  final VoidCallback onBack;
  final VoidCallback onHelp;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onToggleCompare;
  final String undoLabel;
  final String redoLabel;
  final String clearLabel;
  final String compareLabel;
  final String compareActiveLabel;

  const InpaintingEditorToolbar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.hasMask,
    required this.compareEnabled,
    required this.canUndo,
    required this.canRedo,
    required this.compact,
    required this.onBack,
    required this.onHelp,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onToggleCompare,
    required this.undoLabel,
    required this.redoLabel,
    required this.clearLabel,
    required this.compareLabel,
    required this.compareActiveLabel,
    required this.l10n,
  });

  final AppL10n l10n;

  /// Current workflow step derived from editor state:
  /// 1 = draw mask, 2 = AI processing (not shown here), 3 = done
  int get _currentStep => hasMask ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final hPad = compact ? 12.0 : 16.0;
    final vPad = compact ? 10.0 : 13.0;

    return StudioGlassPanel(
      radius: 26,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      fillColor: InpaintingStudioTheme.surfaceSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Back button ─────────────────────────────────────────
          _TopBarIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          SizedBox(width: compact ? 10 : 14),

          // ── Title + breadcrumb ──────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InpaintingStudioTheme.textPrimary,
                    fontSize: compact ? 16.0 : 18.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                StudioStepBreadcrumb(
                  l10n: l10n,
                  currentStep: _currentStep,
                ),
              ],
            ),
          ),

          SizedBox(width: 10),

          // ── Undo / Redo icon buttons ────────────────────────────
          _TopBarIconButton(
            icon: Icons.undo_rounded,
            onTap: canUndo ? onUndo : null,
            tooltip: undoLabel,
          ),
          SizedBox(width: 6),
          _TopBarIconButton(
            icon: Icons.redo_rounded,
            onTap: canRedo ? onRedo : null,
            tooltip: redoLabel,
          ),
          SizedBox(width: 6),

          // ── Help button ─────────────────────────────────────────
          _TopBarIconButton(
            icon: Icons.help_outline_rounded,
            onTap: onHelp,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const _TopBarIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    Widget button = Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? InpaintingStudioTheme.textPrimary
                : InpaintingStudioTheme.textSecondary,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
