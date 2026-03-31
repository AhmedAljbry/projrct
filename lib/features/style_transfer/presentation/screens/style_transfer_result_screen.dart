import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:untitled2/features/style_transfer/application/style_transfer_controller.dart';
import 'package:untitled2/features/style_transfer/application/style_transfer_state.dart';
import 'package:untitled2/features/style_transfer/presentation/widgets/before_after_slider.dart';
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
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save')),
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
    if (mounted) Navigator.of(context).pop();
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
                  child:
                      Text('No result yet.', style: ViralStudioTokens.body()));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: <Widget>[
                BeforeAfterSlider(
                  beforeBytes: state.targetBytes!,
                  afterBytes: result.exportBytes ?? result.previewBytes,
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
                      Text(result.appliedProfile.name,
                          style: ViralStudioTokens.headline(24)),
                      const SizedBox(height: 8),
                      Text(
                        '${result.appliedProfile.sceneType.toUpperCase()} • ${(result.compatibility * 100).round()}% compatibility • ${(result.viralScore * 100).round()}% viral score',
                        style: ViralStudioTokens.body(),
                      ),
                      const SizedBox(height: 14),
                      Text('Safety Notes',
                          style: ViralStudioTokens.sectionTitle()),
                      const SizedBox(height: 10),
                      ...result.safetyReport.notes.map(
                        (note) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child:
                              Text('• $note', style: ViralStudioTokens.body()),
                        ),
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
