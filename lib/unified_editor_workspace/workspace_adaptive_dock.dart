import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'unified_editor_workspace.dart';

/// Compact, horizontally-scrollable dock pinned to the bottom of the screen.
///
/// Replaced the old fixed-height 2-row GridView (which overflowed at 118 px)
/// with a single-row scrollable chip list (height 68 px).
/// All Quick / Pro / Architect actions are preserved — they scroll horizontally.
class WorkspaceAdaptiveDock extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedDockAction activeDock;
  final ValueChanged<UnifiedDockAction> onDockTapped;
  final bool compareEnabled;

  /// Total widget height. Kept as a named param for layout coordination.
  final double height;
  final bool isGrid; // ADDED THIS

  const WorkspaceAdaptiveDock({
    super.key,
    required this.mode,
    required this.activeDock,
    required this.onDockTapped,
    required this.compareEnabled,
    this.height = 68,
    this.isGrid = false, // ADDED THIS
  });

  @override
  Widget build(BuildContext context) {
    final actions = _actionsForMode(mode);

    return SafeArea(
      top: false,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTokens.surface.withValues(alpha: 0.92),
          border: Border(
            top: BorderSide(color: AppTokens.border.withValues(alpha: 0.6)),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _DockRow(
            key: ValueKey(mode),
            actions: actions,
            activeDock: activeDock,
            onDockTapped: onDockTapped,
            compareEnabled: compareEnabled,
            isGrid: isGrid, // ADDED THIS
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

// ─── Horizontal scrollable chip row ─────────────────────────────────────────

class _DockRow extends StatelessWidget {
  final List<UnifiedDockAction> actions;
  final UnifiedDockAction activeDock;
  final ValueChanged<UnifiedDockAction> onDockTapped;
  final bool compareEnabled;
  final bool isGrid; // ADDED THIS

  const _DockRow({
    super.key,
    required this.actions,
    required this.activeDock,
    required this.onDockTapped,
    required this.compareEnabled,
    required this.isGrid, // ADDED THIS
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0, // Squares!
        ),
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        itemBuilder: (context, i) {
          final a = actions[i];
          final data = _DockData.from(a);
          // Tools in the grid act as navigation buttons now, so they shouldn't remain visually "selected".
          final active = a == UnifiedDockAction.compare ? compareEnabled : false;
          return _DockChip(
            data: data,
            active: active,
            onTap: () => onDockTapped(a),
          );
        },
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      itemCount: actions.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final a = actions[i];
        final data = _DockData.from(a);
        final active = a == UnifiedDockAction.compare
            ? compareEnabled
            : false;

        return _DockChip(
          data: data,
          active: active,
          onTap: () => onDockTapped(a),
        );
      },
    );
  }
}

// ─── Individual pill chip ────────────────────────────────────────────────────

class _DockChip extends StatelessWidget {
  final _DockData data;
  final bool active;
  final VoidCallback onTap;

  const _DockChip({
    required this.data,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: active
              ? AppTokens.primary.withValues(alpha: 0.18)
              : AppTokens.card2.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: active
                ? AppTokens.primary.withValues(alpha: 0.80)
                : AppTokens.border.withValues(alpha: 0.55),
            width: 1,
          ),
          boxShadow: active ? AppTokens.primaryGlow(0.14) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              data.icon,
              size: 18,
              color: active ? AppTokens.primary : AppTokens.text2,
            ),
            const SizedBox(width: 7),
            Text(
              data.label,
              style: TextStyle(
                color: active ? AppTokens.primary : AppTokens.text2,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dock metadata ───────────────────────────────────────────────────────────

class _DockData {
  final IconData icon;
  final String label;

  const _DockData({required this.icon, required this.label});

  static _DockData from(UnifiedDockAction action) {
    switch (action) {
      // Quick
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

      // Pro
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

      // Architect
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

      // Shared
      case UnifiedDockAction.export:
        return const _DockData(icon: Icons.download_rounded, label: 'Export');
    }
  }
}
