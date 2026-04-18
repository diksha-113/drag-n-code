import 'package:logging/logging.dart';

final Logger _vmLogger = Logger('vm');

/// Enable logging globally
void enableLogging() {
  // Set the root logger level
  Logger.root.level = Level.ALL;

  // Listen to logs and print them to console
  Logger.root.onRecord.listen((record) {
    final level = record.level.name;
    final time = record.time.toIso8601String();
    final message = record.message;
    print('[$level] $time: $message');
  });
}

/// Top-level wrapper functions for convenience
void info(String message) => _vmLogger.info(message);
void warn(String message) => _vmLogger.warning(message);
void error(String message) => _vmLogger.severe(message);

/// Static class wrapper (optional)
class Log {
  /// Log an info message
  static void info(String message) => _vmLogger.info(message);

  /// Log a warning message
  static void warn(String message) => _vmLogger.warning(message);

  /// Log an error message
  static void error(String message) => _vmLogger.severe(message);
}
