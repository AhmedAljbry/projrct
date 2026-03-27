import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'reference_image_chip.dart';
import 'unified_editor_workspace.dart';

class WorkspaceTopBar extends StatelessWidget {
  final String title;
  final UnifiedEditorMode mode;

  final bool compareActive;
  final VoidCallback onCompareTapped;
  final VoidCallback onSaveTapped;
  final VoidCallback onExportTapped;
  final VoidCallback onAdvancedInspectorTapped;

  // Reference image
  final bool referenceActive;
  final VoidCallback onAddReferenceTapped;

  const WorkspaceTopBar({
    super.key,
    required this.title,
    required this.mode,
    required this.compareActive,
    required this.onCompareTapped,
    required this.onSaveTapped,
    required this.onExportTapped,
    required this.onAdvancedInspectorTapped,
    required this.referenceActive,
    required this.onAddReferenceTapped,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final modeLabel = _modeLabel(mode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTokens.surface.withValues(alpha: 0.78),
        border: Border(
          bottom: BorderSide(color: AppTokens.border.withValues(alpha: 0.55), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (canPop)
            _IconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 40),

          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTokens.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _ModePill(label: modeLabel, active: true),
              ],
            ),
          ),

          _IconButton(
            icon: Icons.save_rounded,
            onPressed: onSaveTapped,
            tooltip: 'Save',
          ),
          const SizedBox(width: 2),
          _IconButton(
            icon: Icons.download_rounded,
            onPressed: onExportTapped,
            tooltip: 'Export',
          ),
          const SizedBox(width: 4),
          AddReferenceButton(
            referenceActive: referenceActive,
            onTap: onAddReferenceTapped,
          ),
          const SizedBox(width: 2),

          PopupMenuButton<_OverflowItem>(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r16),
            ),
            icon: const Icon(Icons.more_horiz_rounded, color: AppTokens.text2, size: 22),
            itemBuilder: (context) => [
              PopupMenuItem<_OverflowItem>(
                value: _OverflowItem.advanced,
                child: Text(
                  'Advanced Inspector',
                  style: TextStyle(color: AppTokens.text, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            color: AppTokens.surface,
            onSelected: (value) {
              if (value == _OverflowItem.advanced) {
                onAdvancedInspectorTapped();
              }
            },
          ),
        ],
      ),
    );
  }

  String _modeLabel(UnifiedEditorMode mode) {
    switch (mode) {
      case UnifiedEditorMode.quick:
        return 'Quick';
      case UnifiedEditorMode.pro:
        return 'Pro';
      case UnifiedEditorMode.architect:
        return 'Architect';
    }
  }
}

enum _OverflowItem { advanced }

class _ModePill extends StatelessWidget {
  final String label;
  final bool active;

  const _ModePill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppTokens.primary.withValues(alpha: 0.14) : AppTokens.card2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? AppTokens.primary.withValues(alpha: 0.28) : AppTokens.border.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppTokens.primary : AppTokens.text2,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _IconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: 22,
        color: AppTokens.text2,
      ),
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    );
  }
}

