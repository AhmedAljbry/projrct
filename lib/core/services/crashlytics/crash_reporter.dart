abstract class CrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  });

  Future<void> log(String message);

  Future<void> setUserId(String? userId);

  Future<void> setCustomKey(String key, Object value);
}
