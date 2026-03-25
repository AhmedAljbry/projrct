import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/line_params.dart';
import '../painters/line_overlay_painter.dart';

enum _LineDragTarget { center, rotation, none }

/// Stateful gesture handler for the line / tilt-shift overlay.
class LineGestureHandler extends StatefulWidget {
  const LineGestureHandler({
    super.key,
    required this.params,
    required this.accentColor,
    required this.onUpdate,
    required this.onEnd,
  });

  final LineBlurParams params;
  final Color accentColor;
  final ValueChanged<LineBlurParams> onUpdate;
  final ValueChanged<LineBlurParams> onEnd;

  @override
  State<LineGestureHandler> createState() => _LineGestureHandlerState();
}

class _LineGestureHandlerState extends State<LineGestureHandler> {
  _LineDragTarget _target = _LineDragTarget.none;
  bool _dragging = false;
  late LineBlurParams _live;
  Offset? _lastPos;

  @override
  void initState() {
    super.initState();
    _live = widget.params;
  }

  @override
  void didUpdateWidget(LineGestureHandler old) {
    super.didUpdateWidget(old);
    if (!_dragging) _live = widget.params;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final painter = LineOverlayPainter(
        params: _live,
        accentColor: widget.accentColor,
        isDragging: _dragging,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          final local = d.localPosition;
          if (painter.hitTestRotationHandle(local, size)) {
            _target = _LineDragTarget.rotation;
          } else if (painter.hitTestCenter(local, size)) {
            _target = _LineDragTarget.center;
          } else {
            _target = _LineDragTarget.none;
          }
          _lastPos = local;
          if (_target != _LineDragTarget.none) {
            setState(() => _dragging = true);
          }
        },
        onPanUpdate: (d) {
          if (_target == _LineDragTarget.none) return;
          final local = d.localPosition;
          final dx = d.delta.dx / size.width;
          final dy = d.delta.dy / size.height;
          setState(() {
            if (_target == _LineDragTarget.center) {
              _live = _live.copyWith(
                centerX: (_live.centerX + dx).clamp(0.05, 0.95),
                centerY: (_live.centerY + dy).clamp(0.05, 0.95),
              );
            } else {
              // rotation: use angle from center
              final cx = _live.centerX * size.width;
              final cy = _live.centerY * size.height;
              final prev = math.atan2(
                  (_lastPos!.dy - cy), (_lastPos!.dx - cx));
              final curr =
                  math.atan2((local.dy - cy), (local.dx - cx));
              _live =
                  _live.copyWith(angle: _live.angle + (curr - prev));
            }
            _lastPos = local;
          });
          widget.onUpdate(_live);
        },
        onPanEnd: (_) {
          if (_target == _LineDragTarget.none) return;
          setState(() => _dragging = false);
          _target = _LineDragTarget.none;
          _lastPos = null;
          widget.onEnd(_live);
        },
        child: CustomPaint(size: Size(size.width, size.height), painter: painter),
      );
    });
  }
}
