// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:firebase_analytics/firebase_analytics.dart' as _i398;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_crashlytics/firebase_crashlytics.dart' as _i141;
import 'package:firebase_messaging/firebase_messaging.dart' as _i892;
import 'package:firebase_remote_config/firebase_remote_config.dart' as _i627;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:talker/talker.dart' as _i993;
import 'package:untitled2/core/di/register_module.dart' as _i23;
import 'package:untitled2/core/monetization/domain/monetization_decision_engine.dart'
    as _i1037;
import 'package:untitled2/core/monetization/services/ad_inventory_manager.dart'
    as _i65;
import 'package:untitled2/core/monetization/services/monetization_analytics.dart'
    as _i90;
import 'package:untitled2/core/monetization/services/monetization_engine.dart'
    as _i554;
import 'package:untitled2/core/monetization/services/monetization_remote_config_service.dart'
    as _i802;
import 'package:untitled2/core/monetization/services/premium_access_service.dart'
    as _i76;
import 'package:untitled2/core/monetization/services/user_consumption_tracker.dart'
    as _i513;
import 'package:untitled2/core/services/analytics/app_analytics.dart' as _i222;
import 'package:untitled2/core/services/analytics/firebase_app_analytics.dart'
    as _i639;
import 'package:untitled2/core/services/app_check/app_check_service.dart'
    as _i519;
import 'package:untitled2/core/services/connectivity/connectivity_cubit.dart'
    as _i523;
import 'package:untitled2/core/services/connectivity/connectivity_service.dart'
    as _i204;
import 'package:untitled2/core/services/crashlytics/crash_reporter.dart'
    as _i758;
import 'package:untitled2/core/services/crashlytics/firebase_crash_reporter.dart'
    as _i1021;
import 'package:untitled2/core/services/feedback/app_message_localizer.dart'
    as _i454;
import 'package:untitled2/core/services/feedback/user_feedback_service.dart'
    as _i848;
import 'package:untitled2/core/services/help/help_content_service.dart'
    as _i947;
import 'package:untitled2/core/services/messaging/push_notification_service.dart'
    as _i759;
import 'package:untitled2/core/services/permissions/permission_ux_service.dart'
    as _i878;
import 'package:untitled2/core/services/remote_config/remote_config_service.dart'
    as _i208;
import 'package:untitled2/features/auth/data/repositories/firebase_auth_repository.dart'
    as _i382;
import 'package:untitled2/features/auth/domain/repositories/auth_repository.dart'
    as _i472;
import 'package:untitled2/features/auth/domain/usecases/get_current_user.dart'
    as _i400;
import 'package:untitled2/features/auth/domain/usecases/send_email_verification.dart'
    as _i709;
import 'package:untitled2/features/auth/domain/usecases/send_password_reset_email.dart'
    as _i330;
import 'package:untitled2/features/auth/domain/usecases/sign_in_with_email_password.dart'
    as _i61;
import 'package:untitled2/features/auth/domain/usecases/sign_out.dart' as _i407;
import 'package:untitled2/features/auth/domain/usecases/sign_up_with_email_password.dart'
    as _i656;
import 'package:untitled2/features/auth/domain/usecases/watch_auth_state.dart'
    as _i852;
import 'package:untitled2/features/auth/presentation/bloc/auth_form_bloc.dart'
    as _i210;
import 'package:untitled2/features/auth/presentation/bloc/auth_session_bloc.dart'
    as _i995;
import 'package:untitled2/features/profile/data/repositories/firebase_user_profile_repository.dart'
    as _i715;
import 'package:untitled2/features/profile/data/services/firebase_user_storage_service.dart'
    as _i657;
import 'package:untitled2/features/profile/domain/repositories/user_profile_repository.dart'
    as _i788;
