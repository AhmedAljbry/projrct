/*
import 'dart:ui';
import 'package:flutter/material.dart';
import 'brush_settings.dart';
import 'stroke_path.dart';

class BrushEngine {
  final List<StrokePath> _strokes = [];
  StrokePath? _currentStroke;
  
  BrushSettings _currentSettings = const BrushSettings();

  List<StrokePath> get strokes => _strokes;
  BrushSettings get currentSettings => _currentSettings;

  void updateSettings(BrushSettings settings) {
    _currentSettings = settings;
  }

  void startStroke(Offset point) {
    _currentStroke = StrokePath(settings: _currentSettings);
    _currentStroke!.addPoint(point);
    _strokes.add(_currentStroke!);
  }

  void updateStroke(Offset point, {double velocity = 0.0}) {
    if (_currentStroke == null) return;
    _currentStroke!.addPoint(point, velocity: velocity);
  }

  void endStroke() {
    _currentStroke = null;
  }

  void clear() {
    _strokes.clear();
    _currentStroke = null;
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
    }
  }

  // Draw all paths to a canvas
  void render(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    
    for (final stroke in _strokes) {
      _renderStroke(canvas, stroke);
    }
    
    canvas.restore();
  }

  void _renderStroke(Canvas canvas, StrokePath stroke) {
    final settings = stroke.settings;
    
    // We use a blend mode and blur to simulate hardness
    final paint = Paint()
      ..color = settings.color.withValues(alpha: settings.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    // Simulating hardness: 1.0 = sharp, 0.0 = completely blurred
    if (settings.hardness < 1.0) {
      // Map 0..1 to a sigma limit, e.g., max sigma 15
      double blurSigma = (1.0 - settings.hardness) * 15.0;
      if (blurSigma > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
      }
    }

    final path = stroke.path;
    canvas.drawPath(path, paint);
  }
}
*/
