import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';

import 'app_feedback_message.dart';

@lazySingleton
class AppMessageLocalizer {
  String localize(BuildContext context, AppMessageKey key) {
    final tr = context.tr;
    return switch (key) {
      AppMessageKey.savedSuccessfully => tr.msgSavedSuccessfully,
      AppMessageKey.somethingWentWrong => tr.msgSomethingWentWrong,
      AppMessageKey.noInternetConnection => tr.msgNoInternetConnection,
      AppMessageKey.pleaseTryAgain => tr.msgPleaseTryAgain,
      AppMessageKey.changesDiscarded => tr.msgChangesDiscarded,
      AppMessageKey.uploadFailed => tr.msgUploadFailed,
      AppMessageKey.sessionExpired => tr.msgSessionExpired,
      AppMessageKey.featureUnavailableRightNow =>
        tr.msgFeatureUnavailableRightNow,
      AppMessageKey.connectionRestored => tr.msgConnectionRestored,
      AppMessageKey.actionCompleted => tr.msgActionCompleted,
      AppMessageKey.failedToLoad => tr.msgFailedToLoad,
      AppMessageKey.retryAction => tr.commonRetry,
      AppMessageKey.permissionDenied => tr.msgPermissionDenied,
      AppMessageKey.permissionPermanentlyDenied =>
        tr.msgPermissionPermanentlyDenied,
      AppMessageKey.openSettings => tr.commonOpenSettings,
      AppMessageKey.supportComingSoon => tr.settingsSupportComingSoon,
      AppMessageKey.languageUpdated => tr.settingsLanguageChangedMessage,
      AppMessageKey.screenHelpTitle => tr.commonHelp,
    };
  }
}
