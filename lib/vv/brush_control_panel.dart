import 'package:flutter/material.dart';
import 'package:untitled2/vv/brush_settings.dart';


/// Compact bottom panel showing brush radius, softness, and strength sliders.
/// Calls back on every change for live preview.
class BrushControlPanel extends StatelessWidget {
  final BrushSettings settings;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double> onSoftnessChanged;
  final ValueChanged<double> onStrengthChanged;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onReset;
  final bool canUndo;
  final bool canRedo;

  const BrushControlPanel({
    super.key,
    required this.settings,
    required this.onRadiusChanged,
    required this.onSoftnessChanged,
    required this.onStrengthChanged,
    this.onUndo,
    this.onRedo,
    this.onReset,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xF0111111),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Action row ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.undo,
                label: 'Undo',
                enabled: canUndo,
                onTap: onUndo,
              ),
              _ActionButton(
                icon: Icons.redo,
                label: 'Redo',
                enabled: canRedo,
                onTap: onRedo,
              ),
              _ActionButton(
                icon: Icons.restart_alt,
                label: 'Reset',
                enabled: true,
                onTap: onReset,
                destructive: true,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ─── Sliders ───────────────────────────────────────────────
          _BrushSlider(
            label: 'Size',
            value: settings.radius,
            min: 8.0,
            max: 80.0,
            displayValue: '${settings.radius.round()}',
            onChanged: onRadiusChanged,
            activeColor: const Color(0xFF56E39F),
          ),
          const SizedBox(height: 8),
          _BrushSlider(
            label: 'Feather',
            value: settings.softness,
            min: 0.0,
            max: 1.0,
            displayValue: '${(settings.softness * 100).round()}%',
            onChanged: onSoftnessChanged,
            activeColor: const Color(0xFF5BC0F8),
          ),
          const SizedBox(height: 8),
          _BrushSlider(
            label: 'Strength',
            value: settings.strength,
            min: 0.1,
            max: 1.0,
            displayValue: '${(settings.strength * 100).round()}%',
            onChanged: onStrengthChanged,
            activeColor: const Color(0xFFF7C59F),
          ),
        ],
      ),
    );
  }
}

class _BrushSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;
  final Color activeColor;

  const _BrushSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: activeColor,
              inactiveTrackColor: const Color(0xFF333333),
              thumbColor: Colors.white,
              overlayColor: activeColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            displayValue,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final bool destructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? const Color(0xFF444444)
        : destructive
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFEEEEEE);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
