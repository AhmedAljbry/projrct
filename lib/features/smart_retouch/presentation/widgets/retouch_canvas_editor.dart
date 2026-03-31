import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/features/smart_retouch/presentation/renderers/canvas_preview_painter.dart';

import '../../application/bloc/retouch_bloc.dart';
import '../../application/bloc/retouch_event.dart';
import '../../application/bloc/retouch_state.dart';
import '../../domain/models/retouch_mode.dart';
import '../../domain/models/retouch_operation.dart';
import '../../infrastructure/engine/brush_stroke_interpolator.dart';
import '../../infrastructure/engine/image_coordinate_mapper.dart';

class RetouchCanvasEditor extends StatefulWidget {
  final ui.Image displayImage;
  final ui.Image originalImage;

  const RetouchCanvasEditor({
    super.key,
    required this.displayImage,
    required this.originalImage,
  });

  @override
  State<RetouchCanvasEditor> createState() => _RetouchCanvasEditorState();
}

class _RetouchCanvasEditorState extends State<RetouchCanvasEditor> {
  final TransformationController _transformationController =
      TransformationController();
  static const double _minScale = 0.5;
  static const double _maxScale = 15.0;
  static const Duration _finishedStrokeHold = Duration(milliseconds: 320);

  Offset? _activeScreenPosition;
  List<Offset> _currentStrokePoints = [];
  bool _isDefiningSource = false;
  Offset? _continuedCloneOffset;
  Offset? _continuedSourceAnchor;
  Offset? _carryStrokeEnd;
  Offset? _carrySourceEnd;
  RetouchMode? _carryMode;
  StrokeOperation? _heldPreviewStroke;
  Offset? _heldPreviewSourceAnchor;
  Timer? _heldPreviewTimer;

  bool _shouldContinueFromLastStroke({
    required RetouchState state,
    required Offset nextPoint,
  }) {
    if (_carryStrokeEnd == null) return false;
    if (_carryMode != state.activeMode) return false;
    return true;
  }

