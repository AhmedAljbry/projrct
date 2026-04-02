import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:untitled2/features/style_library/presentation/screens/style_library_screen.dart';
import 'package:untitled2/features/style_transfer/application/style_transfer_controller.dart';
import 'package:untitled2/features/style_transfer/application/style_transfer_state.dart';
import 'package:untitled2/features/style_transfer/data/models/style_preset_registry.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_result.dart';
import 'package:untitled2/features/style_transfer/presentation/screens/style_transfer_pro_controls_screen.dart';
import 'package:untitled2/features/style_transfer/presentation/widgets/before_after_slider.dart';
import 'package:untitled2/features/style_transfer/presentation/widgets/style_preset_strip.dart';
import 'package:untitled2/features/style_transfer/presentation/widgets/style_slider_tile.dart';
import 'package:untitled2/shared/ui_tokens/viral_studio_tokens.dart';

enum _ResultToolTab { quick, pro, diagnostics }

/// Preview-first result surface that keeps most controls compact until the
/// user intentionally opens quick tweaks, pro adjustments, or diagnostics.
class StyleTransferResultScreen extends StatefulWidget {
  const StyleTransferResultScreen({super.key});

  @override
  State<StyleTransferResultScreen> createState() =>
      _StyleTransferResultScreenState();
}

