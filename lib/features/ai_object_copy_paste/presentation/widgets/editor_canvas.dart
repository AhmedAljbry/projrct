import 'package:flutter/material.dart';

import '../../domain/entities/editor_models.dart';
import '../controllers/ai_object_copy_paste_controller.dart';

enum _CanvasDragMode {
  none,
  drawing,
  moveSelection,
  resizeSelection,
  panZoom,
}

class EditorCanvas extends StatefulWidget {
  const EditorCanvas({
    super.key,
    required this.controller,
  });

  final AiObjectCopyPasteController controller;

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  _CanvasDragMode _dragMode = _CanvasDragMode.none;
  Offset? _lastImagePoint;
  SelectionHandle? _activeHandle;
  final TransformationController _transformationController =
      TransformationController();
  double _gestureStartScale = 1;
  Offset _gestureStartTranslation = Offset.zero;
  Offset _gestureStartFocalPoint = Offset.zero;

  AiObjectCopyPasteController get controller => widget.controller;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final document = state.activeDocument ?? state.effectiveTargetDocument;
    if (document == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101113),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Text(
            'Import a source image to start selecting objects or regions.',
            style: TextStyle(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final visibleItems = <PastedItem>[
      ...state.items.where((item) => item.targetDocumentId == document.id),
      if (state.pendingItem != null &&
          state.pendingItem!.targetDocumentId == document.id)
        state.pendingItem!,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = _CanvasViewport.fit(
          sourceSize:
              Size(document.width.toDouble(), document.height.toDouble()),
          maxSize: Size(constraints.maxWidth, constraints.maxHeight),
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) =>
              _handleTapDown(details.localPosition, viewport, document),
          onScaleStart: (details) =>
              _handleScaleStart(details, viewport, document),
          onScaleUpdate: (details) => _handleScaleUpdate(details, viewport),
          onScaleEnd: (_) => _handleScaleEnd(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              color: const Color(0xFF070809),
              child: Transform(
                transform: _transformationController.value,
                child: Stack(
                  children: [
                  Positioned.fromRect(
                    rect: viewport.imageRect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: RawImage(
                        image: document.preview,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  if (controller.showItemsOnActiveCanvas)
                    ...visibleItems.map(
                      (item) => _InteractiveItem(
                        key: ValueKey(item.id),
                        item: item,
                        selected: item.id == state.selectedItemId,
                        isPending: state.pendingItem?.id == item.id,
                        viewport: viewport,
                        onTap: () => controller.selectItem(item.id),
                        onChanged: ({center, scale, rotation, commit = false}) {
                          controller.updateSelectedItem(
                            center: center,
                            scale: scale,
                            rotation: rotation,
                            commit: commit,
                          );
                        },
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SelectionPainter(
                          selection: state.selection,
                          activeDocumentId: document.id,
                          viewport: viewport,
                          selectedItemRect: controller.selectedItem == null
                              ? null
                              : controller
                                  .transformedRect(controller.selectedItem!),
                          showItemBounds: controller.selectedItem != null &&
                              controller.showItemsOnActiveCanvas,
                          showSmartCursor: state.interactionMode ==
                                  CanvasInteractionMode.smartTap ||
                              state.interactionMode ==
                                  CanvasInteractionMode.smartPersonTap,
                          hasPendingPreview: state.pendingItem != null &&
                              state.pendingItem!.targetDocumentId ==
                                  document.id,
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTapDown(
      Offset localPosition, _CanvasViewport viewport, EditorDocument document) {
    final state = controller.state;
    final imagePoint = _transformedLocalToImage(localPosition, viewport);
    final selection = state.selection;
    if (selection != null && selection.documentId == document.id) {
      if (_hitDeleteHandle(selection, imagePoint, viewport)) {
        controller.deleteSelection();
        _dragMode = _CanvasDragMode.none;
        return;
      }
    }
    if (state.interactionMode == CanvasInteractionMode.smartTap) {
      controller.runSmartSelectionAtPoint(imagePoint);
      _dragMode = _CanvasDragMode.none;
      return;
    }
    if (state.interactionMode == CanvasInteractionMode.smartPersonTap) {
      controller.runPeopleSelectionAtPoint(imagePoint);
      _dragMode = _CanvasDragMode.none;
      return;
    }
    if (state.interactionMode == CanvasInteractionMode.transform) {
      controller.clearSelection();
    }
  }

  void _handleScaleStart(
      ScaleStartDetails details, _CanvasViewport viewport, EditorDocument document) {
    final state = controller.state;
    _gestureStartScale = _currentCanvasScale;
    _gestureStartTranslation = _currentCanvasTranslation;
    _gestureStartFocalPoint = details.localFocalPoint;

    if (details.pointerCount > 1) {
      _dragMode = _CanvasDragMode.panZoom;
      _lastImagePoint = null;
      _activeHandle = null;
      return;
    }

    if (state.interactionMode == CanvasInteractionMode.transform ||
        state.interactionMode == CanvasInteractionMode.smartTap ||
        state.interactionMode == CanvasInteractionMode.smartPersonTap) {
      _dragMode = _CanvasDragMode.none;
      return;
    }
    final imagePoint = _transformedLocalToImage(details.localFocalPoint, viewport);
    _lastImagePoint = imagePoint;
    final selection = state.selection;
    if (selection != null && selection.documentId == document.id) {
      final handleHit = _hitResizeHandle(selection, imagePoint, viewport);
      final selectionHit = _hitSelection(selection, imagePoint, viewport);
      if (handleHit != null) {
        _dragMode = _CanvasDragMode.resizeSelection;
        _activeHandle = handleHit;
        controller.beginSelectionResize();
        return;
      }
      if (selectionHit) {
        _dragMode = _CanvasDragMode.moveSelection;
        _activeHandle = null;
        return;
      }
    }
    _dragMode = _CanvasDragMode.drawing;
    _activeHandle = null;
    controller.beginSelection(imagePoint);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, _CanvasViewport viewport) {
    if (details.pointerCount > 1 || _dragMode == _CanvasDragMode.panZoom) {
      _dragMode = _CanvasDragMode.panZoom;
      _updateCanvasTransform(details);
      return;
    }

    final imagePoint = _transformedLocalToImage(details.localFocalPoint, viewport);
    switch (_dragMode) {
      case _CanvasDragMode.drawing:
        controller.updateSelection(imagePoint);
        break;
      case _CanvasDragMode.moveSelection:
        final previous = _lastImagePoint;
        if (previous != null) {
          controller.translateSelectionBy(imagePoint - previous);
        }
        break;
      case _CanvasDragMode.resizeSelection:
        controller.resizeSelectionFromHandle(
          imagePoint: imagePoint,
          handle: _activeHandle ?? SelectionHandle.bottomRight,
        );
        break;
      case _CanvasDragMode.panZoom:
        _updateCanvasTransform(details);
        break;
      case _CanvasDragMode.none:
        break;
    }
    _lastImagePoint = imagePoint;
  }

  void _handleScaleEnd() {
    switch (_dragMode) {
      case _CanvasDragMode.drawing:
        controller.endSelection();
        break;
      case _CanvasDragMode.moveSelection:
      case _CanvasDragMode.resizeSelection:
        controller.commitSelectionEdit();
        break;
      case _CanvasDragMode.panZoom:
      case _CanvasDragMode.none:
        break;
    }
    _dragMode = _CanvasDragMode.none;
    _lastImagePoint = null;
    _activeHandle = null;
  }

  bool _hitSelection(
      SelectionRegion selection, Offset imagePoint, _CanvasViewport viewport) {
    if (selection.tool == SelectionTool.smart && selection.maskData != null) {
      return _hitSmartMask(selection, imagePoint, viewport);
    }
    final padding = 18 / viewport.scale;
    return selection.bounds.inflate(padding).contains(imagePoint);
  }

  bool _hitSmartMask(
    SelectionRegion selection,
    Offset imagePoint,
    _CanvasViewport viewport,
  ) {
    final mask = selection.maskData;
    if (mask == null || !selection.bounds.inflate(12 / viewport.scale).contains(imagePoint)) {
      return false;
    }
    final localX = (((imagePoint.dx - selection.bounds.left) / selection.bounds.width) *
            mask.width)
        .floor()
        .clamp(0, mask.width - 1);
    final localY = (((imagePoint.dy - selection.bounds.top) / selection.bounds.height) *
            mask.height)
        .floor()
        .clamp(0, mask.height - 1);
    return mask.alpha[localY * mask.width + localX] >= 24;
  }

  SelectionHandle? _hitResizeHandle(
      SelectionRegion selection, Offset imagePoint, _CanvasViewport viewport) {
    final radius = 24 / viewport.scale;
    final handles = <SelectionHandle, Offset>{
      SelectionHandle.topLeft: selection.bounds.topLeft,
      SelectionHandle.topRight: selection.bounds.topRight,
      SelectionHandle.bottomLeft: selection.bounds.bottomLeft,
      SelectionHandle.bottomRight: selection.bounds.bottomRight,
    };
    for (final entry in handles.entries) {
      if ((entry.value - imagePoint).distance <= radius) {
        return entry.key;
      }
    }
    return null;
  }

  bool _hitDeleteHandle(
      SelectionRegion selection, Offset imagePoint, _CanvasViewport viewport) {
    final center = Offset(
        selection.bounds.center.dx, selection.bounds.top - 20 / viewport.scale);
    final radius = 22 / viewport.scale;
    return (center - imagePoint).distance <= radius;
  }

  void _updateCanvasTransform(ScaleUpdateDetails details) {
    final desiredScale = (_gestureStartScale * details.scale).clamp(1.0, 5.0);
    final focalDelta = details.localFocalPoint - _gestureStartFocalPoint;
    final translated = _gestureStartTranslation + focalDelta;
    final matrix = Matrix4.identity()
      ..translate(translated.dx, translated.dy)
      ..scale(desiredScale);
    _transformationController.value = matrix;
  }

  Offset _transformedLocalToImage(Offset local, _CanvasViewport viewport) {
    final inverse = Matrix4.inverted(_transformationController.value);
    final corrected = MatrixUtils.transformPoint(inverse, local);
    return viewport.localToImage(corrected);
  }

  double get _currentCanvasScale => _transformationController.value.getMaxScaleOnAxis();

  Offset get _currentCanvasTranslation {
    final storage = _transformationController.value.storage;
    return Offset(storage[12], storage[13]);
  }
}

class _InteractiveItem extends StatefulWidget {
  const _InteractiveItem({
    super.key,
    required this.item,
    required this.selected,
    required this.isPending,
    required this.viewport,
    required this.onTap,
    required this.onChanged,
  });

  final PastedItem item;
  final bool selected;
  final bool isPending;
  final _CanvasViewport viewport;
  final VoidCallback onTap;
  final void Function(
      {Offset? center, double? scale, double? rotation, bool commit}) onChanged;

  @override
  State<_InteractiveItem> createState() => _InteractiveItemState();
}

class _InteractiveItemState extends State<_InteractiveItem> {
  Offset? _startFocalPoint;
  Offset? _startCenter;
  double? _startScale;
  double? _startRotation;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final center = widget.viewport.imageToLocal(item.center);
    final width = item.baseSize.width * item.scale * widget.viewport.scale;
    final height = item.baseSize.height * item.scale * widget.viewport.scale;

    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - height / 2,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: widget.onTap,
        onScaleStart: (details) {
          widget.onTap();
          _startFocalPoint = details.focalPoint;
          _startCenter = item.center;
          _startScale = item.scale;
          _startRotation = item.rotation;
        },
        onScaleUpdate: (details) {
          if (_startFocalPoint == null ||
              _startCenter == null ||
              _startScale == null ||
              _startRotation == null) {
            return;
          }
          final delta = details.focalPoint - _startFocalPoint!;
          widget.onChanged(
            center: _startCenter! +
                Offset(delta.dx / widget.viewport.scale,
                    delta.dy / widget.viewport.scale),
            scale: _startScale! * details.scale,
            rotation: _startRotation! + details.rotation,
          );
        },
        onScaleEnd: (_) => widget.onChanged(commit: true),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scale(item.flipX ? -1.0 : 1.0, item.flipY ? -1.0 : 1.0)
                ..rotateZ(item.rotation),
              child: Opacity(
                opacity: item.opacity,
                child: RawImage(
                  image: item.clipboard.preview,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            if (widget.selected)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.isPending
                        ? const Color(0xFF63D5A3)
                        : Colors.white,
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: widget.isPending
                          ? const Color(0xFF63D5A3)
                          : Colors.white,
                      child: Icon(
                        widget.isPending
                            ? Icons.check_rounded
                            : Icons.open_in_full_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectionPainter extends CustomPainter {
  const _SelectionPainter({
    required this.selection,
    required this.activeDocumentId,
    required this.viewport,
    required this.selectedItemRect,
    required this.showItemBounds,
    required this.showSmartCursor,
    required this.hasPendingPreview,
  });

  final SelectionRegion? selection;
  final String activeDocumentId;
  final _CanvasViewport viewport;
  final Rect? selectedItemRect;
  final bool showItemBounds;
  final bool showSmartCursor;
  final bool hasPendingPreview;

  @override
  void paint(Canvas canvas, Size size) {
    if (showSmartCursor) {
      final center = viewport.imageRect.center;
      final cursorPaint = Paint()
        ..color = const Color(0xFF63D5A3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, 18, cursorPaint);
      canvas.drawLine(center + const Offset(-28, 0),
          center + const Offset(-10, 0), cursorPaint);
      canvas.drawLine(center + const Offset(10, 0),
          center + const Offset(28, 0), cursorPaint);
      canvas.drawLine(center + const Offset(0, -28),
          center + const Offset(0, -10), cursorPaint);
      canvas.drawLine(center + const Offset(0, 10),
          center + const Offset(0, 28), cursorPaint);
    }

    if (selection != null && selection!.documentId == activeDocumentId) {
      final rect = viewport.imageRectFromPixels(selection!.bounds);
      final fillPaint = Paint()..color = const Color(0x1AE287FF);
      final linePaint = Paint()
        ..color = const Color(0xFFE287FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      if (selection!.tool == SelectionTool.smart && selection!.maskData != null) {
        _drawSmartSelection(canvas, selection!, fillPaint, linePaint);
      } else if (selection!.tool == SelectionTool.lasso &&
          selection!.path.length > 2) {
        final first = viewport.imageToLocal(selection!.path.first);
        final path = Path()..moveTo(first.dx, first.dy);
        for (final point in selection!.path.skip(1)) {
          final local = viewport.imageToLocal(point);
          path.lineTo(local.dx, local.dy);
        }
        path.close();
        canvas.drawPath(path, fillPaint);
        _drawDashedPath(canvas, path, linePaint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(6)), fillPaint);
        _drawDashedRect(canvas, rect, linePaint);
      }
      _drawDeleteButton(canvas, rect);
      _drawResizeHandle(canvas, rect);
    }

    if (showItemBounds && selectedItemRect != null) {
      final rect = viewport.imageRectFromPixels(selectedItemRect!);
      final linePaint = Paint()
        ..color = hasPendingPreview ? const Color(0xFF63D5A3) : Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      _drawDashedRect(canvas, rect, linePaint, dash: 7, gap: 6);
    }
  }

  void _drawDeleteButton(Canvas canvas, Rect rect) {
    final center = Offset(rect.center.dx, rect.top - 20);
    canvas.drawCircle(center, 16, Paint()..color = const Color(0xFFE55151));
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        center + const Offset(-5, -5), center + const Offset(5, 5), linePaint);
    canvas.drawLine(
        center + const Offset(5, -5), center + const Offset(-5, 5), linePaint);
  }

  void _drawResizeHandle(Canvas canvas, Rect rect) {
    final handles = <Offset>[
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];
    for (final handle in handles) {
      canvas.drawCircle(handle, 14, Paint()..color = Colors.white);
      canvas.drawCircle(
        handle,
        5,
        Paint()..color = const Color(0xFFE287FF),
      );
    }
  }

  void _drawSmartSelection(
    Canvas canvas,
    SelectionRegion selection,
    Paint fillPaint,
    Paint linePaint,
  ) {
    final mask = selection.maskData!;
    final pixelWidth = selection.bounds.width / mask.width;
    final pixelHeight = selection.bounds.height / mask.height;
    final sampledPath = Path();
    const step = 2;

    for (var y = 0; y < mask.height; y += step) {
      for (var x = 0; x < mask.width; x += step) {
        final alpha = mask.alpha[y * mask.width + x];
        if (alpha < 42) {
          continue;
        }
        final left = selection.bounds.left + x * pixelWidth;
        final top = selection.bounds.top + y * pixelHeight;
        sampledPath.addRRect(
          RRect.fromRectAndRadius(
            viewport.imageRectFromPixels(
              Rect.fromLTWH(left, top, pixelWidth * step, pixelHeight * step),
            ),
            const Radius.circular(1.5),
          ),
        );
      }
    }

    final glowPaint = Paint()
      ..color = const Color(0x33E287FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(sampledPath, glowPaint);
    canvas.drawPath(sampledPath, fillPaint);
    _drawSmartMaskOutline(canvas, selection, linePaint);
  }

  void _drawSmartMaskOutline(
    Canvas canvas,
    SelectionRegion selection,
    Paint linePaint,
  ) {
    final mask = selection.maskData!;
    final pixelWidth = selection.bounds.width / mask.width;
    final pixelHeight = selection.bounds.height / mask.height;
    final outlinePath = Path();
    const step = 2;

    for (var y = 0; y < mask.height; y += step) {
      for (var x = 0; x < mask.width; x += step) {
        final alpha = mask.alpha[y * mask.width + x];
        if (alpha < 58) {
          continue;
        }
        final left = selection.bounds.left + x * pixelWidth;
        final top = selection.bounds.top + y * pixelHeight;
        final current = viewport.imageRectFromPixels(
          Rect.fromLTWH(left, top, pixelWidth * step, pixelHeight * step),
        );

        bool isEdge(int nx, int ny) {
          if (nx < 0 || ny < 0 || nx >= mask.width || ny >= mask.height) {
            return true;
          }
          return mask.alpha[ny * mask.width + nx] < 58;
        }

        if (isEdge(x, y - step)) {
          outlinePath.moveTo(current.left, current.top);
          outlinePath.lineTo(current.right, current.top);
        }
        if (isEdge(x + step, y)) {
          outlinePath.moveTo(current.right, current.top);
          outlinePath.lineTo(current.right, current.bottom);
        }
        if (isEdge(x, y + step)) {
          outlinePath.moveTo(current.left, current.bottom);
          outlinePath.lineTo(current.right, current.bottom);
        }
        if (isEdge(x - step, y)) {
          outlinePath.moveTo(current.left, current.top);
          outlinePath.lineTo(current.left, current.bottom);
        }
      }
    }

    _drawDashedPath(canvas, outlinePath, linePaint, dash: 10, gap: 5);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint,
      {double dash = 10, double gap = 6}) {
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint,
        dash: dash, gap: gap);
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint,
        dash: dash, gap: gap);
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint,
        dash: dash, gap: gap);
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint,
        dash: dash, gap: gap);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {double dash = 10, double gap = 6}) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final segment = metric.extractPath(
            distance, (distance + dash).clamp(0.0, metric.length));
        canvas.drawPath(segment, paint);
        distance += dash + gap;
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      {double dash = 10, double gap = 6}) {
    final total = (end - start).distance;
    if (total == 0) {
      return;
    }
    final direction = (end - start) / total;
    var distance = 0.0;
    while (distance < total) {
      final from = start + direction * distance;
      final to = start + direction * (distance + dash).clamp(0.0, total);
      canvas.drawLine(from, to, paint);
      distance += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) {
    return oldDelegate.selection != selection ||
        oldDelegate.selectedItemRect != selectedItemRect ||
        oldDelegate.showSmartCursor != showSmartCursor ||
        oldDelegate.hasPendingPreview != hasPendingPreview;
  }
}

class _CanvasViewport {
  const _CanvasViewport({
    required this.imageRect,
    required this.scale,
  });

  final Rect imageRect;
  final double scale;

  factory _CanvasViewport.fit(
      {required Size sourceSize, required Size maxSize}) {
    final fitted = applyBoxFit(BoxFit.contain, sourceSize, maxSize);
    final imageSize = fitted.destination;
    final offset = Offset(
      (maxSize.width - imageSize.width) / 2,
      (maxSize.height - imageSize.height) / 2,
    );
    return _CanvasViewport(
      imageRect: offset & imageSize,
      scale: imageSize.width / sourceSize.width,
    );
  }

  Offset localToImage(Offset local) {
    return Offset(
      ((local.dx - imageRect.left) / scale).clamp(0.0, imageRect.width / scale),
      ((local.dy - imageRect.top) / scale).clamp(0.0, imageRect.height / scale),
    );
  }

  Offset imageToLocal(Offset imagePoint) {
    return Offset(
      imageRect.left + imagePoint.dx * scale,
      imageRect.top + imagePoint.dy * scale,
    );
  }

  Rect imageRectFromPixels(Rect rect) {
    final topLeft = imageToLocal(rect.topLeft);
    return Rect.fromLTWH(
        topLeft.dx, topLeft.dy, rect.width * scale, rect.height * scale);
  }
}

