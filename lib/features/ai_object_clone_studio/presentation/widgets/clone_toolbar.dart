import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/core/ui/AppL10n.dart';

import '../bloc/clone_studio_bloc.dart';
import '../bloc/clone_studio_state.dart';

class CloneToolbar extends StatelessWidget {
  const CloneToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return BlocBuilder<CloneStudioBloc, CloneStudioState>(
      builder: (context, state) {
        return Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolButton(
                icon: Icons.auto_fix_high_rounded,
                label: l10n.get('clone_tool_select'),
                isActive: state.mode == CloneStudioMode.select,
                onPressed: () {
                  context.read<CloneStudioBloc>().add(
                        SetModeEvent(CloneStudioMode.select),
                      );
                },
              ),
              _buildToolButton(
                icon: Icons.open_with_rounded,
                label: l10n.get('clone_tool_move'),
                isActive: state.mode == CloneStudioMode.place,
                onPressed: state.activeLayerId == null
                    ? null
                    : () {
                        context.read<CloneStudioBloc>().add(
                              SetModeEvent(CloneStudioMode.place),
                            );
                      },
              ),
              _buildToolButton(
                icon: Icons.flip,
                label: l10n.get('clone_tool_flip'),
                isActive: false,
                onPressed: state.activeLayerId == null
                    ? null
                    : () {
                        final layer = state.layers.firstWhere(
                          (l) => l.id == state.activeLayerId,
                        );
                        context.read<CloneStudioBloc>().add(
                              UpdateLayerTransformEvent(
                                layer.id,
                                layer.transform.copyWith(
                                  flipX: !layer.transform.flipX,
                                ),
                              ),
                            );
                      },
              ),
              _buildToolButton(
                icon: Icons.delete_outline,
                label: l10n.get('clone_tool_delete'),
                isActive: false,
                onPressed: state.activeLayerId == null
                    ? null
                    : () {
                        context.read<CloneStudioBloc>().add(
                              DeleteLayerEvent(state.activeLayerId!),
                            );
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
    required VoidCallback? onPressed,
  }) {
    final color = onPressed == null
        ? Colors.white24
        : isActive
            ? const Color(0xFF56E39F)
            : Colors.white70;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
