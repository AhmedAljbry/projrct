import '../logging/app_logger.dart';

class ErrorReporter {
  final AppLogger logger;
  const ErrorReporter(this.logger);

  void report(Object error, StackTrace stack, {String context = "unknown"}) {
    logger.log("Error in $context", level: LogLevel.error, error: error, stack: stack);
    // جاهز لاحقًا: Crashlytics/Sentry

  }


  void capture(Object error, StackTrace stack, {String? context}) {
    logger.log(
      context == null ? 'Error captured' : 'Error captured: $context',
      level: LogLevel.error,
      error: error,
      stack: stack,
    );
  }
}