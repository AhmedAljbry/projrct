import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/app/router/analytics_route_observer.dart';
import 'package:untitled2/app/router/router_refresh_notifier.dart';
import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/i18n/locale_controller.dart';
import 'package:untitled2/core/services/analytics/app_analytics.dart';
import 'package:untitled2/core/services/remote_config/remote_config_service.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:untitled2/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:untitled2/features/auth/presentation/screens/register_screen.dart';
import 'package:untitled2/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:untitled2/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:untitled2/features/home/presentation/screens/home_screen.dart';
import 'package:untitled2/features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  AppRouter({
    required AuthSessionBloc authSessionBloc,
    required AppAnalytics analytics,
    required RemoteConfigService remoteConfigService,
    required AppConfig appConfig,
    required LocaleController localeController,
  }) : router = GoRouter(
          initialLocation: '/',
          refreshListenable: RouterRefreshNotifier(authSessionBloc.stream),
          observers: [AnalyticsRouteObserver(analytics)],
          redirect: (context, state) {
            final authState = authSessionBloc.state;
            final path = state.matchedLocation;
            if (authState is AuthSessionUnknown) {
              return path == '/splash' ? null : '/splash';
            }
            if (remoteConfigService.isMaintenanceMode &&
                path != '/' &&
                path != '/login' &&
                path != '/register') {
              return '/';
            }
            if (authState is AuthSessionGuest &&
                path == '/verify-email') {
              return '/';
            }
            if (authState is AuthSessionAuthenticated) {
              if (path == '/splash') {
                return '/';
              }
            }
            return null;
          },
          routes: [
            GoRoute(
              path: '/splash',
              name: 'splash',
              builder: (_, __) => const _SplashScreen(),
            ),
            GoRoute(
              path: '/',
              name: 'home',
              builder: (_, __) => HomeScreen(
                config: appConfig,
                localeController: localeController,
              ),
            ),
            GoRoute(
              path: '/login',
              name: 'login',
              builder: (_, __) => const SignInScreen(),
            ),
            GoRoute(
              path: '/register',
              name: 'register',
              builder: (_, __) => const RegisterScreen(),
            ),
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (_, __) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/forgot-password',
              name: 'forgot-password',
              builder: (_, __) => const ForgotPasswordScreen(),
            ),
            GoRoute(
              path: '/verify-email',
              name: 'verify-email',
              builder: (_, __) => const VerifyEmailScreen(),
            ),
          ],
        );

  final GoRouter router;
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
