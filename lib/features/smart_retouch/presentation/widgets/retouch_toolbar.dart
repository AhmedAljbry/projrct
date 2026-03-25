import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/bloc/retouch_bloc.dart';
import '../../application/bloc/retouch_event.dart';
import '../../domain/models/retouch_mode.dart';

class RetouchToolbar extends StatelessWidget {
  final bool isSettingsVisible;
  final VoidCallback onToggleSettings;

  const RetouchToolbar({
    super.key,
    required this.isSettingsVisible,
    required this.onToggleSettings,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RetouchBloc>().state;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFF161616).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 5),
            )
          ]),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left compact control icon (Pan mode)
          _ToolIconButton(
            icon: Icons.back_hand,
            isActive: state.activeMode == RetouchMode.none,
            onTap: () => context
                .read<RetouchBloc>()
                .add(const ChangeModeEvent(RetouchMode.none)),
          ),
          _ToolIconButton(
            icon: Icons.tune,
            isActive: isSettingsVisible,
            onTap: onToggleSettings,
          ),
          const Spacer(),

          _ToolIconButton(
            icon: Icons.auto_fix_high,
            isActive: state.activeMode == RetouchMode.heal ||
                state.activeMode == RetouchMode.clone,
            onTap: () => context
                .read<RetouchBloc>()
                .add(const ChangeModeEvent(RetouchMode.heal)),
          ),
          _ToolIconButton(
            icon: Icons.layers_clear,
            isActive: state.activeMode == RetouchMode.eraser,
            onTap: () => context
                .read<RetouchBloc>()
                .add(const ChangeModeEvent(RetouchMode.eraser)),
          ),
        ],
      ),
    );
  }
}

class BrushSizeBar extends StatelessWidget {
  const BrushSizeBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RetouchBloc>().state;
    final settings = state.activeBrushSettings;

    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161616).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StepButton(
            icon: Icons.remove,
            onTap: () {
              final nextSize = (settings.size - 5).clamp(5, 150).toDouble();
              context.read<RetouchBloc>().add(
                    UpdateBrushSettingsEvent(settings.copyWith(size: nextSize)),
                  );
            },
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF56E39F),
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
                overlayColor: const Color(0xFF56E39F).withValues(alpha: 0.2),
                trackHeight: 2.0,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8.0),
              ),
              child: Slider(
                value: settings.size,
                min: 5,
                max: 150,
                onChanged: (val) {
                  context.read<RetouchBloc>().add(
                        UpdateBrushSettingsEvent(settings.copyWith(size: val)),
                      );
                },
              ),
            ),
          ),
          Text(
            settings.size.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          _StepButton(
            icon: Icons.add,
            onTap: () {
              final nextSize = (settings.size + 5).clamp(5, 150).toDouble();
              context.read<RetouchBloc>().add(
                    UpdateBrushSettingsEvent(settings.copyWith(size: nextSize)),
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF56E39F) : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
