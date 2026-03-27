import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/blur_mode.dart';
import '../../domain/entities/blur_settings.dart';
import '../gestures/circle_gesture_handler.dart';
import '../gestures/line_gesture_handler.dart';

const _kAccent = Color(0xFF56E39F);

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageAspect = image.width / image.height;
          final viewAspect = constraints.maxWidth / constraints.maxHeight;

          double canvasWidth;
          double canvasHeight;
          if (imageAspect > viewAspect) {
            canvasWidth = constraints.maxWidth;
            canvasHeight = canvasWidth / imageAspect;
          } else {
            canvasHeight = constraints.maxHeight;
            canvasWidth = canvasHeight * imageAspect;
          }

          final canvasSize = Size(canvasWidth, canvasHeight);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF121216),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Center(
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RawImage(image: image, fit: BoxFit.contain),
                      if (settings.mode == BlurPhotoMode.circle)
                        CircleGestureHandler(
                          params: settings.circle,
                          canvasSize: canvasSize,
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
            ),
          );
        },
      ),
    );
  }
}
