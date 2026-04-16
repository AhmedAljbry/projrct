import 'package:flutter/foundation.dart';

class ModuleLogger {
  const ModuleLogger(this.enabled);

  final bool enabled;

  void info(String message) {
    if (enabled) {
      debugPrint('[CoinsModule][INFO] $message');
    }
  }

  void warn(String message) {
    if (enabled) {
      debugPrint('[CoinsModule][WARN] $message');
    }
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (enabled) {
      debugPrint(
          '[CoinsModule][ERROR] $message ${error ?? ''} ${stackTrace ?? ''}');
    }
  }
}
