import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/vv/blemish_cubit.dart';
import 'package:untitled2/vv/blemish_state.dart';

import 'blemish_canvas_painter.dart';

class BlemishEditCanvas extends StatefulWidget {
  const BlemishEditCanvas({super.key});

  @override
  State<BlemishEditCanvas> createState() => _BlemishEditCanvasState();
}

class _BlemishEditCanvasState extends State<BlemishEditCanvas>
    with SingleTickerProviderStateMixin {
  Offset? _cursorPos;
  bool _cursorVisible = false;
  Timer? _cursorHideTimer;
  late final AnimationController _cursorPulseController;

  bool _isPinching = false;
  double? _scaleStart;
  Offset? _focalStart;
  Offset? _translationStart;

  ui.Image? _sourceUiImage;
  ui.Image? _previewUiImage;
  Uint8List? _lastPreviewPixels;
  bool _transformReady = false;

  @override
  void initState() {
    super.initState();
    _cursorPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorHideTimer?.cancel();
    _cursorPulseController.dispose();
    _previewUiImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BlemishCubit, BlemishState>(
      listenWhen: (previous, current) =>
          previous.previewPixels != current.previewPixels ||
          previous.sourceImage != current.sourceImage,
      listener: (context, state) => _onStateChanged(state),
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            if (!_transformReady && state.sourceImage != null && width > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitImage(state, width, height);
              });
            }

            return MouseRegion(
              opaque: true,
              onHover: (event) => _showCursor(event.localPosition),
              onExit: (_) => _hideCursor(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: BlemishCanvasPainter(
                          sourceImage: _sourceUiImage,
                          previewImage: _previewUiImage,
                          activeStrokePoints: state.activeStrokePoints,
                          brushSettings: state.brushSettings,
                          canvasScale: state.canvasScale,
                          canvasTranslation: state.canvasTranslation,
                          compareMode: state.compareMode,
                        ),
                      ),
                      if (_cursorVisible && _cursorPos != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _cursorPulseController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _CursorOnlyPainter(
                                    pos: _cursorPos!,
                                    screenRadius: state.brushSettings.radius *
                                        state.canvasScale,
                                    softness: state.brushSettings.softness,
                                    pulse: _cursorPulseController.value,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount >= 2) {
      _isPinching = true;
      _hideCursor();
      context.read<BlemishCubit>().cancelActiveStroke();

      final state = context.read<BlemishCubit>().state;
      _scaleStart = state.canvasScale;
      _focalStart = details.localFocalPoint;
      _translationStart = state.canvasTranslation;
      return;
    }

    _isPinching = false;
    _showCursor(details.localFocalPoint);
    context.read<BlemishCubit>().onStrokeBegin(details.localFocalPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_isPinching || details.pointerCount >= 2) {
      _isPinching = true;
      if (_scaleStart == null) return;

      final newScale = (_scaleStart! * details.scale).clamp(0.15, 12.0);
      final focalInImage = (_focalStart! - _translationStart!) / _scaleStart!;
      final newTranslation = _focalStart! - focalInImage * newScale;

      context.read<BlemishCubit>().updateCanvasTransform(
            scale: newScale,
            translation: newTranslation,
          );
      return;
    }

    _showCursor(details.localFocalPoint);
    context.read<BlemishCubit>().onStrokeUpdate(details.localFocalPoint);
  }

  Future<void> _onScaleEnd(ScaleEndDetails details) async {
    if (_isPinching) {
      _isPinching = false;
      _scaleStart = null;
      _focalStart = null;
      _translationStart = null;
      _singleTouchStart = null;
      _singleTouchCurrent = null;
      _singleTouchMoved = false;
      return;
    }

    final tapPoint = _singleTouchCurrent ?? _singleTouchStart;
    final shouldHeal = !_singleTouchMoved && tapPoint != null;
    _singleTouchStart = null;
    _singleTouchCurrent = null;
    _singleTouchMoved = false;

    if (shouldHeal) {
      await context.read<BlemishCubit>().onSpotHeal(tapPoint);
    }

    _cursorHideTimer?.cancel();
    _cursorHideTimer = Timer(const Duration(milliseconds: 900), _hideCursor);
  }

  void _showCursor(Offset position) {
    if (!mounted) return;

    _cursorHideTimer?.cancel();
    setState(() {
      _cursorPos = position;
      _cursorVisible = true;
    });
  }

  void _hideCursor() {
    if (!mounted) return;
    setState(() => _cursorVisible = false);
  }

  void _fitImage(BlemishState state, double canvasWidth, double canvasHeight) {
    if (_transformReady) return;

    final imageWidth = state.imageWidth.toDouble();
    final imageHeight = state.imageHeight.toDouble();
    if (imageWidth <= 0 || imageHeight <= 0) return;

    final scale = (canvasWidth / imageWidth) < (canvasHeight / imageHeight)
        ? canvasWidth / imageWidth
        : canvasHeight / imageHeight;
    _transformReady = true;

    context.read<BlemishCubit>().updateCanvasTransform(
          scale: scale,
          translation: Offset(
            (canvasWidth - imageWidth * scale) / 2.0,
            (canvasHeight - imageHeight * scale) / 2.0,
          ),
        );
  }

  Future<void> _onStateChanged(BlemishState state) async {
    if (state.sourceImage != null && state.sourceImage != _sourceUiImage) {
      _transformReady = false;
      if (mounted) {
        setState(() => _sourceUiImage = state.sourceImage);
      }
    }

    if (state.previewPixels == null) {
      if (_previewUiImage != null && mounted) {
        setState(() {
          _previewUiImage?.dispose();
          _previewUiImage = null;
        });
      }
      return;
    }

    if (state.previewPixels != _lastPreviewPixels) {
      _lastPreviewPixels = state.previewPixels;
      final image = await _decodePixels(
        state.previewPixels!,
        state.imageWidth,
        state.imageHeight,
      );

      if (mounted) {
        setState(() {
          _previewUiImage?.dispose();
          _previewUiImage = image;
        });
      }
    }
  }

  Future<ui.Image> _decodePixels(Uint8List pixels, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}

class _CursorOnlyPainter extends CustomPainter {
  final Offset pos;
  final double screenRadius;
  final double softness;
  final double pulse;

  const _CursorOnlyPainter({
    required this.pos,
    required this.screenRadius,
    required this.softness,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pulseScale = 0.95 + (pulse * 0.10);
    final animatedRadius = screenRadius * pulseScale;
    final outerRadius = animatedRadius * 1.12;

    canvas.drawCircle(
      pos,
      outerRadius,
      Paint()..color = const Color(0xFF16B07E).withValues(alpha: 0.16),
    );

    canvas.drawCircle(
      pos,
      animatedRadius,
      Paint()..color = const Color(0xFF16B07E).withValues(alpha: 0.66),
    );

    canvas.drawCircle(
      pos,
      animatedRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    if (softness > 0.05) {
      canvas.drawCircle(
        pos,
        animatedRadius * (1.0 - softness * 0.55),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CursorOnlyPainter oldDelegate) {
    return oldDelegate.pos != pos ||
        oldDelegate.screenRadius != screenRadius ||
        oldDelegate.softness != softness ||
        oldDelegate.pulse != pulse;
  }
}
