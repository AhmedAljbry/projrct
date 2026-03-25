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

  bool _isPinching = false;
  double? _scaleStart;
  Offset? _focalStart;
  Offset? _translationStart;

  Offset? _tapDownPos;
  DateTime? _tapDownTime;
  bool _movedTooMuch = false;
  static const double _kDragThreshold = 10.0;
  static const int _kTapMaxMs = 400;

  ui.Image? _sourceUiImage;
  ui.Image? _previewUiImage;
  Uint8List? _lastPreviewPixels;
  bool _transformReady = false;

  @override
  void dispose() {
    _cursorHideTimer?.cancel();
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
                            child: CustomPaint(
                              painter: _CursorOnlyPainter(
                                pos: _cursorPos!,
                                screenRadius: state.brushSettings.radius *
                                    state.canvasScale,
                                softness: state.brushSettings.softness,
                              ),
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
    _tapDownPos = details.localFocalPoint;
    _tapDownTime = DateTime.now();
    _movedTooMuch = false;
    _showCursor(details.localFocalPoint);
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

    if (_tapDownPos != null &&
        (details.localFocalPoint - _tapDownPos!).distance > _kDragThreshold) {
      _movedTooMuch = true;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_isPinching) {
      _isPinching = false;
      _scaleStart = null;
      _focalStart = null;
      _translationStart = null;
      return;
    }

    final elapsedMs = _tapDownTime != null
        ? DateTime.now().difference(_tapDownTime!).inMilliseconds
        : 9999;

    if (!_movedTooMuch && elapsedMs < _kTapMaxMs && _tapDownPos != null) {
      _doTapHeal(_tapDownPos!);
    }

    _tapDownPos = null;
    _tapDownTime = null;
  }

  void _doTapHeal(Offset screenPos) {
    _showCursor(screenPos);

    final cubit = context.read<BlemishCubit>();
    cubit.onStrokeBegin(screenPos);
    cubit.onStrokeEnd();

    _cursorHideTimer?.cancel();
    _cursorHideTimer = Timer(const Duration(milliseconds: 800), _hideCursor);
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

  const _CursorOnlyPainter({
    required this.pos,
    required this.screenRadius,
    required this.softness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      pos,
      screenRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: pos, radius: screenRadius),
        ),
    );

    canvas.drawCircle(
      pos,
      screenRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    if (softness > 0.05) {
      canvas.drawCircle(
        pos,
        screenRadius * (1.0 - softness),
        Paint()
          ..color = const Color(0xFF56E39F).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    canvas.drawCircle(pos, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CursorOnlyPainter oldDelegate) {
    return oldDelegate.pos != pos ||
        oldDelegate.screenRadius != screenRadius ||
        oldDelegate.softness != softness;
  }
}
