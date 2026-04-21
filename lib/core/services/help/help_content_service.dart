import 'package:injectable/injectable.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'help_content.dart';
import 'help_topic.dart';

@lazySingleton
class HelpContentService {
  HelpContent resolve(HelpTopic topic, AppLocalizations tr) {
    return switch (topic) {
      HelpTopic.home => HelpContent(
        title: tr.helpHomeTitle,
        summary: tr.helpHomeSummary,
        steps: [
          tr.helpHomeStep1,
          tr.helpHomeStep2,
          tr.helpHomeStep3,
        ],
        tips: [
          tr.helpHomeTip1,
          tr.helpHomeTip2,
        ],
      ),
      HelpTopic.signIn => HelpContent(
        title: tr.helpSignInTitle,
        summary: tr.helpSignInSummary,
        steps: [
          tr.helpSignInStep1,
          tr.helpSignInStep2,
          tr.helpSignInStep3,
        ],
        tips: [tr.helpSignInTip1],
      ),
      HelpTopic.register => HelpContent(
        title: tr.helpRegisterTitle,
        summary: tr.helpRegisterSummary,
        steps: [
          tr.helpRegisterStep1,
          tr.helpRegisterStep2,
          tr.helpRegisterStep3,
        ],
        tips: [tr.helpRegisterTip1],
      ),
      HelpTopic.forgotPassword => HelpContent(
        title: tr.helpForgotPasswordTitle,
        summary: tr.helpForgotPasswordSummary,
        steps: [
          tr.helpForgotPasswordStep1,
          tr.helpForgotPasswordStep2,
          tr.helpForgotPasswordStep3,
        ],
      ),
      HelpTopic.verifyEmail => HelpContent(
        title: tr.helpVerifyEmailTitle,
        summary: tr.helpVerifyEmailSummary,
        steps: [
          tr.helpVerifyEmailStep1,
          tr.helpVerifyEmailStep2,
          tr.helpVerifyEmailStep3,
        ],
        warnings: [tr.helpVerifyEmailWarning1],
      ),
      HelpTopic.securityCenter => HelpContent(
        title: tr.helpSecurityTitle,
        summary: tr.helpSecuritySummary,
        steps: [
          tr.helpSecurityStep1,
          tr.helpSecurityStep2,
          tr.helpSecurityStep3,
        ],
      ),
      HelpTopic.settings => HelpContent(
        title: tr.helpSettingsTitle,
        summary: tr.helpSettingsSummary,
        steps: [
          tr.helpSettingsStep1,
          tr.helpSettingsStep2,
          tr.helpSettingsStep3,
        ],
      ),
      HelpTopic.inpaintingHome => HelpContent(
        title: tr.helpInpaintingHomeTitle,
        summary: tr.helpInpaintingHomeSummary,
        steps: [
          tr.helpInpaintingHomeStep1,
          tr.helpInpaintingHomeStep2,
          tr.helpInpaintingHomeStep3,
        ],
        tips: [tr.helpInpaintingHomeTip1],
      ),
      HelpTopic.inpaintingEditor => HelpContent(
        title: tr.helpInpaintingEditorTitle,
        summary: tr.helpInpaintingEditorSummary,
        steps: [
          tr.helpInpaintingEditorStep1,
          tr.helpInpaintingEditorStep2,
          tr.helpInpaintingEditorStep3,
        ],
        tips: [tr.helpInpaintingEditorTip1],
      ),
      HelpTopic.inpaintingProcessing => HelpContent(
        title: tr.helpInpaintingProcessingTitle,
        summary: tr.helpInpaintingProcessingSummary,
        steps: [
          tr.helpInpaintingProcessingStep1,
          tr.helpInpaintingProcessingStep2,
          tr.helpInpaintingProcessingStep3,
        ],
      ),
      HelpTopic.inpaintingResult => HelpContent(
        title: tr.helpInpaintingResultTitle,
        summary: tr.helpInpaintingResultSummary,
        steps: [
          tr.helpInpaintingResultStep1,
          tr.helpInpaintingResultStep2,
          tr.helpInpaintingResultStep3,
        ],
        tips: [tr.helpInpaintingResultTip1],
      ),
    };
  }
}
