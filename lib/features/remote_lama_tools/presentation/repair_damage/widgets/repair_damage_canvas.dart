import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/widgets/repair_damage_brush_overlay.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/widgets/repair_damage_magnifier.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';

class RepairDamageCanvas extends StatefulWidget {
  const RepairDamageCanvas({
    super.key,
    required this.image,
    required this.editMode,
    required this.brushRadiusImage,
    required this.drawingEnabled,
    required this.onStrokeCommitted,
    this.previewOverlayPng,
  });

  final ui.Image image;
  final Uint8List? previewOverlayPng;
  final MaskEditMode editMode;
  final double brushRadiusImage;
  final bool drawingEnabled;
  final Future<void> Function(List<Offset> imagePoints) onStrokeCommitted;

  @override
  State<RepairDamageCanvas> createState() => _RepairDamageCanvasState();
}

class _RepairDamageCanvasState extends State<RepairDamageCanvas> {
  static const double _minScale = 1.0;
  static const double _maxScale = 6.0;
  static const double _doubleTapZoomScale = 2.6;

  final TransformationController _viewportController =
      TransformationController();

  int _activePointers = 0;
  bool _isDrawingStroke = false;
  bool _isViewportGestureActive = false;
  double _gestureBaseScale = 1.0;
  Offset? _gestureSceneFocalPoint;
  Offset? _doubleTapDownPosition;
  Offset? _cursorViewportPoint;
  Offset? _cursorImagePoint;
  List<Offset> _activeStrokePoints = <Offset>[];

  @override
  void dispose() {
    _viewportController.dispose();
    super.dispose();
  }

  double get _currentViewportScale =>
      _viewportController.value.getMaxScaleOnAxis();

  Color get _accentColor => widget.editMode == MaskEditMode.add
      ? LamaTheme.accent
      : const Color(0xFFFF7B7B);

  double _loupeScaleFor(double zoomScale) {
    if (zoomScale < 1.0) {
      return 2.2;
    }
    if (zoomScale < 2.0) {
      return 1.95;
    }
    if (zoomScale < 3.5) {
      return 1.7;
    }
    return 1.45;
  }

  void _handlePointerDown() {
    _activePointers += 1;
    if (_activePointers > 1 && _isDrawingStroke) {
      _finishStroke();
    }
  }

  void _handlePointerEnd() {
    _activePointers = math.max(0, _activePointers - 1);
  }

  void _onPointerSignal(PointerSignalEvent event, Size canvasSize) {
    if (event is! PointerScrollEvent) {
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }

    final focalPoint = box.globalToLocal(event.position);
    final sceneFocalPoint = _viewportController.toScene(focalPoint);
    final zoomFactor = event.scrollDelta.dy < 0 ? 1.08 : 0.92;
    final targetScale = (_currentViewportScale * zoomFactor)
        .clamp(_minScale, _maxScale)
        .toDouble();

    _viewportController.value = _clampViewportMatrix(
      _buildViewportMatrix(
        scale: targetScale,
        viewportFocalPoint: focalPoint,
        sceneFocalPoint: sceneFocalPoint,
      ),
      canvasSize,
    );
  }

  void _onScaleStart(ScaleStartDetails details, Size canvasSize) {
    if (_activePointers > 1 || !widget.drawingEnabled) {
      _startViewportGesture(details.localFocalPoint, canvasSize);
      return;
    }

    _startStroke(details.localFocalPoint, canvasSize);
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size canvasSize) {
    if (_activePointers > 1 ||
        _isViewportGestureActive ||
        !widget.drawingEnabled) {
      if (!_isViewportGestureActive) {
        _startViewportGesture(details.localFocalPoint, canvasSize);
      }
      _updateViewportGesture(
          details.localFocalPoint, details.scale, canvasSize);
      return;
    }

    _updateStroke(details.localFocalPoint, canvasSize);
  }

  void _onScaleEnd() {
    if (_isViewportGestureActive) {
      _endViewportGesture();
      return;
    }

    if (_isDrawingStroke) {
      _finishStroke();
    }
  }

