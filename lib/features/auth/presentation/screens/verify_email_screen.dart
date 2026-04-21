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
import 'package:untitled2/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:untitled2/features/auth/presentation/widgets/auth_feedback_listener.dart';
import 'package:untitled2/features/auth/presentation/widgets/auth_shell.dart';
import 'package:untitled2/features/home/presentation/widgets/studio_navigation_drawer.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return BlocProvider(
      create: (_) => getIt<AuthFormBloc>(),
      child: AuthFeedbackListener(
        child: BlocBuilder<AuthFormBloc, AuthFormState>(
          builder: (context, state) {
            final isLoading = state is AuthFormLoading;
            return AuthShell(
              title: tr.authVerifyEmailTitle,
              subtitle: tr.authVerifyEmailSubtitle,
              helpTopic: HelpTopic.verifyEmail,
              drawer: const StudioNavigationDrawer(),
              footer: TextButton(
                onPressed: () {
                  context
                      .read<AuthSessionBloc>()
                      .add(const AuthSessionStarted());
                },
                child: Text(tr.authRefreshVerificationCta),
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
                      SizedBox(
                        width: double.infinity,
                        child: AppLoadingButton(
                          isLoading: isLoading,
                          label: tr.authSendVerificationCta,
                          loadingLabel: tr.authLoadingCta,
                          icon: Icons.mark_email_read_rounded,
                          onPressed: () {
                            final connectivityCubit =
                                context.read<ConnectivityCubit>();
                            final authFormBloc = context.read<AuthFormBloc>();
                            connectivityCubit.canUseNetworkAction().then((canUse) {
                              if (!canUse) {
                                return;
                              }
                              authFormBloc.add(
                                    const AuthFormSubmitted(
                                      type: AuthFormType.verifyEmail,
                                      email: 'verification@local.dev',
                                    ),
                                  );
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/'),
                          child: Text(tr.authContinueToAppCta),
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
}
