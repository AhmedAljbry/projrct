import 'package:flutter/material.dart';

import 'package:untitled2/features/style_transfer/domain/entities/style_preset_definition.dart';
import 'package:untitled2/shared/ui_tokens/viral_studio_tokens.dart';

/// Compact horizontal selector that keeps preset browsing close to the preview.
class StylePresetStrip extends StatelessWidget {
  const StylePresetStrip({
    super.key,
    required this.presets,
    required this.selectedId,
    required this.onSelected,
  });

  final List<StylePresetDefinition> presets;
  final String? selectedId;
  final ValueChanged<StylePresetDefinition> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final preset = presets[index];
          final isSelected = preset.id == selectedId;
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => onSelected(preset),
            child: Ink(
              width: 178,
              decoration: BoxDecoration(
                color: isSelected
                    ? ViralStudioTokens.surfaceSoft
                    : ViralStudioTokens.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? ViralStudioTokens.accent
                      : ViralStudioTokens.outline,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 6,
                      children: preset.profile.color.palette
                          .take(4)
                          .map(
                            (color) => Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const Spacer(),
                    Text(
                      preset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ViralStudioTokens.sectionTitle().copyWith(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preset.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ViralStudioTokens.body(11),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
