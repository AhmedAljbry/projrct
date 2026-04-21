import 'package:flutter/material.dart';

enum AppFeedbackType {
  success,
  info,
  warning,
  error,
}

enum AppMessageKey {
  savedSuccessfully,
  somethingWentWrong,
  noInternetConnection,
  pleaseTryAgain,
  changesDiscarded,
  uploadFailed,
  sessionExpired,
  featureUnavailableRightNow,
  connectionRestored,
  actionCompleted,
  failedToLoad,
  retryAction,
  permissionDenied,
  permissionPermanentlyDenied,
  openSettings,
  supportComingSoon,
  languageUpdated,
  screenHelpTitle,
}

class AppFeedbackMessage {
  const AppFeedbackMessage({
    required this.key,
    required this.type,
    this.actionLabelKey,
    this.onAction,
    this.duration = const Duration(seconds: 4),
  });

  final AppMessageKey key;
  final AppFeedbackType type;
  final AppMessageKey? actionLabelKey;
  final VoidCallback? onAction;
  final Duration duration;
}

class AppConfirmationRequest {
  const AppConfirmationRequest({
    required this.titleKey,
    required this.messageKey,
    required this.confirmLabelKey,
    this.cancelLabelKey = AppMessageKey.pleaseTryAgain,
    this.isDestructive = false,
  });

  final AppMessageKey titleKey;
  final AppMessageKey messageKey;
  final AppMessageKey confirmLabelKey;
  final AppMessageKey cancelLabelKey;
  final bool isDestructive;
}
