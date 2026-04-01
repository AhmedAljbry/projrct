import 'package:flutter/material.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/repair_damage_manual_mask_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/widgets/repair_damage_tool_components.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';

class RepairDamageManualTools extends StatelessWidget {
  const RepairDamageManualTools({
    super.key,
    required this.state,
    required this.brushRadius,
    required this.advancedExpanded,
    required this.onAdvancedExpandedChanged,
    required this.onEditModeChanged,
    required this.onBrushRadiusChanged,
    required this.onFeatherChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onExpand,
    required this.onContract,
    required this.onClear,
    required this.onPreviewChanged,
  });

  final RepairDamageManualMaskState state;
  final double brushRadius;
  final bool advancedExpanded;
  final ValueChanged<bool> onAdvancedExpandedChanged;
  final ValueChanged<MaskEditMode> onEditModeChanged;
  final ValueChanged<double> onBrushRadiusChanged;
  final ValueChanged<double> onFeatherChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onExpand;
  final VoidCallback onContract;
  final VoidCallback onClear;
  final ValueChanged<bool> onPreviewChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 760
            ? (constraints.maxWidth - repairDamageToolGap) / 2
            : constraints.maxWidth;

        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Wrap(
            spacing: repairDamageToolGap,
            runSpacing: repairDamageToolGap,
            children: [
              SizedBox(
                width: cardWidth,
                child: RepairDamageToolCard(
                  title: 'Brush Tools',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          RepairDamageModePill(
                            label: 'Add',
                            icon: Icons.add_rounded,
                            selected: state.editMode == MaskEditMode.add,
                            onTap: () => onEditModeChanged(MaskEditMode.add),
                          ),
                          RepairDamageModePill(
                            label: 'Erase',
                            icon: Icons.remove_rounded,
                            selected: state.editMode == MaskEditMode.erase,
                            onTap: () => onEditModeChanged(MaskEditMode.erase),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SliderSection(
                        label: 'Brush Radius',
                        valueLabel: '${brushRadius.round()} px',
                        value: brushRadius,
                        min: 6,
                        max: 120,
                        onChanged: onBrushRadiusChanged,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: RepairDamageToolCard(
                  title: 'History & Cleanup',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      RepairDamageActionButton(
                        label: 'Undo',
                        icon: Icons.undo_rounded,
                        onPressed: state.canUndo ? onUndo : null,
                      ),
                      RepairDamageActionButton(
                        label: 'Redo',
                        icon: Icons.redo_rounded,
                        onPressed: state.canRedo ? onRedo : null,
                      ),
                      RepairDamageActionButton(
                        label: 'Clear Mask',
                        icon: Icons.layers_clear_rounded,
                        onPressed: state.hasMaskContent ? onClear : null,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: RepairDamageToolCard(
                  title: 'Preview',
                  child: Row(
                    children: [
                      Icon(
                        state.previewVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: Colors.white60,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Preview Mask',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: state.previewVisible,
                        activeColor: LamaTheme.accent,
                        onChanged: onPreviewChanged,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: RepairDamageToolCard(
                  title: 'Mask Refinement',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () =>
                            onAdvancedExpandedChanged(!advancedExpanded),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                advancedExpanded ? 'Advanced' : 'Advanced',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                advancedExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: Colors.white60,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox(height: 6),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SliderSection(
                                label: 'Feather',
                                valueLabel: state.feather.round().toString(),
                                value: state.feather,
                                min: 0,
                                max: 12,
                                divisions: 12,
                                activeColor: Colors.orangeAccent,
                                onChanged: onFeatherChanged,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  RepairDamageActionButton(
                                    label: 'Expand Mask',
                                    icon: Icons.add_circle_outline_rounded,
                                    emphasized: true,
                                    onPressed:
                                        state.hasMaskContent ? onExpand : null,
                                  ),
                                  RepairDamageActionButton(
                                    label: 'Contract Mask',
                                    icon: Icons.remove_circle_outline_rounded,
                                    onPressed: state.hasMaskContent
                                        ? onContract
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        crossFadeState: advancedExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 180),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliderSection extends StatelessWidget {
  const _SliderSection({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.activeColor = LamaTheme.accent,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
