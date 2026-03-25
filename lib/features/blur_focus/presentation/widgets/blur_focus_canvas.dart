import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_mode.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_settings.dart';
import 'package:untitled2/features/blur_focus/domain/models/focus_geometry.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';
import 'package:untitled2/features/blur_focus/presentation/painters/blur_focus_overlay_painter.dart';

/// Interactive canvas that shows the current preview image and overlay.
///
/// v2 improvements:
/// - **Live brush cursor**: a circle follows the user's finger every frame
///   during refine-mask drawing so the exact brush footprint is always visible.
/// - **Velocity sub-sampling**: inserts intermediate points when the pointer
///   moves faster than [_maxSegmentLength] normalised units, preventing gaps
///   in the painted mask.
class BlurFocusCanvas extends StatefulWidget {
  const BlurFocusCanvas({
    super.key,
    required this.image,
    required this.settings,
    required this.showMaskPreview,
    required this.refineMaskMode,
    required this.segmentation,
    required this.manualBlendMode,
    required this.onSettingsChanged,
    required this.onManualStroke,
  });

  final ui.Image image;
  final BlurSettings settings;
  final bool showMaskPreview;
  final bool refineMaskMode;
  final SegmentationResultData? segmentation;
  final ManualMaskBlendMode manualBlendMode;
  final ValueChanged<BlurSettings> onSettingsChanged;
  final ValueChanged<List<ManualMaskPoint>> onManualStroke;

  @override
  State<BlurFocusCanvas> createState() => _BlurFocusCanvasState();
}

class _BlurFocusCanvasState extends State<BlurFocusCanvas> {
  // Max normalised distance between sampled stroke points before inserting
  // sub-samples.  ~1.5 % of the shorter canvas dimension.
  static const double _maxSegmentLength = 0.015;

  final List<ManualMaskPoint> _activeStroke = [];
  ManualMaskPoint? _cursorPosition; // tracks live finger position
  Size? _layoutSize;
  Offset? _startFocal;
  CircleFocusSettings? _initialCircle;
  LineFocusSettings? _initialLine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _layoutSize = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Live preview / original image
              RawImage(image: widget.image, fit: BoxFit.contain),

              // Focus geometry overlay
              CustomPaint(
                painter: BlurFocusOverlayPainter(
                  settings: widget.settings,
                  showMaskPreview: widget.showMaskPreview,
                  segmentation: widget.segmentation,
                  refineMaskMode: widget.refineMaskMode,
                ),
              ),