import 'package:untitled2/features/profile/domain/services/user_storage_service.dart'
    as _i781;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt $initGetIt({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.singleton<_i993.Talker>(() => registerModule.talker);
    gh.lazySingleton<_i59.FirebaseAuth>(() => registerModule.firebaseAuth);
    gh.lazySingleton<_i398.FirebaseAnalytics>(
        () => registerModule.firebaseAnalytics);
    gh.lazySingleton<_i141.FirebaseCrashlytics>(
        () => registerModule.firebaseCrashlytics);
    gh.lazySingleton<_i892.FirebaseMessaging>(
        () => registerModule.firebaseMessaging);
    gh.lazySingleton<_i627.FirebaseRemoteConfig>(
        () => registerModule.firebaseRemoteConfig);
    gh.lazySingleton<_i974.FirebaseFirestore>(
        () => registerModule.firebaseFirestore);
    gh.lazySingleton<_i457.FirebaseStorage>(
        () => registerModule.firebaseStorage);
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i1037.MonetizationDecisionEngine>(
        () => const _i1037.MonetizationDecisionEngine());
    gh.lazySingleton<_i454.AppMessageLocalizer>(
        () => _i454.AppMessageLocalizer());
    gh.lazySingleton<_i848.UserFeedbackService>(
        () => _i848.UserFeedbackService());
    gh.lazySingleton<_i947.HelpContentService>(
        () => _i947.HelpContentService());
    gh.lazySingleton<_i781.UserStorageService>(
        () => _i657.FirebaseUserStorageService(
              gh<_i457.FirebaseStorage>(),
              gh<_i993.Talker>(),
            ));
    gh.lazySingleton<_i204.ConnectivityService>(() => _i204.ConnectivityService(
          gh<_i895.Connectivity>(),
          gh<_i993.Talker>(),
        ));
    gh.lazySingleton<_i878.PermissionUxService>(
        () => _i878.PermissionUxService(gh<_i848.UserFeedbackService>()));
    gh.lazySingleton<_i788.UserProfileRepository>(
        () => _i715.FirebaseUserProfileRepository(
              gh<_i974.FirebaseFirestore>(),
              gh<_i993.Talker>(),
            ));
    gh.lazySingleton<_i76.PremiumAccessService>(
        () => _i76.PremiumAccessService(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i758.CrashReporter>(() => _i1021.FirebaseCrashReporter(
          gh<_i141.FirebaseCrashlytics>(),
          gh<_i993.Talker>(),
        ));
    gh.lazySingleton<_i519.AppCheckService>(
        () => _i519.AppCheckService(gh<_i993.Talker>()));
    gh.lazySingleton<_i208.RemoteConfigService>(() => _i208.RemoteConfigService(
          gh<_i627.FirebaseRemoteConfig>(),
          gh<_i993.Talker>(),
        ));
    gh.lazySingleton<_i513.UserConsumptionTracker>(
        () => _i513.UserConsumptionTracker(
              gh<_i460.SharedPreferences>(),
              gh<_i76.PremiumAccessService>(),
            ));
    gh.lazySingleton<_i222.AppAnalytics>(() => _i639.FirebaseAppAnalytics(
          gh<_i398.FirebaseAnalytics>(),
          gh<_i993.Talker>(),
        ));
    gh.lazySingleton<_i759.PushNotificationService>(
        () => _i759.PushNotificationService(
              gh<_i892.FirebaseMessaging>(),
              gh<_i788.UserProfileRepository>(),
              gh<_i993.Talker>(),
            ));
    gh.lazySingleton<_i90.MonetizationAnalytics>(
        () => _i90.MonetizationAnalytics(
              gh<_i222.AppAnalytics>(),
              gh<_i993.Talker>(),
            ));
    gh.lazySingleton<_i523.ConnectivityCubit>(() => _i523.ConnectivityCubit(
          gh<_i204.ConnectivityService>(),
          gh<_i222.AppAnalytics>(),
        ));
    gh.lazySingleton<_i802.MonetizationRemoteConfigService>(
        () => _i802.MonetizationRemoteConfigService(
              gh<_i208.RemoteConfigService>(),
              gh<_i993.Talker>(),
            ));
    gh.lazySingleton<_i65.AdInventoryManager>(() => _i65.AdInventoryManager(
          gh<_i993.Talker>(),
          gh<_i90.MonetizationAnalytics>(),
        ));
    gh.lazySingleton<_i472.AuthRepository>(() => _i382.FirebaseAuthRepository(
          gh<_i59.FirebaseAuth>(),
          gh<_i788.UserProfileRepository>(),
          gh<_i222.AppAnalytics>(),
          gh<_i758.CrashReporter>(),
          gh<_i759.PushNotificationService>(),
          gh<_i208.RemoteConfigService>(),
          gh<_i993.Talker>(),
        ));
    gh.factory<_i400.GetCurrentUser>(
        () => _i400.GetCurrentUser(gh<_i472.AuthRepository>()));
    gh.factory<_i709.SendEmailVerification>(
        () => _i709.SendEmailVerification(gh<_i472.AuthRepository>()));
    gh.factory<_i330.SendPasswordResetEmail>(
        () => _i330.SendPasswordResetEmail(gh<_i472.AuthRepository>()));
    gh.factory<_i61.SignInWithEmailPassword>(
        () => _i61.SignInWithEmailPassword(gh<_i472.AuthRepository>()));
    gh.factory<_i407.SignOut>(() => _i407.SignOut(gh<_i472.AuthRepository>()));
    gh.factory<_i656.SignUpWithEmailPassword>(
        () => _i656.SignUpWithEmailPassword(gh<_i472.AuthRepository>()));
    gh.factory<_i852.WatchAuthState>(
        () => _i852.WatchAuthState(gh<_i472.AuthRepository>()));
    gh.factory<_i210.AuthFormBloc>(() => _i210.AuthFormBloc(
          gh<_i61.SignInWithEmailPassword>(),
          gh<_i656.SignUpWithEmailPassword>(),
          gh<_i330.SendPasswordResetEmail>(),
          gh<_i709.SendEmailVerification>(),
        ));
    gh.lazySingleton<_i554.MonetizationEngine>(() => _i554.MonetizationEngine(
          gh<_i1037.MonetizationDecisionEngine>(),
          gh<_i65.AdInventoryManager>(),
          gh<_i802.MonetizationRemoteConfigService>(),
          gh<_i90.MonetizationAnalytics>(),
          gh<_i513.UserConsumptionTracker>(),
          gh<_i895.Connectivity>(),
          gh<_i993.Talker>(),
        ));
    gh.lazySingleton<_i995.AuthSessionBloc>(() => _i995.AuthSessionBloc(
          gh<_i852.WatchAuthState>(),
          gh<_i407.SignOut>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i23.RegisterModule {}
