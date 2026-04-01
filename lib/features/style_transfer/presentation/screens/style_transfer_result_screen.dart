import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:untitled2/features/style_transfer/application/style_transfer_controller.dart';
import 'package:untitled2/features/style_transfer/application/style_transfer_state.dart';
import 'package:untitled2/features/style_transfer/data/models/style_preset_registry.dart';
import 'package:untitled2/features/style_transfer/presentation/widgets/before_after_slider.dart';
import 'package:untitled2/features/style_transfer/presentation/widgets/style_preset_strip.dart';
import 'package:untitled2/shared/ui_tokens/viral_studio_tokens.dart';

class StyleTransferResultScreen extends StatefulWidget {
  const StyleTransferResultScreen({super.key});

  @override
  State<StyleTransferResultScreen> createState() =>
      _StyleTransferResultScreenState();
}

class _StyleTransferResultScreenState extends State<StyleTransferResultScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _savePreset() async {
    final controller = context.read<StyleTransferController>();
    final nameController = TextEditingController(
      text: controller.state.previewResult?.appliedProfile.name ??
          'My Viral Style',
    );
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ViralStudioTokens.surface,
          title:
              const Text('Save Preset', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Preset name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (shouldSave == true && mounted) {
      await controller.saveCurrentPreset(nameController.text.trim().isEmpty
          ? 'My Viral Style'
          : nameController.text.trim());
    }
  }

  Future<void> _applyToAnother() async {
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await context
        .read<StyleTransferController>()
        .setTargetImage(bytes, name: file.name);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _editWatermark() async {
    final controller = context.read<StyleTransferController>();
    final textController =
        TextEditingController(text: controller.state.settings.watermarkText);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ViralStudioTokens.surface,
          title: const Text('Watermark Text',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (shouldSave == true && mounted) {
      controller.updateWatermarkText(textController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StyleTransferController, StyleTransferState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.statusMessage != current.statusMessage,
      listener: (context, state) {
        final message = state.errorMessage ?? state.statusMessage;
        if (message == null || message.isEmpty) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        context.read<StyleTransferController>().clearMessages();
      },
      child: Scaffold(
        backgroundColor: ViralStudioTokens.background,
        appBar: AppBar(
          backgroundColor: ViralStudioTokens.background,
          foregroundColor: Colors.white,
          title: const Text('Result'),
        ),
        body: BlocBuilder<StyleTransferController, StyleTransferState>(
          builder: (context, state) {
            final result = state.exportResult ?? state.previewResult;
            if (result == null || state.targetBytes == null) {
              return Center(
                child: Text('No result yet.', style: ViralStudioTokens.body()),
              );
            }
            final safetyNotes = result.safetyReport.notes.isEmpty
                ? const <String>[
                    'Protection layers kept skin, highlights, and shadows stable.'
                  ]
                : result.safetyReport.notes;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: <Widget>[
                BeforeAfterSlider(
                  beforeBytes: state.targetBytes!,
                  afterBytes: result.exportBytes ?? result.previewBytes,
                ),
                const SizedBox(height: 18),
                StylePresetStrip(
                  presets: StylePresetRegistry.allPresets,
                  selectedId: state.selectedPresetId,
                  onSelected: (preset) => context
                      .read<StyleTransferController>()
                      .applyPreset(preset),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    SizedBox(
                      width: 170,
                      child: FilledButton(
                        style: ViralStudioTokens.primaryButton(),
                        onPressed: _savePreset,
                        child: const Text('Save Preset'),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: OutlinedButton(
                        style: ViralStudioTokens.secondaryButton(),
                        onPressed: _applyToAnother,
                        child: const Text('Apply Another'),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: OutlinedButton(
                        style: ViralStudioTokens.secondaryButton(),
                        onPressed: () => context
                            .read<StyleTransferController>()
                            .exportCurrent(),
                        child: const Text('Export'),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: OutlinedButton(
                        style: ViralStudioTokens.secondaryButton(),
                        onPressed: () => context
                            .read<StyleTransferController>()
                            .shareCurrent(),
                        child: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: ViralStudioTokens.panelDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: state.settings.watermarkEnabled,
                        onChanged: context
                            .read<StyleTransferController>()
                            .updateWatermarkEnabled,
                        title: const Text('Watermark Export',
                            style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          state.settings.watermarkEnabled
                              ? 'A subtle studio label will be added on the next render.'
                              : 'Keep exports clean with no branding overlay.',
                          style: ViralStudioTokens.body(12),
                        ),
                      ),
                      if (state.settings.watermarkEnabled) ...<Widget>[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _editWatermark,
                          child: Text(
                            'Edit watermark text',
                            style: ViralStudioTokens.body(13)
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: ViralStudioTokens.panelDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(result.appliedProfile.name,
                          style: ViralStudioTokens.headline(24)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          _InfoPill(
                            label: result.usedFallback
                                ? 'Safe mode'
                                : 'Full render path',
                          ),
                          _InfoPill(
                            label: result.usedCachedAnalysis
                                ? 'Cached scene'
                                : 'Fresh scene analysis',
                          ),
                          _InfoPill(
                            label: result.watermarkApplied
                                ? 'Watermark on'
                                : 'Watermark off',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          _MetricPill(
                            label: 'Scene',
                            value:
                                result.appliedProfile.sceneType.toUpperCase(),
                          ),
                          _MetricPill(
                            label: 'Fit',
                            value: '${(result.compatibility * 100).round()}%',
                          ),
                          _MetricPill(
                            label: 'Viral',
                            value: '${(result.viralScore * 100).round()}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        collapsedIconColor: Colors.white,
                        iconColor: Colors.white,
                        title: Text('Safety Notes',
                            style: ViralStudioTokens.sectionTitle()),
                        subtitle: Text(
                          'Protection details and rendering notes',
                          style: ViralStudioTokens.body(12),
                        ),
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        children: safetyNotes
                            .map(
                              (note) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('- $note',
                                    style: ViralStudioTokens.body()),
                              ),
                            )
                            .toList(growable: false),
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
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ViralStudioTokens.outline),
      ),
      child: Text(label, style: ViralStudioTokens.body(12)),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ViralStudioTokens.outline),
      ),
      child: RichText(
        text: TextSpan(
          style: ViralStudioTokens.body(12),
          children: <InlineSpan>[
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: ViralStudioTokens.body(12)
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
