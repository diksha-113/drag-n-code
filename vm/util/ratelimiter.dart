import 'dart:math';
import 'timer.dart';

/// A utility for limiting the rate of repetitive send operations.
/// Uses a token bucket strategy.
class RateLimiter {
  final int _maxTokens;
  final double _refillInterval; // milliseconds per token
  int _count;
  final TimerUtil _timer;
  double _lastUpdateTime;

  /// maxRate: maximum number of sends allowed per second.
  RateLimiter(int maxRate)
      : _maxTokens = maxRate,
        _refillInterval = 1000 / maxRate,
        _count = maxRate,
        _timer = TimerUtil(),
        _lastUpdateTime = 0 {
    _timer.start();
    _lastUpdateTime = _timer.timeElapsed();
  }

  /// Check if it is okay to send a message.
  /// Returns true if under the rate limit.
  bool okayToSend() {
    final now = _timer.timeElapsed();
    final timeSinceRefill = now - _lastUpdateTime;
    final refillCount = (timeSinceRefill / _refillInterval).floor();

    if (refillCount > 0) {
      _lastUpdateTime = now;
    }

    _count = min(_maxTokens, _count + refillCount);

    if (_count > 0) {
      _count--;
      return true;
    }

    return false;
  }
}
