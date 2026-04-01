import 'package:flutter/material.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';

class RepairDamageModeSwitcher extends StatelessWidget {
  const RepairDamageModeSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final MaskCreationMode mode;
  final ValueChanged<MaskCreationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MaskCreationMode>(
      segments: const [
        ButtonSegment<MaskCreationMode>(
          value: MaskCreationMode.manual,
          label: Text('Manual'),
          icon: Icon(Icons.brush_rounded),
        ),
        ButtonSegment<MaskCreationMode>(
          value: MaskCreationMode.aiAssist,
          label: Text('AI Assist'),
          icon: Icon(Icons.auto_awesome_rounded),
        ),
      ],
      selected: <MaskCreationMode>{mode},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        side: WidgetStateProperty.all(
          const BorderSide(color: Colors.white12),
        ),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LamaTheme.accent.withValues(alpha: 0.22);
          }
          return Colors.white.withValues(alpha: 0.04);
        }),
      ),
    );
  }
}
