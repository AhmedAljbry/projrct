import 'dart:ui';
import 'package:flutter/gestures.dart';

/// Processes raw touch/pointer events into smoothed image-space stroke points.
///
/// Responsibilities:
///  - Convert canvas-space touch coordinates to image-space coordinates
///  - Track gesture velocity for optional pressure simulation
///  - Enforce minimum distance between emitted points to avoid redundant dabs
///  - Smooth rapid direction changes to reduce jagged masks
class BrushInteractionService {
  /// Minimum distance between consecutive stroke points (in image pixels).
  static const double _minPointSpacing = 1.2;
  static const double _smoothingFactor = 0.42;
  static const double _maxSegmentLength = 5.5;

  final List<Offset> _currentStroke = [];
  Offset? _lastEmitted;
  Offset? _lastRawPoint;
  Offset? _velocity;
  DateTime? _lastTimestamp;

  bool get hasActiveStroke => _currentStroke.isNotEmpty;
  List<Offset> get currentStroke => List.unmodifiable(_currentStroke);

  /// Begin a new stroke at [imagePoint].
  void beginStroke(Offset imagePoint) {
    _currentStroke.clear();
    _lastEmitted = imagePoint;
    _lastRawPoint = imagePoint;
    _velocity = Offset.zero;
    _lastTimestamp = DateTime.now();
    _currentStroke.add(imagePoint);
  }

  /// Continue the stroke with a new touch position [imagePoint].
  /// Returns true if a new point was added (spacing threshold passed).
  bool continueStroke(Offset imagePoint) {
    if (_lastEmitted == null) {
      beginStroke(imagePoint);
      return true;
    }

    final smoothedPoint = _smoothPoint(imagePoint);
    final dist = (smoothedPoint - _lastEmitted!).distance;
    if (dist < _minPointSpacing) return false;

    // Update velocity estimate for pressure simulation.
    final now = DateTime.now();
    if (_lastTimestamp != null) {
      final dt = now.difference(_lastTimestamp!).inMicroseconds / 1000.0; // ms
      if (dt > 0) {
        final rawVelocity = (smoothedPoint - _lastEmitted!) / dt;
        _velocity = _velocity == null
            ? rawVelocity
            : Offset(
                _lerp(_velocity!.dx, rawVelocity.dx, 0.4),
                _lerp(_velocity!.dy, rawVelocity.dy, 0.4),
              );
      }
    }
    _lastTimestamp = now;
    _appendInterpolatedPoints(smoothedPoint);
    return true;
  }

  /// End the stroke. Returns the final list of stroke points.
  List<Offset> endStroke() {
    final result = List<Offset>.from(_currentStroke);
    _currentStroke.clear();
    _lastEmitted = null;
    _lastRawPoint = null;
    _velocity = null;
    _lastTimestamp = null;
    return result;
  }

  /// Cancel the current stroke without committing.
  void cancelStroke() {
    _currentStroke.clear();
    _lastEmitted = null;
    _lastRawPoint = null;
    _velocity = null;
    _lastTimestamp = null;
  }

  /// Compute simulated pressure from velocity magnitude.
  /// Fast movement = less pressure (wider, softer dab).
  /// Slow movement = more pressure (denser, harder dab).
  double simulatedPressure({required bool velocityEnabled}) {
    if (!velocityEnabled || _velocity == null) return 1.0;
    final speed = _velocity!.distance;
    // Map speed to pressure: 0–50 px/ms = 1.0–0.5 pressure.
    return (1.0 - (speed / 50.0).clamp(0.0, 0.5));
  }

  /// Convert a canvas-space point to image-space given the current
  /// transform (scale + translation).
  static Offset canvasToImage(
    Offset canvasPoint, {
    required double scale,
    required Offset translation,
    required int imageWidth,
    required int imageHeight,
  }) {
    // Invert the canvas transform: canvasPoint = imagePoint * scale + translation
    // → imagePoint = (canvasPoint - translation) / scale
    final imageX = (canvasPoint.dx - translation.dx) / scale;
    final imageY = (canvasPoint.dy - translation.dy) / scale;
    return Offset(
      imageX.clamp(0.0, imageWidth.toDouble() - 1),
      imageY.clamp(0.0, imageHeight.toDouble() - 1),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Offset _smoothPoint(Offset imagePoint) {
    if (_lastRawPoint == null || _lastEmitted == null) {
      _lastRawPoint = imagePoint;
      return imagePoint;
    }

    final rawBlend = Offset.lerp(_lastRawPoint, imagePoint, 0.68) ?? imagePoint;
    _lastRawPoint = imagePoint;
    return Offset(
      _lerp(_lastEmitted!.dx, rawBlend.dx, _smoothingFactor),
      _lerp(_lastEmitted!.dy, rawBlend.dy, _smoothingFactor),
    );
  }

  void _appendInterpolatedPoints(Offset nextPoint) {
    final start = _lastEmitted!;
    final distance = (nextPoint - start).distance;
    final steps = (distance / _maxSegmentLength).ceil().clamp(1, 8);

    for (int step = 1; step <= steps; step++) {
      final t = step / steps;
      final point = Offset.lerp(start, nextPoint, t) ?? nextPoint;
      _currentStroke.add(point);
    }

    _lastEmitted = nextPoint;
  }
}
