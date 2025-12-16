import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('🔵 [INFO] $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('🟡 [WARNING] $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🔴 [ERROR] $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }
}
