import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/features/blur_focus/data/engines/mlkit_subject_segmentation_engine.dart';
import 'package:untitled2/features/blur_focus/data/processors/focus_mask_refinement_engine_impl.dart';
import 'package:untitled2/features/blur_focus/data/processors/isolate_blur_renderer.dart';
import 'package:untitled2/features/blur_focus/data/repositories/blur_focus_repository.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_mode.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_settings.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';
import 'package:untitled2/features/blur_focus/integration/mappers/blur_focus_operation_mapper.dart';
import 'package:untitled2/features/blur_focus/presentation/controller/blur_focus_controller.dart';
import 'package:untitled2/features/blur_focus/presentation/controller/blur_focus_state.dart';
import 'package:untitled2/features/blur_focus/presentation/widgets/blur_focus_canvas.dart';

// ── Entry point ──────────────────────────────────────────────────────────────

class BlurFocusStudioScreen extends StatelessWidget {
  const BlurFocusStudioScreen({
    super.key,
    required this.initialImage,
    this.onApply,
    this.onCancel,
  });

  final ui.Image initialImage;
  final ValueChanged<Uint8List>? onApply;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BlurFocusController(
        repository: BlurFocusRepository(
          segmentationEngine: MlKitSubjectSegmentationEngine(),
          refinementEngine: FocusMaskRefinementEngineImpl(),
          previewRenderer: const IsolateBlurRenderer(),
          commitRenderer: const IsolateBlurRenderer(),
        ),
        mapper: const BlurFocusOperationMapper(),
      )..initialize(initialImage),
      child: _BlurFocusStudioView(onApply: onApply, onCancel: onCancel),
    );
  }
}

// ── Root view ─────────────────────────────────────────────────────────────────

class _BlurFocusStudioView extends StatefulWidget {
  const _BlurFocusStudioView({this.onApply, this.onCancel});

  final ValueChanged<Uint8List>? onApply;
  final VoidCallback? onCancel;

  @override
  State<_BlurFocusStudioView> createState() => _BlurFocusStudioViewState();
}

class _BlurFocusStudioViewState extends State<_BlurFocusStudioView> {
  bool _advancedOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: SafeArea(
        child: BlocConsumer<BlurFocusController, BlurFocusState>(
          listenWhen: (prev, curr) => prev.errorMessage != curr.errorMessage,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
            final controller = context.read<BlurFocusController>();
            final visibleImage = state.showOriginalPreview
                ? state.originalImage
                : (state.previewImage ?? state.originalImage);

            if (visibleImage == null) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF56E39F)),
              );
            }

            return Column(
              children: [
                // Export progress bar at very top
                if (state.status == BlurFocusStatus.exporting)
                  const LinearProgressIndicator(
                    backgroundColor: Color(0xFF1E1E22),
                    color: Color(0xFF56E39F),
                    minHeight: 3,
                  ),

                _TopBar(
                  state: state,
                  onClose: () {
                    widget.onCancel?.call();
                    Navigator.of(context).pop();
                  },
                  onReset: controller.resetCurrentMode,
                  onApply: () async {
                    final bytes = await controller.exportFinal();
                    if (!mounted || bytes == null) return;
                    widget.onApply?.call(bytes);
                    Navigator.of(context).pop();
                  },
                  onCompareStart: () => controller.showOriginal(true),
                  onCompareEnd: () => controller.showOriginal(false),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BlurFocusCanvas(
                              image: visibleImage,
                              settings: state.operation.settings,
                              showMaskPreview: state.showMaskPreview,
                              refineMaskMode: state.refineMaskMode,
                              segmentation: state.operation.segmentation,
                              manualBlendMode: state.manualBlendMode,
                              onSettingsChanged: controller.updateSettings,
                              onManualStroke: controller.addManualStroke,
                            ),
                          ),
                        ),
                      ),

                      // Processing badge (only for non-track quality renders)
                      if (state.status == BlurFocusStatus.processing ||
                          state.segmentationInProgress)
                        Positioned(
                          right: 24,
                          top: 20,
                          child: _ProcessingBadge(
                            label: state.segmentationInProgress
                                ? 'Analyzing subject\u2026'
                                : 'Refining preview\u2026',
                          ),
                        ),
                    ],
                  ),
                ),

                // Hint message with animated fade
                _AnimatedHint(message: state.hintMessage),

                _ModeSelector(
                  activeMode: state.activeMode,
                  onChanged: controller.setMode,
                ),
                _SliderPanel(
                  settings: state.operation.settings,
                  state: state,
                  advancedOpen: _advancedOpen,
                  onToggleAdvanced: () =>
                      setState(() => _advancedOpen = !_advancedOpen),
                  onSettingChange: controller.updateSettings,
                  onToggleMaskPreview: controller.toggleMaskPreview,
                  onToggleRefineMask: controller.toggleRefineMask,
                  onManualBlendModeChanged: controller.setManualBlendMode,
                  onRedetect: () => controller.redetectSubject(),
                  onUndo: () => controller.undo(),
                  onRedo: () => controller.redo(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.state,
    required this.onClose,
    required this.onReset,
    required this.onApply,
    required this.onCompareStart,
    required this.onCompareEnd,
  });

  final BlurFocusState state;
  final VoidCallback onClose;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final VoidCallback onCompareStart;
  final VoidCallback onCompareEnd;

  @override
  Widget build(BuildContext context) {
    final isExporting = state.status == BlurFocusStatus.exporting;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),
          const Text(
            'AI Blur',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: -0.5),
          ),
          IconButton(
            onPressed: isExporting ? null : onApply,
            icon: Icon(
              Icons.file_download_outlined,
              color: isExporting ? Colors.white38 : Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Processing badge ──────────────────────────────────────────────────────────

class _ProcessingBadge extends StatelessWidget {
  const _ProcessingBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF56E39F)),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Animated hint message ─────────────────────────────────────────────────────

class _AnimatedHint extends StatelessWidget {
  const _AnimatedHint({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: message == null
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey(message),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message!,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70), fontSize: 12.5),
                ),
              ),
            ),
    );
  }
}

