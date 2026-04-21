import 'dart:async';

import 'package:injectable/injectable.dart';

import 'app_feedback_message.dart';

@lazySingleton
class UserFeedbackService {
  final StreamController<AppFeedbackMessage> _messagesController =
      StreamController<AppFeedbackMessage>.broadcast();

  Stream<AppFeedbackMessage> get messages => _messagesController.stream;

  void showMessage(AppFeedbackMessage message) {
    if (!_messagesController.isClosed) {
      _messagesController.add(message);
    }
  }

  void showSuccess(AppMessageKey key, {AppMessageKey? actionLabelKey}) {
    showMessage(
      AppFeedbackMessage(
        key: key,
        type: AppFeedbackType.success,
        actionLabelKey: actionLabelKey,
      ),
    );
  }

  void showInfo(AppMessageKey key, {AppMessageKey? actionLabelKey}) {
    showMessage(
      AppFeedbackMessage(
        key: key,
        type: AppFeedbackType.info,
        actionLabelKey: actionLabelKey,
      ),
    );
  }

  void showWarning(AppMessageKey key, {AppMessageKey? actionLabelKey}) {
    showMessage(
      AppFeedbackMessage(
        key: key,
        type: AppFeedbackType.warning,
        actionLabelKey: actionLabelKey,
      ),
    );
  }

  void showError(AppMessageKey key, {AppMessageKey? actionLabelKey}) {
    showMessage(
      AppFeedbackMessage(
        key: key,
        type: AppFeedbackType.error,
        actionLabelKey: actionLabelKey,
      ),
    );
  }
}
