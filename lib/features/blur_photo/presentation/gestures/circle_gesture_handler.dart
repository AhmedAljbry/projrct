import 'package:flutter/material.dart';

import '../../domain/entities/circle_params.dart';
import '../painters/circle_overlay_painter.dart';

enum _CircleDragTarget { center, radius, none }

class CircleGestureHandler extends StatefulWidget {
  const CircleGestureHandler({
    super.key,
    required this.params,
    required this.canvasSize,
    required this.accentColor,
    required this.onUpdate,
    required this.onEnd,
  });

  final CircleBlurParams params;
  final Size canvasSize;
  final Color accentColor;
  final ValueChanged<CircleBlurParams> onUpdate;
  final ValueChanged<CircleBlurParams> onEnd;

  @override
  State<CircleGestureHandler> createState() => _CircleGestureHandlerState();
}

class _CircleGestureHandlerState extends State<CircleGestureHandler> {
  _CircleDragTarget _target = _CircleDragTarget.none;
  bool _dragging = false;
  late CircleBlurParams _live;

  @override
  void initState() {
    super.initState();
    _live = widget.params;
  }

  @override
  void didUpdateWidget(CircleGestureHandler old) {
    super.didUpdateWidget(old);
    if (!_dragging) _live = widget.params;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final painter = CircleOverlayPainter(
          params: _live,
          accentColor: widget.accentColor,
          isDragging: _dragging,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            final local = details.localPosition;
            if (painter.hitTestCenter(local, size)) {
              _target = _CircleDragTarget.center;
            } else if (painter.hitTestRadiusHandle(local, size)) {
              _target = _CircleDragTarget.radius;
            } else {
              _target = _CircleDragTarget.none;
            }
            if (_target != _CircleDragTarget.none) {
              setState(() => _dragging = true);
            }
          },
          onPanUpdate: (details) {
            if (_target == _CircleDragTarget.none) return;
            final dx = (details.delta.dx / size.width) * 1.15;
            final dy = (details.delta.dy / size.height) * 1.15;
            setState(() {
              if (_target == _CircleDragTarget.center) {
                _live = _live.copyWith(
                  centerX: (_live.centerX + dx).clamp(0.05, 0.95),
                  centerY: (_live.centerY + dy).clamp(0.05, 0.95),
                );
              } else {
                final radialDelta =
                    ((dx.abs() + dy.abs()) * 0.5).clamp(0.0, 0.08);
                _live = _live.copyWith(
                  radiusX: (_live.radiusX + radialDelta).clamp(0.04, 0.72),
                  radiusY: (_live.radiusY + radialDelta).clamp(0.04, 0.72),
                );
              }
            });
            widget.onUpdate(_live);
          },
          onPanEnd: (_) {
            if (_target == _CircleDragTarget.none) return;
            setState(() => _dragging = false);
            _target = _CircleDragTarget.none;
            widget.onEnd(_live);
          },
          child: CustomPaint(size: size, painter: painter),
        );
      },
    );
  }
}
