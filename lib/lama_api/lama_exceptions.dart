class LamaExceptions implements Exception {
  final String message;
  final int? statusCode;

  LamaExceptions(this.message, [this.statusCode]);

  @override
  String toString() => 'LamaException(statusCode: $statusCode, message: $message)';
}

class LamaRateLimitException extends LamaExceptions {
  LamaRateLimitException() : super('Too many requests', 429);
}

class LamaServerBusyException extends LamaExceptions {
  LamaServerBusyException(super.message, [super.statusCode]);
}
