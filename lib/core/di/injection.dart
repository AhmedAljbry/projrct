import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/firebase/firebase_bootstrap.dart';
import 'package:untitled2/core/di/injection.config.dart';
import 'package:untitled2/core/i18n/locale_controller.dart';
import 'package:untitled2/core/services/analytics/app_analytics.dart';
import 'package:untitled2/core/services/connectivity/connectivity_cubit.dart';
import 'package:untitled2/core/services/connectivity/connectivity_service.dart';
import 'package:untitled2/core/services/feedback/app_message_localizer.dart';
import 'package:untitled2/core/services/feedback/user_feedback_service.dart';
import 'package:untitled2/core/services/help/help_content_service.dart';
import 'package:untitled2/core/services/permissions/permission_ux_service.dart';
import 'package:untitled2/features/auth/domain/repositories/auth_repository.dart';
import 'package:untitled2/features/auth/domain/usecases/get_auth_state_use_case.dart';
import 'package:untitled2/features/auth/domain/usecases/listen_auth_changes_use_case.dart';
import 'package:untitled2/features/auth/domain/usecases/mark_login_reminder_dismissed_use_case.dart';
import 'package:untitled2/features/auth/domain/usecases/should_show_login_reminder_use_case.dart';
import 'package:talker/talker.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(initializerName: r'$initGetIt')
Future<void> configureDependencies({
  required AppConfig appConfig,
  required SharedPreferences sharedPreferences,
  required LocaleController localeController,
}) async {
  if (!getIt.isRegistered<AppConfig>()) {
    getIt.registerSingleton<AppConfig>(appConfig);
  }
  if (!getIt.isRegistered<SharedPreferences>()) {
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  }
  if (!getIt.isRegistered<LocaleController>()) {
    getIt.registerSingleton<LocaleController>(localeController);
  }
  if (!getIt.isRegistered<FirebaseBootstrap>()) {
    getIt.registerLazySingleton<FirebaseBootstrap>(
        () => const FirebaseBootstrap());
  }
  getIt.$initGetIt();
  if (!getIt.isRegistered<Connectivity>()) {
    getIt.registerLazySingleton<Connectivity>(Connectivity.new);
  }
  if (!getIt.isRegistered<AppMessageLocalizer>()) {
    getIt.registerLazySingleton<AppMessageLocalizer>(AppMessageLocalizer.new);
  }
  if (!getIt.isRegistered<UserFeedbackService>()) {
    getIt.registerLazySingleton<UserFeedbackService>(UserFeedbackService.new);
  }
  if (!getIt.isRegistered<HelpContentService>()) {
    getIt.registerLazySingleton<HelpContentService>(HelpContentService.new);
  }
  if (!getIt.isRegistered<ConnectivityService>()) {
    getIt.registerLazySingleton<ConnectivityService>(
      () => ConnectivityService(getIt<Connectivity>(), getIt<Talker>()),
    );
  }
  if (!getIt.isRegistered<PermissionUxService>()) {
    getIt.registerLazySingleton<PermissionUxService>(
      () => PermissionUxService(getIt<UserFeedbackService>()),
    );
  }
  if (!getIt.isRegistered<ConnectivityCubit>()) {
    getIt.registerLazySingleton<ConnectivityCubit>(
      () => ConnectivityCubit(
        getIt<ConnectivityService>(),
        getIt<AppAnalytics>(),
      ),
    );
  }
  if (!getIt.isRegistered<GetAuthStateUseCase>()) {
    getIt.registerFactory<GetAuthStateUseCase>(
      () => GetAuthStateUseCase(getIt<AuthRepository>()),
    );
  }
  if (!getIt.isRegistered<ListenAuthChangesUseCase>()) {
    getIt.registerFactory<ListenAuthChangesUseCase>(
      () => ListenAuthChangesUseCase(getIt<AuthRepository>()),
    );
  }
  if (!getIt.isRegistered<ShouldShowLoginReminderUseCase>()) {
    getIt.registerFactory<ShouldShowLoginReminderUseCase>(
      () => ShouldShowLoginReminderUseCase(getIt<AuthRepository>()),
    );
  }
  if (!getIt.isRegistered<MarkLoginReminderDismissedUseCase>()) {
    getIt.registerFactory<MarkLoginReminderDismissedUseCase>(
      () => MarkLoginReminderDismissedUseCase(getIt<AuthRepository>()),
    );
  }
}
