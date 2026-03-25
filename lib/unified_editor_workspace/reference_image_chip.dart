import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'reference_image_state.dart';

/// Compact reference image chip shown in the workspace (below top bar or in strip).
/// Shows thumbnail, "Reference Active" label, quick disable button.
class ReferenceImageChip extends StatelessWidget {
  final ReferenceImageState refState;
  final VoidCallback onClear;
  final VoidCallback onReplace;

  const ReferenceImageChip({
    super.key,
    required this.refState,
    required this.onClear,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: refState.hasReference
          ? _ActiveChip(
              key: const ValueKey('active'),
              refState: refState,
              onClear: onClear,
              onReplace: onReplace,
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final ReferenceImageState refState;
  final VoidCallback onClear;
  final VoidCallback onReplace;

  const _ActiveChip({
    super.key,
    required this.refState,
    required this.onClear,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final profile = refState.profile;

    return GestureDetector(
      onTap: onReplace,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppTokens.card2.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppTokens.success.withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTokens.success.withValues(alpha: 0.22),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: refState.bytes != null
                  ? Image.memory(
                      refState.bytes!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 32,
                      height: 32,
                      color: AppTokens.card,
                      child: const Icon(Icons.image_rounded, size: 18, color: AppTokens.text2),
                    ),
            ),
            const SizedBox(width: 8),
            // Labels
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTokens.success,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Reference Active',
                      style: TextStyle(
                        color: AppTokens.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                if (profile != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.shortSummary,
                    style: TextStyle(
                      color: AppTokens.text2,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 6),
            // Palette mini swatches (up to 4)
            if (profile != null && profile.palette.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: profile.palette
                    .take(4)
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(width: 6),
            // Dismiss
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTokens.card.withValues(alpha: 0.7),
                  border: Border.all(color: AppTokens.border.withValues(alpha: 0.55)),
                ),
                child: const Icon(Icons.close_rounded, size: 13, color: AppTokens.text2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small "Add Reference" button for the top bar / style rail.
class AddReferenceButton extends StatelessWidget {
  final bool referenceActive;
  final VoidCallback onTap;

  const AddReferenceButton({
    super.key,
    required this.referenceActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: referenceActive ? 'Replace Reference' : 'Add Reference',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: referenceActive
                ? AppTokens.success.withValues(alpha: 0.14)
                : AppTokens.card2.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: referenceActive
                  ? AppTokens.success.withValues(alpha: 0.55)
                  : AppTokens.border.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: referenceActive
                ? [
                    BoxShadow(
                      color: AppTokens.success.withValues(alpha: 0.18),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                referenceActive
                    ? Icons.image_search_rounded
                    : Icons.add_photo_alternate_rounded,
                size: 16,
                color: referenceActive ? AppTokens.success : AppTokens.text2,
              ),
              if (MediaQuery.of(context).size.width > 380) ...[
                const SizedBox(width: 6),
                Text(
                  referenceActive ? 'Reference' : 'Add Reference',
                  style: TextStyle(
                    color: referenceActive ? AppTokens.success : AppTokens.text2,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
