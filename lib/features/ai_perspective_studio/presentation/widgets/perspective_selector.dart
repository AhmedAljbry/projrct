import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled2/features/ai_perspective_studio/domain/models/perspective_points.dart';


class PerspectiveSelector extends StatefulWidget {
  final ui.Image image;
  final PerspectivePoints points;
  final ValueChanged<PerspectivePoints> onPointsChanged;

  const PerspectiveSelector({
    super.key,
    required this.image,
    required this.points,
    required this.onPointsChanged,
  });

  @override
  State<PerspectiveSelector> createState() => _PerspectiveSelectorState();
}

class _PerspectiveSelectorState extends State<PerspectiveSelector> {
  final double handleRadius = 14.0;
  final Color themeColor = const Color(0xFF56E39F);
  
  // Use ValueNotifier to track points for 60fps smoothness without full-screen rebuilds
  late ValueNotifier<PerspectivePoints> _pointsNotifier;
  Offset? _draggingPosition;
  int? _draggingHandleIndex;

  @override
  void initState() {
    super.initState();
    _pointsNotifier = ValueNotifier(widget.points);
  }

  @override
  void didUpdateWidget(PerspectiveSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points && _draggingHandleIndex == null) {
      _pointsNotifier.value = widget.points;
    }
  }

  @override
  void dispose() {
    _pointsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double viewWidth = constraints.maxWidth;
        final double viewHeight = constraints.maxHeight;
        
        final double imgWidth = widget.image.width.toDouble();
        final double imgHeight = widget.image.height.toDouble();
        
        final double scale = _calculateScale(viewWidth, viewHeight, imgWidth, imgHeight);
        final double displayWidth = imgWidth * scale;
        final double displayHeight = imgHeight * scale;
        
        final double offsetX = (viewWidth - displayWidth) / 2;
        final double offsetY = (viewHeight - displayHeight) / 2;

        Offset toView(Offset imgCoord) {
          return Offset(
            offsetX + (imgCoord.dx * scale),
            offsetY + (imgCoord.dy * scale),
          );
        }

        Offset toImage(Offset viewCoord) {
          double ix = (viewCoord.dx - offsetX) / scale;
          double iy = (viewCoord.dy - offsetY) / scale;
          return Offset(ix.clamp(0, imgWidth), iy.clamp(0, imgHeight));
        }

        return Stack(
          children: [
            // ── STATIC BACKGROUND ──────────────────────────────────────────
            RepaintBoundary(
              child: Center(
                child: RawImage(
                  image: widget.image,
                  width: displayWidth,
                  height: displayHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // ── DYNAMIC LINES ─────────────────────────────────────────────
            CustomPaint(
              size: Size(viewWidth, viewHeight),
              painter: _PerspectivePainter(
                listenable: _pointsNotifier,
                toView: toView,
                color: themeColor,
              ),
            ),

            // ── DYNAMIC HANDLES & MAGNIFIER ────────────────────────────────
            ValueListenableBuilder<PerspectivePoints>(
              valueListenable: _pointsNotifier,
              builder: (context, pts, _) {
                final vTL = toView(pts.topLeft);
                final vTR = toView(pts.topRight);
                final vBL = toView(pts.bottomLeft);
                final vBR = toView(pts.bottomRight);

                return Stack(
                  children: [
                    _buildHandle(0, vTL, (d) => _updatePoint(0, toImage(d))),
                    _buildHandle(1, vTR, (d) => _updatePoint(1, toImage(d))),
                    _buildHandle(3, vBL, (d) => _updatePoint(3, toImage(d))),
                    _buildHandle(2, vBR, (d) => _updatePoint(2, toImage(d))),

                    if (_draggingPosition != null)
                      _buildMagnifier(_draggingPosition!, scale, offsetX, offsetY),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _updatePoint(int index, Offset newPos) {
    final current = _pointsNotifier.value;
    switch (index) {
      case 0: _pointsNotifier.value = current.copyWith(topLeft: newPos); break;
      case 1: _pointsNotifier.value = current.copyWith(topRight: newPos); break;
      case 2: _pointsNotifier.value = current.copyWith(bottomRight: newPos); break;
      case 3: _pointsNotifier.value = current.copyWith(bottomLeft: newPos); break;
    }
  }

  double _calculateScale(double vw, double vh, double iw, double ih) {
    return (vw / vh > iw / ih) ? vh / ih : vw / iw;
  }

  Widget _buildHandle(int index, Offset position, ValueChanged<Offset> onDrag) {
    return Positioned(
      left: position.dx - (handleRadius * 1.5),
      top: position.dy - (handleRadius * 1.5),
      child: GestureDetector(
        onPanStart: (_) {
          HapticFeedback.lightImpact();
          setState(() {
            _draggingHandleIndex = index;
            _draggingPosition = position;
          });
        },
        onPanUpdate: (details) {
          final nextPos = position + details.delta;
          setState(() => _draggingPosition = nextPos);
          onDrag(nextPos);
        },
        onPanEnd: (_) {
          HapticFeedback.mediumImpact();
          widget.onPointsChanged(_pointsNotifier.value);
          setState(() {
            _draggingPosition = null;
            _draggingHandleIndex = null;
          });
        },
        child: Container(
          width: handleRadius * 3,
          height: handleRadius * 3,
          color: Colors.transparent, 
          child: Center(
            child: Container(
              width: handleRadius * 2,
              height: handleRadius * 2,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMagnifier(Offset position, double scale, double ox, double oy) {
    return Positioned(
      left: position.dx - 60,
      top: position.dy - 140,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: themeColor, width: 2.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _MagnifierImageDisplay(
          image: widget.image,
          viewPosition: position,
          imageScale: scale,
          offsetX: ox,
          offsetY: oy,
        ),
      ),
    );
  }
}

class _MagnifierImageDisplay extends StatelessWidget {
  final ui.Image image;
  final Offset viewPosition;
  final double imageScale;
  final double offsetX;
  final double offsetY;

  const _MagnifierImageDisplay({
    required this.image,
    required this.viewPosition,
    required this.imageScale,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  Widget build(BuildContext context) {
    const double magnifierZoom = 1.6;
    final double totalScale = imageScale * magnifierZoom;
    
    // Map view position back to image space
    final double imgX = (viewPosition.dx - offsetX) / imageScale;
    final double imgY = (viewPosition.dy - offsetY) / imageScale;

    return CustomPaint(
      painter: _MagnifierPainter(
        image: image,
        imgX: imgX,
        imgY: imgY,
        totalScale: totalScale,
      ),
    );
  }
}

class _MagnifierPainter extends CustomPainter {
  final ui.Image image;
  final double imgX;
  final double imgY;
  final double totalScale;

  _MagnifierPainter({
    required this.image,
    required this.imgX,
    required this.imgY,
    required this.totalScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    
    // Calculate the source Rect in the image
    // Center is (imgX, imgY)
    // Width in image space is (size.width / totalScale)
    final double srcW = size.width / totalScale;
    final double srcH = size.height / totalScale;
    
    final Rect src = Rect.fromCenter(
      center: Offset(imgX, imgY),
      width: srcW,
      height: srcH,
    );

    final Rect dst = Offset.zero & size;

    canvas.drawRect(dst, Paint()..color = Colors.black);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = ui.FilterQuality.medium);

    // Crosshair in the middle of the magnifier
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center - 10, center), Offset(center + 10, center), crossPaint);
    canvas.drawLine(Offset(center, center - 10), Offset(center, center + 10), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _MagnifierPainter oldDelegate) => 
      oldDelegate.imgX != imgX || oldDelegate.imgY != imgY;
}

class _PerspectivePainter extends CustomPainter {
  final ValueNotifier<PerspectivePoints> listenable;
  final Offset Function(Offset) toView;
  final Color color;

  _PerspectivePainter({
    required this.listenable,
    required this.toView,
    required this.color,
  }) : super(repaint: listenable);

  @override
  void paint(Canvas canvas, Size size) {
    // Only print sometimes to avoid log flooding
    if (DateTime.now().millisecond % 100 == 0) {
      debugPrint('Painter: Repainting layer');
    }
    final pts = listenable.value;
    final points = [
      toView(pts.topLeft),
      toView(pts.topRight),
      toView(pts.bottomRight),
      toView(pts.bottomLeft),
    ];
    
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..addPolygon(points, true);
    
    // Draw edges
    canvas.drawPath(path, paint);
    
    // Fill slightly
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _PerspectivePainter oldDelegate) => 
      oldDelegate.listenable != listenable;
}