class _StyleTransferResultScreenState extends State<StyleTransferResultScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _compareEnabled = true;
  _ResultToolTab _activeTab = _ResultToolTab.quick;

  Future<void> _savePreset() async {
    final controller = context.read<StyleTransferController>();
    final nameController = TextEditingController(
      text: controller.state.previewResult?.appliedProfile.name ??
          'My Viral Style',
    );
    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: ViralStudioTokens.surface,
            title: const Text('Save Preset',
                style: TextStyle(color: Colors.white)),
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
    } finally {
      nameController.dispose();
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
    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: ViralStudioTokens.surface,
            title: const Text(
              'Watermark Text',
              style: TextStyle(color: Colors.white),
            ),
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
    } finally {
      textController.dispose();
    }
  }

  Future<void> _openPresetLibrary() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<StyleTransferController>(),
          child: const StyleLibraryScreen(),
        ),
      ),
    );
  }

  Future<void> _openProControls() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<StyleTransferController>(),
          child: const StyleTransferProControlsScreen(),
        ),
      ),
    );
  }

  Future<void> _openSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<StyleTransferController>(),
          child: BlocBuilder<StyleTransferController, StyleTransferState>(
            builder: (context, state) {
              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    0,
                    18,
                    MediaQuery.of(context).viewInsets.bottom + 18,
                  ),
                  child: Container(
                    decoration: ViralStudioTokens.panelDecoration(
                      emphasized: true,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Result Settings',
                            style: ViralStudioTokens.sectionTitle()),
                        const SizedBox(height: 6),
                        Text(
                          'Keep export options and branding tucked away so the preview stays clean.',
                          style: ViralStudioTokens.body(12),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: state.settings.watermarkEnabled,
                          onChanged: context
                              .read<StyleTransferController>()
                              .updateWatermarkEnabled,
                          title: const Text(
                            'Watermark Export',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            state.settings.watermarkEnabled
                                ? 'A subtle studio label will be added on the next export render.'
                                : 'Exports stay clean with no studio branding.',
                            style: ViralStudioTokens.body(12),
                          ),
                        ),
                        if (state.settings.watermarkEnabled) ...<Widget>[
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            style: ViralStudioTokens.secondaryButton(),
                            onPressed: _editWatermark,
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit Watermark'),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            FilledButton.icon(
                              style: ViralStudioTokens.primaryButton(),
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                context
                                    .read<StyleTransferController>()
                                    .exportCurrent();
                              },
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Export'),
                            ),
                            OutlinedButton.icon(
                              style: ViralStudioTokens.secondaryButton(),
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                context
                                    .read<StyleTransferController>()
                                    .shareCurrent();
                              },
                              icon: const Icon(Icons.ios_share_rounded),
                              label: const Text('Share'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: ViralStudioTokens.pageGlow),
          child: SafeArea(
            child: BlocBuilder<StyleTransferController, StyleTransferState>(
              builder: (context, state) {
                final result = state.exportResult ?? state.previewResult;
                if (result == null || state.targetBytes == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: ViralStudioTokens.panelDecoration(),
                        child: Text(
                          'No result yet.',
                          textAlign: TextAlign.center,
                          style: ViralStudioTokens.body(),
                        ),
                      ),
                    ),
                  );
                }

                final sceneLabel =
                    _toDisplayLabel(result.sceneAnalysis.scene.sceneType);
                final compatibility = (result.compatibility * 100).round();
                final safetyNotes = result.safetyReport.notes.isEmpty
                    ? const <String>[
                        'Protection layers kept skin, highlights, and shadows stable.'
                      ]
                    : result.safetyReport.notes;

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  children: <Widget>[
                    _CompactHeader(
                      title: 'Result',
                      subtitle: state.statusMessage ??
                          'Polish the look, compare it, and export when it feels premium.',
                      onBack: () => Navigator.of(context).maybePop(),
                      onPresets: _openPresetLibrary,
                      onSettings: _openSettingsSheet,
                    ),
                    const SizedBox(height: 18),
                    _PreviewHero(
                      beforeBytes: state.targetBytes!,
                      afterBytes: result.exportBytes ?? result.previewBytes,
                      compareEnabled: _compareEnabled,
                      activeStyle: result.appliedProfile.name,
                      compatibilityLabel: '$compatibility% fit',
                      sceneLabel: sceneLabel,
                      statusLabel: state.isRenderingExport
                          ? 'HQ render'
                          : state.isRenderingPreview
                              ? 'Updating'
                              : result.exportReady
                                  ? 'HQ ready'
                                  : 'Preview',
                    ),
                    const SizedBox(height: 18),
                    _PrimaryActionPanel(
                      strength: state.settings.strength,
                      compareEnabled: _compareEnabled,
                      isBusy:
                          state.isRenderingPreview || state.isRenderingExport,
                      onStrengthChanged: context
                          .read<StyleTransferController>()
                          .updateStrength,
                      onCompareChanged: (value) {
                        setState(() {
                          _compareEnabled = value;
                        });
                      },
                      onMakeItViral: () => context
                          .read<StyleTransferController>()
                          .renderHighQuality(),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          _ActionShortcut(
                            icon: Icons.bookmark_add_rounded,
                            label: 'Save Preset',
                            onPressed: _savePreset,
                          ),
                          const SizedBox(width: 10),
                          _ActionShortcut(
                            icon: Icons.photo_library_outlined,
                            label: 'Apply Another',
                            onPressed: _applyToAnother,
                          ),
                          const SizedBox(width: 10),
                          _ActionShortcut(
                            icon: Icons.download_rounded,
                            label: 'Export',
                            onPressed: () => context
                                .read<StyleTransferController>()
                                .exportCurrent(),
                          ),
                          const SizedBox(width: 10),
                          _ActionShortcut(
                            icon: Icons.ios_share_rounded,
                            label: 'Share',
                            onPressed: () => context
                                .read<StyleTransferController>()
                                .shareCurrent(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _SectionHeading(
                      title: 'Style Presets',
                      subtitle:
                          'Tap through the built-in looks without losing your current result context.',
                    ),
                    const SizedBox(height: 12),
                    StylePresetStrip(
                      presets: StylePresetRegistry.allPresets,
                      selectedId: state.selectedPresetId,
                      height: 112,
                      cardWidth: 164,
                      contentPadding: const EdgeInsets.all(12),
                      descriptionMaxLines: 1,
                      nameFontSize: 14,
                      onSelected: (preset) => context
                          .read<StyleTransferController>()
                          .applyPreset(preset),
                    ),
                    const SizedBox(height: 20),
                    _ToolSheet(
                      activeTab: _activeTab,
                      onTabChanged: (tab) {
                        setState(() {
                          _activeTab = tab;
                        });
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(
                          key: ValueKey<_ResultToolTab>(_activeTab),
                          child: switch (_activeTab) {
                            _ResultToolTab.quick => _QuickTab(
                                state: state,
                                result: result,
                              ),
                            _ResultToolTab.pro => _ProTab(
                                state: state,
                                onOpenFullEditor: _openProControls,
                                onEditWatermark: _editWatermark,
                              ),
                            _ResultToolTab.diagnostics => _DiagnosticsTab(
                                state: state,
                                result: result,
                                safetyNotes: safetyNotes,
                              ),
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onPresets,
    required this.onSettings,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onPresets;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: ViralStudioTokens.sectionTitle()
                        .copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: ViralStudioTokens.body(12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _HeaderIconButton(
          icon: Icons.style_rounded,
          onPressed: onPresets,
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.tune_rounded,
          onPressed: onSettings,
        ),
      ],
    );
  }
}

class _PreviewHero extends StatelessWidget {
  const _PreviewHero({
    required this.beforeBytes,
    required this.afterBytes,
    required this.compareEnabled,
    required this.activeStyle,
    required this.compatibilityLabel,
    required this.sceneLabel,
    required this.statusLabel,
  });

  final Uint8List beforeBytes;
  final Uint8List afterBytes;
  final bool compareEnabled;
  final String activeStyle;
  final String compatibilityLabel;
  final String sceneLabel;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ViralStudioTokens.outline),
        gradient: LinearGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.08),
            ViralStudioTokens.surface.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: <Widget>[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: compareEnabled
                  ? BeforeAfterSlider(
                      key: const ValueKey<String>('compare-preview'),
                      beforeBytes: beforeBytes,
                      afterBytes: afterBytes,
                      aspectRatio: 4 / 3,
                      borderRadius: 24,
                    )
                  : AspectRatio(
                      key: const ValueKey<String>('after-preview'),
                      aspectRatio: 4 / 3,
                      child: Image.memory(afterBytes, fit: BoxFit.cover),
                    ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.12),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.28),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const <double>[0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _PreviewChip(
                          icon: Icons.auto_awesome_rounded,
                          label: activeStyle,
                        ),
                        _PreviewChip(
                          icon: Icons.hub_rounded,
                          label: compatibilityLabel,
                        ),
                        _PreviewChip(
                          icon: Icons.landscape_rounded,
                          label: sceneLabel,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PreviewChip(
                    icon: Icons.bolt_rounded,
                    label: statusLabel,
                    emphasized: true,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              child: _PreviewChip(
                icon: compareEnabled
                    ? Icons.compare_arrows_rounded
                    : Icons.image_rounded,
                label: compareEnabled ? 'Drag to compare' : 'Styled preview',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionPanel extends StatelessWidget {
  const _PrimaryActionPanel({
    required this.strength,
    required this.compareEnabled,
    required this.isBusy,
    required this.onStrengthChanged,
    required this.onCompareChanged,
    required this.onMakeItViral,
  });

  final double strength;
  final bool compareEnabled;
  final bool isBusy;
  final ValueChanged<double> onStrengthChanged;
  final ValueChanged<bool> onCompareChanged;
  final VoidCallback onMakeItViral;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ViralStudioTokens.panelDecoration(emphasized: true),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Make it Viral',
                        style: ViralStudioTokens.sectionTitle()),
                    const SizedBox(height: 4),
                    Text(
                      'Render the polished high-resolution version with the current preset and safety routing.',
                      style: ViralStudioTokens.body(12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CompareToggle(
                value: compareEnabled,
                onChanged: onCompareChanged,
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: ViralStudioTokens.primaryButton().copyWith(
              minimumSize: const WidgetStatePropertyAll<Size>(
                Size(double.infinity, 54),
              ),
            ),
            onPressed: isBusy ? null : onMakeItViral,
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: const Text('Make it Viral'),
          ),
          const SizedBox(height: 16),
          _InlineValueSlider(
            label: 'Strength',
            hint: 'Adaptive intensity',
            value: strength,
            min: 0.2,
            max: 1.0,
            onChanged: onStrengthChanged,
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: ViralStudioTokens.sectionTitle()),
        const SizedBox(height: 4),
        Text(subtitle, style: ViralStudioTokens.body(12)),
      ],
    );
  }
}

class _ToolSheet extends StatelessWidget {
  const _ToolSheet({
    required this.activeTab,
    required this.onTabChanged,
    required this.child,
  });

  final _ResultToolTab activeTab;
  final ValueChanged<_ResultToolTab> onTabChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ViralStudioTokens.panelDecoration(emphasized: true),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Edit Tools', style: ViralStudioTokens.sectionTitle()),
          const SizedBox(height: 4),
          Text(
            'Quick tweaks stay close at hand while deeper controls and diagnostics stay tucked below.',
            style: ViralStudioTokens.body(12),
          ),
          const SizedBox(height: 14),
          Row(
            children: _ResultToolTab.values
                .map(
                  (tab) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: tab == _ResultToolTab.diagnostics ? 0 : 8,
                      ),
                      child: _ToolTabButton(
                        label: switch (tab) {
                          _ResultToolTab.quick => 'Quick',
                          _ResultToolTab.pro => 'Pro',
                          _ResultToolTab.diagnostics => 'Diagnostics',
                        },
                        selected: activeTab == tab,
                        onPressed: () => onTabChanged(tab),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _QuickTab extends StatelessWidget {
  const _QuickTab({
    required this.state,
    required this.result,
  });

  final StyleTransferState state;
  final StyleTransferResult result;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<StyleTransferController>();
    final local = state.settings.localOverrides;
    final faceFurProtect = local.skinProtect && local.faceExposureGuard;
    final isWildlife = result.sceneAnalysis.statistics.furLikelihood > 0.24 ||
        result.sceneAnalysis.scene.sceneType == 'wildlife';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StyleSliderTile(
          label: 'Strength',
          subtitle:
              'Keep the look adaptive. Higher values push the preset harder onto the target.',
          value: state.settings.strength,
          min: 0.2,
          max: 1.0,
          onChanged: controller.updateStrength,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 760
                ? 3
                : constraints.maxWidth > 430
                    ? 2
                    : 1;
            const spacing = 12.0;
            final itemWidth =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: <Widget>[
                SizedBox(
                  width: itemWidth,
                  child: _QuickToggleCard(
                    title: 'Natural Protect',
                    description:
                        'Prioritize realism, balanced luminance, and softer style aggression.',
                    value: state.settings.naturalMode,
                    onChanged: controller.updateNaturalMode,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _QuickToggleCard(
                    title: 'Face/Fur Protect',
                    description: isWildlife
                        ? 'Preserve fur texture, edge energy, and warm animal tones.'
                        : 'Protect facial brightness, skin stability, and subject texture.',
                    value: faceFurProtect,
                    onChanged: (value) => controller.updateMaskRules(
                      (current) => current.copyWith(
                        skinProtect: value,
                        faceExposureGuard: value,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _QuickToggleCard(
                    title: 'Preserve Brightness',
                    description:
                        'Hold onto the original light structure and avoid the washed-out fog look.',
                    value: state.settings.exposureLock,
                    onChanged: controller.updateExposureLock,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _QuickToggleCard(
                    title: 'Scene Auto',
                    description:
                        'Tune the preset to portraits, wildlife, products, and harder scene changes.',
                    value: state.settings.sceneFit,
                    onChanged: controller.updateSceneFit,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _QuickToggleCard(
                    title: 'Style Fit',
                    description:
                        'Enable safe fallback damping when the reference and target mismatch too much.',
                    value: state.settings.fallbackEnabled,
                    onChanged: controller.updateFallbackEnabled,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProTab extends StatelessWidget {
  const _ProTab({
    required this.state,
    required this.onOpenFullEditor,
    required this.onEditWatermark,
  });

  final StyleTransferState state;
  final VoidCallback onOpenFullEditor;
  final VoidCallback onEditWatermark;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<StyleTransferController>();
    final tone = state.settings.toneAdjustment;
    final detail = state.settings.detailAdjustment;
    final hsl = state.settings.hslAdjustment;
    final local = state.settings.localOverrides;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ProGroup(
          title: 'Tone',
          subtitle:
              'Rebalance contrast and brightness without flattening the frame.',
          children: <Widget>[
            StyleSliderTile(
              label: 'Exposure',
              value: tone.exposure,
              min: -0.4,
              max: 0.4,
              onChanged: (value) => controller
                  .updateTone((current) => current.copyWith(exposure: value)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Contrast',
              value: tone.contrast,
              min: -0.4,
              max: 0.4,
              onChanged: (value) => controller
                  .updateTone((current) => current.copyWith(contrast: value)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Highlights',
              value: tone.highlights,
              min: -0.4,
              max: 0.4,
              onChanged: (value) => controller
                  .updateTone((current) => current.copyWith(highlights: value)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Shadows',
              value: tone.shadows,
              min: -0.4,
              max: 0.4,
              onChanged: (value) => controller
                  .updateTone((current) => current.copyWith(shadows: value)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Fade',
              value: tone.fade,
              min: -0.2,
              max: 0.4,
              onChanged: (value) => controller
                  .updateTone((current) => current.copyWith(fade: value)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProGroup(
          title: 'Color',
          subtitle:
              'Keep color premium and natural while protecting luminance.',
          children: <Widget>[
            StyleSliderTile(
              label: 'Luminance Preserve',
              value: state.settings.luminancePreservation,
              min: 0.55,
              max: 1.0,
              onChanged: controller.updateLuminancePreservation,
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Orange Saturation',
              value: hsl.orange.s,
              min: -0.3,
              max: 0.3,
              onChanged: (value) => controller.updateHslChannel(
                'orange',
                (current) => current.copyWith(s: value),
              ),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Green Saturation',
              value: hsl.green.s,
              min: -0.3,
              max: 0.3,
              onChanged: (value) => controller.updateHslChannel(
                'green',
                (current) => current.copyWith(s: value),
              ),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Blue Saturation',
              value: hsl.blue.s,
              min: -0.3,
              max: 0.3,
              onChanged: (value) => controller.updateHslChannel(
                'blue',
                (current) => current.copyWith(s: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProGroup(
          title: 'Detail',
          subtitle:
              'Recover texture and local contrast without halos or fake HDR.',
          children: <Widget>[
            StyleSliderTile(
              label: 'Clarity',
              value: detail.clarity,
              min: -0.3,
              max: 0.4,
              onChanged: (value) => controller
                  .updateDetail((current) => current.copyWith(clarity: value)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Texture',
              value: detail.texture,
              min: -0.3,
              max: 0.4,
              onChanged: (value) => controller
                  .updateDetail((current) => current.copyWith(texture: value)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Bloom',
              value: detail.bloom,
              min: -0.1,
              max: 0.4,
              onChanged: (value) => controller
                  .updateDetail((current) => current.copyWith(bloom: value)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Detail Recovery',
              value: state.settings.detailRecovery,
              min: 0.05,
              max: 0.7,
              onChanged: controller.updateDetailRecoveryAmount,
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Glow Boost',
              value: state.settings.glowBoost,
              min: 0,
              max: 0.7,
              onChanged: controller.updateGlowBoost,
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Micro Contrast',
              value: state.settings.detailBoost,
              min: 0,
              max: 0.7,
              onChanged: controller.updateDetailBoost,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProGroup(
          title: 'Region',
          subtitle:
              'Control which subjects and areas receive the strongest protection.',
          children: <Widget>[
            _SettingSwitchTile(
              title: 'Skin Protect',
              subtitle: 'Guard skin hue and portrait tonal balance.',
              value: local.skinProtect,
              onChanged: (value) => controller.updateMaskRules(
                (current) => current.copyWith(skinProtect: value),
              ),
            ),
            _SettingSwitchTile(
              title: 'Face Exposure Guard',
              subtitle:
                  'Keep faces from going flat or clipped after tone mapping.',
              value: local.faceExposureGuard,
              onChanged: (value) => controller.updateMaskRules(
                (current) => current.copyWith(faceExposureGuard: value),
              ),
            ),
            _SettingSwitchTile(
              title: 'Sky Adjust',
              subtitle: 'Allow sky regions to receive dedicated color shaping.',
              value: local.skyAdjust,
              onChanged: (value) => controller.updateMaskRules(
                (current) => current.copyWith(skyAdjust: value),
              ),
            ),
            _SettingSwitchTile(
              title: 'Background Adjust',
              subtitle:
                  'Keep background grading active without overpushing the subject.',
              value: local.backgroundAdjust,
              onChanged: (value) => controller.updateMaskRules(
                (current) => current.copyWith(backgroundAdjust: value),
              ),
            ),
            _SettingSwitchTile(
              title: 'Face Refinement',
              subtitle: 'Adds subtle face-aware cleanup in supported scenes.',
              value: state.settings.faceRefinement,
              onChanged: controller.updateFaceRefinement,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProGroup(
          title: 'Safety',
          subtitle:
              'Keep the render stable when a preset becomes too aggressive.',
          initiallyExpanded: true,
          children: <Widget>[
            _SettingSwitchTile(
              title: 'Natural Protect',
              subtitle: 'Prefer realism and calmer luminance routing.',
              value: state.settings.naturalMode,
              onChanged: controller.updateNaturalMode,
            ),
            _SettingSwitchTile(
              title: 'Fallback Guard',
              subtitle:
                  'Reduce style aggression when scene compatibility drops.',
              value: state.settings.fallbackEnabled,
              onChanged: controller.updateFallbackEnabled,
            ),
            _SettingSwitchTile(
              title: 'Cinematic Glow',
              subtitle:
                  'Enable subtle bloom routing tied to highlight protection.',
              value: state.settings.cinematicGlow,
              onChanged: controller.updateCinematicGlow,
            ),
            _SettingSwitchTile(
              title: 'Depth Illusion',
              subtitle:
                  'Maintain cinematic separation without turning the image artificial.',
              value: state.settings.depthIllusion,
              onChanged: controller.updateDepthIllusion,
            ),
            _SettingSwitchTile(
              title: 'Watermark Export',
              subtitle: 'Apply studio branding only on exported output.',
              value: state.settings.watermarkEnabled,
              onChanged: controller.updateWatermarkEnabled,
            ),
            if (state.settings.watermarkEnabled) ...<Widget>[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: ViralStudioTokens.secondaryButton(),
                onPressed: onEditWatermark,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Watermark'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          style: ViralStudioTokens.secondaryButton().copyWith(
            minimumSize: const WidgetStatePropertyAll<Size>(
              Size(double.infinity, 48),
            ),
          ),
          onPressed: onOpenFullEditor,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Open Full Pro Editor'),
        ),
      ],
    );
  }
}

class _DiagnosticsTab extends StatelessWidget {
  const _DiagnosticsTab({
    required this.state,
    required this.result,
    required this.safetyNotes,
  });

  final StyleTransferState state;
  final StyleTransferResult result;
  final List<String> safetyNotes;

  @override
  Widget build(BuildContext context) {
    final report = result.safetyReport;
    final sceneStatistics = result.sceneAnalysis.statistics;
    final notes = <String>[
      if (state.statusMessage != null && state.statusMessage!.isNotEmpty)
        state.statusMessage!,
      ...safetyNotes,
    ];
    final warnings = result.warnings.isEmpty
        ? <String>[
            'No active warnings. The current render is within safety thresholds.'
          ]
        : result.warnings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _DiagnosticMetricCard(
              label: 'Compatibility',
              value: '${(result.compatibility * 100).round()}%',
            ),
            _DiagnosticMetricCard(
              label: 'Scene',
              value: _toDisplayLabel(result.sceneAnalysis.scene.sceneType),
            ),
            _DiagnosticMetricCard(
              label: 'Applied',
              value: '${(result.appliedStrength * 100).round()}%',
            ),
            _DiagnosticMetricCard(
              label: 'Viral',
              value: '${(result.viralScore * 100).round()}%',
            ),
            _DiagnosticMetricCard(
              label: 'Preview',
              value: '${result.previewRenderMs}ms',
            ),
            _DiagnosticMetricCard(
              label: 'Export',
              value:
                  result.exportReady ? '${result.exportRenderMs}ms' : 'Pending',
            ),
            _DiagnosticMetricCard(
              label: 'Clip Risk',
              value: '${(report.clipRisk * 100).round()}%',
            ),
            _DiagnosticMetricCard(
              label: 'Banding',
              value: '${(report.bandingRisk * 100).round()}%',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Active Safety Rules', style: ViralStudioTokens.sectionTitle()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (report.skinPreserved) const _InfoPill(label: 'Skin preserve'),
            if (report.highlightsProtected)
              const _InfoPill(label: 'Highlight roll-off'),
            if (report.shadowsProtected)
              const _InfoPill(label: 'Shadow protection'),
            if (report.haloFree) const _InfoPill(label: 'Halo guard'),
            if (state.settings.exposureLock)
              const _InfoPill(label: 'Brightness lock'),
            if (state.settings.fallbackEnabled)
              const _InfoPill(label: 'Style fit guard'),
            if (state.settings.naturalMode)
              const _InfoPill(label: 'Natural protect'),
            if (sceneStatistics.furLikelihood > 0.24)
              const _InfoPill(label: 'Wildlife texture route'),
            if (sceneStatistics.neutralLikelihood > 0.28)
              const _InfoPill(label: 'Neutral color preserve'),
          ],
        ),
        const SizedBox(height: 16),
        _DiagnosticListPanel(
          title: 'Processing Notes',
          items: notes,
        ),
        const SizedBox(height: 12),
        _DiagnosticListPanel(
          title: 'Warnings',
          items: warnings,
          warning: result.warnings.isNotEmpty,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: emphasized
            ? ViralStudioTokens.accent.withValues(alpha: 0.88)
            : ViralStudioTokens.background.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? ViralStudioTokens.accentSoft.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 14,
            color: emphasized ? Colors.black : Colors.white,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: ViralStudioTokens.body(11).copyWith(
                color: emphasized ? Colors.black : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareToggle extends StatelessWidget {
  const _CompareToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: value ? 0.1 : 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value
              ? ViralStudioTokens.accent.withValues(alpha: 0.65)
              : ViralStudioTokens.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Compare',
            style: ViralStudioTokens.body(12)
                .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: ViralStudioTokens.accent,
          ),
        ],
      ),
    );
  }
}

class _InlineValueSlider extends StatelessWidget {
  const _InlineValueSlider({
    required this.label,
    required this.hint,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ViralStudioTokens.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style:
                      ViralStudioTokens.sectionTitle().copyWith(fontSize: 15),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${(value * 100).round()}%',
                  style: ViralStudioTokens.body(11).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(hint, style: ViralStudioTokens.body(12)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ViralStudioTokens.accent,
              thumbColor: ViralStudioTokens.accentSoft,
              inactiveTrackColor: ViralStudioTokens.outline,
              overlayColor: ViralStudioTokens.accent.withValues(alpha: 0.16),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionShortcut extends StatelessWidget {
  const _ActionShortcut({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: ViralStudioTokens.secondaryButton().copyWith(
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _ToolTabButton extends StatelessWidget {
  const _ToolTabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ViralStudioTokens.accent.withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: ViralStudioTokens.body(12).copyWith(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickToggleCard extends StatelessWidget {
  const _QuickToggleCard({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: ViralStudioTokens.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style:
                      ViralStudioTokens.sectionTitle().copyWith(fontSize: 15),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: ViralStudioTokens.accent,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: ViralStudioTokens.body(12)),
        ],
      ),
    );
  }
}

class _ProGroup extends StatelessWidget {
  const _ProGroup({
    required this.title,
    required this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ViralStudioTokens.panelDecoration(),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        textColor: Colors.white,
        collapsedTextColor: Colors.white,
        title: Text(title, style: ViralStudioTokens.sectionTitle()),
        subtitle: Text(subtitle, style: ViralStudioTokens.body(12)),
        children: children,
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ViralStudioTokens.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style:
                      ViralStudioTokens.sectionTitle().copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: ViralStudioTokens.body(12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: ViralStudioTokens.accent,
          ),
        ],
      ),
    );
  }
}

class _DiagnosticMetricCard extends StatelessWidget {
  const _DiagnosticMetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 108),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
          Text(
            value,
            style: ViralStudioTokens.sectionTitle().copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticListPanel extends StatelessWidget {
  const _DiagnosticListPanel({
    required this.title,
    required this.items,
    this.warning = false,
  });

  final String title;
  final List<String> items;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: ViralStudioTokens.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: ViralStudioTokens.sectionTitle()),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      warning
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_rounded,
                      size: 16,
                      color: warning
                          ? ViralStudioTokens.accentSoft
                          : ViralStudioTokens.cool,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item, style: ViralStudioTokens.body(12)),
                  ),
                ],
              ),
            ),
          ),
        ],
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

String _toDisplayLabel(String raw) {
  if (raw.trim().isEmpty) {
    return 'Unknown';
  }
  return raw
      .split(RegExp(r'[_\\s-]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
