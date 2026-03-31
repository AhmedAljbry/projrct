import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/vv/blemish_cubit.dart';
import 'package:untitled2/vv/blemish_edit_canvas.dart';
import 'package:untitled2/vv/blemish_state.dart';
import 'package:untitled2/vv/blemish_ui_widgets.dart';
import 'package:untitled2/vv/brush_interaction_service.dart';
import 'package:untitled2/vv/engine_isolate_worker.dart';
import 'package:untitled2/vv/export_service.dart';
import 'package:untitled2/vv/history_service.dart';
import 'package:untitled2/vv/mask_generation_service.dart';

class BlemishRemoverScreen extends StatelessWidget {
  final ui.Image sourceImage;
  final void Function(Uint8List pngBytes)? onApply;
  final VoidCallback? onCancel;

  const BlemishRemoverScreen({
    super.key,
    required this.sourceImage,
    this.onApply,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final worker = EngineIsolateWorker();
        final cubit = BlemishCubit(
          worker: worker,
          maskService: MaskGenerationService(),
          brushInteraction: BrushInteractionService(),
          history: HistoryService(),
          exportService: ExportService(worker),
        );
        cubit.loadImage(sourceImage);
        return cubit;
      },
      child: const _BlemishRemoverView(),
    );
  }
}

class _BlemishRemoverView extends StatelessWidget {
  const _BlemishRemoverView();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0D0D0D),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: Column(
            children: const [
              _TopBar(),
              Expanded(child: _CanvasArea()),
              _BottomPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlemishCubit, BlemishState>(
      builder: (context, state) {
        final cubit = context.read<BlemishCubit>();
        return Container(
          height: 92,
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          color: const Color(0xFF111111),
          child: Row(
            children: [
              _TopIconButton(
                icon: Icons.close_rounded,
                onTap: () {
                  final screen = context.findAncestorWidgetOfExactType<BlemishRemoverScreen>();
                  screen?.onCancel != null
                      ? screen!.onCancel!()
                      : Navigator.of(context).maybePop();
                },
              ),
              const Spacer(),
              _TopIconButton(
                icon: Icons.undo_rounded,
                enabled: cubit.canUndo,
                onTap: cubit.canUndo ? cubit.undo : null,
              ),
              const SizedBox(width: 10),
              _TopIconButton(
                icon: Icons.redo_rounded,
                enabled: cubit.canRedo,
                onTap: cubit.canRedo ? cubit.redo : null,
              ),
              const SizedBox(width: 10),
              _TopIconButton(
                icon: state.compareMode == CompareMode.original
                    ? Icons.photo_library_outlined
                    : Icons.photo_album_outlined,
                highlighted: state.compareMode == CompareMode.original,
                onTap: cubit.toggleCompare,
              ),
              const SizedBox(width: 10),
              _TopIconButton(
                icon: Icons.download_rounded,
                enabled: state.hasOperations && !state.isProcessing,
                onTap: state.hasOperations && !state.isProcessing
                    ? () => _onApply(context)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onApply(BuildContext context) async {
    final bytes = await context.read<BlemishCubit>().exportImage();
    if (bytes != null && context.mounted) {
      final screen = context.findAncestorWidgetOfExactType<BlemishRemoverScreen>();
      screen?.onApply?.call(bytes);
    }
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool highlighted;

  const _TopIconButton({
    required this.icon,
    this.onTap,
    this.enabled = true,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? Colors.white.withValues(alpha: 0.25)
        : highlighted
            ? const Color(0xFF16B07E)
            : Colors.white;

    return InkResponse(
      radius: 28,
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(icon, color: color, size: 31),
      ),
    );
  }
}

class _CanvasArea extends StatelessWidget {
  const _CanvasArea();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlemishCubit, BlemishState>(
      builder: (context, state) {
        return Container(
          color: const Color(0xFF0D0D0D),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: ClipRect(child: BlemishEditCanvas()),
              ),
              ProcessingOverlay(
                status: state.processingStatus,
                exportProgress: state.exportProgress,
              ),
              if (state.errorMessage != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: BlemishErrorBar(
                    message: state.errorMessage,
                    onDismiss: () => context.read<BlemishCubit>().clearError(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlemishCubit, BlemishState>(
      buildWhen: (previous, current) =>
          previous.brushSettings != current.brushSettings ||
          previous.processingStatus != current.processingStatus,
      builder: (context, state) {
        final cubit = context.read<BlemishCubit>();
        return Container(
          color: const Color(0xFF0D0D0D),
          padding: const EdgeInsets.fromLTRB(26, 18, 26, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReferenceSlider(
                value: state.brushSettings.radius,
                onChanged: state.isProcessing ? null : cubit.setBrushRadius,
              ),
              const SizedBox(height: 18),
              Text(
                'Erase lens size',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReferenceSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;

  const _ReferenceSlider({
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: const Color(0xFF16B07E),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.92),
        trackShape: const RoundedRectSliderTrackShape(),
        thumbColor: Colors.white,
        thumbShape: _LensSliderThumbShape(radius: value),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(
        min: 10.0,
        max: 44.0,
        value: value.clamp(10.0, 44.0),
        onChanged: onChanged,
      ),
    );
  }
}

class _LensSliderThumbShape extends SliderComponentShape {
  final double radius;

  const _LensSliderThumbShape({required this.radius});

  double get _visualRadius {
    final normalized = ((radius - 10.0) / 34.0).clamp(0.0, 1.0);
    return 14.0 + (normalized * 4.0);
  }

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    final r = _visualRadius;
    return Size.square(r * 2.2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final r = _visualRadius;

    canvas.drawCircle(
      center,
      r + 3,
      Paint()..color = const Color(0xFF16B07E).withValues(alpha: 0.16),
    );

    canvas.drawCircle(center, r, Paint()..color = Colors.white);

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFF16B07E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
  }
}

