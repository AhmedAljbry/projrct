import 'package:flutter/material.dart';

import 'package:untitled2/shared/ui_tokens/viral_studio_tokens.dart';

class StyleSliderTile extends StatelessWidget {
  const StyleSliderTile({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: ViralStudioTokens.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style:
                      ViralStudioTokens.sectionTitle().copyWith(fontSize: 15),
                ),
              ),
              Text(
                value.toStringAsFixed(2),
                style: ViralStudioTokens.body(12).copyWith(color: Colors.white),
              ),
            ],
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(subtitle!, style: ViralStudioTokens.body(12)),
          ],
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ViralStudioTokens.accent,
              thumbColor: ViralStudioTokens.accentSoft,
              inactiveTrackColor: ViralStudioTokens.outline,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
