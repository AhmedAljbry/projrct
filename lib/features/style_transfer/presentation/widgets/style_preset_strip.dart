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
    this.height = 126,
    this.cardWidth = 178,
    this.contentPadding = const EdgeInsets.all(14),
    this.descriptionMaxLines = 2,
    this.showDescription = true,
    this.nameFontSize = 15,
  });

  final List<StylePresetDefinition> presets;
  final String? selectedId;
  final ValueChanged<StylePresetDefinition> onSelected;
  final double height;
  final double cardWidth;
  final EdgeInsetsGeometry contentPadding;
  final int descriptionMaxLines;
  final bool showDescription;
  final double nameFontSize;

  @override
  Widget build(BuildContext context) {
    final swatchSize = cardWidth < 168 ? 14.0 : 18.0;
    return SizedBox(
      height: height,
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
              width: cardWidth,
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
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isSelected ? 0.24 : 0.14),
                    blurRadius: isSelected ? 18 : 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 6,
                      children: preset.profile.color.palette
                          .take(4)
                          .map(
                            (color) => Container(
                              width: swatchSize,
                              height: swatchSize,
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
                        fontSize: nameFontSize,
                        color: Colors.white,
                      ),
                    ),
                    if (showDescription) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        preset.description,
                        maxLines: descriptionMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: ViralStudioTokens.body(11),
                      ),
                    ],
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
