import 'package:untitled2/core/constants/app_constants.dart';

class AuthValidators {
  AuthValidators._();

  static String? validateEmail(String value) {
    final trimmed = value.trim();
    const pattern = r'^[^\s@]+@[^\s@]+\.[^\s@]+$';
    if (trimmed.isEmpty) {
      return 'auth.validation.emailRequired';
    }
    if (!RegExp(pattern).hasMatch(trimmed)) {
      return 'auth.validation.invalidEmail';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'auth.validation.passwordRequired';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'auth.validation.passwordTooShort';
    }
    return null;
  }

  static String? validateConfirmPassword(String password, String confirm) {
    if (confirm.isEmpty) {
      return 'auth.validation.confirmPasswordRequired';
    }
    if (password != confirm) {
      return 'auth.validation.passwordMismatch';
    }
    return null;
  }
}
