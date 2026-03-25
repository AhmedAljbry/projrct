import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'unified_editor_workspace.dart';

class WorkspaceModeSwitcher extends StatelessWidget {
  final UnifiedEditorMode mode;
  final ValueChanged<UnifiedEditorMode> onChanged;

  const WorkspaceModeSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppTokens.card.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(color: AppTokens.border.withValues(alpha: 0.55), width: 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / 3;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: _index(mode) * segmentWidth,
                  child: Container(
                    width: segmentWidth,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTokens.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppTokens.r16),
                      border: Border.all(
                        color: AppTokens.primary.withValues(alpha: 0.28),
                        width: 1,
                      ),
                      boxShadow: AppTokens.primaryGlow(0.15),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      _Segment(
                        label: 'Quick',
                        active: mode == UnifiedEditorMode.quick,
                        onTap: () => onChanged(UnifiedEditorMode.quick),
                      ),
                      _Segment(
                        label: 'Pro',
                        active: mode == UnifiedEditorMode.pro,
                        onTap: () => onChanged(UnifiedEditorMode.pro),
                      ),
                      _Segment(
                        label: 'Architect',
                        active: mode == UnifiedEditorMode.architect,
                        onTap: () => onChanged(UnifiedEditorMode.architect),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _index(UnifiedEditorMode mode) {
    switch (mode) {
      case UnifiedEditorMode.quick:
        return 0;
      case UnifiedEditorMode.pro:
        return 1;
      case UnifiedEditorMode.architect:
        return 2;
    }
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? AppTokens.primary : AppTokens.text2,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

