typedef AsyncFactory<T> = Future<T> Function();
typedef SyncFactory<T> = T Function();

class SafeExecutor {
  const SafeExecutor();

  Future<T> runAsync<T>(
    AsyncFactory<T> action, {
    required T fallback,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      return fallback;
    }
  }

  T runSync<T>(
    SyncFactory<T> action, {
    required T fallback,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    try {
      return action();
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      return fallback;
    }
  }
}