              // Painted stroke trail (only in refine-mask mode)
              if (widget.refineMaskMode && _activeStroke.isNotEmpty)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _LiveStrokePainter(
                      points: _activeStroke,
                      brushRadius: widget.settings.manualBrushRadius,
                      blendMode: widget.manualBlendMode,
                    ),
                  ),
                ),

              // Live brush cursor circle
              if (widget.refineMaskMode && _cursorPosition != null)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _BrushCursorPainter(
                      position: _cursorPosition!,
                      radius: widget.settings.manualBrushRadius,
                      blendMode: widget.manualBlendMode,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Gesture callbacks ─────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails details) {
    _startFocal = details.focalPoint;
    _initialCircle = widget.settings.circleSettings;
    _initialLine = widget.settings.lineSettings;

    if (widget.refineMaskMode) {
      final pt = _normalize(details.localFocalPoint);
      _activeStroke
        ..clear()
        ..add(pt);
      setState(() => _cursorPosition = pt);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (widget.refineMaskMode) {
      final pt = _normalize(details.localFocalPoint);
      _addSubSampledPoint(pt);
      setState(() => _cursorPosition = pt);
      return;
    }

    if (_layoutSize == null || _startFocal == null) return;

    final size = _layoutSize!;

    if (widget.settings.mode == BlurMode.smart) {
      // Smart mode: Gestures are used for refinement mask drawing ONLY,
      // not for moving a hidden circle.
      return;
    }

    if (widget.settings.mode == BlurMode.circle) {
      final start = _initialCircle ?? widget.settings.circleSettings;
      final delta = details.focalPoint - _startFocal!;
      widget.onSettingsChanged(
        widget.settings.copyWith(
          circleSettings: start.copyWith(
            centerX: (start.centerX + (delta.dx / size.width)).clamp(0.08, 0.92),
            centerY: (start.centerY + (delta.dy / size.height)).clamp(0.08, 0.92),
            radiusX: (start.radiusX * details.scale).clamp(0.08, 0.48),
            radiusY: (start.radiusY *
                    (widget.settings.circleSettings.allowEllipse
                        ? details.verticalScale
                        : details.scale))
                .clamp(0.08, 0.52),
            rotation: start.rotation + details.rotation,
          ),
        ),
      );
      return;
    }

    // Line mode
    final start = _initialLine ?? widget.settings.lineSettings;
    final delta = details.focalPoint - _startFocal!;
    widget.onSettingsChanged(
      widget.settings.copyWith(
        lineSettings: start.copyWith(
          centerX: (start.centerX + (delta.dx / size.width)).clamp(0.08, 0.92),
          centerY: (start.centerY + (delta.dy / size.height)).clamp(0.08, 0.92),
          width: (start.width * details.scale).clamp(0.06, 0.45),
          angle: start.angle + details.rotation,
        ),
      ),
    );
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (widget.refineMaskMode && _activeStroke.isNotEmpty) {
      widget.onManualStroke(List<ManualMaskPoint>.from(_activeStroke));
      _activeStroke.clear();
    }
    setState(() => _cursorPosition = null);
  }

  // ── Sub-sampling helper ───────────────────────────────────────────────────

  /// Inserts intermediate points between the last stroke point and [newPoint]
  /// so that fast swipes don't leave gaps in the painted mask.
  void _addSubSampledPoint(ManualMaskPoint newPoint) {
    if (_activeStroke.isEmpty) {
      _activeStroke.add(newPoint);
      return;
    }
    final last = _activeStroke.last;
    final dx = newPoint.x - last.x;
    final dy = newPoint.y - last.y;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist > _maxSegmentLength) {
      final steps = (dist / _maxSegmentLength).ceil();
      for (var i = 1; i < steps; i++) {
        final t = i / steps;
        _activeStroke.add(ManualMaskPoint(
          last.x + dx * t,
          last.y + dy * t,
        ));
      }
    }
    _activeStroke.add(newPoint);
  }

  // ── Normalization ─────────────────────────────────────────────────────────

  ManualMaskPoint _normalize(Offset point) {
    final size = _layoutSize ?? const Size(1, 1);
    return ManualMaskPoint(
      (point.dx / math.max(size.width, 1)).clamp(0.0, 1.0),
      (point.dy / math.max(size.height, 1)).clamp(0.0, 1.0),
    );
  }
}

// ── Stroke trail painter ─────────────────────────────────────────────────────

class _LiveStrokePainter extends CustomPainter {
  const _LiveStrokePainter({
    required this.points,
    required this.brushRadius,
    required this.blendMode,
  });

  final List<ManualMaskPoint> points;
  final double brushRadius;
  final ManualMaskBlendMode blendMode;

  @override
  void paint(Canvas canvas, Size size) {
    final color = blendMode == ManualMaskBlendMode.include
        ? const Color(0x5056E39F)
        : const Color(0x50FF7A7A);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final radius = brushRadius * size.shortestSide;
    for (final pt in points) {
      canvas.drawCircle(Offset(pt.x * size.width, pt.y * size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveStrokePainter old) =>
      old.points != points ||
      old.brushRadius != brushRadius ||
      old.blendMode != blendMode;
}

// ── Live cursor painter ───────────────────────────────────────────────────────

class _BrushCursorPainter extends CustomPainter {
  const _BrushCursorPainter({
    required this.position,
    required this.radius,
    required this.blendMode,
  });

  final ManualMaskPoint position;
  final double radius;
  final ManualMaskBlendMode blendMode;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = position.x * size.width;
    final cy = position.y * size.height;
    final r = radius * size.shortestSide;
    final center = Offset(cx, cy);

    final borderColor = blendMode == ManualMaskBlendMode.include
        ? const Color(0xFF56E39F)
        : const Color(0xFFFF7A7A);

    // Outer white ring for visibility on any background
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white.withValues(alpha: 0.9),
    );

    // Coloured inner ring
    canvas.drawCircle(
      center,
      math.max(1, r - 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = borderColor.withValues(alpha: 0.85),
    );

    // Center crosshair dot
    canvas.drawCircle(center, 2.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _BrushCursorPainter old) =>
      old.position != old.position ||
      old.radius != radius ||
      old.blendMode != blendMode;
}


