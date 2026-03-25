import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/models/af_blur_mode.dart';
import '../../domain/models/af_blur_settings.dart';
import '../../domain/models/af_focus_geometry.dart';
import '../../domain/models/af_mask_data.dart';
import '../painters/af_brush_painters.dart';
import '../painters/af_overlay_painter.dart';

class AfCanvasView extends StatefulWidget {
  const AfCanvasView({
    super.key,
    required this.image,
    required this.settings,
    required this.showMaskOverlay,
    required this.refineMaskMode,
    required this.segmentation,
    required this.brushAdd,
    required this.onSettingsChanged,
    required this.onStroke,
  });

  final ui.Image image;
  final AfBlurSettings settings;
  final bool showMaskOverlay;
  final bool refineMaskMode;
  final AfMaskData? segmentation;
  final bool brushAdd;
  final ValueChanged<AfBlurSettings> onSettingsChanged;
  final ValueChanged<List<AfStrokePoint>> onStroke;

  @override
  State<AfCanvasView> createState() => _AfCanvasViewState();
}

class _AfCanvasViewState extends State<AfCanvasView> {
  static const double _maxSegment = 0.014;

  final List<AfStrokePoint> _activeStroke = [];
  AfStrokePoint? _cursor;
  Size? _size;
  Offset? _focalStart;
  AfCircleSettings? _circleStart;
  AfLineSettings? _lineStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RawImage(image: widget.image, fit: BoxFit.contain),
              CustomPaint(
                painter: AfOverlayPainter(
                  settings: widget.settings,
                  showMaskOverlay: widget.showMaskOverlay,
                  segmentation: widget.segmentation,
                  refineMaskMode: widget.refineMaskMode,
                ),
              ),
              if (widget.refineMaskMode && _activeStroke.isNotEmpty)
                IgnorePointer(
                  child: CustomPaint(
                    painter: AfStrokeTrailPainter(
                      points: _activeStroke,
                      radius: widget.settings.brushRadius,
                      add: widget.brushAdd,
                    ),
                  ),
                ),
              if (widget.refineMaskMode && _cursor != null)
                IgnorePointer(
                  child: CustomPaint(
                    painter: AfBrushCursorPainter(
                      position: _cursor!,
                      radius: widget.settings.brushRadius,
                      add: widget.brushAdd,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _focalStart = details.focalPoint;
    _circleStart = widget.settings.circleSettings;
    _lineStart = widget.settings.lineSettings;

    if (widget.refineMaskMode) {
      final point = _normalize(details.localFocalPoint);
      _activeStroke
        ..clear()
        ..add(point);
      setState(() => _cursor = point);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (widget.refineMaskMode) {
      final point = _normalize(details.localFocalPoint);
      _appendInterpolatedPoint(point);
      setState(() => _cursor = point);
      return;
    }

    if (_size == null || _focalStart == null) {
      return;
    }

    if (widget.settings.mode == AfBlurMode.smart) {
      return;
    }

    final size = _size!;
    final delta = details.focalPoint - _focalStart!;

    if (widget.settings.mode == AfBlurMode.circle) {
      final start = _circleStart ?? widget.settings.circleSettings;
      widget.onSettingsChanged(
        widget.settings.copyWith(
          circleSettings: start.copyWith(
            centerX: (start.centerX + delta.dx / size.width).clamp(0.06, 0.94),
            centerY: (start.centerY + delta.dy / size.height).clamp(0.06, 0.94),
            radiusX: (start.radiusX * details.scale).clamp(0.07, 0.50),
            radiusY: (start.radiusY *
                    (widget.settings.circleSettings.allowEllipse
                        ? details.verticalScale
                        : details.scale))
                .clamp(0.07, 0.55),
            rotation: start.rotation + details.rotation,
          ),
        ),
      );
      return;
    }

    final start = _lineStart ?? widget.settings.lineSettings;
    widget.onSettingsChanged(
      widget.settings.copyWith(
        lineSettings: start.copyWith(
          centerX: (start.centerX + delta.dx / size.width).clamp(0.06, 0.94),
          centerY: (start.centerY + delta.dy / size.height).clamp(0.06, 0.94),
          width: (start.width * details.scale).clamp(0.05, 0.46),
          angle: start.angle + details.rotation,
        ),
      ),
    );
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (widget.refineMaskMode && _activeStroke.isNotEmpty) {
      widget.onStroke(List<AfStrokePoint>.from(_activeStroke));
      _activeStroke.clear();
    }
    setState(() => _cursor = null);
  }

  void _appendInterpolatedPoint(AfStrokePoint point) {
    if (_activeStroke.isEmpty) {
      _activeStroke.add(point);
      return;
    }

    final last = _activeStroke.last;
    final dx = point.x - last.x;
    final dy = point.y - last.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance > _maxSegment) {
      final steps = (distance / _maxSegment).ceil();
      for (var i = 1; i < steps; i++) {
        final t = i / steps;
        _activeStroke.add(AfStrokePoint(last.x + dx * t, last.y + dy * t));
      }
    }
    _activeStroke.add(point);
  }

  AfStrokePoint _normalize(Offset point) {
    final size = _size ?? const Size(1, 1);
    return AfStrokePoint(
      (point.dx / math.max(size.width, 1)).clamp(0.0, 1.0),
      (point.dy / math.max(size.height, 1)).clamp(0.0, 1.0),
    );
  }
}
