import 'package:flutter/material.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/widgets/repair_damage_tool_components.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';
import 'package:untitled2/features/retouch_mask_assist/presentation/bloc/repair_mask_assist_cubit.dart';

class RepairDamageAiTools extends StatelessWidget {
  const RepairDamageAiTools({
    super.key,
    required this.state,
    required this.hasMaskContent,
    required this.brushRadius,
    required this.advancedExpanded,
    required this.onAdvancedExpandedChanged,
    required this.onGenerate,
    required this.onRetry,
    required this.onEditModeChanged,
    required this.onBrushRadiusChanged,
    required this.onFeatherChanged,
    required this.onExpand,
    required this.onContract,
    required this.onClear,
    required this.onUndo,
    required this.onRedo,
    required this.onPreviewChanged,
  });

  final RepairMaskAssistState state;
  final bool hasMaskContent;
  final double brushRadius;
  final bool advancedExpanded;
  final ValueChanged<bool> onAdvancedExpandedChanged;
  final VoidCallback onGenerate;
  final VoidCallback onRetry;
  final ValueChanged<MaskEditMode> onEditModeChanged;
  final ValueChanged<double> onBrushRadiusChanged;
  final ValueChanged<double> onFeatherChanged;
  final VoidCallback onExpand;
  final VoidCallback onContract;
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
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
                  title: 'AI Assist',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: state.generationStatus ==
                                    MaskGenerationStatus.generating
                                ? null
                                : onGenerate,
                            style: FilledButton.styleFrom(
                              backgroundColor: LamaTheme.accent,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.white10,
                              disabledForegroundColor: Colors.white24,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: state.generationStatus ==
                                    MaskGenerationStatus.generating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome_rounded),
                            label: const Text(
                              'Auto Detect',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          RepairDamageActionButton(
                            label: 'Retry',
                            icon: Icons.refresh_rounded,
                            onPressed: state.sourceImageBytes == null ||
                                    state.generationStatus ==
                                        MaskGenerationStatus.generating
                                ? null
                                : onRetry,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            state.previewVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 18,
                            color: Colors.white60,
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
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: RepairDamageToolCard(
                  title: 'Refine Result',
                  child: state.hasSuggestion
                      ? Column(
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
                                  onTap: () =>
                                      onEditModeChanged(MaskEditMode.add),
                                ),
                                RepairDamageModePill(
                                  label: 'Erase',
                                  icon: Icons.remove_rounded,
                                  selected:
                                      state.editMode == MaskEditMode.erase,
                                  onTap: () =>
                                      onEditModeChanged(MaskEditMode.erase),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _SliderSection(
                              label: 'Brush Radius',
                              valueLabel: '${brushRadius.round()} px',
                              value: brushRadius,
                              min: 8,
                              max: 128,
                              onChanged: onBrushRadiusChanged,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: RepairDamageToolCard(
                  title: 'Advanced Refinement',
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
                              Wrap(
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
                                    onPressed: hasMaskContent ? onClear : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
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
                                        state.hasSuggestion && hasMaskContent
                                            ? onExpand
                                            : null,
                                  ),
                                  RepairDamageActionButton(
                                    label: 'Contract Mask',
                                    icon: Icons.remove_circle_outline_rounded,
                                    onPressed:
                                        state.hasSuggestion && hasMaskContent
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