  @override
  void didUpdateWidget(covariant RetouchCanvasEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.displayImage, widget.displayImage)) {
      _clearHeldPreview();
    }
  }

  @override
  void dispose() {
    _heldPreviewTimer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  double get _currentScale {
    return _transformationController.value.getMaxScaleOnAxis();
  }

  double _loupeScaleFor(double zoomScale) {
    if (zoomScale < 1.0) return 2.6;
    if (zoomScale < 2.0) return 2.1;
    if (zoomScale < 4.0) return 1.7;
    return 1.35;
  }

  void _clearHeldPreview() {
    _heldPreviewTimer?.cancel();
    _heldPreviewTimer = null;
    _heldPreviewStroke = null;
    _heldPreviewSourceAnchor = null;
  }

  void _holdFinishedPreview(StrokeOperation stroke, Offset? sourceAnchor) {
    _heldPreviewTimer?.cancel();
    _heldPreviewStroke = stroke;
    _heldPreviewSourceAnchor = sourceAnchor;
    _heldPreviewTimer = Timer(_finishedStrokeHold, () {
      if (!mounted) return;
      setState(() {
        _heldPreviewStroke = null;
        _heldPreviewSourceAnchor = null;
      });
    });
  }

  Offset _mapPointerToImagePoint(Offset screenPoint, Rect displayRect) {
    final Matrix4 inverseMatrix =
        Matrix4.inverted(_transformationController.value);
    final Offset unTransformedPoint =
        MatrixUtils.transformPoint(inverseMatrix, screenPoint);

    return ImageCoordinateMapper.screenToImage(
      unTransformedPoint,
      displayRect,
      Size(
        widget.displayImage.width.toDouble(),
        widget.displayImage.height.toDouble(),
      ),
    );
  }

  void _onPanStart(DragStartDetails details, Rect displayRect) {
    if (displayRect.isEmpty) return;

    final state = context.read<RetouchBloc>().state;
    if (state.activeMode == RetouchMode.none) return;

    _clearHeldPreview();

    final Offset imagePoint =
        _mapPointerToImagePoint(details.localPosition, displayRect);

    if ((state.activeMode == RetouchMode.clone ||
            state.activeMode == RetouchMode.heal) &&
        state.activeSourceAnchor == null) {
      _isDefiningSource = true;
      _continuedCloneOffset = null;
      _continuedSourceAnchor = null;
      _carryStrokeEnd = null;
      _carrySourceEnd = null;
      _carryMode = null;
      context.read<RetouchBloc>().add(SetSourceAnchorEvent(imagePoint));
      return;
    }

    _isDefiningSource = false;
    _continuedCloneOffset = null;
    _continuedSourceAnchor = null;
    final bool continueStroke =
        _shouldContinueFromLastStroke(state: state, nextPoint: imagePoint);
    if (continueStroke && _carryStrokeEnd != null) {
      _currentStrokePoints = [_carryStrokeEnd!];
      if ((_currentStrokePoints.first - imagePoint).distance > 0.1) {
        _currentStrokePoints.add(imagePoint);
      }
      if ((state.activeMode == RetouchMode.clone ||
              state.activeMode == RetouchMode.heal) &&
          _carrySourceEnd != null) {
        _continuedCloneOffset = _carrySourceEnd! - _carryStrokeEnd!;
        _continuedSourceAnchor =
            _currentStrokePoints.first + _continuedCloneOffset!;
      }
    } else {
      _currentStrokePoints = [imagePoint];
    }

    setState(() {
      _activeScreenPosition = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Rect displayRect) {
    final state = context.read<RetouchBloc>().state;
    if (state.activeMode == RetouchMode.none) return;

    setState(() {
      _activeScreenPosition = details.localPosition;
    });

    if (_isDefiningSource) return;

    final Offset imagePoint =
        _mapPointerToImagePoint(details.localPosition, displayRect);
    const double spacing = 0.1;
    final double size = state.activeBrushSettings.size;

    if (_currentStrokePoints.isNotEmpty) {
      final lastPoint = _currentStrokePoints.last;
      final interpolated = BrushStrokeInterpolator.interpolateStroke(
        lastPoint,
        imagePoint,
        size,
        spacing,
      );
      if (interpolated.length > 1) {
        _currentStrokePoints.addAll(interpolated.sublist(1));
      }
    } else {
      _currentStrokePoints.add(imagePoint);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final bloc = context.read<RetouchBloc>();
    final state = bloc.state;

    setState(() {
      _activeScreenPosition = null;
    });

    if (_isDefiningSource || _currentStrokePoints.isEmpty) {
      _currentStrokePoints.clear();
      _continuedCloneOffset = null;
      _continuedSourceAnchor = null;
      return;
    }

    if (_currentStrokePoints.length == 1 &&
        (state.activeMode == RetouchMode.clone ||
            state.activeMode == RetouchMode.heal)) {
      bloc.add(SetSourceAnchorEvent(_currentStrokePoints.first));
      _currentStrokePoints.clear();
      _continuedCloneOffset = null;
      _continuedSourceAnchor = null;
      _carryStrokeEnd = null;
      _carrySourceEnd = null;
      _carryMode = null;
      return;
    }

    Offset? currentOffset = _continuedCloneOffset ?? state.activeCloneOffset;
    if (currentOffset == null && state.activeSourceAnchor != null) {
      currentOffset = state.activeSourceAnchor! - _currentStrokePoints.first;
      bloc.add(SetCloneOffsetEvent(currentOffset));
    }

    final Offset effectiveSource = (currentOffset != null)
        ? (_currentStrokePoints.first + currentOffset)
        : (state.activeSourceAnchor ?? _currentStrokePoints.first);

    RetouchOperation op;
    StrokeOperation holdStroke;
    Offset? holdSourceAnchor;

    if (state.activeMode == RetouchMode.eraser) {
      op = EraseOperation(
        id: UniqueKey().toString(),
        mode: state.activeMode,
        settings: state.activeBrushSettings,
        path: List.of(_currentStrokePoints),
      );
      holdStroke = StrokeOperation(
        id: 'hold',
        mode: state.activeMode,
        settings: state.activeBrushSettings,
        path: List.of(_currentStrokePoints),
        sourceAnchor: null,
        targetAnchor: _currentStrokePoints.first,
      );
    } else {
      op = StrokeOperation(
        id: UniqueKey().toString(),
        mode: state.activeMode,
        settings: state.activeBrushSettings,
        path: List.of(_currentStrokePoints),
        sourceAnchor: effectiveSource,
        targetAnchor: _currentStrokePoints.first,
      );
      holdStroke = StrokeOperation(
        id: 'hold',
        mode: state.activeMode,
        settings: state.activeBrushSettings,
        path: List.of(_currentStrokePoints),
        sourceAnchor: effectiveSource,
        targetAnchor: _currentStrokePoints.first,
      );
      holdSourceAnchor = effectiveSource;
    }

    _carryStrokeEnd = _currentStrokePoints.last;
    _carryMode = state.activeMode;
    if (op is StrokeOperation && op.sourceAnchor != null) {
      _carrySourceEnd = op.sourceAnchor! + (op.path.last - op.path.first);
    } else {
      _carrySourceEnd = null;
    }

    _currentStrokePoints.clear();
    _continuedCloneOffset = null;
    _continuedSourceAnchor = null;
    _holdFinishedPreview(holdStroke, holdSourceAnchor);
    bloc.add(ApplyOperationEvent(operation: op));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentDisplayRect =
            ImageCoordinateMapper.calculateImageDisplayRect(
          canvasSize: constraints.biggest,
          imageSize: Size(
            widget.displayImage.width.toDouble(),
            widget.displayImage.height.toDouble(),
          ),
        );

        return BlocBuilder<RetouchBloc, RetouchState>(
          builder: (context, state) {
            final bool isPanEnabled = state.activeMode == RetouchMode.none;
            final StrokeOperation? previewStroke =
                _currentStrokePoints.isNotEmpty
                    ? StrokeOperation(
                        id: 'temp',
                        mode: state.activeMode,
                        settings: state.activeBrushSettings,
                        path: _currentStrokePoints,
                        sourceAnchor: (_continuedSourceAnchor != null)
                            ? _continuedSourceAnchor
                            : (state.activeCloneOffset != null)
                                ? (_currentStrokePoints.first +
                                    state.activeCloneOffset!)
                                : state.activeSourceAnchor,
                        targetAnchor: _currentStrokePoints.first,
                      )
                    : _heldPreviewStroke;
            final Offset? previewSourceAnchor = _currentStrokePoints.isNotEmpty
                ? ((_continuedSourceAnchor != null)
                    ? _continuedSourceAnchor
                    : (state.activeCloneOffset != null)
                        ? _currentStrokePoints.first + state.activeCloneOffset!
                        : state.activeSourceAnchor)
                : _heldPreviewSourceAnchor;

            return MouseRegion(
              onHover: (e) {
                if (state.activeMode != RetouchMode.none) {
                  setState(() => _activeScreenPosition = e.localPosition);
                }
              },
              onExit: (_) => setState(() => _activeScreenPosition = null),
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _transformationController,
                    panEnabled: isPanEnabled,
                    scaleEnabled: true,
                    minScale: _minScale,
                    maxScale: _maxScale,
                    onInteractionUpdate: (details) {
                      if (details.scale != 1.0) {
                        setState(() => _activeScreenPosition = null);
                      }
                    },
                    child: GestureDetector(
                      onPanDown: (d) {},
                      onPanStart: isPanEnabled
                          ? null
                          : (details) =>
                              _onPanStart(details, currentDisplayRect),
                      onPanUpdate: isPanEnabled
                          ? null
                          : (details) =>
                              _onPanUpdate(details, currentDisplayRect),
                      onPanEnd: isPanEnabled ? null : _onPanEnd,
                      child: Stack(
                        alignment: Alignment.center,
                        fit: StackFit.expand,
                        children: [
                          RepaintBoundary(
                            child: RawImage(
                              image: widget.displayImage,
                              fit: BoxFit.contain,
                            ),
                          ),
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: CanvasPreviewPainter(
                                operations: state.operations,
                                inProgressStroke: previewStroke,
                                inProgressSourceAnchor: previewSourceAnchor,
                                activeBrushPosition:
                                    _activeScreenPosition != null
                                        ? MatrixUtils.transformPoint(
                                            Matrix4.inverted(
                                              _transformationController.value,
                                            ),
                                            _activeScreenPosition!,
                                          )
                                        : null,
                                brushSize: state.activeBrushSettings.size,
                                imageRect: currentDisplayRect,
                                imageSize: Size(
                                  widget.displayImage.width.toDouble(),
                                  widget.displayImage.height.toDouble(),
                                ),
                                baseImage: widget.displayImage,
                                originalImage: widget.originalImage,
                              ),
                            ),
                          ),
                          if (_isDefiningSource)
                            const Center(
                              child: Text(
                                'Tap to set Source Point',
                                style: TextStyle(
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!isPanEnabled && _activeScreenPosition != null)
                    Positioned(
                      left: 16,
                      top: 16,
                      child: _RetouchLoupe(
                        focalPoint: _activeScreenPosition!,
                        transform: _transformationController.value,
                        canvasSize: constraints.biggest,
                        displayImage: widget.displayImage,
                        operations: state.operations,
                        inProgressStroke: previewStroke,
                        inProgressSourceAnchor: previewSourceAnchor,
                        brushSize: state.activeBrushSettings.size,
                        imageRect: currentDisplayRect,
                        imageSize: Size(
                          widget.displayImage.width.toDouble(),
                          widget.displayImage.height.toDouble(),
                        ),
                        zoomScale: _currentScale,
                        loupeScale: _loupeScaleFor(_currentScale),
                        originalImage: widget.originalImage,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RetouchLoupe extends StatelessWidget {
  final Offset focalPoint;
  final Matrix4 transform;
  final Size canvasSize;
  final ui.Image displayImage;
  final ui.Image originalImage;
  final List<RetouchOperation> operations;
  final StrokeOperation? inProgressStroke;
  final Offset? inProgressSourceAnchor;
  final double brushSize;
  final Rect imageRect;
  final Size imageSize;
  final double zoomScale;
  final double loupeScale;

  const _RetouchLoupe({
    required this.focalPoint,
    required this.transform,
    required this.canvasSize,
    required this.displayImage,
    required this.originalImage,
    required this.operations,
    required this.inProgressStroke,
    required this.inProgressSourceAnchor,
    required this.brushSize,
    required this.imageRect,
    required this.imageSize,
    required this.zoomScale,
    required this.loupeScale,
  });

  @override
  Widget build(BuildContext context) {
    const double loupeSize = 156;
    final Offset untransformedPoint =
        MatrixUtils.transformPoint(Matrix4.inverted(transform), focalPoint);

    return Container(
      width: loupeSize,
      height: loupeSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF56E39F).withValues(alpha: 0.9),
          width: 2,
        ),
        color: const Color(0xFF090909),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Transform(
              alignment: Alignment.topLeft,
              transform: Matrix4.identity()
                ..translate(loupeSize / 2, loupeSize / 2)
                ..scale(loupeScale)
                ..translate(-untransformedPoint.dx, -untransformedPoint.dy)
                ..multiply(transform),
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    RawImage(
                      image: displayImage,
                      fit: BoxFit.contain,
                    ),
                    CustomPaint(
                      painter: CanvasPreviewPainter(
                        operations: operations,
                        inProgressStroke: inProgressStroke,
                        inProgressSourceAnchor: inProgressSourceAnchor,
                        activeBrushPosition: untransformedPoint,
                        brushSize: brushSize,
                        imageRect: imageRect,
                        imageSize: imageSize,
                        baseImage: displayImage,
                        originalImage: originalImage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Zoom ${zoomScale.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'Brush ${brushSize.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFFBFF6DB),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