  void _startStroke(Offset viewportPoint, Size canvasSize) {
    final imagePoint = _viewportPointToImagePx(
      viewportPoint,
      canvasSize,
    );

    setState(() {
      _cursorViewportPoint = viewportPoint;
      _cursorImagePoint = imagePoint;
    });

    if (imagePoint == null) {
      _isDrawingStroke = false;
      _activeStrokePoints = <Offset>[];
      return;
    }

    _isDrawingStroke = true;
    _activeStrokePoints = <Offset>[imagePoint];
  }

  void _updateStroke(Offset viewportPoint, Size canvasSize) {
    final imagePoint = _viewportPointToImagePx(
      viewportPoint,
      canvasSize,
      clampToBounds: _isDrawingStroke,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _cursorViewportPoint = viewportPoint;
      _cursorImagePoint = imagePoint;
    });

    if (imagePoint == null) {
      return;
    }

    if (!_isDrawingStroke) {
      _startStroke(viewportPoint, canvasSize);
      return;
    }

    final nextPoints = <Offset>[];
    if (_activeStrokePoints.isNotEmpty) {
      nextPoints.addAll(
        _interpolateStroke(
          _activeStrokePoints.last,
          imagePoint,
          widget.brushRadiusImage,
        ),
      );
      if (nextPoints.isNotEmpty) {
        nextPoints.removeAt(0);
      }
    }

    if (nextPoints.isEmpty &&
        _activeStrokePoints.isNotEmpty &&
        (_activeStrokePoints.last - imagePoint).distance < 0.2) {
      return;
    }

