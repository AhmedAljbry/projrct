import 'package:flutter/material.dart';

import '../../domain/entities/editor_models.dart';
import '../controllers/ai_object_copy_paste_controller.dart';

enum _CanvasDragMode {
  none,
  drawing,
  moveSelection,
  resizeSelection,
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

  AiObjectCopyPasteController get controller => widget.controller;

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
          onPanStart: (details) =>
              _handlePanStart(details.localPosition, viewport, document),
          onPanUpdate: (details) =>
              _handlePanUpdate(details.localPosition, viewport),
          onPanEnd: (_) => _handlePanEnd(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              color: const Color(0xFF070809),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                boundaryMargin: const EdgeInsets.all(140),
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
    final imagePoint = viewport.localToImage(localPosition);
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

  void _handlePanStart(
      Offset localPosition, _CanvasViewport viewport, EditorDocument document) {
    final state = controller.state;
    if (state.interactionMode == CanvasInteractionMode.transform ||
        state.interactionMode == CanvasInteractionMode.smartTap ||
        state.interactionMode == CanvasInteractionMode.smartPersonTap) {
      _dragMode = _CanvasDragMode.none;
      return;
    }
    final imagePoint = viewport.localToImage(localPosition);
    _lastImagePoint = imagePoint;
    final selection = state.selection;
    if (selection != null && selection.documentId == document.id) {
      final handleHit = _hitResizeHandle(selection, imagePoint, viewport);
      final selectionHit = _hitSelection(selection, imagePoint, viewport);
      if (handleHit) {
        _dragMode = _CanvasDragMode.resizeSelection;
        return;
      }
      if (selectionHit) {
        _dragMode = _CanvasDragMode.moveSelection;
        return;
      }
    }
    _dragMode = _CanvasDragMode.drawing;
    controller.beginSelection(imagePoint);
  }

  void _handlePanUpdate(Offset localPosition, _CanvasViewport viewport) {
    final imagePoint = viewport.localToImage(localPosition);
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
        controller.resizeSelectionToPoint(imagePoint);
        break;
      case _CanvasDragMode.none:
        break;
    }
    _lastImagePoint = imagePoint;
  }

  void _handlePanEnd() {
    switch (_dragMode) {
      case _CanvasDragMode.drawing:
        controller.endSelection();
        break;
      case _CanvasDragMode.moveSelection:
      case _CanvasDragMode.resizeSelection:
        controller.commitSelectionEdit();
        break;
      case _CanvasDragMode.none:
        break;
    }
    _dragMode = _CanvasDragMode.none;
    _lastImagePoint = null;
  }

  bool _hitSelection(
      SelectionRegion selection, Offset imagePoint, _CanvasViewport viewport) {
    final padding = 18 / viewport.scale;
    return selection.bounds.inflate(padding).contains(imagePoint);
  }

  bool _hitResizeHandle(
      SelectionRegion selection, Offset imagePoint, _CanvasViewport viewport) {
    final radius = 24 / viewport.scale;
    return (selection.bounds.bottomRight - imagePoint).distance <= radius;
  }

  bool _hitDeleteHandle(
      SelectionRegion selection, Offset imagePoint, _CanvasViewport viewport) {
    final center = Offset(
        selection.bounds.center.dx, selection.bounds.top - 20 / viewport.scale);
    final radius = 22 / viewport.scale;
    return (center - imagePoint).distance <= radius;
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
      if (selection!.tool == SelectionTool.lasso &&
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
    final handleCenter = rect.bottomRight + const Offset(6, 6);
    canvas.drawCircle(handleCenter, 18, Paint()..color = Colors.white);
    final iconPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(handleCenter + const Offset(-5, -5),
        handleCenter + const Offset(5, 5), iconPaint);
    canvas.drawLine(handleCenter + const Offset(1, -5),
        handleCenter + const Offset(5, -5), iconPaint);
    canvas.drawLine(handleCenter + const Offset(5, -5),
        handleCenter + const Offset(5, -1), iconPaint);
    canvas.drawLine(handleCenter + const Offset(-5, 1),
        handleCenter + const Offset(-5, 5), iconPaint);
    canvas.drawLine(handleCenter + const Offset(-5, 5),
        handleCenter + const Offset(-1, 5), iconPaint);
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
