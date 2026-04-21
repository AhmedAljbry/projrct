import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/app/router/app_router.dart';
import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/i18n/locale_controller.dart';
import 'package:untitled2/core/services/analytics/app_analytics.dart';
import 'package:untitled2/core/services/analytics/app_analytics_event.dart';
import 'package:untitled2/core/services/connectivity/connectivity_cubit.dart';
import 'package:untitled2/core/ui/AppL10n.dart';
import 'package:untitled2/core/ui/app_theme.dart';
import 'package:untitled2/core/widgets/feedback/app_feedback_listener.dart';
import 'package:untitled2/core/widgets/feedback/app_offline_banner.dart';
import 'package:untitled2/features/auth/domain/usecases/mark_login_reminder_dismissed_use_case.dart';
import 'package:untitled2/features/auth/domain/usecases/should_show_login_reminder_use_case.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:untitled2/features/auth/presentation/bloc/login_reminder_cubit.dart';
import 'package:untitled2/features/auth/presentation/widgets/login_reminder_coordinator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StudioApp extends StatefulWidget {
  const StudioApp({
    super.key,
    required this.config,
    required this.localeController,
  });

  final AppConfig config;
  final LocaleController localeController;

  @override
  State<StudioApp> createState() => _StudioAppState();
}

class _StudioAppState extends State<StudioApp> {
  late final AuthSessionBloc _authSessionBloc = getIt<AuthSessionBloc>()
    ..add(const AuthSessionStarted());
  late final ConnectivityCubit _connectivityCubit = getIt<ConnectivityCubit>();
  late final LoginReminderCubit _loginReminderCubit = LoginReminderCubit(
    getIt<ShouldShowLoginReminderUseCase>(),
    getIt<MarkLoginReminderDismissedUseCase>(),
    getIt(),
  );
  late final AppRouter _appRouter = AppRouter(
    authSessionBloc: _authSessionBloc,
    analytics: getIt(),
    remoteConfigService: getIt(),
    appConfig: widget.config,
    localeController: widget.localeController,
  );

  @override
  void initState() {
    super.initState();
    getIt<AppAnalytics>().log(AppAnalyticsEvent.appOpen());
  }

  @override
  void dispose() {
    _loginReminderCubit.close();
    _connectivityCubit.close();
    _authSessionBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authSessionBloc),
        BlocProvider.value(value: _connectivityCubit),
        BlocProvider.value(value: _loginReminderCubit),
      ],
      child: AnimatedBuilder(
        animation: widget.localeController,
        builder: (context, _) {
          return MaterialApp.router(
            locale: widget.localeController.locale,
            debugShowCheckedModeBanner: false,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppL10nDelegate(),
              ...AppLocalizations.localizationsDelegates,
            ],
            theme: AppTheme.dark(),
            builder: (context, child) {
              return LoginReminderCoordinator(
                child: AppFeedbackListener(
                  child: Column(
                    children: [
                      const AppOfflineBanner(),
                      Expanded(child: child ?? const SizedBox.shrink()),
                    ],
                  ),
                ),
              );
            },
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
