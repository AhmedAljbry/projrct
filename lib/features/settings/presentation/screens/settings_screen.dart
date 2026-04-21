import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';
import 'package:untitled2/core/i18n/locale_controller.dart';
import 'package:untitled2/core/services/analytics/app_analytics.dart';
import 'package:untitled2/core/services/analytics/app_analytics_event.dart';
import 'package:untitled2/core/services/feedback/app_feedback_message.dart';
import 'package:untitled2/core/services/feedback/user_feedback_service.dart';
import 'package:untitled2/core/services/help/help_topic.dart';
import 'package:untitled2/core/widgets/common/app_help_button.dart';
import 'package:untitled2/core/widgets/states/app_loading_state.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:untitled2/features/auth/presentation/widgets/account_status_badge.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  LocaleController get _localeController => getIt<LocaleController>();
  UserFeedbackService get _feedback => getIt<UserFeedbackService>();
  AppAnalytics get _analytics => getIt<AppAnalytics>();

  @override
  void initState() {
    super.initState();
    _analytics.log(AppAnalyticsEvent.settingsOpened());
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    setState(() => _packageInfo = packageInfo);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.settingsTitle),
        actions: const [
          AppHelpButton(topic: HelpTopic.settings),
        ],
      ),
      body: _packageInfo == null
          ? const AppLoadingState()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                BlocBuilder<AuthSessionBloc, AuthSessionState>(
                  builder: (context, state) {
                    final user =
                        state is AuthSessionAuthenticated ? state.user : null;
                    return Column(
                      children: [
                        _SectionCard(
                          title: tr.settingsAccountTitle,
                          subtitle: tr.settingsAccountSubtitle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AccountStatusBadge(state: state),
                              const SizedBox(height: 16),
                              _InfoTile(
                                label: tr.settingsAccountStateLabel,
                                value: state is AuthSessionAuthenticated
                                    ? tr.accountStatusLoggedIn
                                    : tr.accountStatusGuest,
                              ),
                              _InfoTile(
                                label: tr.settingsAccountIdentityLabel,
                                value: user?.email ??
                                    tr.settingsAccountGuestIdentity,
                              ),
                              const SizedBox(height: 8),
                              if (state is! AuthSessionAuthenticated) ...[
                                _ActionTile(
                                  icon: Icons.login_rounded,
                                  title: tr.authSignInCta,
                                  onTap: () => context.go('/login'),
                                ),
                                _ActionTile(
                                  icon: Icons.person_add_alt_1_rounded,
                                  title: tr.authRegisterCta,
                                  onTap: () => context.go('/register'),
                                ),
                              ] else
                                _ActionTile(
                                  icon: Icons.logout_rounded,
                                  title: tr.settingsSignOut,
                                  onTap: () => context
                                      .read<AuthSessionBloc>()
                                      .add(const AuthSignOutRequested()),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                _SectionCard(
                  title: tr.settingsLanguageTitle,
                  subtitle: tr.settingsLanguageSubtitle,
                  child: DropdownButtonFormField<Locale>(
                    value: _localeController.locale,
                    items: [
                      DropdownMenuItem(
                        value: const Locale('en'),
                        child: Text(tr.languageEnglish),
                      ),
                      DropdownMenuItem(
                        value: const Locale('ar'),
                        child: Text(tr.languageArabic),
                      ),
                    ],
                    onChanged: (locale) async {
                      if (locale == null) {
                        return;
                      }
                      await _localeController.setLocale(locale);
                      await _analytics.log(
                        AppAnalyticsEvent.languageChanged(
                          languageCode: locale.languageCode,
                        ),
                      );
                      _feedback.showSuccess(AppMessageKey.languageUpdated);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: tr.settingsAboutTitle,
                  subtitle: tr.settingsAboutSubtitle,
                  child: Column(
                    children: [
                      _InfoTile(
                        label: tr.settingsVersionLabel,
                        value:
                            '${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                      ),
                      _InfoTile(
                        label: tr.settingsPackageLabel,
                        value: _packageInfo!.packageName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: tr.settingsSupportTitle,
                  subtitle: tr.settingsSupportSubtitle,
                  child: Column(
                    children: [
                      _ActionTile(
                        icon: Icons.privacy_tip_outlined,
                        title: tr.settingsPrivacyPolicy,
                        onTap: _showPlaceholder,
                      ),
                      _ActionTile(
                        icon: Icons.gavel_outlined,
                        title: tr.settingsTermsOfService,
                        onTap: _showPlaceholder,
                      ),
                      _ActionTile(
                        icon: Icons.support_agent_rounded,
                        title: tr.settingsContactSupport,
                        onTap: _showPlaceholder,
                      ),
                      _ActionTile(
                        icon: Icons.star_outline_rounded,
                        title: tr.settingsRateApp,
                        onTap: _showPlaceholder,
                      ),
                      _ActionTile(
                        icon: Icons.cleaning_services_outlined,
                        title: tr.settingsClearCache,
                        onTap: _showPlaceholder,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showPlaceholder() {
    _feedback.showInfo(AppMessageKey.supportComingSoon);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
