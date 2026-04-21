sealed class AuthFormState {
  const AuthFormState();
}

class AuthFormIdle extends AuthFormState {
  const AuthFormIdle();
}

class AuthFormLoading extends AuthFormState {
  const AuthFormLoading();
}

class AuthFormSuccess extends AuthFormState {
  const AuthFormSuccess(this.messageKey);

  final String messageKey;
}

class AuthFormFailure extends AuthFormState {
  const AuthFormFailure(this.messageKey);

  final String messageKey;
}

class AuthFormValidationError extends AuthFormState {
  const AuthFormValidationError(this.fieldErrors);

  final Map<String, String> fieldErrors;
}
