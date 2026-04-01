import 'package:flutter/material.dart';

class RepairDamageMagnifier extends StatelessWidget {
  const RepairDamageMagnifier({
    super.key,
    required this.focalViewportPoint,
    required this.canvasSize,
    required this.transform,
    required this.sceneBuilder,
    required this.accentColor,
    this.diameter = 136,
    this.magnification = 1.9,
  });

  final Offset focalViewportPoint;
  final Size canvasSize;
  final Matrix4 transform;
  final WidgetBuilder sceneBuilder;
  final Color accentColor;
  final double diameter;
  final double magnification;

  @override
  Widget build(BuildContext context) {
    const frameInset = 7.0;
    const anchorGap = 18.0;

    final contentSize = diameter - (frameInset * 2);
    final inverse = Matrix4.inverted(transform);
    final scenePoint = MatrixUtils.transformPoint(inverse, focalViewportPoint);

    final left = (focalViewportPoint.dx + anchorGap)
        .clamp(12.0, canvasSize.width - diameter - 12.0);
    final top = (focalViewportPoint.dy - diameter - anchorGap)
        .clamp(12.0, canvasSize.height - diameter - 12.0);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Container(
            width: diameter,
            height: diameter,
            padding: const EdgeInsets.all(frameInset),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFD6E3DE),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1.4,
              ),
            ),
            child: ClipOval(
              child: ColoredBox(
                color: const Color(0xFF0A1110),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform(
                      alignment: Alignment.topLeft,
                      transform: Matrix4.identity()
                        ..translate(contentSize / 2, contentSize / 2)
                        ..scale(magnification)
                        ..translate(-scenePoint.dx, -scenePoint.dy)
                        ..multiply(transform),
                      child: SizedBox(
                        width: canvasSize.width,
                        height: canvasSize.height,
                        child: sceneBuilder(context),
                      ),
                    ),
                    CustomPaint(
                      painter: _RepairDamageMagnifierFramePainter(
                        accentColor: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepairDamageMagnifierFramePainter extends CustomPainter {
  const _RepairDamageMagnifierFramePainter({
    required this.accentColor,
  });

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset((size.width / 3) * 2, 0),
      Offset((size.width / 3) * 2, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, (size.height / 3) * 2),
      Offset(size.width, (size.height / 3) * 2),
      gridPaint,
    );

    final crosshairPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(center.dx - 11, center.dy),
      Offset(center.dx + 11, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 11),
      Offset(center.dx, center.dy + 11),
      crosshairPaint,
    );

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accentColor.withValues(alpha: 0.96);
    canvas.drawCircle(center, (size.width / 2) - 2, accentPaint);
    canvas.drawCircle(center, 2.6, Paint()..color = accentColor);
  }

  @override
  bool shouldRepaint(covariant _RepairDamageMagnifierFramePainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}
