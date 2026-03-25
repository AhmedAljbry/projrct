import 'package:flutter/material.dart';

import '../../domain/entities/blur_mode.dart';

const _kAccent = Color(0xFF56E39F);
const _kPanel = Color(0xFF101012);

/// Bottom mode selector rendered as compact chips.
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: _kPanel,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: BlurPhotoMode.values.map((mode) {
              final active = mode == activeMode;
              final color =
                  active ? _kAccent : Colors.white.withValues(alpha: 0.62);

              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: active
                          ? _kAccent.withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active
                            ? _kAccent.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconFor(mode), size: 16, color: color),
                        const SizedBox(width: 6),
                        Text(
                          mode.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 12.5,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(BlurPhotoMode mode) => switch (mode) {
        BlurPhotoMode.full => Icons.blur_on_rounded,
        BlurPhotoMode.text => Icons.text_fields_rounded,
        BlurPhotoMode.smart => Icons.auto_awesome_rounded,
        BlurPhotoMode.circle => Icons.radio_button_unchecked_rounded,
        BlurPhotoMode.line => Icons.reorder_rounded,
      };
}
