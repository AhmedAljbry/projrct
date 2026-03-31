import 'package:flutter/material.dart';

import 'package:untitled2/core/ui/AppL10n.dart';

import 'inpainting_studio_chrome.dart';

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
    final hPad = compact ? 12.0 : 16.0;
    final vPad = compact ? 10.0 : 13.0;

    return StudioGlassPanel(
      radius: 32,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      fillColor: InpaintingStudioTheme.surfaceStrong.withValues(alpha: 0.8),
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ToolIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          SizedBox(width: compact ? 12 : 16),
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
                    fontSize: compact ? 16.0 : 18.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
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
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
               color: Colors.white.withValues(alpha: 0.04),
               borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 _ToolIconButton(
                   icon: Icons.undo_rounded,
                   onTap: canUndo ? onUndo : null,
                   tooltip: undoLabel,
                 ),
                 SizedBox(width: 4),
                 _ToolIconButton(
                   icon: Icons.redo_rounded,
                   onTap: canRedo ? onRedo : null,
                   tooltip: redoLabel,
                 ),
               ]
            ),
          ),
          SizedBox(width: 8),
          _ToolIconButton(
            icon: Icons.help_outline_rounded,
            onTap: onHelp,
          ),
        ],
      ),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const _ToolIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    Widget button = Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? Colors.white : Colors.white70,
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
