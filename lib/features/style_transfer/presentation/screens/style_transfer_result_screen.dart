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

/// Preview-first result surface — compact header, hero preview, slim action
/// panel, style carousel, and a tabbed tool sheet. All BLoC wiring preserved.
class StyleTransferResultScreen extends StatefulWidget {
  const StyleTransferResultScreen({super.key});

  @override
  State<StyleTransferResultScreen> createState() =>
      _StyleTransferResultScreenState();
}

class _StyleTransferResultScreenState
    extends State<StyleTransferResultScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _compareEnabled = true;
  _ResultToolTab _activeTab = _ResultToolTab.quick;

  // ─── dialogs / navigation ──────────────────────────────────────────────────

  Future<void> _savePreset() async {
    final controller = context.read<StyleTransferController>();
    final nameCtrl = TextEditingController(
      text:
          controller.state.previewResult?.appliedProfile.name ?? 'My Viral Style',
    );
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ViralStudioTokens.surface,
          title: const Text('Save Preset',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Preset name'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Save')),
          ],
        ),
      );
      if (ok == true && mounted) {
        await controller.saveCurrentPreset(
            nameCtrl.text.trim().isEmpty ? 'My Viral Style' : nameCtrl.text.trim());
      }
    } finally {
      nameCtrl.dispose();
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

  Future<void> _editWatermark() async {
    final controller = context.read<StyleTransferController>();
    final textCtrl =
        TextEditingController(text: controller.state.settings.watermarkText);
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ViralStudioTokens.surface,
          title: const Text('Watermark Text',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: textCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Save')),
          ],
        ),
      );
      if (ok == true && mounted) {
        controller.updateWatermarkText(textCtrl.text);
      }
    } finally {
      textCtrl.dispose();
    }
  }

  Future<void> _openPresetLibrary() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: context.read<StyleTransferController>(),
        child: const StyleLibraryScreen(),
      ),
    ));
  }

  Future<void> _openProControls() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: context.read<StyleTransferController>(),
        child: const StyleTransferProControlsScreen(),
      ),
    ));
  }

  Future<void> _openSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<StyleTransferController>(),
        child: BlocBuilder<StyleTransferController, StyleTransferState>(
          builder: (ctx, state) => SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: Container(
                decoration: ViralStudioTokens.panelDecoration(emphasized: true),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export Settings',
                        style: ViralStudioTokens.sectionTitle()
                            .copyWith(fontSize: 16)),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: state.settings.watermarkEnabled,
                      onChanged:
                          ctx.read<StyleTransferController>().updateWatermarkEnabled,
                      title: const Text('Watermark Export',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text(
                        state.settings.watermarkEnabled
                            ? 'Studio label added on export'
                            : 'Exports stay clean',
                        style: ViralStudioTokens.body(12),
                      ),
                    ),
                    if (state.settings.watermarkEnabled) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: ViralStudioTokens.secondaryButton(),
                        onPressed: _editWatermark,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit Watermark'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: ViralStudioTokens.primaryButton(),
                            onPressed: () {
                              Navigator.of(sheetCtx).pop();
                              ctx
                                  .read<StyleTransferController>()
                                  .exportCurrent();
                            },
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Export'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: ViralStudioTokens.secondaryButton(),
                            onPressed: () {
                              Navigator.of(sheetCtx).pop();
                              ctx
                                  .read<StyleTransferController>()
                                  .shareCurrent();
                            },
                            icon: const Icon(Icons.ios_share_rounded),
                            label: const Text('Share'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<StyleTransferController, StyleTransferState>(
      listenWhen: (prev, cur) =>
          prev.errorMessage != cur.errorMessage ||
          prev.statusMessage != cur.statusMessage,
      listener: (ctx, state) {
        final msg = state.errorMessage ?? state.statusMessage;
        if (msg == null || msg.isEmpty) return;
        ScaffoldMessenger.of(ctx)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
        ctx.read<StyleTransferController>().clearMessages();
      },
      child: Scaffold(
        backgroundColor: ViralStudioTokens.background,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: ViralStudioTokens.pageGlow),
          child: SafeArea(
            child: BlocBuilder<StyleTransferController, StyleTransferState>(
              builder: (ctx, state) {
                final result = state.exportResult ?? state.previewResult;
                if (result == null || state.targetBytes == null) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      padding: const EdgeInsets.all(22),
                      decoration: ViralStudioTokens.panelDecoration(),
                      child:
                          Text('No result yet.', style: ViralStudioTokens.body()),
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

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // 1. Compact header
                          _CompactHeader(
                            title: 'AI Style Transfer',
                            subtitle: state.statusMessage ??
                                'Polish, compare, and export.',
                            onBack: () => Navigator.of(ctx).maybePop(),
                            onPresets: _openPresetLibrary,
                            onSettings: _openSettingsSheet,
                          ),
                          const SizedBox(height: 14),

                          // 2. Preview hero
                          _PreviewHero(
                            beforeBytes: state.targetBytes!,
                            afterBytes:
                                result.exportBytes ?? result.previewBytes,
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
                          const SizedBox(height: 14),

                          // 3. Primary action panel
                          _PrimaryActionPanel(
                            strength: state.settings.strength,
                            compareEnabled: _compareEnabled,
                            isBusy: state.isRenderingPreview ||
                                state.isRenderingExport,
                            onStrengthChanged: ctx
                                .read<StyleTransferController>()
                                .updateStrength,
                            onCompareChanged: (v) =>
                                setState(() => _compareEnabled = v),
                            onMakeItViral: () => ctx
                                .read<StyleTransferController>()
                                .renderHighQuality(),
                            onSavePreset: _savePreset,
                            onApplyAnother: _applyToAnother,
                          ),
                          const SizedBox(height: 16),

                          // 4. Style carousel label
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              'STYLES',
                              style: ViralStudioTokens.body(11).copyWith(
                                color: ViralStudioTokens.textMuted,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 4b. Compact style carousel
                          _CompactStyleCarousel(
                            presets: StylePresetRegistry.allPresets,
                            selectedId: state.selectedPresetId,
                            onSelected: (preset) => ctx
                                .read<StyleTransferController>()
                                .applyPreset(preset),
                          ),
                          const SizedBox(height: 16),

                          // 5. Tool sheet (tabs)
                          _ToolSheet(
                            activeTab: _activeTab,
                            onTabChanged: (tab) =>
                                setState(() => _activeTab = tab),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
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
                                  _ResultToolTab.diagnostics =>
                                    _DiagnosticsTab(
                                      state: state,
                                      result: result,
                                      safetyNotes: safetyNotes,
                                    ),
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ]),
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

// ═══════════════════════════════════════════════════════════════════════════════
// LAYOUT COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

/// Slim top bar: back | title+subtitle | presets | settings.
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _HeaderIconButton(icon: Icons.arrow_back_rounded, onPressed: onBack),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ViralStudioTokens.sectionTitle().copyWith(fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: ViralStudioTokens.body(11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
            icon: Icons.style_rounded, onPressed: onPresets),
        const SizedBox(width: 6),
        _HeaderIconButton(
            icon: Icons.tune_rounded, onPressed: onSettings),
      ],
    );
  }
}

/// Hero preview: large before/after slider with overlay chips.
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
    final screenH = MediaQuery.of(context).size.height;
    final previewH = (screenH * 0.46).clamp(260.0, 420.0);

    return Container(
      height: previewH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: ViralStudioTokens.outline.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Before/after or single preview
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: compareEnabled
                  ? BeforeAfterSlider(
                      key: const ValueKey<String>('compare'),
                      beforeBytes: beforeBytes,
                      afterBytes: afterBytes,
                      aspectRatio: null, // stretch to container
                      borderRadius: 0,
                    )
                  : Image.memory(
                      key: const ValueKey<String>('after'),
                      afterBytes,
                      fit: BoxFit.cover,
                    ),
            ),

            // Subtle vignette overlay
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.14),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.30),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.42, 1],
                  ),
                ),
              ),
            ),

            // Top chips row
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _PreviewChip(
                            icon: Icons.auto_awesome_rounded,
                            label: activeStyle),
                        _PreviewChip(
                            icon: Icons.hub_rounded,
                            label: compatibilityLabel),
                        _PreviewChip(
                            icon: Icons.landscape_rounded,
                            label: sceneLabel),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _PreviewChip(
                    icon: Icons.bolt_rounded,
                    label: statusLabel,
                    emphasized: true,
                  ),
                ],
              ),
            ),

            // Bottom hint
            Positioned(
              left: 12,
              bottom: 12,
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

/// Slim action panel: CTA + strength slider + compare toggle + quick actions.
class _PrimaryActionPanel extends StatelessWidget {
  const _PrimaryActionPanel({
    required this.strength,
    required this.compareEnabled,
    required this.isBusy,
    required this.onStrengthChanged,
    required this.onCompareChanged,
    required this.onMakeItViral,
    required this.onSavePreset,
    required this.onApplyAnother,
  });

  final double strength;
  final bool compareEnabled;
  final bool isBusy;
  final ValueChanged<double> onStrengthChanged;
  final ValueChanged<bool> onCompareChanged;
  final VoidCallback onMakeItViral;
  final VoidCallback onSavePreset;
  final VoidCallback onApplyAnother;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ViralStudioTokens.panelDecoration(emphasized: true),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CTA row
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: ViralStudioTokens.primaryButton().copyWith(
                    minimumSize: const WidgetStatePropertyAll<Size>(
                        Size(0, 50)),
                  ),
                  onPressed: isBusy ? null : onMakeItViral,
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black),
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Make it Viral'),
                ),
              ),
              const SizedBox(width: 10),
              _CompareToggle(
                value: compareEnabled,
                onChanged: onCompareChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Strength slider
          _InlineSlider(
            label: 'Strength',
            value: strength,
            min: 0.2,
            max: 1.0,
            onChanged: onStrengthChanged,
          ),
          const SizedBox(height: 12),

          // Quick action row
          Row(
            children: [
              _QuickAction(
                icon: Icons.bookmark_add_rounded,
                label: 'Save Preset',
                onPressed: onSavePreset,
              ),
              const SizedBox(width: 8),
              _QuickAction(
                icon: Icons.photo_library_outlined,
                label: 'Apply Another',
                onPressed: onApplyAnother,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact horizontal preset carousel — smaller cards with color swatches + name only.
class _CompactStyleCarousel extends StatelessWidget {
  const _CompactStyleCarousel({
    required this.presets,
    required this.selectedId,
    required this.onSelected,
  });

  final List<dynamic> presets;
  final String? selectedId;
  final ValueChanged<dynamic> onSelected;

  @override
  Widget build(BuildContext context) {
    return StylePresetStrip(
      presets: presets.cast(),
      selectedId: selectedId,
      height: 88,
      cardWidth: 118,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      descriptionMaxLines: 0,
      showDescription: false,
      nameFontSize: 12,
      onSelected: onSelected,
    );
  }
}

/// Tab container for Quick / Pro / Diagnostics — no redundant header text.
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
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab bar
          Row(
            children: _ResultToolTab.values.map((tab) {
              final isLast = tab == _ResultToolTab.diagnostics;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
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
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 14),

          // Tab content
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: child,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB CONTENT
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickTab extends StatelessWidget {
  const _QuickTab({required this.state, required this.result});

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
      children: [
        StyleSliderTile(
          label: 'Strength',
          subtitle: 'Adaptive style intensity',
          value: state.settings.strength,
          min: 0.2,
          max: 1.0,
          onChanged: controller.updateStrength,
        ),
        const SizedBox(height: 10),
        _CompactSwitchRow(
          title: 'Natural Protect',
          subtitle: 'Calm luminance routing',
          value: state.settings.naturalMode,
          onChanged: controller.updateNaturalMode,
        ),
        _CompactSwitchRow(
          title: isWildlife ? 'Fur Protect' : 'Face Protect',
          subtitle: isWildlife
              ? 'Preserve fur texture and tones'
              : 'Protect facial brightness',
          value: faceFurProtect,
          onChanged: (v) => controller.updateMaskRules(
            (c) => c.copyWith(skinProtect: v, faceExposureGuard: v),
          ),
        ),
        _CompactSwitchRow(
          title: 'Preserve Brightness',
          subtitle: 'Lock original light structure',
          value: state.settings.exposureLock,
          onChanged: controller.updateExposureLock,
        ),
        _CompactSwitchRow(
          title: 'Scene Auto',
          subtitle: 'Tune preset to detected scene',
          value: state.settings.sceneFit,
          onChanged: controller.updateSceneFit,
        ),
        _CompactSwitchRow(
          title: 'Style Fit',
          subtitle: 'Fallback damping on mismatch',
          value: state.settings.fallbackEnabled,
          onChanged: controller.updateFallbackEnabled,
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
      children: [
        _ProGroup(
          title: 'Tone',
          subtitle: 'Rebalance contrast without flattening.',
          children: [
            StyleSliderTile(
              label: 'Exposure',
              value: tone.exposure,
              min: -0.4,
              max: 0.4,
              onChanged: (v) => controller
                  .updateTone((c) => c.copyWith(exposure: v)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Contrast',
              value: tone.contrast,
              min: -0.4,
              max: 0.4,
              onChanged: (v) => controller
                  .updateTone((c) => c.copyWith(contrast: v)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Highlights',
              value: tone.highlights,
              min: -0.4,
              max: 0.4,
              onChanged: (v) => controller
                  .updateTone((c) => c.copyWith(highlights: v)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Shadows',
              value: tone.shadows,
              min: -0.4,
              max: 0.4,
              onChanged: (v) => controller
                  .updateTone((c) => c.copyWith(shadows: v)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Fade',
              value: tone.fade,
              min: -0.2,
              max: 0.4,
              onChanged: (v) =>
                  controller.updateTone((c) => c.copyWith(fade: v)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ProGroup(
          title: 'Color',
          subtitle: 'Protect luminance, shape hue.',
          children: [
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
              onChanged: (v) =>
                  controller.updateHslChannel('orange', (c) => c.copyWith(s: v)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Green Saturation',
              value: hsl.green.s,
              min: -0.3,
              max: 0.3,
              onChanged: (v) =>
                  controller.updateHslChannel('green', (c) => c.copyWith(s: v)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Blue Saturation',
              value: hsl.blue.s,
              min: -0.3,
              max: 0.3,
              onChanged: (v) =>
                  controller.updateHslChannel('blue', (c) => c.copyWith(s: v)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ProGroup(
          title: 'Detail',
          subtitle: 'Recover texture without halos.',
          children: [
            StyleSliderTile(
              label: 'Clarity',
              value: detail.clarity,
              min: -0.3,
              max: 0.4,
              onChanged: (v) => controller
                  .updateDetail((c) => c.copyWith(clarity: v)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Texture',
              value: detail.texture,
              min: -0.3,
              max: 0.4,
              onChanged: (v) => controller
                  .updateDetail((c) => c.copyWith(texture: v)),
            ),
            const SizedBox(height: 10),
            StyleSliderTile(
              label: 'Bloom',
              value: detail.bloom,
              min: -0.1,
              max: 0.4,
              onChanged: (v) =>
                  controller.updateDetail((c) => c.copyWith(bloom: v)),
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
        const SizedBox(height: 10),
        _ProGroup(
          title: 'Region',
          subtitle: 'Control per-area protection.',
          children: [
            _SettingSwitchTile(
              title: 'Skin Protect',
              subtitle: 'Guard skin hue and portrait balance.',
              value: local.skinProtect,
              onChanged: (v) => controller
                  .updateMaskRules((c) => c.copyWith(skinProtect: v)),
            ),
            _SettingSwitchTile(
              title: 'Face Exposure Guard',
              subtitle: 'Prevent flat or clipped faces.',
              value: local.faceExposureGuard,
              onChanged: (v) => controller
                  .updateMaskRules((c) => c.copyWith(faceExposureGuard: v)),
            ),
            _SettingSwitchTile(
              title: 'Sky Adjust',
              subtitle: 'Dedicated sky color shaping.',
              value: local.skyAdjust,
              onChanged: (v) => controller
                  .updateMaskRules((c) => c.copyWith(skyAdjust: v)),
            ),
            _SettingSwitchTile(
              title: 'Background Adjust',
              subtitle: 'Grade background without overpush.',
              value: local.backgroundAdjust,
              onChanged: (v) => controller
                  .updateMaskRules((c) => c.copyWith(backgroundAdjust: v)),
            ),
            _SettingSwitchTile(
              title: 'Face Refinement',
              subtitle: 'Subtle face-aware cleanup.',
              value: state.settings.faceRefinement,
              onChanged: controller.updateFaceRefinement,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ProGroup(
          title: 'Safety',
          subtitle: 'Stabilize aggressive presets.',
          initiallyExpanded: true,
          children: [
            _SettingSwitchTile(
              title: 'Natural Protect',
              subtitle: 'Prefer realism and calmer routing.',
              value: state.settings.naturalMode,
              onChanged: controller.updateNaturalMode,
            ),
            _SettingSwitchTile(
              title: 'Fallback Guard',
              subtitle: 'Reduce aggression on mismatch.',
              value: state.settings.fallbackEnabled,
              onChanged: controller.updateFallbackEnabled,
            ),
            _SettingSwitchTile(
              title: 'Cinematic Glow',
              subtitle: 'Subtle bloom with highlight protection.',
              value: state.settings.cinematicGlow,
              onChanged: controller.updateCinematicGlow,
            ),
            _SettingSwitchTile(
              title: 'Depth Illusion',
              subtitle: 'Cinematic separation without artifacts.',
              value: state.settings.depthIllusion,
              onChanged: controller.updateDepthIllusion,
            ),
            _SettingSwitchTile(
              title: 'Watermark Export',
              subtitle: 'Studio label on exported output.',
              value: state.settings.watermarkEnabled,
              onChanged: controller.updateWatermarkEnabled,
            ),
            if (state.settings.watermarkEnabled) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: ViralStudioTokens.secondaryButton(),
                onPressed: onEditWatermark,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Watermark'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: ViralStudioTokens.secondaryButton().copyWith(
            minimumSize:
                const WidgetStatePropertyAll<Size>(Size(double.infinity, 48)),
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
    final stats = result.sceneAnalysis.statistics;
    final notes = <String>[
      if (state.statusMessage != null && state.statusMessage!.isNotEmpty)
        state.statusMessage!,
      ...safetyNotes,
    ];
    final warnings = result.warnings.isEmpty
        ? <String>[
            'No active warnings. Render is within safety thresholds.'
          ]
        : result.warnings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric grid
        _DiagnosticGrid(items: {
          'Compatibility': '${(result.compatibility * 100).round()}%',
          'Scene': _toDisplayLabel(result.sceneAnalysis.scene.sceneType),
          'Applied': '${(result.appliedStrength * 100).round()}%',
          'Viral Score': '${(result.viralScore * 100).round()}%',
          'Preview': '${result.previewRenderMs}ms',
          'Export': result.exportReady
              ? '${result.exportRenderMs}ms'
              : 'Pending',
          'Clip Risk': '${(report.clipRisk * 100).round()}%',
          'Banding': '${(report.bandingRisk * 100).round()}%',
        }),
        const SizedBox(height: 14),

        // Safety pills
        Text('Active Safety Rules',
            style: ViralStudioTokens.body(11).copyWith(
              color: ViralStudioTokens.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (report.skinPreserved)
              const _InfoPill(label: 'Skin preserve'),
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
            if (stats.furLikelihood > 0.24)
              const _InfoPill(label: 'Wildlife texture'),
            if (stats.neutralLikelihood > 0.28)
              const _InfoPill(label: 'Neutral color preserve'),
          ],
        ),
        const SizedBox(height: 14),

        _DiagnosticListPanel(title: 'Processing Notes', items: notes),
        const SizedBox(height: 10),
        _DiagnosticListPanel(
          title: 'Warnings',
          items: warnings,
          warning: result.warnings.isNotEmpty,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized
            ? ViralStudioTokens.accent.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? ViralStudioTokens.accentSoft.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12,
              color: emphasized ? Colors.black : Colors.white),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
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
  const _CompareToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? ViralStudioTokens.accent.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? ViralStudioTokens.accent.withValues(alpha: 0.6)
                : ViralStudioTokens.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              size: 16,
              color: value
                  ? ViralStudioTokens.accent
                  : ViralStudioTokens.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              'Compare',
              style: ViralStudioTokens.body(12).copyWith(
                color: value ? ViralStudioTokens.accent : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineSlider extends StatelessWidget {
  const _InlineSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: ViralStudioTokens.body(13)
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: ViralStudioTokens.accent,
            thumbColor: ViralStudioTokens.accentSoft,
            inactiveTrackColor: ViralStudioTokens.outline,
            overlayColor:
                ViralStudioTokens.accent.withValues(alpha: 0.14),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        style: ViralStudioTokens.secondaryButton().copyWith(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 42)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis),
      ),
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
          : Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
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

/// Compact 2-column switch row used in Quick tab.
class _CompactSwitchRow extends StatelessWidget {
  const _CompactSwitchRow({
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: value
            ? ViralStudioTokens.accent.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? ViralStudioTokens.accent.withValues(alpha: 0.30)
              : ViralStudioTokens.outline.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: ViralStudioTokens.body(13).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    )),
                Text(subtitle,
                    style: ViralStudioTokens.body(11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: ViralStudioTokens.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
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
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 14),
        collapsedIconColor: Colors.white,
        iconColor: ViralStudioTokens.accent,
        textColor: Colors.white,
        collapsedTextColor: Colors.white,
        title:
            Text(title, style: ViralStudioTokens.sectionTitle().copyWith(fontSize: 15)),
        subtitle: Text(subtitle, style: ViralStudioTokens.body(11)),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ViralStudioTokens.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: ViralStudioTokens.body(13).copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: ViralStudioTokens.body(11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: ViralStudioTokens.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

/// Responsive 2-column grid for diagnostic metrics.
class _DiagnosticGrid extends StatelessWidget {
  const _DiagnosticGrid({required this.items});
  final Map<String, String> items;

  @override
  Widget build(BuildContext context) {
    final keys = items.keys.toList();
    final vals = items.values.toList();

    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 500 ? 4 : 2;
      final rows = (keys.length / cols).ceil();
      final cellW =
          (constraints.maxWidth - ((cols - 1) * 8)) / cols;

      return Column(
        children: List.generate(rows, (r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: List.generate(cols, (c) {
                final idx = r * cols + c;
                if (idx >= keys.length) {
                  return SizedBox(width: cellW);
                }
                return Padding(
                  padding: EdgeInsets.only(right: c < cols - 1 ? 8 : 0),
                  child: SizedBox(
                    width: cellW,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: ViralStudioTokens.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(keys[idx],
                              style: ViralStudioTokens.body(10)),
                          const SizedBox(height: 3),
                          Text(vals[idx],
                              style: ViralStudioTokens.sectionTitle()
                                  .copyWith(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      );
    });
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: ViralStudioTokens.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: ViralStudioTokens.sectionTitle().copyWith(fontSize: 14)),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      warning
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_rounded,
                      size: 14,
                      color: warning
                          ? ViralStudioTokens.accentSoft
                          : ViralStudioTokens.cool,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item,
                        style: ViralStudioTokens.body(12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ViralStudioTokens.outline),
      ),
      child: Text(label, style: ViralStudioTokens.body(11)),
    );
  }
}

// ─── helpers ───────────────────────────────────────────────────────────────────

String _toDisplayLabel(String raw) {
  if (raw.trim().isEmpty) return 'Unknown';
  return raw
      .split(RegExp(r'[_\s-]+'))
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
      .join(' ');
}
