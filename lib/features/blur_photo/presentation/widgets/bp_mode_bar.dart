import 'package:flutter/material.dart';

import '../../domain/entities/blur_mode.dart';

const _kAccent = Color(0xFF56E39F);
const _kPanel = Color(0xFF101012);

class BpModeBar extends StatelessWidget {
  const BpModeBar({
    super.key,
    required this.activeMode,
    required this.onChanged,
  });

  final BlurPhotoMode activeMode;
  final ValueChanged<BlurPhotoMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final visibleModes = BlurPhotoMode.values
        .where((mode) => mode != BlurPhotoMode.text)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: _kPanel,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: visibleModes
              .map(
                (mode) => _ModeButton(
                  mode: mode,
                  active: activeMode == mode,
                  onTap: () => onChanged(mode),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.active,
    required this.onTap,
  });

  final BlurPhotoMode mode;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? _kAccent : Colors.white.withValues(alpha: 0.78);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active
              ? _kAccent.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? _kAccent.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(mode), size: 17, color: color),
            const SizedBox(width: 7),
            Text(
              mode.label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(BlurPhotoMode mode) => switch (mode) {
      BlurPhotoMode.full => Icons.blur_on_rounded,
      BlurPhotoMode.text => Icons.text_fields_rounded,
      BlurPhotoMode.smart => Icons.auto_awesome_rounded,
      BlurPhotoMode.circle => Icons.radio_button_unchecked_rounded,
      BlurPhotoMode.line => Icons.reorder_rounded,
    };
