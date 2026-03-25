import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled2/features/smart_retouch/infrastructure/engine/retouch_image_service.dart';

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
  bool _isSaving = false;
  bool _isSettingsVisible = false;
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
      _processingHintTimer = Timer(const Duration(milliseconds: 180), () {
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

  Future<void> _saveImage(RetouchState state) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);

    Uint8List? finalBytes;
    if (state.operations.isNotEmpty && state.originalImageBytes != null) {
      finalBytes = await RetouchImageService.renderOperations(
        originalImageBytes: state.originalImageBytes!,
        operations: state.operations,
      );
    } else {
      final data =
          await state.currentImage!.toByteData(format: ui.ImageByteFormat.png);
      finalBytes = data?.buffer.asUint8List();
    }

    if (finalBytes != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/retouch_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(finalBytes);
        await Gal.putImage(file.path);

        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Saved to Gallery Successfully!')),
        );
        widget.onApply?.call(finalBytes);
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to save to gallery: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
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
                    onPressed: (state.currentImage != null && !_isSaving)
                        ? () => _saveImage(state)
                        : null,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF56E39F),
                            ),
                          )
                        : const Text(
                            'Save',
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

            if (state.currentImage == null) {
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
                  ),
                ),
                if (_isSettingsVisible)
                  const Positioned(
                    left: 16,
                    bottom: 100,
                    width: 240,
                    child: BrushParameterControl(),
                  ),
                Positioned(
                  bottom: 104,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: BrushSizeBar(),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: RetouchToolbar(
                      isSettingsVisible: _isSettingsVisible,
                      onToggleSettings: _toggleSettings,
                    ),
                  ),
                ),
                if (_showProcessingHint && !_isSaving)
                  Positioned(
                    bottom: 178,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF161616).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF56E39F),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Applying...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_isSaving)
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
