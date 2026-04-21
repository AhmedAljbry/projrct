enum AuthFormType {
  signIn,
  signUp,
  forgotPassword,
  verifyEmail,
}

sealed class AuthFormEvent {
  const AuthFormEvent();
}

class AuthFormSubmitted extends AuthFormEvent {
  const AuthFormSubmitted({
    required this.type,
    required this.email,
    this.password = '',
    this.confirmPassword = '',
  });

  final AuthFormType type;
  final String email;
  final String password;
  final String confirmPassword;
}

class AuthFormResetStatus extends AuthFormEvent {
  const AuthFormResetStatus();
}
