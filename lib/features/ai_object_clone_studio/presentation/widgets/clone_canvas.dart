import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/clone_studio_bloc.dart';
import '../bloc/clone_studio_state.dart';
import '../../engine/transform/transform_engine.dart';
import '../../domain/entities/clone_entities.dart';

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
          onPanStart: (details) => _handlePanStart(context, details, state),
          onPanUpdate: (details) => _handlePanUpdate(context, details, state),
          onPanEnd: (details) => _handlePanEnd(context, details, state),
          child: Container(
            color: const Color(0xFF121212),
            child: Stack(
              children: [
                // Base Image
                if (state.baseImage != null)
                  Center(
                    child: Image.memory(
                      state.baseImage!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Text('Waiting for image...', style: TextStyle(color: Colors.white54)),
                  ),

                // Layers
                ...state.layers.map((layer) => _buildLayer(context, layer, layer.id == state.activeLayerId)),

                // Selection UI (if in select mode)
                if (state.mode == CloneStudioMode.select)
                  _buildSelectionOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayer(BuildContext context, EditLayer layer, bool isActive) {
    final matrix = TransformEngine.getMatrix(layer.transform, layer.object.originalSize);
    
    return Positioned.fill(
      child: Transform(
        transform: matrix,
        child: Stack(
          children: [
             Image.memory(
               layer.object.imageBytes,
               errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
             ),
             if (isActive)
               _buildLayerHandles(context, layer),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerHandles(BuildContext context, EditLayer layer) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent, width: 2),
      ),
    );
  }

  Widget _buildSelectionOverlay() {
     // Implement selection visualization (brush strokes, lasso path, etc.)
     return CustomPaint(
        painter: SelectionPainter(points: _selectionPoints),
        size: Size.infinite,
     );
  }

  void _handlePanStart(BuildContext context, DragStartDetails details, CloneStudioState state) {
    if (state.mode == CloneStudioMode.select) {
      _selectionPoints.clear();
      _selectionPoints.add(details.localPosition);
      setState(() {});
    }
  }

  void _handlePanUpdate(BuildContext context, DragUpdateDetails details, CloneStudioState state) {
    if (state.mode == CloneStudioMode.select) {
      _selectionPoints.add(details.localPosition);
      setState(() {});
    } else if (state.mode == CloneStudioMode.place && state.activeLayerId != null) {
      final layer = state.layers.firstWhere((l) => l.id == state.activeLayerId);
      final newPos = layer.transform.position + details.delta;
      context.read<CloneStudioBloc>().add(
        UpdateLayerTransformEvent(layer.id, layer.transform.copyWith(position: newPos)),
      );
    }
  }

  void _handlePanEnd(BuildContext context, DragEndDetails details, CloneStudioState state) {
    if (state.mode == CloneStudioMode.select) {
       context.read<CloneStudioBloc>().add(SelectObjectEvent(List.from(_selectionPoints)));
    }
  }
}

class SelectionPainter extends CustomPainter {
  final List<Offset> points;
  SelectionPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.5)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var point in points) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