// ── Mode selector ─────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.activeMode, required this.onChanged});

  final BlurMode activeMode;
  final ValueChanged<BlurMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: BlurMode.values.map((mode) {
          final selected = mode == activeMode;
          final color = selected ? const Color(0xFF56E39F) : Colors.white54;
          
          return GestureDetector(
            onTap: () => onChanged(mode),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  switch (mode) {
                    BlurMode.smart => Icons.face_retouching_natural,
                    BlurMode.circle => Icons.circle_outlined,
                    BlurMode.line => Icons.linear_scale,
                  },
                  color: color,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  switch (mode) {
                    BlurMode.smart => 'Smart',
                    BlurMode.circle => 'Circle',
                    BlurMode.line => 'Line',
                  },
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Slider panel ──────────────────────────────────────────────────────────────

class _SliderPanel extends StatelessWidget {
  const _SliderPanel({
    required this.settings,
    required this.state,
    required this.advancedOpen,
    required this.onToggleAdvanced,
    required this.onSettingChange,
    required this.onToggleMaskPreview,
    required this.onToggleRefineMask,
    required this.onManualBlendModeChanged,
    required this.onRedetect,
    required this.onUndo,
    required this.onRedo,
  });

  final BlurSettings settings;
  final BlurFocusState state;
  final bool advancedOpen;
  final VoidCallback onToggleAdvanced;
  final ValueChanged<BlurSettings> onSettingChange;
  final VoidCallback onToggleMaskPreview;
  final VoidCallback onToggleRefineMask;
  final ValueChanged<ManualMaskBlendMode> onManualBlendModeChanged;
  final Future<void> Function() onRedetect;
  final Future<void> Function() onUndo;
  final Future<void> Function() onRedo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Single prominent slider (matching the green one in screenshot)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF56E39F),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                      thumbColor: Colors.white,
                      overlayColor: const Color(0x3356E39F),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: settings.blurAmount.clamp(2.0, 30.0),
                      min: 2.0,
                      max: 30.0,
                      onChanged: (v) =>
                          onSettingChange(settings.copyWith(blurAmount: v)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onToggleRefineMask,
                  icon: Icon(
                    Icons.auto_fix_high,
                    color: state.refineMaskMode ? const Color(0xFF56E39F) : Colors.white70,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
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
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              value.toStringAsFixed(max <= 1 ? 2 : 1),
              style:
                  TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 12),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF56E39F),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: Colors.white,
            overlayColor: const Color(0x3356E39F),
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

class _TogglePill extends StatelessWidget {
  const _TogglePill(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF56E39F)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(
      {required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
                color: enabled ? Colors.white : Colors.white24, fontSize: 12)),
      ),
    );
  }
}
