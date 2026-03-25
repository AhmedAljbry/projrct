import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/bloc/retouch_bloc.dart';
import '../../application/bloc/retouch_event.dart';

class BrushParameterControl extends StatelessWidget {
  const BrushParameterControl({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RetouchBloc>().state;
    final settings = state.activeBrushSettings;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161616).withValues(alpha: 0.5), // Semi-transparent
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1), // Subtle border
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SliderRow(
            icon: Icons.circle_outlined,
            label: 'Size',
            value: settings.size,
            min: 5,
            max: 150,
            onChanged: (val) {
              context.read<RetouchBloc>().add(
                UpdateBrushSettingsEvent(settings.copyWith(size: val))
              );
            },
          ),
          const SizedBox(height: 12),
          _SliderRow(
            icon: Icons.blur_on,
            label: 'Hardness',
            value: settings.hardness,
            min: 0.0,
            max: 1.0,
            onChanged: (val) {
              context.read<RetouchBloc>().add(
                UpdateBrushSettingsEvent(settings.copyWith(hardness: val))
              );
            },
          ),
          const SizedBox(height: 12),
          _SliderRow(
            icon: Icons.opacity,
            label: 'Opacity',
            value: settings.opacity,
            min: 0.1,
            max: 1.0,
            onChanged: (val) {
              context.read<RetouchBloc>().add(
                UpdateBrushSettingsEvent(settings.copyWith(opacity: val))
              );
            },
          ),
        ],
      ),
    )));
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF56E39F),
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF56E39F).withValues(alpha: 0.2),
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
