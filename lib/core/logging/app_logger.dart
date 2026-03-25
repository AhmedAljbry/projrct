import 'dart:developer' as dev;

enum LogLevel { debug, info, warn, error }

class AppLogger {
  const AppLogger();

  void log(String message, {LogLevel level = LogLevel.info, Object? error, StackTrace? stack}) {
    dev.log(
      message,
      name: 'LUMA',
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warn => 900,
        LogLevel.error => 1000,
      },
      error: error,
      stackTrace: stack,
    );
  }
}