import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/vv/blemish_cubit.dart';
import 'package:untitled2/vv/blemish_edit_canvas.dart';
import 'package:untitled2/vv/blemish_state.dart';
import 'package:untitled2/vv/blemish_ui_widgets.dart';
import 'package:untitled2/vv/brush_control_panel.dart';
import 'package:untitled2/vv/brush_interaction_service.dart';
import 'package:untitled2/vv/brush_preview_indicator.dart';
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
          worker:           worker,
          maskService:      MaskGenerationService(),
          brushInteraction: BrushInteractionService(),
          history:          HistoryService(),
          exportService:    ExportService(worker),
        );
        cubit.loadImage(sourceImage);
        return cubit;
      },
      child: const _BlemishRemoverView(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════

class _BlemishRemoverView extends StatelessWidget {
  const _BlemishRemoverView();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0C0C),
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ───────────────────────────────────────
              _TopBar(),

              // ── Canvas (Expanded) ─────────────────────────────
              const Expanded(child: _CanvasArea()),

              // ── Brush preview ثابتة ───────────────────────────
              _BrushPreviewRow(),

              // ── Controls ─────────────────────────────────────
              _BottomControls(),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TOP BAR
// ══════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlemishCubit, BlemishState>(
      builder: (context, state) {
        final cubit = context.read<BlemishCubit>();
        return Container(
          height: 52,
          color: const Color(0xFF111111),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  final screen =
                  context.findAncestorWidgetOfExactType<BlemishRemoverScreen>();
                  screen?.onCancel != null
                      ? screen!.onCancel!()
                      : Navigator.of(context).maybePop();
                },
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white70, fontSize: 15)),
              ),
              const Spacer(),
              const Text('Blemish Remover',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: state.hasOperations && !state.isProcessing
                    ? () => _onApply(context)
                    : null,
                child: Text(
                  'Apply',
                  style: TextStyle(
                    color: state.hasOperations && !state.isProcessing
                        ? const Color(0xFF56E39F)
                        : Colors.white24,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onApply(BuildContext context) async {
    final cubit  = context.read<BlemishCubit>();
    final bytes  = await cubit.exportImage();
    if (bytes != null && context.mounted) {
      final screen =
      context.findAncestorWidgetOfExactType<BlemishRemoverScreen>();
      screen?.onApply?.call(bytes);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CANVAS AREA
// ══════════════════════════════════════════════════════════════════════════════

class _CanvasArea extends StatelessWidget {
  const _CanvasArea();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlemishCubit, BlemishState>(
      builder: (context, state) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const BlemishEditCanvas(),

            // Compare button
            Positioned(
              top: 10,
              right: 12,
              child: _CompareBtn(
                mode: state.compareMode,
                onToggle: context.read<BlemishCubit>().toggleCompare,
              ),
            ),

            // Processing overlay
            ProcessingOverlay(
              status:         state.processingStatus,
              exportProgress: state.exportProgress,
            ),

            // Error bar
            if (state.errorMessage != null)
              Positioned(
                bottom: 6,
                left: 8,
                right: 8,
                child: BlemishErrorBar(
                  message:   state.errorMessage,
                  onDismiss: () => context
                      .read<BlemishCubit>()
                      .emit(state.copyWith(clearError: true)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CompareBtn extends StatelessWidget {
  final CompareMode mode;
  final VoidCallback onToggle;
  const _CompareBtn({required this.mode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final active = mode == CompareMode.original;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF56E39F).withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF56E39F) : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? Icons.visibility : Icons.compare,
                color: active ? const Color(0xFF56E39F) : Colors.white60,
                size: 15),
            const SizedBox(width: 5),
            Text(
              active ? 'Original' : 'Compare',
              style: TextStyle(
                color: active ? const Color(0xFF56E39F) : Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BRUSH PREVIEW ROW (ثابتة أسفل الكانفاس)
// ══════════════════════════════════════════════════════════════════════════════

class _BrushPreviewRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlemishCubit, BlemishState>(
      buildWhen: (p, c) => p.brushSettings != c.brushSettings,
      builder: (context, state) {
        return BrushPreviewIndicator(settings: state.brushSettings);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BOTTOM CONTROLS
// ══════════════════════════════════════════════════════════════════════════════

class _BottomControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlemishCubit, BlemishState>(
      builder: (context, state) {
        final cubit = context.read<BlemishCubit>();
        return BrushControlPanel(
          settings:          state.brushSettings,
          onRadiusChanged:   cubit.setBrushRadius,
          onSoftnessChanged: cubit.setBrushSoftness,
          onStrengthChanged: cubit.setBrushStrength,
          onUndo:            cubit.canUndo ? cubit.undo : null,
          onRedo:            cubit.canRedo ? cubit.redo : null,
          onReset:           () => _confirmReset(context, cubit),
          canUndo:           cubit.canUndo,
          canRedo:           cubit.canRedo,
        );
      },
    );
  }

  void _confirmReset(BuildContext context, BlemishCubit cubit) {
    if (!cubit.state.hasOperations) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Reset all edits?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('All blemish removals will be discarded.',
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
            const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    ).then((v) {
      if (v == true && context.mounted) context.read<BlemishCubit>().reset();
    });
  }
}
