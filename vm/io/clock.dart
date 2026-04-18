import '../util/timer.dart';
import '../engine/runtime.dart';

class Clock {
  final Runtime runtime;
  late TimerUtil _projectTimer;
  double _pausedTime = 0.0;
  bool _paused = false;

  Clock(this.runtime) {
    // Initialize timer using runtime's current milliseconds
    _projectTimer = TimerUtil();
    _projectTimer.startTime = runtime.currentMSecs.toInt();
  }

  /// Project timer in seconds
  double get projectTimer {
    if (_paused) return _pausedTime / 1000;
    return _projectTimer.timeElapsed() / 1000;
  }

  /// Pause the timer
  void pause() {
    if (!_paused) {
      _paused = true;
      _pausedTime = _projectTimer.timeElapsed();
    }
  }

  /// Resume the timer
  void resume() {
    if (_paused) {
      _paused = false;
      final dt = _projectTimer.timeElapsed() - _pausedTime;
      _projectTimer.startTime += dt.toInt();
    }
  }

  /// Reset the timer
  void resetProjectTimer() {
    _paused = false;
    _projectTimer.startTime = runtime.currentMSecs.toInt();
    _pausedTime = 0.0;
  }
}
