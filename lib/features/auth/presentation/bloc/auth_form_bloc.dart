import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:untitled2/features/auth/domain/usecases/send_email_verification.dart';
import 'package:untitled2/features/auth/domain/usecases/send_password_reset_email.dart';
import 'package:untitled2/features/auth/domain/usecases/sign_in_with_email_password.dart';
import 'package:untitled2/features/auth/domain/usecases/sign_up_with_email_password.dart';
import 'package:untitled2/features/auth/domain/validation/auth_validators.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_form_event.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_form_state.dart';

@injectable
class AuthFormBloc extends Bloc<AuthFormEvent, AuthFormState> {
  AuthFormBloc(
    this._signIn,
    this._signUp,
    this._sendPasswordResetEmail,
    this._sendEmailVerification,
  ) : super(const AuthFormIdle()) {
    on<AuthFormSubmitted>(_onSubmitted);
    on<AuthFormResetStatus>(_onResetStatus);
  }

  final SignInWithEmailPassword _signIn;
  final SignUpWithEmailPassword _signUp;
  final SendPasswordResetEmail _sendPasswordResetEmail;
  final SendEmailVerification _sendEmailVerification;

  Future<void> _onSubmitted(
    AuthFormSubmitted event,
    Emitter<AuthFormState> emit,
  ) async {
    final fieldErrors = _validate(event);
    if (fieldErrors.isNotEmpty) {
      emit(AuthFormValidationError(fieldErrors));
      return;
    }
    emit(const AuthFormLoading());
    switch (event.type) {
      case AuthFormType.signIn:
        final result = await _signIn(
          email: event.email,
          password: event.password,
        );
        emit(
          result.fold(
            (failure) =>
                AuthFormFailure(failure.messageKey ?? 'auth.error.unknown'),
            (_) => const AuthFormSuccess('auth.success.signIn'),
          ),
        );
        return;
      case AuthFormType.signUp:
        final result = await _signUp(
          email: event.email,
          password: event.password,
        );
        emit(
          result.fold(
            (failure) =>
                AuthFormFailure(failure.messageKey ?? 'auth.error.unknown'),
            (_) => const AuthFormSuccess('auth.success.signUp'),
          ),
        );
        return;
      case AuthFormType.forgotPassword:
        final result = await _sendPasswordResetEmail(email: event.email);
        emit(
          result.fold(
            (failure) =>
                AuthFormFailure(failure.messageKey ?? 'auth.error.unknown'),
            (_) => const AuthFormSuccess('auth.success.resetPassword'),
          ),
        );
        return;
      case AuthFormType.verifyEmail:
        final result = await _sendEmailVerification();
        emit(
          result.fold(
            (failure) =>
                AuthFormFailure(failure.messageKey ?? 'auth.error.unknown'),
            (_) => const AuthFormSuccess('auth.success.verifyEmail'),
          ),
        );
        return;
    }
  }

  void _onResetStatus(
    AuthFormResetStatus event,
    Emitter<AuthFormState> emit,
  ) {
    emit(const AuthFormIdle());
  }

  Map<String, String> _validate(AuthFormSubmitted event) {
    final errors = <String, String>{};
    final emailError = AuthValidators.validateEmail(event.email);
    if (emailError != null) {
      errors['email'] = emailError;
    }
    if (event.type == AuthFormType.signIn ||
        event.type == AuthFormType.signUp) {
      final passwordError = AuthValidators.validatePassword(event.password);
      if (passwordError != null) {
        errors['password'] = passwordError;
      }
    }
    if (event.type == AuthFormType.signUp) {
      final confirmError = AuthValidators.validateConfirmPassword(
        event.password,
        event.confirmPassword,
      );
      if (confirmError != null) {
        errors['confirmPassword'] = confirmError;
      }
    }
    return errors;
  }
}
