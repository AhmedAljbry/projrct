part of 'editor_page.dart';

extension _EditorPageGestures on _EditorPageState {
  void _handlePointerDown(BuildContext context) {
    _activePointers += 1;
    if (_activePointers > 1 && _isDrawingStroke) {
      _finishStroke(context);
    }
  }

  void _handlePointerEnd() {
    _activePointers = math.max(0, _activePointers - 1);
  }

  void _onPointerSignal(PointerSignalEvent event, Size canvasSize) {
    if (event is! PointerScrollEvent) {
      return;
    }

    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }

    final focalPoint = box.globalToLocal(event.position);
    final sceneFocalPoint = _viewportController.toScene(focalPoint);
    final zoomFactor = event.scrollDelta.dy < 0 ? 1.08 : 0.92;
    final targetScale = (_currentViewportScale * zoomFactor)
        .clamp(
          _EditorPageState._minViewportScale,
          _EditorPageState._maxViewportScale,
        )
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

  void _onScaleStart(
    BuildContext context,
    ScaleStartDetails details,
    Size canvasSize,
  ) {
    if (_activePointers > 1) {
      _startViewportGesture(details.localFocalPoint, canvasSize);
      return;
    }

    _startStroke(context, details.localFocalPoint, canvasSize);
  }

  void _onScaleUpdate(
    BuildContext context,
    ScaleUpdateDetails details,
    Size canvasSize,
  ) {
    if (_activePointers > 1) {
      if (!_isViewportGestureActive) {
        _startViewportGesture(details.localFocalPoint, canvasSize);
      }
      _updateViewportGesture(
          details.localFocalPoint, details.scale, canvasSize);
      return;
    }

    if (_isViewportGestureActive) {
      return;
    }

    _updateStroke(context, details.localFocalPoint, canvasSize);
  }

  void _onScaleEnd(BuildContext context) {
    if (_isViewportGestureActive) {
      _endViewportGesture();
      return;
    }

    if (_isDrawingStroke) {
      _finishStroke(context);
    }
  }

  void _startStroke(
    BuildContext context,
    Offset viewportPoint,
    Size canvasSize,
  ) {
    if (_showOriginalPreview) {
      return;
    }

    final pickState = context.read<ImagePickCubit>().state;
    if (pickState is! ImagePickReady) {
      return;
    }

    final imagePoint = _viewportPointToImagePx(
      viewportPoint,
      canvasSize,
      pickState.uiImage,
    );

    _updateEditorUi(() {
      _cursorPoint = viewportPoint;
      _magnifierImagePoint = imagePoint;
    });

    if (imagePoint == null) {
      _isDrawingStroke = false;
      return;
    }

    _isDrawingStroke = true;

    final drawingState = context.read<DrawingCubit>().state;
    context.read<DrawingCubit>().startStrokeImagePx(
          imagePoint,
          widthPx: _brushWidgetPxToImagePx(
            drawingState.brushSize,
            canvasSize,
            pickState.uiImage.width,
            pickState.uiImage.height,
          ),
        );
  }

  void _updateStroke(
    BuildContext context,
    Offset viewportPoint,
    Size canvasSize,
  ) {
    if (_showOriginalPreview) {
      return;
    }

    final pickState = context.read<ImagePickCubit>().state;
    if (pickState is! ImagePickReady) {
      return;
    }

    final imagePoint = _viewportPointToImagePx(
      viewportPoint,
      canvasSize,
      pickState.uiImage,
    );

    _updateEditorUi(() {
      _cursorPoint = viewportPoint;
      _magnifierImagePoint = imagePoint;
    });

    if (imagePoint == null) {
      return;
    }

    if (!_isDrawingStroke) {
      _startStroke(context, viewportPoint, canvasSize);
      return;
    }

    context.read<DrawingCubit>().addPointImagePx(imagePoint);
  }

  void _finishStroke(BuildContext context) {
    context.read<DrawingCubit>().endStroke();
    _updateEditorUi(() {
      _isDrawingStroke = false;
      _cursorPoint = null;
      _magnifierImagePoint = null;
    });
  }

  void _startViewportGesture(Offset focalPoint, Size canvasSize) {
    _updateEditorUi(() {
      _isViewportGestureActive = true;
      _isDrawingStroke = false;
      _cursorPoint = null;
      _magnifierImagePoint = null;
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
        .clamp(
          _EditorPageState._minViewportScale,
          _EditorPageState._maxViewportScale,
        )
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
    _updateEditorUi(() {
      _isViewportGestureActive = false;
      _gestureSceneFocalPoint = null;
    });
  }

  void _resetViewport() {
    _viewportController.value = Matrix4.identity();
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
    final scale = matrix
        .getMaxScaleOnAxis()
        .clamp(
          _EditorPageState._minViewportScale,
          _EditorPageState._maxViewportScale,
        )
        .toDouble();

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

  double get _currentViewportScale =>
      _viewportController.value.getMaxScaleOnAxis();

  Offset? _viewportPointToImagePx(
    Offset viewportPoint,
    Size canvasSize,
    ui.Image image,
  ) {
    final scenePoint = _viewportController.toScene(viewportPoint);
    final p01 = widgetPointToImage01(
      widgetPoint: scenePoint,
      widgetSize: canvasSize,
      imageW: image.width,
      imageH: image.height,
      fit: BoxFit.contain,
    );
    if (p01 == null) {
      return null;
    }

    return Offset(
      p01.dx * image.width,
      p01.dy * image.height,
    );
  }

  double _brushWidgetPxToImagePx(
    double brushWidgetPx,
    Size widgetSize,
    int imageW,
    int imageH,
  ) {
    final scaleX = widgetSize.width / imageW;
    final scaleY = widgetSize.height / imageH;
    final containScale = scaleX < scaleY ? scaleX : scaleY;

    return (brushWidgetPx / (containScale * _currentViewportScale))
        .clamp(1.0, 600.0);
  }
}
