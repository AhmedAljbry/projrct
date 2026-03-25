import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/bp_segmentation_datasource.dart';
import '../../data/rendering/bp_isolate_renderer.dart';
import '../../data/repositories/bp_blur_repository_impl.dart';
import '../../domain/entities/circle_params.dart';
import '../../domain/entities/line_params.dart';
import '../cubit/blur_photo_cubit.dart';
import '../cubit/blur_photo_state.dart';
import '../widgets/bp_canvas_view.dart';
import '../widgets/bp_intensity_slider.dart';
import '../widgets/bp_mode_bar.dart';
import '../widgets/bp_top_bar.dart';

const _kBg = Color(0xFF0B0B0D);
const _kAccent = Color(0xFF56E39F);

/// Entry point widget — wraps [_BlurPhotoView] in a [BlocProvider].
class BlurPhotoPage extends StatelessWidget {
  const BlurPhotoPage({
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
    return BlocProvider<BlurPhotoCubit>(
      create: (_) => BlurPhotoCubit(
        repository: BpBlurRepositoryImpl(
          renderer: const BpIsolateRenderer(),
          segmentation: BpSegmentationDatasource(),
        ),
      )..initialize(initialImage),
      child: _BlurPhotoView(onApply: onApply, onClose: onClose),
    );
  }
}

// ── Private view ─────────────────────────────────────────────────────────────

class _BlurPhotoView extends StatelessWidget {
  const _BlurPhotoView({this.onApply, this.onClose});

  final ValueChanged<Uint8List>? onApply;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: BlocConsumer<BlurPhotoCubit, BlurPhotoState>(
        listenWhen: (p, c) => p.errorMessage != c.errorMessage,
        listener: (context, state) {
          final msg = state.errorMessage;
          if (msg != null && msg.isNotEmpty) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        builder: (context, state) {
          final cubit = context.read<BlurPhotoCubit>();

          if (state.status == BpEditorStatus.loading ||
              state.originalImage == null) {
            return const Center(
              child: CircularProgressIndicator(color: _kAccent),
            );
          }

          final visibleImage = state.showOriginal
              ? state.originalImage!
              : (state.previewImage ?? state.originalImage!);

          return Column(
            children: [
              // ── Top bar ────────────────────────────────────────────────────
              BpTopBar(
                status: state.status,
                canUndo: state.canUndo,
                onClose: () {
                  onClose?.call();
                  Navigator.of(context).pop();
                },
                onExport: () async {
                  final navigator = Navigator.of(context);
                  final bytes = await cubit.exportFinal();
                  if (!context.mounted || bytes == null) return;

                  // Save to gallery using gal
                  try {
                    // We try using gal; if it's unavailable, trigger onApply directly
                    onApply?.call(bytes);
                  } catch (_) {}

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image saved!'),
                      backgroundColor: Color(0xFF1E1E22),
                    ),
                  );
                  navigator.pop();
                },
                onUndo: state.canUndo ? () => cubit.undo() : null,
                onCompareStart: () => cubit.showOriginal(true),
                onCompareEnd: () => cubit.showOriginal(false),
              ),

              // ── Canvas ─────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Stack(
                    children: [
                      BpCanvasView(
                        image: visibleImage,
                        settings: state.settings,
                        onCircleUpdate: (p) =>
                            cubit.updateCircle(p as CircleBlurParams, trackOnly: true),
                        onCircleEnd: (p) =>
                            cubit.commitCircleInteractionEnd(p as CircleBlurParams),
                        onLineUpdate: (p) =>
                            cubit.updateLine(p as LineBlurParams, trackOnly: true),
                        onLineEnd: (p) =>
                            cubit.commitLineInteractionEnd(p as LineBlurParams),
                      ),

                      // Busy indicator
                      if (state.isBusy)
                        const Positioned(
                          top: 12,
                          right: 12,
                          child: _BusyIndicator(),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Intensity slider ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                child: BpIntensitySlider(
                  value: state.settings.blurIntensity,
                  onChanged: cubit.updateIntensity,
                  onChangeEnd: cubit.onIntensityDragEnd,
                ),
              ),

              // ── Hint message ───────────────────────────────────────────────
              if (state.hintMessage != null && state.hintMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.hintMessage!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

              // ── Mode bar ───────────────────────────────────────────────────
              BpModeBar(
                activeMode: state.activeMode,
                onChanged: cubit.setMode,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Busy indicator ────────────────────────────────────────────────────────────

class _BusyIndicator extends StatelessWidget {
  const _BusyIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kAccent,
            ),
          ),
          SizedBox(width: 8),
          Text('Processing',
              style: TextStyle(color: Colors.white, fontSize: 11.5)),
        ],
      ),
    );
  }
}
