import 'package:flutter/material.dart';
import 'package:untitled2/core/utils/Responsive.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'engine/style_registry.dart';
import 'unified_editor_workspace.dart';

class QuickStyleRail extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedEditorStatus status;
  final ValueChanged<String> onStyleSelected;
  final bool isGrid; // ADDED THIS

  const QuickStyleRail({
    super.key,
    required this.mode,
    required this.status,
    required this.onStyleSelected,
    this.isGrid = false, // ADDED THIS
  });

  @override
  Widget build(BuildContext context) {
    final device = Responsive.of(context);
    final vertical = device != DeviceType.phone;

    final styles = _stylesForMode(mode);

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
        itemCount: styles.length,
        itemBuilder: (context, i) {
          final s = styles[i];
          return _StyleCard(
            styleName: s,
            active: s == status.activeStyle,
            onTap: () => onStyleSelected(s),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      // Only show background if not in grid mode
      decoration: BoxDecoration(
        color: AppTokens.card.withValues(alpha: 0.3),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      child: vertical
          ? SizedBox(
              width: 168,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: styles.length,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final s = styles[i];
                  return _StyleCard(
                    styleName: s,
                    active: s == status.activeStyle,
                    onTap: () => onStyleSelected(s),
                    compact: true,
                  );
                },
              ),
            )
          : SizedBox(
              height: 86,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: (styles).map((s) {
                  final active = s == status.activeStyle;
                  return _StyleCard(
                    styleName: s,
                    active: active,
                    onTap: () => onStyleSelected(s),
                  );
                }).toList(),
              ),
            ),
    );
  }

  List<String> _stylesForMode(UnifiedEditorMode mode) {
    switch (mode) {
      case UnifiedEditorMode.quick:
        return CreativeStyleRegistry.coreStyleDisplayNames;
      case UnifiedEditorMode.pro:
        return [
          ...CreativeStyleRegistry.coreStyleDisplayNames,
          'Style Steal PRO',
        ];
      case UnifiedEditorMode.architect:
        return CreativeStyleRegistry.architectStyleDisplayNames;
    }
  }
}

class _StyleCard extends StatelessWidget {
  final String styleName;
  final bool active;
  final VoidCallback onTap;
  final bool compact;

  const _StyleCard({
    required this.styleName,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = compact ? 148.0 : 110.0;
    final height = compact ? 44.0 : 70.0;

    return SizedBox(
      width: width,
      height: height,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTokens.primary.withValues(alpha: 0.14) : AppTokens.card,
            borderRadius: BorderRadius.circular(AppTokens.r16),
            border: Border.all(
              color: active ? AppTokens.primary.withValues(alpha: 0.65) : AppTokens.border.withValues(alpha: 0.55),
              width: 1,
            ),
            boxShadow: active ? AppTokens.primaryGlow(0.18) : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 22 : 26,
                height: compact ? 22 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTokens.primaryGradient,
                  border: Border.all(color: AppTokens.primary.withValues(alpha: 0.4), width: 1),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: compact ? 14 : 16,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  styleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? AppTokens.primary : AppTokens.text2,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 12 : 13,
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

