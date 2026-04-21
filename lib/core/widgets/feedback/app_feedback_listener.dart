import 'dart:async';

import 'package:flutter/material.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/services/feedback/app_feedback_message.dart';
import 'package:untitled2/core/services/feedback/app_message_localizer.dart';
import 'package:untitled2/core/services/feedback/user_feedback_service.dart';

class AppFeedbackListener extends StatefulWidget {
  const AppFeedbackListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppFeedbackListener> createState() => _AppFeedbackListenerState();
}

class _AppFeedbackListenerState extends State<AppFeedbackListener> {
  late final UserFeedbackService _feedbackService = getIt<UserFeedbackService>();
  late final AppMessageLocalizer _localizer = getIt<AppMessageLocalizer>();
  StreamSubscription<AppFeedbackMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _feedbackService.messages.listen(_showMessage);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _showMessage(AppFeedbackMessage message) {
    if (!mounted) {
      return;
    }
    final color = switch (message.type) {
      AppFeedbackType.success => const Color(0xFF1F5F45),
      AppFeedbackType.info => const Color(0xFF18456B),
      AppFeedbackType.warning => const Color(0xFF6B4A18),
      AppFeedbackType.error => const Color(0xFF6B1D1D),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: message.duration,
          backgroundColor: color,
          content: Text(_localizer.localize(context, message.key)),
          action: message.actionLabelKey != null && message.onAction != null
              ? SnackBarAction(
                  label: _localizer.localize(context, message.actionLabelKey!),
                  onPressed: message.onAction!,
                )
              : null,
        ),
      );
  }
}
