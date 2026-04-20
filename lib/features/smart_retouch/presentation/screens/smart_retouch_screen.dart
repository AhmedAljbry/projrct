import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/features/smart_retouch/infrastructure/engine/retouch_image_service.dart';
import 'package:untitled2/shared/widgets/result_preview_screen.dart';

import '../../application/bloc/retouch_bloc.dart';
import '../../application/bloc/retouch_event.dart';
import '../../application/bloc/retouch_state.dart';
import '../widgets/brush_parameter_control.dart';
import '../widgets/retouch_canvas_editor.dart';
import '../widgets/retouch_toolbar.dart';

class SmartRetouchScreen extends StatelessWidget {
  final ui.Image initialImage;
  final ValueChanged<Uint8List>? onApply;
  final VoidCallback? onCancel;

  const SmartRetouchScreen({
    super.key,
    required this.initialImage,
    this.onApply,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RetouchBloc()..add(LoadImageEvent(initialImage)),
      child: _SmartRetouchView(onApply: onApply, onCancel: onCancel),
    );
  }
}

class _SmartRetouchView extends StatefulWidget {
  final ValueChanged<Uint8List>? onApply;
  final VoidCallback? onCancel;

  const _SmartRetouchView({this.onApply, this.onCancel});

  @override
  State<_SmartRetouchView> createState() => _SmartRetouchViewState();
}

class _SmartRetouchViewState extends State<_SmartRetouchView> {
  bool _isExporting = false;
  bool _isSettingsVisible = false;
  bool _isBrushesVisible = false;
  bool _showProcessingHint = false;
  Timer? _processingHintTimer;

  @override
  void dispose() {
    _processingHintTimer?.cancel();
    super.dispose();
  }

  void _handleProcessingState(RetouchStatus status) {
    if (status == RetouchStatus.processing) {
      _processingHintTimer?.cancel();
      _processingHintTimer = Timer(const Duration(milliseconds: 260), () {
        if (!mounted) return;
        setState(() => _showProcessingHint = true);
      });
      return;
    }

    _processingHintTimer?.cancel();
    if (_showProcessingHint) {
      setState(() => _showProcessingHint = false);
    }
  }

  void _toggleSettings() {
    setState(() {
      _isSettingsVisible = !_isSettingsVisible;
    });
  }

  void _toggleBrushes() {
    setState(() {
      _isBrushesVisible = !_isBrushesVisible;
    });
  }

  Future<void> _openResultPreview(RetouchState state) async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    Uint8List? finalBytes = state.currentImageBytes;
    if (finalBytes == null &&
        state.operations.isNotEmpty &&
        state.originalImageBytes != null) {
      finalBytes = await RetouchImageService.renderOperations(
        originalImageBytes: state.originalImageBytes!,
        operations: state.operations,
      );
    } else if (finalBytes == null) {
      final data =
          await state.currentImage!.toByteData(format: ui.ImageByteFormat.png);
      finalBytes = data?.buffer.asUint8List();
    }

    if (!mounted) return;
    setState(() => _isExporting = false);

    if (finalBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to prepare result preview')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultPreviewScreen(
          title: 'Smart Retouch Result',
          resultBytes: finalBytes!,
          originalBytes: state.originalImageBytes,
          onDone: widget.onApply == null
              ? null
              : () => widget.onApply!.call(finalBytes!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            widget.onCancel?.call();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Smart Retouch',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<RetouchBloc, RetouchState>(
            builder: (context, state) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo),
                    color: state.canUndo ? Colors.white : Colors.white30,
                    onPressed: state.canUndo
                        ? () => context.read<RetouchBloc>().add(UndoEvent())
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo),
                    color: state.canRedo ? Colors.white : Colors.white30,
                    onPressed: state.canRedo
                        ? () => context.read<RetouchBloc>().add(RedoEvent())
                        : null,
                  ),
                  TextButton(
                    onPressed: (state.currentImage != null && !_isExporting)
                        ? () => _openResultPreview(state)
                        : null,
                    child: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF56E39F),
                            ),
                          )
                        : const Text(
                            'Result',
                            style: TextStyle(
                              color: Color(0xFF56E39F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocListener<RetouchBloc, RetouchState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) => _handleProcessingState(state.status),
        child: BlocBuilder<RetouchBloc, RetouchState>(
          builder: (context, state) {
            if (state.status == RetouchStatus.initial ||
                state.status == RetouchStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF56E39F)),
              );
            }

            if (state.currentImage == null || state.originalImage == null) {
              return const Center(
                child: Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: RetouchCanvasEditor(
                    displayImage: state.currentImage!,
                    originalImage: state.originalImage!,
                  ),
                ),
                if (_isSettingsVisible)
                  const Positioned(
                    left: 16,
                    bottom: 100,
                    width: 240,
                    child: BrushParameterControl(),
                  ),
                if (_isBrushesVisible)
                  Positioned(
                    bottom: 154,
                    left: 0,
                    right: 0,
                    child: const Center(child: BrushPresetBar()),
                  ),
                Positioned(
                  bottom: 104,
                  left: 0,
                  right: 0,
                  child: const Center(child: BrushSizeBar()),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: RetouchToolbar(
                      isSettingsVisible: _isSettingsVisible,
                      isBrushesVisible: _isBrushesVisible,
                      onToggleSettings: _toggleSettings,
                      onToggleBrushes: _toggleBrushes,
                    ),
                  ),
                ),
                if (_showProcessingHint && !_isExporting)
                  IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: _showProcessingHint ? 1 : 0,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.42),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111)
                                  .withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFF56E39F)
                                    .withValues(alpha: 0.18),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Color(0xFF56E39F),
                                  ),
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'جار تجهيز المعاينة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_isExporting)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF56E39F)),
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
