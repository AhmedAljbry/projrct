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

class _BlurFocusStudioView extends StatefulWidget {
  const _BlurFocusStudioView({this.onApply, this.onCancel});

  final ValueChanged<Uint8List>? onApply;
  final VoidCallback? onCancel;

  @override
  State<_BlurFocusStudioView> createState() => _BlurFocusStudioViewState();
}

class _BlurFocusStudioViewState extends State<_BlurFocusStudioView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: SafeArea(
        child: BlocConsumer<BlurFocusController, BlurFocusState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            final message = state.errorMessage;
            if (message == null || message.isEmpty) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          builder: (context, state) {
            final controller = context.read<BlurFocusController>();
            final visibleImage = state.showOriginalPreview
                ? state.originalImage
                : (state.previewImage ?? state.originalImage);

            if (visibleImage == null) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF12B886)),
              );
            }

            return Column(
              children: [
                _TopBar(
                  isBusy: state.status == BlurFocusStatus.exporting,
                  onClose: () {
                    widget.onCancel?.call();
                    Navigator.of(context).pop();
                  },
                  onApply: () async {
                    final bytes = await controller.exportFinal();
                    if (!mounted || bytes == null) {
                      return;
                    }
                    widget.onApply?.call(bytes);
                    Navigator.of(context).pop();
                  },
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: AspectRatio(
                        aspectRatio: visibleImage.width / visibleImage.height,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RepaintBoundary(
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
                            if (state.status == BlurFocusStatus.processing ||
                                state.segmentationInProgress)
                              const Positioned(
                                top: 16,
                                right: 16,
                                child: _BusyChip(),
                              ),
                            Positioned(
                              left: 22,
                              right: 22,
                              bottom: 22,
                              child: _IntensitySlider(
                                settings: state.operation.settings,
                                manualBlendMode: state.manualBlendMode,
                                onSettingChange: controller.updateSettings,
                                onBlendModeToggle: () {
                                  controller.setManualBlendMode(
                                    state.manualBlendMode ==
                                            ManualMaskBlendMode.exclude
                                        ? ManualMaskBlendMode.include
                                        : ManualMaskBlendMode.exclude,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _BottomModes(
                  activeMode: state.activeMode,
                  onChanged: controller.setMode,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isBusy,
    required this.onClose,
    required this.onApply,
  });

  final bool isBusy;
  final VoidCallback onClose;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          _IconFrame(
            onTap: onClose,
            icon: Icons.close_rounded,
          ),
          const Spacer(),
          _IconFrame(
            onTap: isBusy ? null : onApply,
            icon: Icons.file_download_outlined,
          ),
        ],
      ),
    );
  }
}

class _BusyChip extends StatelessWidget {
  const _BusyChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF12B886),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Processing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntensitySlider extends StatelessWidget {
  const _IntensitySlider({
    required this.settings,
    required this.manualBlendMode,
    required this.onSettingChange,
    required this.onBlendModeToggle,
  });

  final BlurSettings settings;
  final ManualMaskBlendMode manualBlendMode;
  final ValueChanged<BlurSettings> onSettingChange;
  final VoidCallback onBlendModeToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: const Color(0xFF12B886),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.88),
              thumbColor: Colors.white,
              overlayColor: const Color(0x3312B886),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: settings.blurAmount.clamp(2.0, 30.0),
              min: 2.0,
              max: 30.0,
              onChanged: (value) {
                onSettingChange(settings.copyWith(blurAmount: value));
              },
            ),
          ),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: onBlendModeToggle,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_fix_off_outlined,
              size: 23,
              color: manualBlendMode == ManualMaskBlendMode.exclude
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF12B886),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomModes extends StatelessWidget {
  const _BottomModes({
    required this.activeMode,
    required this.onChanged,
  });

  final BlurMode activeMode;
  final ValueChanged<BlurMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: BlurMode.values.map((mode) {
          return _ModeButton(
            mode: mode,
            selected: mode == activeMode,
            onTap: () => onChanged(mode),
          );
        }).toList(),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final BlurMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFF12B886)
        : Colors.white.withValues(alpha: 0.62);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              switch (mode) {
                BlurMode.smart => Icons.center_focus_strong_rounded,
                BlurMode.circle => Icons.radio_button_unchecked_rounded,
                BlurMode.line => Icons.reorder_rounded,
              },
              size: 42,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              switch (mode) {
                BlurMode.smart => 'Smart',
                BlurMode.circle => 'Circle',
                BlurMode.line => 'Line',
              },
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconFrame extends StatelessWidget {
  const _IconFrame({
    required this.onTap,
    required this.icon,
  });

  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      splashRadius: 24,
      iconSize: 40,
      color: Colors.white,
      icon: Icon(icon),
    );
  }
}
