import 'package:flutter/material.dart';

import '../../domain/entities/blur_style.dart';

const _kAccent = Color(0xFF56E39F);

class BpStyleBar extends StatelessWidget {
  const BpStyleBar({
    super.key,
    required this.activeStyle,
    required this.onChanged,
  });

  final BlurPhotoStyle activeStyle;
  final ValueChanged<BlurPhotoStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: BlurPhotoStyle.values.map((style) {
            final active = style == activeStyle;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onChanged(style),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? _kAccent.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active
                          ? _kAccent.withValues(alpha: 0.34)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        style.label,
                        style: TextStyle(
                          color: active
                              ? _kAccent
                              : Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        style.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.48),
                          fontSize: 10.5,
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
    );
  }
}
