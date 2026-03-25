import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/clone_studio_bloc.dart';
import '../bloc/clone_studio_state.dart';

class CloneToolbar extends StatelessWidget {
  const CloneToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CloneStudioBloc, CloneStudioState>(
      builder: (context, state) {
        return Container(
          height: 70,
          color: Colors.black.withValues(alpha: 0.8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolButton(
                icon: Icons.gesture,
                label: 'SELECT',
                isActive: state.mode == CloneStudioMode.select,
                onPressed: () {
                   // Add mode switch event if needed
                },
              ),
              _buildToolButton(
                icon: Icons.layers,
                label: 'LAYERS',
                isActive: state.mode == CloneStudioMode.place,
                onPressed: () {},
              ),
              _buildToolButton(
                icon: Icons.flip,
                label: 'FLIP',
                isActive: false,
                onPressed: () {
                  if (state.activeLayerId != null) {
                    final layer = state.layers.firstWhere((l) => l.id == state.activeLayerId);
                    context.read<CloneStudioBloc>().add(
                      UpdateLayerTransformEvent(layer.id, layer.transform.copyWith(flipX: !layer.transform.flipX)),
                    );
                  }
                },
              ),
               _buildToolButton(
                icon: Icons.delete_outline,
                label: 'DELETE',
                isActive: false,
                onPressed: () {
                   if (state.activeLayerId != null) {
                    context.read<CloneStudioBloc>().add(DeleteLayerEvent(state.activeLayerId!));
                  }
                },
              ),
            ],
          ),
        );

      },
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.blueAccent : Colors.white70, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isActive ? Colors.blueAccent : Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}
