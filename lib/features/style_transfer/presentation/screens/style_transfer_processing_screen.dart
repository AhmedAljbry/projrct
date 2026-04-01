import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/features/style_library/presentation/screens/style_library_screen.dart';
import 'package:untitled2/features/style_transfer/application/style_transfer_controller.dart';
import 'package:untitled2/features/style_transfer/application/style_transfer_state.dart';
import 'package:untitled2/features/style_transfer/data/models/style_preset_registry.dart';
import 'package:untitled2/features/style_transfer/presentation/screens/style_transfer_pro_controls_screen.dart';
import 'package:untitled2/features/style_transfer/presentation/screens/style_transfer_result_screen.dart';
import 'package:untitled2/features/style_transfer/presentation/widgets/before_after_slider.dart';
import 'package:untitled2/features/style_transfer/presentation/widgets/style_preset_strip.dart';
import 'package:untitled2/features/style_transfer/presentation/widgets/style_slider_tile.dart';
import 'package:untitled2/shared/ui_tokens/viral_studio_tokens.dart';

class StyleTransferProcessingScreen extends StatelessWidget {
  const StyleTransferProcessingScreen({super.key});

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
          title: const Text('Processing Studio'),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: context.read<StyleTransferController>(),
                      child: const StyleLibraryScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.style_rounded),
            ),
          ],
        ),
        body: BlocBuilder<StyleTransferController, StyleTransferState>(
          builder: (context, state) {
            final result = state.previewResult;
            return Stack(
              children: <Widget>[
                ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  children: <Widget>[
                    if (state.targetBytes != null && result != null)
                      BeforeAfterSlider(
                        beforeBytes: state.targetBytes!,
                        afterBytes: result.previewBytes,
                      )
                    else
                      Container(
                        height: 360,
                        alignment: Alignment.center,
                        decoration:
                            ViralStudioTokens.panelDecoration(emphasized: true),
                        child: Text(
                          state.isRenderingPreview
                              ? 'Generating instant preview...'
                              : 'Preview will appear here.',
                          style: ViralStudioTokens.body(),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Text('Style Packs',
                        style: ViralStudioTokens.sectionTitle()),
                    const SizedBox(height: 12),
                    StylePresetStrip(
                      presets: StylePresetRegistry.allPresets,
                      selectedId: state.selectedPresetId,
                      onSelected: (preset) => context
                          .read<StyleTransferController>()
                          .applyPreset(preset),
                    ),
                    const SizedBox(height: 18),
                    StyleSliderTile(
                      label: 'Strength',
                      subtitle:
                          'Controls how aggressively the reference look is pushed onto the target.',
                      value: state.settings.strength,
                      min: 0.2,
                      max: 1.0,
                      onChanged: context
                          .read<StyleTransferController>()
                          .updateStrength,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: ViralStudioTokens.panelDecoration(),
                      child: Column(
                        children: <Widget>[
                          SwitchListTile.adaptive(
                            value: state.settings.skinProtect,
                            onChanged: context
                                .read<StyleTransferController>()
                                .updateSkinProtect,
                            title: const Text('Skin Protect',
                                style: TextStyle(color: Colors.white)),
                            subtitle: Text(
                                'Prevents skin hue drift and face artifacts.',
                                style: ViralStudioTokens.body(12)),
                          ),
                          SwitchListTile.adaptive(
                            value: state.settings.sceneFit,
                            onChanged: context
                                .read<StyleTransferController>()
                                .updateSceneFit,
                            title: const Text('Scene Fit',
                                style: TextStyle(color: Colors.white)),
                            subtitle: Text(
                                'Softens mismatched references for better realism.',
                                style: ViralStudioTokens.body(12)),
                          ),
                          SwitchListTile.adaptive(
                            value: state.settings.exposureLock,
                            onChanged: context
                                .read<StyleTransferController>()
                                .updateExposureLock,
                            title: const Text('Exposure Lock',
                                style: TextStyle(color: Colors.white)),
                            subtitle: Text(
                                'Keeps original lighting structure more intact.',
                                style: ViralStudioTokens.body(12)),
                          ),
                          SwitchListTile.adaptive(
                            value: state.settings.naturalMode,
                            onChanged: context
                                .read<StyleTransferController>()
                                .updateNaturalMode,
                            title: const Text('Natural Mode',
                                style: TextStyle(color: Colors.white)),
                            subtitle: Text(
                                'Prioritizes realism, detail, and luminance safety.',
                                style: ViralStudioTokens.body(12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            style: ViralStudioTokens.secondaryButton(),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BlocProvider.value(
                                    value:
                                        context.read<StyleTransferController>(),
                                    child:
                                        const StyleTransferProControlsScreen(),
                                  ),
                                ),
                              );
                            },
                            child: const Text('Pro Controls'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: ViralStudioTokens.primaryButton(),
                            onPressed: () async {
                              await context
                                  .read<StyleTransferController>()
                                  .renderHighQuality();
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BlocProvider.value(
                                    value:
                                        context.read<StyleTransferController>(),
                                    child: const StyleTransferResultScreen(),
                                  ),
                                ),
                              );
                            },
                            child: const Text('Make it Viral'),
                          ),
                        ),
                      ],
                    ),
                    if (result != null) ...<Widget>[
                      const SizedBox(height: 18),
                      Container(
                        decoration: ViralStudioTokens.panelDecoration(),
                        child: ExpansionTile(
                          collapsedIconColor: Colors.white,
                          iconColor: Colors.white,
                          title: Text('Pro Diagnostics',
                              style: ViralStudioTokens.sectionTitle()),
                          subtitle: Text(
                            'Compatibility, render timing, and safety notes',
                            style: ViralStudioTokens.body(12),
                          ),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(18, 0, 18, 18),
                          children: <Widget>[
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                _StatusPill(
                                  label: result.usedFallback
                                      ? 'Safe mode'
                                      : 'Full render path',
                                ),
                                _StatusPill(
                                  label: result.usedCachedAnalysis
                                      ? 'Cached scene'
                                      : 'Fresh scene analysis',
                                ),
                                _StatusPill(
                                  label: result.exportReady
                                      ? 'High-res ready'
                                      : 'Preview only',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                _Metric(
                                    label: 'Scene',
                                    value:
                                        result.sceneAnalysis.scene.sceneType),
                                _Metric(
                                    label: 'Compatibility',
                                    value:
                                        '${(result.compatibility * 100).round()}%'),
                                _Metric(
                                    label: 'Viral Score',
                                    value:
                                        '${(result.viralScore * 100).round()}%'),
                                _Metric(
                                    label: 'Preview',
                                    value: '${result.previewRenderMs}ms'),
                              ],
                            ),
                            if (result.warnings.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 14),
                              ...result.warnings.map(
                                (warning) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text('- $warning',
                                      style: ViralStudioTokens.body()),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (state.isRenderingPreview || state.isRenderingExport)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(child: CircularProgressIndicator()),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ViralStudioTokens.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: ViralStudioTokens.body(11)),
          const SizedBox(height: 4),
          Text(value,
              style: ViralStudioTokens.sectionTitle().copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}
