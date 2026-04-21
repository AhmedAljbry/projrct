import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/firebase/firebase_runtime_options.dart';
import 'package:untitled2/core/logging/app_logger.dart';
import 'package:untitled2/features/secure_signup/data/datasources/restricted_signup_remote_data_source.dart';
import 'package:untitled2/features/secure_signup/data/repositories/restricted_signup_repository_impl.dart';
import 'package:untitled2/features/secure_signup/data/services/firebase_installation_identity_service.dart';
import 'package:untitled2/features/secure_signup/data/services/firebase_signup_attestation_service.dart';
import 'package:untitled2/features/secure_signup/data/services/method_channel_platform_security_signal_service.dart';
import 'package:untitled2/features/secure_signup/domain/usecases/create_restricted_account_use_case.dart';
import 'package:untitled2/features/secure_signup/domain/usecases/request_signup_override_use_case.dart';
import 'package:untitled2/features/secure_signup/presentation/cubit/restricted_signup_cubit.dart';
import 'package:untitled2/features/secure_signup/presentation/cubit/restricted_signup_state.dart';

class RestrictedSignupPage extends StatefulWidget {
  const RestrictedSignupPage({
    super.key,
    required this.config,
  });

  final AppConfig config;

  static Widget create({
    required AppConfig config,
    required AppLogger logger,
  }) {
    final repository = RestrictedSignupRepositoryImpl(
      remoteDataSource: RestrictedSignupRemoteDataSourceImpl(
        baseUrl: config.secureSignupBaseUrl ?? '',
      ),
      installationIdentityService: FirebaseInstallationIdentityService(
        securitySignalService: MethodChannelPlatformSecuritySignalService(),
      ),
      signupAttestationService: FirebaseSignupAttestationService(),
      logger: logger,
    );
    return BlocProvider(
      create: (_) => RestrictedSignupCubit(
        createRestrictedAccountUseCase:
            CreateRestrictedAccountUseCase(repository),
        requestSignupOverrideUseCase: RequestSignupOverrideUseCase(repository),
      ),
      child: RestrictedSignupPage(config: config),
    );
  }

  @override
  State<RestrictedSignupPage> createState() => _RestrictedSignupPageState();
}

class _RestrictedSignupPageState extends State<RestrictedSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _reviewReasonController = TextEditingController(
    text: 'Legitimate device change or recovery request.',
  );

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _reviewReasonController.dispose();
    super.dispose();
  }

  bool get _isConfigured =>
      FirebaseRuntimeOptions.isConfigured &&
      (widget.config.secureSignupBaseUrl?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Signup'),
      ),
      body: BlocConsumer<RestrictedSignupCubit, RestrictedSignupState>(
        listener: (context, state) {
          if (state.status == RestrictedSignupStatus.success &&
              context.mounted) {
            context.go('/verify-email');
          }
          if (state.userMessage == null || state.userMessage!.isEmpty) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.userMessage!)),
          );
        },
        builder: (context, state) {
          if (!_isConfigured) {
            return _ConfigurationHint(config: widget.config);
          }

          final isBusy = state.status == RestrictedSignupStatus.loading;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'One app installation can create one account. This is a risk-reduction control enforced by the backend using Firebase App Check and Firebase Installations.',
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _displayNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Enter a display name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Enter a valid email.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Use at least 8 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isBusy ? null : _submit,
                        child: Text(isBusy ? 'Working...' : 'Create account'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _StatusCard(state: state),
              if (state.status == RestrictedSignupStatus.blocked ||
                  state.status ==
                      RestrictedSignupStatus.verificationRequired) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _reviewReasonController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Manual review reason',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () =>
                            context.read<RestrictedSignupCubit>().requestReview(
                                  reason: _reviewReasonController.text.trim(),
                                ),
                    child: const Text('Request manual review'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    context.read<RestrictedSignupCubit>().submit(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
        );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final RestrictedSignupState state;

  @override
  Widget build(BuildContext context) {
    final message = switch (state.status) {
      RestrictedSignupStatus.success =>
        'Signup allowed. The installation is now linked to this account.',
      RestrictedSignupStatus.blocked => state.failure?.message ??
          'This installation has already been used for account creation.',
      RestrictedSignupStatus.verificationRequired => state.failure?.message ??
          state.result?.message ??
          'Extra verification is required before signup can continue.',
      RestrictedSignupStatus.reviewRequested =>
        'Your override request is pending admin review.',
      RestrictedSignupStatus.failure =>
        state.failure?.message ?? 'Signup failed unexpectedly.',
      _ =>
        'Protected signup is backed by App Check, Firebase Auth, and installation-based enforcement.',
    };

    final color = switch (state.status) {
      RestrictedSignupStatus.success => Colors.green,
      RestrictedSignupStatus.blocked => Colors.redAccent,
      RestrictedSignupStatus.verificationRequired => Colors.orangeAccent,
      RestrictedSignupStatus.reviewRequested => Colors.blueAccent,
      RestrictedSignupStatus.failure => Colors.redAccent,
      _ => Colors.white24,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(message),
    );
  }
}

class _ConfigurationHint extends StatelessWidget {
  const _ConfigurationHint({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final missing = <String>[
      if (!FirebaseRuntimeOptions.isConfigured) 'Firebase runtime options',
      if (config.secureSignupBaseUrl == null ||
          config.secureSignupBaseUrl!.isEmpty)
        'SECURE_SIGNUP_BASE_URL',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Secure signup is disabled until these values are configured: ${missing.join(', ')}.',
        ),
      ),
    );
  }
}
