import 'package:flutter/material.dart';

import 'package:untitled2/core/services/feedback/app_feedback_message.dart';

class AppInlineMessage extends StatelessWidget {
  const AppInlineMessage({
    super.key,
    required this.type,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final AppFeedbackType type;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      AppFeedbackType.success => const Color(0xFF56E39F),
      AppFeedbackType.info => const Color(0xFF3D8BFD),
      AppFeedbackType.warning => const Color(0xFFFFB74D),
      AppFeedbackType.error => const Color(0xFFEF5350),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
