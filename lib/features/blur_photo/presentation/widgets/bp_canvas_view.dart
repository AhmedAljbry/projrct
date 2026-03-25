import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/blur_mode.dart';
import '../../domain/entities/blur_settings.dart';
import '../gestures/circle_gesture_handler.dart';
import '../gestures/line_gesture_handler.dart';

const _kAccent = Color(0xFF56E39F);

/// Image canvas displaying the preview + interactive gesture overlay.
/// Isolates expensive RepaintBoundary to minimise rebuild cascades.
class BpCanvasView extends StatelessWidget {
  const BpCanvasView({
    super.key,
    required this.image,
    required this.settings,
    required this.onCircleUpdate,
    required this.onCircleEnd,
    required this.onLineUpdate,
    required this.onLineEnd,
  });

  final ui.Image image;
  final BlurPhotoSettings settings;
  final ValueChanged<dynamic> onCircleUpdate;
  final ValueChanged<dynamic> onCircleEnd;
  final ValueChanged<dynamic> onLineUpdate;
  final ValueChanged<dynamic> onLineEnd;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(builder: (context, constraints) {
        final canvasAspect = image.width / image.height;
        return Center(
          child: AspectRatio(
            aspectRatio: canvasAspect,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Rendered blur preview
                  RawImage(image: image, fit: BoxFit.cover),

                  // Overlay — only shown when the mode needs gestures
                  if (settings.mode == BlurPhotoMode.circle)
                    CircleGestureHandler(
                      params: settings.circle,
                      canvasSize: Size(
                        constraints.maxWidth,
                        constraints.maxWidth / canvasAspect,
                      ),
                      accentColor: _kAccent,
                      onUpdate: (p) => onCircleUpdate(p),
                      onEnd: (p) => onCircleEnd(p),
                    ),

                  if (settings.mode == BlurPhotoMode.line)
                    LineGestureHandler(
                      params: settings.line,
                      accentColor: _kAccent,
                      onUpdate: (p) => onLineUpdate(p),
                      onEnd: (p) => onLineEnd(p),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
