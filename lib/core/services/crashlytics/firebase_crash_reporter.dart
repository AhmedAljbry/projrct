import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/core/services/crashlytics/crash_reporter.dart';

@LazySingleton(as: CrashReporter)
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics, this._talker);

  final FirebaseCrashlytics _crashlytics;
  final Talker _talker;

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: reason,
      );
    } catch (innerError, innerStackTrace) {
      _talker.error(
        'Crashlytics recordError failed',
        innerError,
        innerStackTrace,
      );
    }
  }

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> setUserId(String? userId) async {
    await _crashlytics.setUserIdentifier(userId ?? '');
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value);
  }
}