    setState(() {
      if (nextPoints.isEmpty) {
        _activeStrokePoints = <Offset>[..._activeStrokePoints, imagePoint];
      } else {
        _activeStrokePoints = <Offset>[..._activeStrokePoints, ...nextPoints];
      }
    });
  }

  Future<void> _finishStroke() async {
    final completedStroke = List<Offset>.unmodifiable(_activeStrokePoints);
    setState(() {
      _isDrawingStroke = false;
      _activeStrokePoints = <Offset>[];
      _cursorViewportPoint = null;
      _cursorImagePoint = null;
    });

    if (completedStroke.isEmpty) {
      return;
    }

    await widget.onStrokeCommitted(completedStroke);
  }

  void _startViewportGesture(Offset focalPoint, Size canvasSize) {
    setState(() {
      _isViewportGestureActive = true;
      _isDrawingStroke = false;
      _activeStrokePoints = <Offset>[];
      _cursorViewportPoint = null;
      _cursorImagePoint = null;
      _gestureBaseScale = _currentViewportScale;
      _gestureSceneFocalPoint = _viewportController.toScene(focalPoint);
    });

    _viewportController.value = _clampViewportMatrix(
      _viewportController.value,
      canvasSize,
    );
  }

  void _updateViewportGesture(
    Offset focalPoint,
    double gestureScale,
    Size canvasSize,
  ) {
    final sceneFocalPoint =
        _gestureSceneFocalPoint ?? _viewportController.toScene(focalPoint);
    final targetScale = (_gestureBaseScale * gestureScale)
        .clamp(_minScale, _maxScale)
        .toDouble();

    _viewportController.value = _clampViewportMatrix(
      _buildViewportMatrix(
        scale: targetScale,
        viewportFocalPoint: focalPoint,
        sceneFocalPoint: sceneFocalPoint,
      ),
      canvasSize,
    );
  }

  void _endViewportGesture() {
    setState(() {
      _isViewportGestureActive = false;
      _gestureSceneFocalPoint = null;
    });
  }

  void _handleDoubleTap(Size canvasSize) {
    final focalPoint = _doubleTapDownPosition ?? canvasSize.center(Offset.zero);
    final targetScale = _currentViewportScale > (_doubleTapZoomScale - 0.2)
        ? 1.0
        : _doubleTapZoomScale;
    final sceneFocalPoint = _viewportController.toScene(focalPoint);

    _viewportController.value = _clampViewportMatrix(
      _buildViewportMatrix(
        scale: targetScale,
        viewportFocalPoint: focalPoint,
        sceneFocalPoint: sceneFocalPoint,
      ),
      canvasSize,
    );
  }

  Matrix4 _buildViewportMatrix({
    required double scale,
    required Offset viewportFocalPoint,
    required Offset sceneFocalPoint,
  }) {
    final tx = viewportFocalPoint.dx - (sceneFocalPoint.dx * scale);
    final ty = viewportFocalPoint.dy - (sceneFocalPoint.dy * scale);

    return Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
  }

  Matrix4 _clampViewportMatrix(Matrix4 matrix, Size canvasSize) {
    final scale =
        matrix.getMaxScaleOnAxis().clamp(_minScale, _maxScale).toDouble();

    var tx = matrix.storage[12];
    var ty = matrix.storage[13];

    if (scale <= 1.0) {
      tx = 0;
      ty = 0;
    } else {
      final minTx = canvasSize.width - (canvasSize.width * scale);
      final minTy = canvasSize.height - (canvasSize.height * scale);
      tx = tx.clamp(minTx, 0.0);
      ty = ty.clamp(minTy, 0.0);
    }

    return Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
  }

  Offset? _viewportPointToImagePx(
    Offset viewportPoint,
    Size canvasSize, {
    bool clampToBounds = false,
  }) {
    final scenePoint = _viewportController.toScene(viewportPoint);
    final normalizedX = scenePoint.dx / canvasSize.width;
    final normalizedY = scenePoint.dy / canvasSize.height;

    if (!clampToBounds &&
        (normalizedX < 0 ||
            normalizedY < 0 ||
            normalizedX > 1 ||
            normalizedY > 1)) {
      return null;
    }

    return Offset(
      normalizedX.clamp(0.0, 1.0) * widget.image.width,
      normalizedY.clamp(0.0, 1.0) * widget.image.height,
    );
  }

  List<Offset> _interpolateStroke(
    Offset start,
    Offset end,
    double brushRadius,
  ) {
    final distance = (end - start).distance;
    final spacing = math.max(1.0, brushRadius * 0.28);
    final steps = math.max(1, (distance / spacing).ceil());

    return List<Offset>.generate(
      steps + 1,
      (index) => Offset.lerp(start, end, index / steps)!,
      growable: false,
    );
  }

  Widget _buildScene() {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: RawImage(
            image: widget.image,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        ),
        if (widget.previewOverlayPng != null)
          RepaintBoundary(
            child: Image.memory(
              widget.previewOverlayPng!,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
          ),
        RepaintBoundary(
          child: RepairDamageBrushOverlay(
            imageSize: Size(
              widget.image.width.toDouble(),
              widget.image.height.toDouble(),
            ),
            strokeImagePoints: _activeStrokePoints,
            activeImagePoint: _cursorImagePoint,
            brushRadiusImage: widget.brushRadiusImage,
            color: _accentColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1C1E23),
            Color(0xFF111317),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize =
                Size(constraints.maxWidth, constraints.maxHeight);

            return Listener(
              onPointerDown: (_) => _handlePointerDown(),
              onPointerUp: (_) => _handlePointerEnd(),
              onPointerCancel: (_) => _handlePointerEnd(),
              onPointerSignal: (event) => _onPointerSignal(event, canvasSize),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTapDown: (details) {
                  _doubleTapDownPosition = details.localPosition;
                },
                onDoubleTap: () => _handleDoubleTap(canvasSize),
                onScaleStart: (details) => _onScaleStart(details, canvasSize),
                onScaleUpdate: (details) => _onScaleUpdate(details, canvasSize),
                onScaleEnd: (_) => _onScaleEnd(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedBuilder(
                      animation: _viewportController,
                      child: _buildScene(),
                      builder: (context, child) {
                        return Transform(
                          alignment: Alignment.topLeft,
                          transform: _viewportController.value,
                          child: SizedBox.expand(child: child),
                        );
                      },
                    ),
                    if (_cursorViewportPoint != null &&
                        _cursorImagePoint != null &&
                        !_isViewportGestureActive)
                      RepairDamageMagnifier(
                        focalViewportPoint: _cursorViewportPoint!,
                        canvasSize: canvasSize,
                        transform: _viewportController.value,
                        accentColor: _accentColor,
                        magnification: _loupeScaleFor(_currentViewportScale),
                        sceneBuilder: (_) => _buildScene(),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
