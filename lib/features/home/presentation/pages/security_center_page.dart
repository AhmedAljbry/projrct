import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/firebase/firebase_runtime_options.dart';
import 'package:untitled2/core/logging/app_logger.dart';
import 'package:untitled2/core/services/help/help_topic.dart';
import 'package:untitled2/core/widgets/common/app_help_button.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:untitled2/features/home/presentation/widgets/home_copy.dart';
import 'package:untitled2/features/secure_signup/presentation/pages/restricted_signup_page.dart';

class SecurityCenterPage extends StatelessWidget {
  const SecurityCenterPage({
    super.key,
    required this.config,
  });

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final hasSecureSignup = config.secureSignupBaseUrl?.isNotEmpty ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          homeText(
            context,
            ar: 'مركز الحماية',
            en: 'Security Center',
          ),
        ),
        actions: const [
          AppHelpButton(topic: HelpTopic.securityCenter),
        ],
      ),
      body: BlocBuilder<AuthSessionBloc, AuthSessionState>(
        builder: (context, state) {
          final user = state is AuthSessionAuthenticated ? state.user : null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _SecurityCard(
                icon: Icons.verified_user_rounded,
                title: homeText(
                  context,
                  ar: 'حالة الحساب',
                  en: 'Account Status',
                ),
                description: user == null
                    ? homeText(
                        context,
                        ar: 'لا يوجد مستخدم مسجل دخول الآن. يمكنك فتح تسجيل الدخول أو إنشاء حساب من القائمة.',
                        en: 'No user is signed in right now. You can open sign in or create account from the drawer.',
                      )
                    : homeText(
                        context,
                        ar: 'الحساب الحالي: ${user.displayName ?? user.email}\nالبريد: ${user.email}',
                        en: 'Current account: ${user.displayName ?? user.email}\nEmail: ${user.email}',
                      ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatusBadge(
                      label: user == null
                          ? homeText(
                              context,
                              ar: 'غير مسجل دخول',
                              en: 'Signed out',
                            )
                          : homeText(
                              context,
                              ar: 'مسجل دخول',
                              en: 'Signed in',
                            ),
                      color: user == null
                          ? const Color(0xFFEF5350)
                          : const Color(0xFF56E39F),
                    ),
                    _StatusBadge(
                      label: user?.isEmailVerified == true
                          ? homeText(
                              context,
                              ar: 'البريد موثق',
                              en: 'Email verified',
                            )
                          : homeText(
                              context,
                              ar: 'البريد غير موثق',
                              en: 'Email not verified',
                            ),
                      color: user?.isEmailVerified == true
                          ? const Color(0xFF56E39F)
                          : const Color(0xFFFFB74D),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SecurityCard(
                icon: Icons.shield_moon_rounded,
                title: homeText(
                  context,
                  ar: 'طبقات الحماية',
                  en: 'Protection Layers',
                ),
                description: homeText(
                  context,
                  ar: 'التطبيق الآن مرتب بحيث تكون طبقات الحماية واضحة: التحقق من البريد، الربط مع Firebase، والتسجيل المحمي عند تفعيل الخادم.',
                  en: 'The app now exposes its protection layers clearly: email verification, Firebase integration, and protected signup when the backend is configured.',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProtectionRow(
                      title: homeText(
                        context,
                        ar: 'Firebase جاهز',
                        en: 'Firebase ready',
                      ),
                      value: FirebaseRuntimeOptions.isConfigured,
                    ),
                    _ProtectionRow(
                      title: homeText(
                        context,
                        ar: 'رابط التسجيل المحمي',
                        en: 'Secure signup endpoint',
                      ),
                      value: hasSecureSignup,
                    ),
                    _ProtectionRow(
                      title: homeText(
                        context,
                        ar: 'توثيق البريد',
                        en: 'Email verification',
                      ),
                      value: user?.isEmailVerified == true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SecurityCard(
                icon: Icons.admin_panel_settings_rounded,
                title: homeText(
                  context,
                  ar: 'إجراءات سريعة',
                  en: 'Quick Actions',
                ),
                description: homeText(
                  context,
                  ar: 'يمكنك من هنا فتح شاشة التحقق أو مراجعة تدفق التسجيل المحمي الذي أضفناه داخل التطبيق.',
                  en: 'From here you can open email verification or review the protected signup flow we exposed inside the app.',
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: user == null || user.isEmailVerified
                          ? null
                          : () => context.go('/verify-email'),
                      icon: const Icon(Icons.mark_email_read_rounded),
                      label: Text(
                        homeText(
                          context,
                          ar: 'فتح التحقق من البريد',
                          en: 'Open email verification',
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: hasSecureSignup
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => RestrictedSignupPage.create(
                                    config: config,
                                    logger: const AppLogger(),
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.lock_person_rounded),
                      label: Text(
                        homeText(
                          context,
                          ar: 'مراجعة التسجيل المحمي',
                          en: 'Review protected signup',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF56E39F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF56E39F)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProtectionRow extends StatelessWidget {
  const _ProtectionRow({
    required this.title,
    required this.value,
  });

  final String title;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final color = value ? const Color(0xFF56E39F) : const Color(0xFFFFB74D);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          _StatusBadge(
            label: homeText(
              context,
              ar: value ? 'مفعل' : 'غير مكتمل',
              en: value ? 'Enabled' : 'Pending',
            ),
            color: color,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
