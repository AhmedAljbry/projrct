import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/core/ui/AppL10n.dart';

import '../bloc/clone_studio_bloc.dart';
import '../bloc/clone_studio_state.dart';

class CloneControlPanel extends StatelessWidget {
  const CloneControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return BlocBuilder<CloneStudioBloc, CloneStudioState>(
      builder: (context, state) {
        if (state.activeLayerId == null || state.mode != CloneStudioMode.place) {
          return const SizedBox.shrink();
        }

        final layer =
            state.layers.firstWhere((l) => l.id == state.activeLayerId);
        final settings = layer.harmonization;

        return Container(
          color: Colors.black.withValues(alpha: 0.8),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.get('clone_harmonization'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              _buildSlider(
                l10n.get('clone_color_match'),
                settings.colorMatch,
                (val) {
                  context.read<CloneStudioBloc>().add(
                        UpdateLayerHarmonizationEvent(
                          layer.id,
                          settings.copyWith(colorMatch: val),
                        ),
                      );
                },
              ),
              _buildSlider(
                l10n.get('clone_blend_strength'),
                settings.blendStrength,
                (val) {
                  context.read<CloneStudioBloc>().add(
                        UpdateLayerHarmonizationEvent(
                          layer.id,
                          settings.copyWith(blendStrength: val),
                        ),
                      );
                },
              ),
              _buildSlider(
                l10n.get('clone_edge_feather'),
                settings.edgeFeather,
                (val) {
                  context.read<CloneStudioBloc>().add(
                        UpdateLayerHarmonizationEvent(
                          layer.id,
                          settings.copyWith(edgeFeather: val),
                        ),
                      );
                },
                max: 50.0,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    ValueChanged<double> onChanged, {
    double max = 1.0,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: const SliderThemeData(
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 2,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
