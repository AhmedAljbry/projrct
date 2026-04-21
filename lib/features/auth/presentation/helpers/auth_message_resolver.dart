import 'package:flutter/widgets.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';

String resolveAuthMessage(BuildContext context, String key) {
  final tr = context.tr;
  return switch (key) {
    'auth.error.invalidEmail' => tr.authErrorInvalidEmail,
    'auth.error.userNotFound' => tr.authErrorUserNotFound,
    'auth.error.invalidCredential' => tr.authErrorInvalidCredential,
    'auth.error.emailAlreadyInUse' => tr.authErrorEmailAlreadyInUse,
    'auth.error.weakPassword' => tr.authErrorWeakPassword,
    'auth.error.tooManyRequests' => tr.authErrorTooManyRequests,
    'auth.error.network' => tr.authErrorNetwork,
    'auth.error.unknown' => tr.authErrorUnknown,
    'auth.success.signIn' => tr.authSuccessSignIn,
    'auth.success.signUp' => tr.authSuccessSignUp,
    'auth.success.resetPassword' => tr.authSuccessResetPassword,
    'auth.success.verifyEmail' => tr.authSuccessVerifyEmail,
    'auth.validation.emailRequired' => tr.authValidationEmailRequired,
    'auth.validation.invalidEmail' => tr.authValidationInvalidEmail,
    'auth.validation.passwordRequired' => tr.authValidationPasswordRequired,
    'auth.validation.passwordTooShort' => tr.authValidationPasswordTooShort,
    'auth.validation.confirmPasswordRequired' =>
      tr.authValidationConfirmPasswordRequired,
    'auth.validation.passwordMismatch' => tr.authValidationPasswordMismatch,
    'profile.error.save' => tr.authErrorUnknown,
    'profile.error.fetch' => tr.authErrorUnknown,
    'profile.error.uploadImage' => tr.authErrorUnknown,
    _ => tr.authErrorUnknown,
  };
}
