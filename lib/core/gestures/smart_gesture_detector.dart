import 'package:flutter/material.dart';

class SmartGestureDetector extends StatefulWidget {
  final Widget child;
  
  // Drawing callbacks
  final void Function(Offset localPosition)? onDrawStart;
  final void Function(Offset localPosition, double velocity)? onDrawUpdate;
  final void Function()? onDrawEnd;

  // Viewport transforms
  final void Function(Matrix4 transform)? onTransformUpdated;

  const SmartGestureDetector({
    super.key,
    required this.child,
    this.onDrawStart,
    this.onDrawUpdate,
    this.onDrawEnd,
    this.onTransformUpdated,
  });

  @override
  State<SmartGestureDetector> createState() => _SmartGestureDetectorState();
}

class _SmartGestureDetectorState extends State<SmartGestureDetector> {
  final TransformationController _transformController = TransformationController();
  
  Offset? _lastDrawPoint;
  int _pointerCount = 0;
  bool _isDrawing = false;
  DateTime? _lastDrawTime;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(() {
      widget.onTransformUpdated?.call(_transformController.value);
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use InteractiveViewer for built-in high performance panning and zooming
    // And Listener to detect pointer count to disable drawing when zooming.
    
    return Listener(
      onPointerDown: (event) {
        _pointerCount++;
        if (_pointerCount == 1) {
           _isDrawing = true;
           _lastDrawPoint = event.localPosition;
           _lastDrawTime = DateTime.now();
           widget.onDrawStart?.call(event.localPosition);
        } else {
           _isDrawing = false;
           // If a second finger touches down, we cancel the drawing stroke
           widget.onDrawEnd?.call(); 
        }
      },
      onPointerMove: (event) {
        if (_isDrawing && _pointerCount == 1 && _lastDrawPoint != null) {
           // Calculate simulated velocity (distance / time)
           final now = DateTime.now();
           double velocity = 0.0;
           
           if (_lastDrawTime != null) {
              final ms = now.difference(_lastDrawTime!).inMilliseconds.toDouble();
              if (ms > 0) {
                 final distance = (event.localPosition - _lastDrawPoint!).distance;
                 velocity = distance / ms * 1000.0; // px per second
              }
           }
           
           widget.onDrawUpdate?.call(event.localPosition, velocity);
           
           _lastDrawPoint = event.localPosition;
           _lastDrawTime = now;
        }
      },
      onPointerUp: (event) {
        _pointerCount--;
        if (_pointerCount <= 0) {
           _pointerCount = 0;
           if (_isDrawing) {
              widget.onDrawEnd?.call();
           }
           _isDrawing = false;
        }
      },
      onPointerCancel: (event) {
        _pointerCount = 0;
        _isDrawing = false;
        widget.onDrawEnd?.call();
      },
      child: InteractiveViewer(
        transformationController: _transformController,
        // Disable interactive viewer transforms if we only have 1 pointer (drawing)
        panEnabled: _pointerCount > 1,
        scaleEnabled: _pointerCount > 1,
        minScale: 1.0,
        maxScale: 10.0, // allowed deep zoom
        // Center focus zooming is default in InteractiveViewer
        clipBehavior: Clip.hardEdge,
        child: widget.child,
      ),
    );
  }
}
