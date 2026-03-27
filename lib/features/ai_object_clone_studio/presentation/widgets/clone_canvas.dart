import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/clone_entities.dart';
import '../bloc/clone_studio_bloc.dart';
import '../bloc/clone_studio_state.dart';

class CloneCanvas extends StatefulWidget {
  const CloneCanvas({super.key});

  @override
  State<CloneCanvas> createState() => _CloneCanvasState();
}

class _CloneCanvasState extends State<CloneCanvas> {
  final List<Offset> _selectionPoints = [];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CloneStudioBloc, CloneStudioState>(
      builder: (context, state) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: state.mode == CloneStudioMode.select && !state.isLoading
              ? (details) => _handleTapSelect(context, details.localPosition)
              : null,
          onPanStart: (details) => _handlePanStart(context, details, state),
          onPanUpdate: (details) => _handlePanUpdate(context, details, state),
          onPanEnd: (details) => _handlePanEnd(context, details, state),
          child: Container(
            color: const Color(0xFF101010),
            child: Stack(
              children: [
                if (state.baseImage != null)
                  Positioned.fill(
                    child: Center(
                      child: Image.memory(
                        state.baseImage!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            'Error: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Text(
                      'Waiting for image...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ...state.layers.map(
                  (layer) => _buildLayer(
                    layer,
                    layer.id == state.activeLayerId,
                  ),
                ),
                if (state.mode == CloneStudioMode.select)
                  _buildSelectionOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayer(EditLayer layer, bool isActive) {
    final objectSize = layer.object.originalSize;
    final left = layer.transform.position.dx - (objectSize.width / 2);
    final top = layer.transform.position.dy - (objectSize.height / 2);

    return Positioned(
      left: left,
      top: top,
      width: objectSize.width,
      height: objectSize.height,
      child: Transform.rotate(
        angle: layer.transform.rotation,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            layer.transform.flipX
                ? -layer.transform.scale
                : layer.transform.scale,
            layer.transform.flipY
                ? -layer.transform.scale
                : layer.transform.scale,
            1,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              Image.memory(
                layer.object.imageBytes,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
              if (isActive) _buildActiveFrame(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFrame() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF56E39F), width: 2.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF56E39F).withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -38,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF56E39F),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: Color(0xFF08110D),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'جاهز للتحريك',
                    style: TextStyle(
                      color: Color(0xFF08110D),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionOverlay() {
    return CustomPaint(
      painter: SelectionPainter(points: _selectionPoints),
      size: Size.infinite,
    );
  }

  void _handleTapSelect(BuildContext context, Offset position) {
    context.read<CloneStudioBloc>().add(
          SelectObjectEvent(_seedPointsAround(position)),
        );
  }

  void _handlePanStart(
    BuildContext context,
    DragStartDetails details,
    CloneStudioState state,
  ) {
    if (state.isLoading) return;
    if (state.mode == CloneStudioMode.select) {
      _selectionPoints
        ..clear()
        ..add(details.localPosition);
      setState(() {});
    }
  }

  void _handlePanUpdate(
    BuildContext context,
    DragUpdateDetails details,
    CloneStudioState state,
  ) {
    if (state.isLoading) return;
    if (state.mode == CloneStudioMode.select) {
      _selectionPoints.add(details.localPosition);
      setState(() {});
      return;
    }

    if (state.mode == CloneStudioMode.place && state.activeLayerId != null) {
      final layer = state.layers.firstWhere((l) => l.id == state.activeLayerId);
      context.read<CloneStudioBloc>().add(
            UpdateLayerTransformEvent(
              layer.id,
              layer.transform.copyWith(
                position: layer.transform.position + details.delta,
              ),
            ),
          );
    }
  }

  void _handlePanEnd(
    BuildContext context,
    DragEndDetails details,
    CloneStudioState state,
  ) {
    if (state.isLoading || state.mode != CloneStudioMode.select) return;
    if (_selectionPoints.length >= 2) {
      context.read<CloneStudioBloc>().add(
            SelectObjectEvent(List<Offset>.from(_selectionPoints)),
          );
    }
  }

  List<Offset> _seedPointsAround(Offset center) {
    const radius = 34.0;
    const steps = 12;
    final points = <Offset>[center];
    for (var i = 0; i < steps; i++) {
      final angle = (i / steps) * math.pi * 2;
      points.add(
        Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        ),
      );
    }
    return points;
  }
}

class SelectionPainter extends CustomPainter {
  final List<Offset> points;
  SelectionPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final strokePaint = Paint()
      ..color = const Color(0xFF56E39F).withValues(alpha: 0.88)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFF56E39F).withValues(alpha: 0.18)
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
