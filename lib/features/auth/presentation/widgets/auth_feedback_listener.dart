import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/services/feedback/app_feedback_message.dart';
import 'package:untitled2/core/services/feedback/user_feedback_service.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_form_bloc.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_form_event.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_form_state.dart';

class AuthFeedbackListener extends StatelessWidget {
  const AuthFeedbackListener({
    super.key,
    required this.child,
    this.onSuccess,
  });

  final Widget child;
  final VoidCallback? onSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthFormBloc, AuthFormState>(
      listener: (context, state) {
        if (state is AuthFormFailure) {
          _show(context, state.messageKey, isError: true);
        }
        if (state is AuthFormSuccess) {
          _show(context, state.messageKey);
          onSuccess?.call();
        }
      },
      child: child,
    );
  }

  void _show(BuildContext context, String key, {bool isError = false}) {
    final feedback = getIt<UserFeedbackService>();
    final message = switch (key) {
      'authErrorNetwork' => AppMessageKey.noInternetConnection,
      'authSuccessResetPassword' => AppMessageKey.actionCompleted,
      'authSuccessVerifyEmail' => AppMessageKey.actionCompleted,
      'authSuccessSignIn' => AppMessageKey.actionCompleted,
      'authSuccessSignUp' => AppMessageKey.actionCompleted,
      _ => isError
          ? AppMessageKey.somethingWentWrong
          : AppMessageKey.actionCompleted,
    };
    if (isError) {
      feedback.showError(message);
    } else {
      feedback.showSuccess(message);
    }
    context.read<AuthFormBloc>().add(const AuthFormResetStatus());
  }
}
