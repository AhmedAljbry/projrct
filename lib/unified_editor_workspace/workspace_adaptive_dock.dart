import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'unified_editor_workspace.dart';

class WorkspaceAdaptiveDock extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedDockAction activeDock;
  final ValueChanged<UnifiedDockAction> onDockTapped;

  final double height;

  const WorkspaceAdaptiveDock({
    super.key,
    required this.mode,
    required this.activeDock,
    required this.onDockTapped,
    this.height = 118,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _actionsForMode(mode);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        height: height,
        decoration: BoxDecoration(
          color: AppTokens.surface.withValues(alpha: 0.82),
          border: Border(top: BorderSide(color: AppTokens.border.withValues(alpha: 0.6))),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _DockGrid(
            key: ValueKey(mode),
            actions: actions,
            activeDock: activeDock,
            onDockTapped: onDockTapped,
          ),
        ),
      ),
    );
  }

  List<UnifiedDockAction> _actionsForMode(UnifiedEditorMode mode) {
    switch (mode) {
      case UnifiedEditorMode.quick:
        return const [
          UnifiedDockAction.viral,
          UnifiedDockAction.natural,
          UnifiedDockAction.fix,
          UnifiedDockAction.styles,
          UnifiedDockAction.compare,
        ];
      case UnifiedEditorMode.pro:
        return const [
          UnifiedDockAction.regions,
          UnifiedDockAction.transfer,
          UnifiedDockAction.masks,
          UnifiedDockAction.lock,
          UnifiedDockAction.blend,
          UnifiedDockAction.refine,
        ];
      case UnifiedEditorMode.architect:
        return const [
          UnifiedDockAction.realism,
          UnifiedDockAction.materials,
          UnifiedDockAction.sky,
          UnifiedDockAction.light,
          UnifiedDockAction.glass,
          UnifiedDockAction.batch,
        ];
    }
  }
}

class _DockGrid extends StatelessWidget {
  final List<UnifiedDockAction> actions;
  final UnifiedDockAction activeDock;
  final ValueChanged<UnifiedDockAction> onDockTapped;

  const _DockGrid({
    super.key,
    required this.actions,
    required this.activeDock,
    required this.onDockTapped,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.9,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        final a = actions[i];
        final data = _DockData.from(a);
        final active = a == activeDock;

        return InkWell(
          onTap: () => onDockTapped(a),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? AppTokens.primary.withValues(alpha: 0.16) : AppTokens.card2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? AppTokens.primary.withValues(alpha: 0.75) : AppTokens.border.withValues(alpha: 0.55),
                width: 1,
              ),
              boxShadow: active ? AppTokens.primaryGlow(0.12) : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data.icon, size: 20, color: active ? AppTokens.primary : AppTokens.text2),
                const SizedBox(height: 4),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? AppTokens.primary : AppTokens.text2,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DockData {
  final IconData icon;
  final String label;

  const _DockData({required this.icon, required this.label});

  static _DockData from(UnifiedDockAction action) {
    switch (action) {
      case UnifiedDockAction.viral:
        return const _DockData(icon: Icons.flash_on_rounded, label: 'Viral');
      case UnifiedDockAction.natural:
        return const _DockData(icon: Icons.wb_sunny, label: 'Natural');
      case UnifiedDockAction.fix:
        return const _DockData(icon: Icons.auto_fix_high_rounded, label: 'Fix');
      case UnifiedDockAction.styles:
        return const _DockData(icon: Icons.style_rounded, label: 'Styles');
      case UnifiedDockAction.compare:
        return const _DockData(icon: Icons.compare_rounded, label: 'Compare');

      case UnifiedDockAction.regions:
        return const _DockData(icon: Icons.crop_rounded, label: 'Regions');
      case UnifiedDockAction.transfer:
        return const _DockData(icon: Icons.swap_horiz_rounded, label: 'Transfer');
      case UnifiedDockAction.masks:
        return const _DockData(icon: Icons.filter_alt_rounded, label: 'Masks');
      case UnifiedDockAction.lock:
        return const _DockData(icon: Icons.lock_rounded, label: 'Lock');
      case UnifiedDockAction.blend:
        return const _DockData(icon: Icons.circle_outlined, label: 'Blend');
      case UnifiedDockAction.refine:
        return const _DockData(icon: Icons.auto_awesome_rounded, label: 'Refine');

      case UnifiedDockAction.realism:
        return const _DockData(icon: Icons.photo_size_select_actual_rounded, label: 'Realism');
      case UnifiedDockAction.materials:
        return const _DockData(icon: Icons.layers_rounded, label: 'Materials');
      case UnifiedDockAction.sky:
        return const _DockData(icon: Icons.cloud_rounded, label: 'Sky');
      case UnifiedDockAction.light:
        return const _DockData(icon: Icons.lightbulb_rounded, label: 'Light');
      case UnifiedDockAction.glass:
        return const _DockData(icon: Icons.opacity_rounded, label: 'Glass');
      case UnifiedDockAction.batch:
        return const _DockData(icon: Icons.queue_music_rounded, label: 'Batch');

      case UnifiedDockAction.export:
        return const _DockData(icon: Icons.download_rounded, label: 'Export');
    }
  }
}

