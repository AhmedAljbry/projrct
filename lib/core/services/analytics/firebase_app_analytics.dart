import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/core/services/analytics/app_analytics.dart';
import 'package:untitled2/core/services/analytics/app_analytics_event.dart';

@LazySingleton(as: AppAnalytics)
class FirebaseAppAnalytics implements AppAnalytics {
  FirebaseAppAnalytics(this._analytics, this._talker);

  final FirebaseAnalytics _analytics;
  final Talker _talker;

  @override
  Future<void> log(AppAnalyticsEvent event) {
    return logEvent(name: event.name, parameters: event.parameters);
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) {
    return _guard(
      () => _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      ),
      'screen_view:$screenName',
    );
  }

  @override
  Future<void> logLoginAttempt() => _logNamedEvent('login_attempt');

  @override
  Future<void> logLoginSuccess({required String method}) {
    return _guard(
      () => _analytics.logLogin(loginMethod: method),
      'login_success',
    );
  }

  @override
  Future<void> logSignupAttempt() => _logNamedEvent('signup_attempt');

  @override
  Future<void> logSignupSuccess({required String method}) {
    return _guard(
      () => _analytics.logSignUp(signUpMethod: method),
      'signup_success',
    );
  }

  @override
  Future<void> logPasswordResetRequested() {
    return _logNamedEvent('password_reset_requested');
  }

  @override
  Future<void> logLogout() => _logNamedEvent('logout');

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?> parameters = const {},
  }) {
    final filteredParameters = Map<String, Object>.fromEntries(
      parameters.entries.where((entry) => entry.value != null).map(
            (entry) => MapEntry(entry.key, entry.value as Object),
          ),
    );
    return _guard(
      () => _analytics.logEvent(name: name, parameters: filteredParameters),
      name,
    );
  }

  @override
  Future<void> setUserId(String? userId) {
    return _guard(() => _analytics.setUserId(id: userId), 'set_user_id');
  }

  Future<void> _logNamedEvent(String name) {
    return _guard(() => _analytics.logEvent(name: name), name);
  }

  Future<void> _guard(Future<void> Function() action, String actionName) async {
    try {
      await action();
    } catch (error, stackTrace) {
      _talker.warning('Analytics failed: $actionName', error, stackTrace);
    }
  }
}
