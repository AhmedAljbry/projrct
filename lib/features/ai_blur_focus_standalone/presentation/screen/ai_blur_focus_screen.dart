import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/af_blur_controller.dart';
import '../../application/af_blur_state.dart';
import '../../data/engines/af_mask_refinement_impl.dart';
import '../../data/engines/af_mlkit_segmentation.dart';
import '../../data/rendering/af_isolate_renderer.dart';
import '../../data/repository/af_blur_repository.dart';
import '../../domain/models/af_blur_mode.dart';
import '../../domain/models/af_blur_settings.dart';
import '../widgets/af_canvas_view.dart';

const _kBg = Color(0xFF0B0B0B);
const _kAccent = Color(0xFF56E39F);
const _kPanel = Color(0xFF101010);

class AiBlurFocusScreen extends StatelessWidget {
  const AiBlurFocusScreen({
    super.key,
    required this.initialImage,
    this.onApply,
    this.onClose,
  });

  final ui.Image initialImage;
  final ValueChanged<Uint8List>? onApply;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AfBlurController(
        repository: AfBlurRepository(
          segmentation: AfMlKitSegmentationEngine(),
          refiner: AfMaskRefinementImpl(),
          renderer: const AfIsolateRenderer(),
        ),
      )..initialize(initialImage),
      child: _AiBlurFocusView(onApply: onApply, onClose: onClose),
    );
  }
}

class _AiBlurFocusView extends StatefulWidget {
  const _AiBlurFocusView({this.onApply, this.onClose});

  final ValueChanged<Uint8List>? onApply;
  final VoidCallback? onClose;

  @override
  State<_AiBlurFocusView> createState() => _AiBlurFocusViewState();
}

class _AiBlurFocusViewState extends State<_AiBlurFocusView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final controller = context.read<AfBlurController>();
      if (controller.state.activeMode != AfBlurMode.smart) {
        controller.setMode(AfBlurMode.smart);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: BlocConsumer<AfBlurController, AfBlurState>(
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
            final controller = context.read<AfBlurController>();
            final visibleImage = state.showOriginalPreview
                ? state.originalImage
                : (state.previewImage ?? state.originalImage);
            if (visibleImage == null) {
              return const Center(
                child: CircularProgressIndicator(color: _kAccent),
              );
            }

            return Column(
              children: [
                _TopBar(
                  state: state,
                  onClose: () {
                    widget.onClose?.call();
                    Navigator.of(context).pop();
                  },
                  onApply: () async {
                    final navigator = Navigator.of(context);
                    final bytes = await controller.exportFinal();
                    if (!mounted || bytes == null) {
                      return;
                    }
                    widget.onApply?.call(bytes);
                    navigator.pop();
                  },
                  onCompareStart: () => controller.showOriginal(true),
                  onCompareEnd: () => controller.showOriginal(false),
                  onRedetect: state.segmentationInProgress
                      ? null
                      : () => controller.redetectSubject(),
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: AfCanvasView(
                                image: visibleImage,
                                settings: state.operation.settings,
                                showMaskOverlay: state.showMaskOverlay,
                                refineMaskMode: state.refineMaskMode,
                                segmentation: state.operation.maskData,
                                brushAdd: state.brushAdd,
                                onSettingsChanged: controller.updateSettings,
                                onStroke: controller.addManualStroke,
                              ),
                            ),
                            if (state.status == AfEditorStatus.processing ||
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
                              child: _StrengthSlider(
                                settings: state.operation.settings,
                                brushAdd: state.brushAdd,
                                onSettingsChanged: controller.updateSettings,
                                onBrushModeToggle: () =>
                                    controller.setBrushMode(!state.brushAdd),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _HintBar(message: state.hintMessage),
                _ModeBar(
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
    required this.state,
    required this.onClose,
    required this.onApply,
    required this.onCompareStart,
    required this.onCompareEnd,
    required this.onRedetect,
  });

  final AfBlurState state;
  final VoidCallback onClose;
  final VoidCallback onApply;
  final VoidCallback onCompareStart;
  final VoidCallback onCompareEnd;
  final VoidCallback? onRedetect;

  @override
  Widget build(BuildContext context) {
    final exporting = state.status == AfEditorStatus.exporting;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon:
                const Icon(Icons.close_rounded, color: Colors.white, size: 30),
          ),
          const Expanded(
            child: Text(
              'AI Blur',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: exporting ? null : onApply,
            icon: Icon(
              Icons.file_download_outlined,
              color: exporting ? Colors.white38 : Colors.white,
              size: 28,
            ),
          ),
          GestureDetector(
            onLongPressStart: (_) => onCompareStart(),
            onLongPressEnd: (_) => onCompareEnd(),
            child: IconButton(
              onPressed: onRedetect,
              icon: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white70, size: 26),
            ),
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
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kAccent,
            ),
          ),
          SizedBox(width: 9),
          Text(
            'Processing',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StrengthSlider extends StatelessWidget {
  const _StrengthSlider({
    required this.settings,
    required this.brushAdd,
    required this.onSettingsChanged,
    required this.onBrushModeToggle,
  });

  final AfBlurSettings settings;
  final bool brushAdd;
  final ValueChanged<AfBlurSettings> onSettingsChanged;
  final VoidCallback onBrushModeToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: _kAccent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
              thumbColor: Colors.white,
              overlayColor: _kAccent.withValues(alpha: 0.22),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
            ),
            child: Slider(
              value: settings.blurAmount.clamp(2.0, 30.0),
              min: 2.0,
              max: 30.0,
              onChanged: (value) {
                onSettingsChanged(settings.copyWith(blurAmount: value));
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onBrushModeToggle,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_fix_off_outlined,
              color: brushAdd ? _kAccent : Colors.white,
              size: 23,
            ),
          ),
        ),
      ],
    );
  }
}

class _HintBar extends StatelessWidget {
  const _HintBar({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox(height: 8);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message!,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  const _ModeBar({
    required this.activeMode,
    required this.onChanged,
  });

  final AfBlurMode activeMode;
  final ValueChanged<AfBlurMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      decoration: BoxDecoration(
        color: _kPanel,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: AfBlurMode.values.map((mode) {
          final selected = mode == activeMode;
          final color =
              selected ? _kAccent : Colors.white.withValues(alpha: 0.62);
          return InkWell(
            onTap: () => onChanged(mode),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    switch (mode) {
                      AfBlurMode.smart => Icons.auto_awesome_rounded,
                      AfBlurMode.circle => Icons.radio_button_unchecked_rounded,
                      AfBlurMode.line => Icons.reorder_rounded,
                    },
                    size: 36,
                    color: color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    switch (mode) {
                      AfBlurMode.smart => 'Smart',
                      AfBlurMode.circle => 'Circle',
                      AfBlurMode.line => 'Line',
                    },
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
