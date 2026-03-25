import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/core/ui/cover_mapping.dart';

import '../../application/drawing/drawing_cubit.dart';
import '../../application/drawing/drawing_state.dart';
import '../../application/drawing/stroke.dart';

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final BoxFit fit;

  const ImagePainter(this.image, {this.fit = BoxFit.contain});

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: image,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant ImagePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.fit != fit;
}

class EditorCanvas extends StatefulWidget {
  final ui.Image uiImage;
  final Uint8List imageBytesToSend;
  final Future<void> Function(Uint8List image, Uint8List mask) onSend;
  final bool isSending;

  const EditorCanvas({
    super.key,
    required this.uiImage,
    required this.imageBytesToSend,
    required this.onSend,
    this.isSending = false,
  });

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  final _key = GlobalKey();

  RenderBox get _box => _key.currentContext!.findRenderObject() as RenderBox;

  double _containScale(Size size, int imageW, int imageH) {
    final sx = size.width / imageW;
    final sy = size.height / imageH;
    return sx < sy ? sx : sy;
  }

  double _widgetBrushToImagePx(
      double brushWidgetPx, Size size, int imageW, int imageH) {
    final scale = _containScale(size, imageW, imageH);
    return (brushWidgetPx / scale).clamp(1.0, 600.0);
  }

  void _onPanStart(BuildContext context, Offset globalPoint) {
    final local = _box.globalToLocal(globalPoint);
    final size = _box.size;
    final image = widget.uiImage;

    final p01 = widgetPointToImage01(
      widgetPoint: local,
      widgetSize: size,
      imageW: image.width,
      imageH: image.height,
      fit: BoxFit.contain,
    );
    if (p01 == null) {
      return;
    }

    final state = context.read<DrawingCubit>().state;
    context.read<DrawingCubit>().startStrokeImagePx(
          Offset(p01.dx * image.width, p01.dy * image.height),
          widthPx: _widgetBrushToImagePx(
            state.brushSize,
            size,
            image.width,
            image.height,
          ),
        );
  }

  void _onPanUpdate(BuildContext context, Offset globalPoint) {
    final local = _box.globalToLocal(globalPoint);
    final size = _box.size;
    final image = widget.uiImage;

    final p01 = widgetPointToImage01(
      widgetPoint: local,
      widgetSize: size,
      imageW: image.width,
      imageH: image.height,
      fit: BoxFit.contain,
    );
    if (p01 == null) {
      return;
    }

    context.read<DrawingCubit>().addPointImagePx(
          Offset(p01.dx * image.width, p01.dy * image.height),
        );
  }

  @override
  Widget build(BuildContext context) {
    final imageW = widget.uiImage.width;
    final imageH = widget.uiImage.height;

    return BlocBuilder<DrawingCubit, DrawingState>(
      builder: (context, state) {
        return GestureDetector(
          onPanStart: (details) => _onPanStart(context, details.globalPosition),
          onPanUpdate: (details) =>
              _onPanUpdate(context, details.globalPosition),
          onPanEnd: (_) => context.read<DrawingCubit>().endStroke(),
          child: RepaintBoundary(
            key: _key,
            child: CustomPaint(
              painter: ImagePainter(widget.uiImage),
              foregroundPainter: _PreviewPainter(
                strokes: state.strokes,
                imageW: imageW,
                imageH: imageH,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final List<Stroke> strokes;
  final int imageW;
  final int imageH;

  const _PreviewPainter({
    required this.strokes,
    required this.imageW,
    required this.imageH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) {
      return;
    }

    canvas.saveLayer(Offset.zero & size, Paint());

    final imageRect = applyBoxFitContainRect(
      inputImageSize: Size(imageW.toDouble(), imageH.toDouble()),
      outputSize: size,
    );
    final scale = imageRect.width / imageW;

    Offset map(Offset imagePx) {
      final x01 = (imagePx.dx / imageW).clamp(0.0, 1.0);
      final y01 = (imagePx.dy / imageH).clamp(0.0, 1.0);
      return image01ToWidgetPoint(
        p01: Offset(x01, y01),
        widgetSize: size,
        imageW: imageW,
        imageH: imageH,
        fit: BoxFit.contain,
      );
    }

    for (final stroke in strokes) {
      if (stroke.pts.isEmpty) {
        continue;
      }

      final strokeWidth = (stroke.width * scale).clamp(1.0, 180.0);
      final isEraser = stroke.mode == StrokeMode.eraser;
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;

      if (isEraser) {
        paint
          ..blendMode = BlendMode.clear
          ..color = const Color(0x00000000);
      } else {
        paint
          ..blendMode = BlendMode.srcOver
          ..color = const Color.fromARGB(170, 0, 229, 200);
      }

      final first = map(stroke.pts.first);
      if (stroke.pts.length == 1) {
        canvas.drawCircle(
            first, strokeWidth / 2, paint..style = PaintingStyle.fill);
        continue;
      }

      final path = Path()..moveTo(first.dx, first.dy);
      for (int i = 1; i < stroke.pts.length; i++) {
        final point = map(stroke.pts[i]);
        if (i < stroke.pts.length - 1) {
          final next = map(stroke.pts[i + 1]);
          final midpoint =
              Offset((point.dx + next.dx) / 2, (point.dy + next.dy) / 2);
          path.quadraticBezierTo(point.dx, point.dy, midpoint.dx, midpoint.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.imageW != imageW ||
      oldDelegate.imageH != imageH;
}
