import 'app_analytics_event.dart';

abstract class AppAnalytics {
  Future<void> log(AppAnalyticsEvent event);

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  });

  Future<void> logLoginAttempt();

  Future<void> logLoginSuccess({required String method});

  Future<void> logSignupAttempt();

  Future<void> logSignupSuccess({required String method});

  Future<void> logPasswordResetRequested();

  Future<void> logLogout();

  Future<void> logEvent({
    required String name,
    Map<String, Object?> parameters = const {},
  });

  Future<void> setUserId(String? userId);
}
