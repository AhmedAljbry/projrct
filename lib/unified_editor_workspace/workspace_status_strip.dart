import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'unified_editor_workspace.dart';

class WorkspaceStatusStrip extends StatelessWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;

  const WorkspaceStatusStrip({
    super.key,
    required this.status,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (status.sceneKindLabel.isNotEmpty)
        _Pill(
          icon: Icons.landscape_rounded,
          label: status.sceneKindLabel,
          accent: AppTokens.info,
        ),
      _Pill(
        icon: Icons.auto_awesome_rounded,
        label: status.activeStyle,
        accent: AppTokens.primary,
      ),
      _Pill(
        icon: _modeIcon(mode),
        label: _modeText(mode),
        accent: AppTokens.accent,
      ),
      _Pill(
        icon: Icons.speed_rounded,
        label: 'Compatibility ${(status.compatibilityScore * 100).toStringAsFixed(0)}%',
        accent: status.compatibilityScore > 0.8 ? AppTokens.success : AppTokens.info,
      ),
      if (status.maskReady)
        _Pill(icon: Icons.filter_alt_rounded, label: 'Mask ready', accent: AppTokens.primary),
      if (status.toneLockActive)
        _Pill(icon: Icons.lock_rounded, label: 'Tone lock', accent: AppTokens.gold),
      if (status.architectAssistActive)
        _Pill(icon: Icons.architecture_rounded, label: 'Architect assist', accent: AppTokens.accent),
      if (status.regionSelected)
        _Pill(icon: Icons.crop_rounded, label: 'Region selected', accent: AppTokens.primary),
      if (status.materialDetected)
        _Pill(icon: Icons.layers_rounded, label: 'Material detected', accent: AppTokens.info),
      if (status.compareActive)
        _Pill(icon: Icons.compare_rounded, label: 'Compare', accent: AppTokens.primary),
      if (status.referenceActive)
        _Pill(
          icon: Icons.image_search_rounded,
          label: status.referenceLabel.isEmpty ? 'Reference Active' : status.referenceLabel,
          accent: AppTokens.success,
        ),
      if (status.engineBusy)
        _Pill(
          icon: Icons.hourglass_top_rounded,
          label: 'Processing',
          accent: AppTokens.gold,
        ),
    ];

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: chips
            .map((w) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: w,
                ))
            .toList(),
      ),
    );
  }

  IconData _modeIcon(UnifiedEditorMode mode) {
    switch (mode) {
      case UnifiedEditorMode.quick:
        return Icons.flash_on_rounded;
      case UnifiedEditorMode.pro:
        return Icons.tune_rounded;
      case UnifiedEditorMode.architect:
        return Icons.architecture_rounded;
    }
  }

  String _modeText(UnifiedEditorMode mode) {
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

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _Pill({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTokens.card2.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTokens.text2,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

