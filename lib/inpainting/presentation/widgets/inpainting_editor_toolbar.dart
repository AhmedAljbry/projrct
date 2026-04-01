import 'package:flutter/material.dart';

import 'package:untitled2/core/ui/AppL10n.dart';

import 'inpainting_studio_chrome.dart';

// ─────────────────────────────────────────────────────────────────────────────
// InpaintingEditorToolbar
// Zone 1: Compact Top App Bar for Magic Eraser editor.
// Height-adaptive: stays under ~60dp on phones, slightly taller on tablets.
// ─────────────────────────────────────────────────────────────────────────────

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
  final AppL10n l10n;

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

  int get _currentStep => hasMask ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    // Tighter vertical padding – 10dp on phones, 12dp on tablets
    final vPad = compact ? 9.0 : 11.0;
    final hPad = compact ? 10.0 : 14.0;

    return Container(
      decoration: BoxDecoration(
        color: InpaintingStudioTheme.surfaceStrong.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Back button
          _TopBarIcon(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
            semanticLabel: 'Back',
          ),
          SizedBox(width: compact ? 10 : 12),

          // ── Title + breadcrumb
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
                    color: Colors.white,
                    fontSize: compact ? 15.0 : 17.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: StudioStepBreadcrumb(
                    l10n: l10n,
                    currentStep: _currentStep,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // ── Undo / Redo group
          _TopBarGroup(
            children: [
              _TopBarIcon(
                icon: Icons.undo_rounded,
                onTap: canUndo ? onUndo : null,
                tooltip: undoLabel,
              ),
              _TopBarIcon(
                icon: Icons.redo_rounded,
                onTap: canRedo ? onRedo : null,
                tooltip: redoLabel,
              ),
            ],
          ),

          const SizedBox(width: 6),

          // ── Help
          _TopBarIcon(
            icon: Icons.help_outline_rounded,
            onTap: onHelp,
            semanticLabel: 'Help',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// A pill that groups related icon buttons with a subtle background.
class _TopBarGroup extends StatelessWidget {
  final List<Widget> children;

  const _TopBarGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// A fixed-size icon button for the top bar – 36×36 tap target.
class _TopBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final String? semanticLabel;

  const _TopBarIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    Widget core = Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      core = Tooltip(message: tooltip!, child: core);
    }
    if (semanticLabel != null) {
      core = Semantics(label: semanticLabel, child: core);
    }
    return core;
  }
}
