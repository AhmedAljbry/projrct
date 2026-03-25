import 'package:flutter/material.dart';

import '../../domain/entities/circle_params.dart';
import '../painters/circle_overlay_painter.dart';

enum _CircleDragTarget { center, radius, none }

/// Stateful gesture handler for the circle overlay.
/// Converts raw pan gestures into [CircleBlurParams] deltas.
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
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final painter = CircleOverlayPainter(
        params: _live,
        accentColor: widget.accentColor,
        isDragging: _dragging,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          final local = d.localPosition;
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
        onPanUpdate: (d) {
          if (_target == _CircleDragTarget.none) return;
          final dx = d.delta.dx / size.width;
          final dy = d.delta.dy / size.height;
          setState(() {
            if (_target == _CircleDragTarget.center) {
              _live = _live.copyWith(
                centerX: (_live.centerX + dx).clamp(0.05, 0.95),
                centerY: (_live.centerY + dy).clamp(0.05, 0.95),
              );
            } else {
              _live = _live.copyWith(
                radiusX: (_live.radiusX + dx.abs() * d.delta.dx.sign)
                    .clamp(0.04, 0.70),
                radiusY: (_live.radiusY + dy.abs() * d.delta.dy.sign)
                    .clamp(0.04, 0.70),
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
    });
  }
}
