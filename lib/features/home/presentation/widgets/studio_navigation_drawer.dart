import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/logging/app_logger.dart';
import 'package:untitled2/core/services/permissions/permission_ux_service.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:untitled2/features/auth/presentation/widgets/account_status_badge.dart';
import 'package:untitled2/features/home/presentation/pages/security_center_page.dart';
import 'package:untitled2/features/home/presentation/widgets/home_copy.dart';
import 'package:untitled2/features/secure_signup/presentation/pages/restricted_signup_page.dart';

class StudioNavigationDrawer extends StatefulWidget {
  const StudioNavigationDrawer({
    super.key,
    this.onOpenOperations,
  });

  final VoidCallback? onOpenOperations;

  @override
  State<StudioNavigationDrawer> createState() => _StudioNavigationDrawerState();
}

class _StudioNavigationDrawerState extends State<StudioNavigationDrawer> {
  Future<PermissionStatus> _galleryPermissionStatus() {
    return (Platform.isIOS ? Permission.photos : Permission.storage).status;
  }

  Future<void> _requestGalleryPermission(BuildContext context) async {
    final granted = await getIt<PermissionUxService>().ensureGalleryPermission(
      context,
    );
    if (mounted && granted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = getIt<AppConfig>();
    final hasSecureSignup = config.secureSignupBaseUrl?.isNotEmpty ?? false;
    return Drawer(
      backgroundColor: const Color(0xFF101318),
      child: SafeArea(
        child: BlocBuilder<AuthSessionBloc, AuthSessionState>(
          builder: (context, state) {
            final user = state is AuthSessionAuthenticated ? state.user : null;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _DrawerHeader(user: user, state: state),
                const SizedBox(height: 18),
                _SectionLabel(
                  title: homeText(
                    context,
                    ar: 'الوصول السريع',
                    en: 'Quick access',
                  ),
                ),
                FutureBuilder<PermissionStatus>(
                  future: _galleryPermissionStatus(),
                  builder: (context, snapshot) {
                    final status = snapshot.data;
                    final isGranted =
                        status?.isGranted == true || status?.isLimited == true;
                    return _DrawerTile(
                      icon: isGranted
                          ? Icons.photo_library_rounded
                          : Icons.perm_media_rounded,
                      title: homeText(
                        context,
                        ar: 'صلاحية التخزين',
                        en: 'Storage permission',
                      ),
                      subtitle: isGranted
                          ? homeText(
                              context,
                              ar: 'مفعلة ويمكنك اختيار الصور من الجهاز مباشرة.',
                              en:
                                  'Enabled, so you can pick photos from the device.',
                            )
                          : homeText(
                              context,
                              ar: 'اضغط للموافقة على الوصول للصور قبل استخدام الأدوات.',
                              en:
                                  'Tap to approve photo access before using the tools.',
                            ),
                      trailingLabel: isGranted
                          ? homeText(
                              context,
                              ar: 'مفعلة',
                              en: 'Ready',
                            )
                          : homeText(
                              context,
                              ar: 'موافقة',
                              en: 'Approve',
                            ),
                      onTap: () => _requestGalleryPermission(context),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.pending_actions_rounded,
                  title: homeText(
                    context,
                    ar: 'مركز العمليات',
                    en: 'Operations center',
                  ),
                  subtitle: homeText(
                    context,
                    ar: 'راجع المهام الجارية والنتائج داخل التطبيق.',
                    en: 'Review active jobs and results inside the app.',
                  ),
                  enabled: widget.onOpenOperations != null,
                  onTap: widget.onOpenOperations == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          widget.onOpenOperations!.call();
                        },
                ),
                _DrawerTile(
                  icon: Icons.settings_outlined,
                  title: homeText(
                    context,
                    ar: 'الإعدادات',
                    en: 'Settings',
                  ),
                  subtitle: homeText(
                    context,
                    ar: 'اللغة والمساعدة وخيارات التطبيق العامة.',
                    en: 'Language, help, and general app options.',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/settings');
                  },
                ),
                _DrawerTile(
                  icon: Icons.security_rounded,
                  title: homeText(
                    context,
                    ar: 'مركز الحماية',
                    en: 'Security center',
                  ),
                  subtitle: homeText(
                    context,
                    ar: 'راجع حالة التحقق وطبقات الحماية المتاحة.',
                    en: 'Review verification status and available protection layers.',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SecurityCenterPage(config: config),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _SectionLabel(
                  title: homeText(
                    context,
                    ar: 'الحساب',
                    en: 'Account',
                  ),
                ),
                if (user == null) ...[
                  _DrawerTile(
                    icon: Icons.login_rounded,
                    title: homeText(
                      context,
                      ar: 'تسجيل الدخول',
                      en: 'Sign in',
                    ),
                    subtitle: homeText(
                      context,
                      ar: 'اختياري ويمكنك فتحه في أي وقت من دون إيقاف استخدام التطبيق.',
                      en:
                          'Optional, and you can open it anytime without blocking app usage.',
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/login');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.person_add_alt_1_rounded,
                    title: homeText(
                      context,
                      ar: 'إنشاء حساب',
                      en: 'Create account',
                    ),
                    subtitle: homeText(
                      context,
                      ar: 'أنشئ حسابًا طبيعيًا عندما تحتاج المزامنة أو الحماية.',
                      en:
                          'Create a normal account when you need sync or extra protection.',
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/register');
                    },
                  ),
                ] else ...[
                  _DrawerTile(
                    icon: Icons.account_circle_rounded,
                    title: user.displayName ?? user.email,
                    subtitle: user.email,
                    trailingLabel: user.isEmailVerified
                        ? homeText(
                            context,
                            ar: 'موثق',
                            en: 'Verified',
                          )
                        : homeText(
                            context,
                            ar: 'غير موثق',
                            en: 'Pending',
                          ),
                  ),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    title: homeText(
                      context,
                      ar: 'تسجيل الخروج',
                      en: 'Sign out',
                    ),
                    subtitle: homeText(
                      context,
                      ar: 'إنهاء الجلسة الحالية مع بقاء التطبيق متاحًا كزائر.',
                      en:
                          'End the current session while keeping guest access available.',
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      context
                          .read<AuthSessionBloc>()
                          .add(const AuthSignOutRequested());
                    },
                  ),
                ],
                if (hasSecureSignup) ...[
                  const SizedBox(height: 14),
                  _SectionLabel(
                    title: homeText(
                      context,
                      ar: 'حماية إضافية',
                      en: 'Extra protection',
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.lock_person_rounded,
                    title: homeText(
                      context,
                      ar: 'التسجيل المحمي',
                      en: 'Protected signup',
                    ),
                    subtitle: homeText(
                      context,
                      ar: 'افتح مسار التسجيل المحمي عند الحاجة.',
                      en: 'Open the protected signup flow when needed.',
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RestrictedSignupPage.create(
                            config: config,
                            logger: const AppLogger(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.user,
    required this.state,
  });

  final dynamic user;
  final AuthSessionState state;

  @override
  Widget build(BuildContext context) {
    final title = homeText(
      context,
      ar: 'قائمة التطبيق',
      en: 'App menu',
    );
    final subtitle = user == null
        ? homeText(
            context,
            ar: 'يمكنك استخدام كل أدوات التطبيق بدون حساب، وتسجيل الدخول اختياري من هنا.',
            en:
                'You can use the app tools without an account, and sign in is optional from here.',
          )
        : homeText(
            context,
            ar: 'أهلًا ${user.displayName ?? user.email}',
            en: 'Welcome ${user.displayName ?? user.email}',
          );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F2B), Color(0xFF12221B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF56E39F), Color(0xFF3D8BFD)],
              ),
            ),
            child: const Icon(Icons.dashboard_customize_rounded),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 14),
          AccountStatusBadge(state: state),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.onTap,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.white : Colors.white38;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: enabled ? onTap : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        tileColor: Colors.white.withValues(alpha: 0.04),
        leading: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white60,
                height: 1.4,
              ),
        ),
        trailing: trailingLabel == null
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF56E39F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trailingLabel!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF56E39F),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
      ),
    );
  }
}
