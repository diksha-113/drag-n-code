// lib/vm/util/timer.dart

import 'dart:async' as dart_async;

/// Timer utility for accurately measuring elapsed time in milliseconds.
class TimerUtil {
  /// Exposed start time in milliseconds since epoch
  int startTime = 0;

  /// Start the timer
  void start() {
    startTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// Reset the timer (same as start)
  void reset() {
    start();
  }

  /// Return milliseconds elapsed since start
  double timeElapsed() {
    return DateTime.now().millisecondsSinceEpoch.toDouble() -
        startTime.toDouble();
  }

  /// Return current absolute time in milliseconds since epoch
  double time() {
    return DateTime.now().millisecondsSinceEpoch.toDouble();
  }

  /// Call a handler function after a specified amount of time (ms)
  /// Returns a Timer object that can be cancelled
  dart_async.Timer setTimeout(void Function() handler, int timeout) {
    return dart_async.Timer(Duration(milliseconds: timeout), handler);
  }

  /// Cancel a previously set timeout
  void clearTimeout(dart_async.Timer? timer) {
    timer?.cancel();
  }

  /// Static method to get absolute current time (optional legacy)
  static int now() {
    return DateTime.now().millisecondsSinceEpoch;
  }
}
