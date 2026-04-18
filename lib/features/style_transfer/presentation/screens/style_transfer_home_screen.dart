import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/core/ui/AppL10n.dart';

import 'package:untitled2/features/style_transfer/application/style_transfer_controller.dart';
import 'package:untitled2/features/style_transfer/application/style_transfer_state.dart';
import 'package:untitled2/features/style_transfer/data/models/style_preset_registry.dart';
import 'package:untitled2/features/style_transfer/presentation/screens/style_transfer_processing_screen.dart';
import 'package:untitled2/features/style_transfer/presentation/widgets/style_preset_strip.dart';
import 'package:untitled2/shared/ui_tokens/viral_studio_tokens.dart';

class StyleTransferHomeScreen extends StatelessWidget {
  const StyleTransferHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StyleTransferController>(
      create: (_) => StyleTransferController.standard(),
      child: const _StyleTransferHomeView(),
    );
  }
}

class _StyleTransferHomeView extends StatefulWidget {
  const _StyleTransferHomeView();

  @override
  State<_StyleTransferHomeView> createState() => _StyleTransferHomeViewState();
}

class _StyleTransferHomeViewState extends State<_StyleTransferHomeView> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickReference() async {
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await context
        .read<StyleTransferController>()
        .setReferenceImage(bytes, name: file.name);
  }

  Future<void> _pickTarget() async {
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await context
        .read<StyleTransferController>()
        .setTargetImage(bytes, name: file.name);
  }

  Future<void> _start() async {
    final controller = context.read<StyleTransferController>();
    await controller.ensureReady();
    if (!mounted || !controller.state.canStart) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: controller,
          child: const StyleTransferProcessingScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
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
        body: Container(
          decoration: BoxDecoration(gradient: ViralStudioTokens.pageGlow),
          child: SafeArea(
            child: BlocBuilder<StyleTransferController, StyleTransferState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration:
                            ViralStudioTokens.panelDecoration(emphasized: true),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(l10n.get('style_transfer_home_title'),
                                style: ViralStudioTokens.headline()),
                            const SizedBox(height: 10),
                            Text(
                              l10n.get('style_transfer_home_desc'),
                              style: ViralStudioTokens.body(),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                _Badge(label: l10n.get('style_transfer_badge_scene_aware')),
                                _Badge(label: l10n.get('style_transfer_badge_face_safe')),
                                _Badge(label: l10n.get('style_transfer_badge_fast_preview')),
                                _Badge(label: l10n.get('style_transfer_badge_high_res')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.get('style_transfer_source_inputs'),
                          style: ViralStudioTokens.sectionTitle()),
                      const SizedBox(height: 12),
                      _ImageInputCard(
                        title: l10n.get('style_transfer_reference_title'),
                        subtitle: l10n.get('style_transfer_reference_subtitle'),
                        buttonLabel: l10n.get('style_transfer_pick_reference'),
                        bytes: state.referenceBytes,
                        fallbackLabel:
                            state.referenceName ?? l10n.get('style_transfer_no_reference'),
                        onTap: _pickReference,
                      ),
                      const SizedBox(height: 12),
                      _ImageInputCard(
                        title: l10n.get('style_transfer_target_title'),
                        subtitle: l10n.get('style_transfer_target_subtitle'),
                        buttonLabel: l10n.get('style_transfer_pick_target'),
                        bytes: state.targetBytes,
                        fallbackLabel:
                            state.targetName ?? l10n.get('style_transfer_no_target'),
                        onTap: _pickTarget,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: <Widget>[
                          Expanded(
                              child: Text(l10n.get('style_transfer_builtin_packs'),
                                  style: ViralStudioTokens.sectionTitle())),
                          Text(l10n.get('style_transfer_tap_without_reference'),
                              style: ViralStudioTokens.body(12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StylePresetStrip(
                        presets: StylePresetRegistry.featuredPresets,
                        selectedId: state.selectedPresetId,
                        onSelected: (preset) => context
                            .read<StyleTransferController>()
                            .applyPreset(preset),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: ViralStudioTokens.panelDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                    child: Text(l10n.get('style_transfer_ready_launch'),
                                        style:
                                            ViralStudioTokens.sectionTitle())),
                                if (state.isPreparing ||
                                    state.isRenderingPreview)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.2),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.get('style_transfer_ready_launch_desc'),
                              style: ViralStudioTokens.body(),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: ViralStudioTokens.primaryButton(),
                                onPressed: state.isPreparing ? null : _start,
                                child: Text(l10n.get('style_transfer_make_viral')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

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
      child: Text(label,
          style: ViralStudioTokens.body(12).copyWith(color: Colors.white)),
    );
  }
}

class _ImageInputCard extends StatelessWidget {
  const _ImageInputCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.bytes,
    required this.fallbackLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final Uint8List? bytes;
  final String fallbackLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ViralStudioTokens.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: ViralStudioTokens.sectionTitle()),
          const SizedBox(height: 6),
          Text(subtitle, style: ViralStudioTokens.body()),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: bytes == null
                  ? Container(
                      color: ViralStudioTokens.surfaceSoft,
                      alignment: Alignment.center,
                      child:
                          Text(fallbackLabel, style: ViralStudioTokens.body()),
                    )
                  : Image.memory(bytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: ViralStudioTokens.secondaryButton(),
              onPressed: onTap,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
