import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/features/style_transfer/application/style_transfer_controller.dart';
import 'package:untitled2/features/style_transfer/application/style_transfer_state.dart';
import 'package:untitled2/features/style_transfer/data/models/style_preset_registry.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_preset_definition.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/shared/ui_tokens/viral_studio_tokens.dart';

class StyleLibraryScreen extends StatelessWidget {
  const StyleLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralStudioTokens.background,
      appBar: AppBar(
        backgroundColor: ViralStudioTokens.background,
        foregroundColor: Colors.white,
        title: const Text('Style Library'),
      ),
      body: BlocBuilder<StyleTransferController, StyleTransferState>(
        builder: (context, state) {
          final controller = context.read<StyleTransferController>();
          return RefreshIndicator(
            onRefresh: controller.loadSavedPresets,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: <Widget>[
                if (state.savedPresets.isNotEmpty) ...<Widget>[
                  Text('Saved Styles', style: ViralStudioTokens.sectionTitle()),
                  const SizedBox(height: 12),
                  ...state.savedPresets.map(
                    (preset) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SavedStyleCard(
                        style: preset,
                        onApply: () async {
                          await controller.useSeedStyle(preset);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        onDelete: () => controller.deletePreset(preset.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                ...StylePresetRegistry.categorizedPresets.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(entry.key,
                            style: ViralStudioTokens.sectionTitle()),
                        const SizedBox(height: 12),
                        ...entry.value.map(
                          (preset) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PresetCard(
                              preset: preset,
                              selected: state.selectedPresetId == preset.id,
                              onApply: () async {
                                await controller.applyPreset(preset);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SavedStyleCard extends StatelessWidget {
  const _SavedStyleCard({
    required this.style,
    required this.onApply,
    this.onDelete,
  });

  final StyleProfile style;
  final VoidCallback onApply;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ViralStudioTokens.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                  child: Text(style.name,
                      style: ViralStudioTokens.sectionTitle())),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white70),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              '${style.sceneType.toUpperCase()} - ${(style.confidence * 100).round()}% confidence',
              style: ViralStudioTokens.body(12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: style.color.palette
                .take(5)
                .map(
                  (color) => Container(
                    width: 28,
                    height: 28,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: ViralStudioTokens.secondaryButton(),
              onPressed: onApply,
              child: const Text('Apply Style'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.onApply,
  });

  final StylePresetDefinition preset;
  final bool selected;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ViralStudioTokens.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  preset.name,
                  style: ViralStudioTokens.sectionTitle(),
                ),
              ),
              if (selected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ViralStudioTokens.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: ViralStudioTokens.accent),
                  ),
                  child: Text(
                    'Selected',
                    style: ViralStudioTokens.body(11)
                        .copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(preset.description, style: ViralStudioTokens.body(12)),
          const SizedBox(height: 10),
          Text(
            preset.supportedScenes
                .map((scene) => scene.toUpperCase())
                .join(' - '),
            style: ViralStudioTokens.body(11),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: preset.profile.color.palette
                .take(5)
                .map(
                  (color) => Container(
                    width: 28,
                    height: 28,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: ViralStudioTokens.secondaryButton(),
              onPressed: onApply,
              child: const Text('Apply Style'),
            ),
          ),
        ],
      ),
    );
  }
}
