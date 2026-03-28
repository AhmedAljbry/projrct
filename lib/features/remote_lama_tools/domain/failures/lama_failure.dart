abstract class LamaFailure implements Exception {
  final String message;
  final bool isRetryable;
  const LamaFailure(this.message, {this.isRetryable = false});

  @override
  String toString() => message;
}

class LamaServerBusyFailure extends LamaFailure {
  const LamaServerBusyFailure(super.message) : super(isRetryable: true);
}

class LamaRateLimitFailure extends LamaFailure {
  const LamaRateLimitFailure(super.message) : super(isRetryable: true);
}

class LamaValidationFailure extends LamaFailure {
  const LamaValidationFailure(super.message);
}

class LamaApiFailure extends LamaFailure {
  const LamaApiFailure(super.message);
}
