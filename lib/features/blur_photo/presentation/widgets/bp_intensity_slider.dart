import 'package:flutter/material.dart';

const _kAccent = Color(0xFF56E39F);

/// Labelled blur intensity slider component.
class BpIntensitySlider extends StatelessWidget {
  const BpIntensitySlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Row(children: [
            Text(
              'Blur Intensity',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(),
            Text(
              '${value.round()}',
              style: const TextStyle(
                color: _kAccent,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            activeTrackColor: _kAccent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
            thumbColor: Colors.white,
            overlayColor: _kAccent.withValues(alpha: 0.18),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: value.clamp(2.0, 30.0),
            min: 2.0,
            max: 30.0,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}
