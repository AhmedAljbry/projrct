import 'package:flutter/material.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';

class RepairDamageActionBar extends StatelessWidget {
  const RepairDamageActionBar({
    super.key,
    required this.canApply,
    required this.isBusy,
    required this.onApply,
  });

  final bool canApply;
  final bool isBusy;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LamaTheme.toolbarBg,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: (!canApply || isBusy) ? null : onApply,
              style: FilledButton.styleFrom(
                backgroundColor: LamaTheme.accent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white10,
                disabledForegroundColor: Colors.white24,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.auto_fix_high_rounded),
              label: Text(
                isBusy ? 'Applying...' : 'Apply Repair',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
