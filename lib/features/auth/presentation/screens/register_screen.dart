import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';
import 'package:untitled2/core/services/connectivity/connectivity_cubit.dart';
import 'package:untitled2/core/services/connectivity/connectivity_state.dart';
import 'package:untitled2/core/services/help/help_topic.dart';
import 'package:untitled2/core/widgets/common/app_loading_button.dart';
import 'package:untitled2/core/widgets/states/app_offline_state.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_form_bloc.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_form_event.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_form_state.dart';
import 'package:untitled2/features/auth/presentation/helpers/auth_message_resolver.dart';
import 'package:untitled2/features/auth/presentation/widgets/auth_feedback_listener.dart';
import 'package:untitled2/features/auth/presentation/widgets/auth_shell.dart';
import 'package:untitled2/features/home/presentation/widgets/studio_navigation_drawer.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return BlocProvider(
      create: (_) => getIt<AuthFormBloc>(),
      child: AuthFeedbackListener(
        onSuccess: () => context.go('/verify-email'),
        child: BlocBuilder<AuthFormBloc, AuthFormState>(
          builder: (context, state) {
            final errors = state is AuthFormValidationError
                ? state.fieldErrors
                : const <String, String>{};
            final isLoading = state is AuthFormLoading;
            return AuthShell(
              title: tr.authRegisterTitle,
              subtitle: tr.authRegisterSubtitle,
              helpTopic: HelpTopic.register,
              drawer: const StudioNavigationDrawer(),
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : () => context.go('/'),
                    child: Text(tr.authContinueAsGuestCta),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : () => context.go('/login'),
                    child: Text(tr.authGoToSignIn),
                  ),
                ],
              ),
              child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
                builder: (context, connectivityState) {
                  if (!connectivityState.isOnline) {
                    return AppOfflineState(
                      title: tr.offlineStateTitle,
                      description: tr.authOfflineDescription,
                      actionLabel: tr.commonRetry,
                      onAction: context.read<ConnectivityCubit>().refresh,
                    );
                  }
                  return Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: tr.authEmailLabel,
                          helperText: tr.authEmailHelper,
                          errorText: _error(context, errors['email']),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: tr.authPasswordLabel,
                          helperText: tr.authPasswordHelper,
                          errorText: _error(context, errors['password']),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: tr.authConfirmPasswordLabel,
                          helperText: tr.authConfirmPasswordHelper,
                          errorText: _error(context, errors['confirmPassword']),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _obscureConfirm = !_obscureConfirm);
                            },
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: AppLoadingButton(
                          isLoading: isLoading,
                          label: tr.authRegisterCta,
                          loadingLabel: tr.authLoadingCta,
                          icon: Icons.person_add_alt_1_rounded,
                          onPressed: () => _submit(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final connectivityCubit = context.read<ConnectivityCubit>();
    final authFormBloc = context.read<AuthFormBloc>();
    connectivityCubit.canUseNetworkAction().then((canUse) {
      if (!canUse) {
        return;
      }
      authFormBloc.add(
        AuthFormSubmitted(
          type: AuthFormType.signUp,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmController.text,
        ),
      );
    });
  }

  String? _error(BuildContext context, String? key) {
    if (key == null) {
      return null;
    }
    return resolveAuthMessage(context, key);
  }
}
