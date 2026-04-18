import 'dart:async';
import 'timer.dart'; // Your TimerUtil class is in this file

/// Represents a single queued task with a cost.
class TaskRecord<T> {
  final int cost;
  late final Future<T> future;
  late final void Function() cancel;
  late final Future<T> Function() wrappedTask;

  TaskRecord(this.cost);
}

/// A token-bucket based task queue
class TaskQueue {
  final double _maxTokens;
  final double _refillRate;
  final double _maxTotalCost;
  final TimerUtil _timer;
  final List<TaskRecord> _pendingTaskRecords = [];
  double _tokenCount;
  Timer? _timeout;
  double _lastUpdateTime;

  TaskQueue(this._maxTokens, this._refillRate,
      {double? startingTokens, double? maxTotalCost})
      : _tokenCount = startingTokens ?? _maxTokens,
        _maxTotalCost = maxTotalCost ?? double.infinity,
        _timer = TimerUtil(),
        _lastUpdateTime = 0 {
    _timer.start();
    _lastUpdateTime = _timer.timeElapsed();
  }

  /// Number of queued tasks that haven't started
  int get length => _pendingTaskRecords.length;

  /// Adds a task to the queue
  Future<T> doTask<T>(FutureOr<T> Function() task, {int cost = 1}) {
    // Check total cost limit
    if (_maxTotalCost < double.infinity) {
      final currentTotalCost =
          _pendingTaskRecords.fold<int>(0, (t, r) => t + r.cost);
      if (currentTotalCost + cost > _maxTotalCost) {
        return Future.error('Maximum total cost exceeded');
      }
    }

    final record = TaskRecord<T>(cost);
    final completer = Completer<T>();

    // Cancel function
    record.cancel = () {
      if (!completer.isCompleted) {
        completer.completeError('Task canceled');
      }
    };

    // Wrapped task logic (safe for Future or direct result)
    record.wrappedTask = () {
      try {
        final result = task();
        final futureResult =
            result is Future<T> ? result : Future.value(result);

        futureResult
            .then((value) => completer.complete(value))
            .catchError((e) => completer.completeError(e));
      } catch (e) {
        completer.completeError(e);
      }
      return completer.future;
    };

    record.future = completer.future;
    _pendingTaskRecords.add(record);

    // Run tasks immediately if first in queue
    if (_pendingTaskRecords.length == 1) {
      _runTasks();
    }

    return record.future;
  }

  /// Cancel a specific task
  bool cancel(Future taskFuture) {
    final index = _pendingTaskRecords.indexWhere((r) => r.future == taskFuture);
    if (index != -1) {
      final record = _pendingTaskRecords.removeAt(index);
      record.cancel();
      if (index == 0 && _pendingTaskRecords.isNotEmpty) {
        _runTasks();
      }
      return true;
    }
    return false;
  }

  /// Cancel all pending tasks
  void cancelAll() {
    _timeout?.cancel();
    _timeout = null;

    final oldTasks = List<TaskRecord>.from(_pendingTaskRecords);
    _pendingTaskRecords.clear();
    for (var r in oldTasks) {
      r.cancel();
    }
  }

  /// Refill tokens and try to spend cost
  bool _refillAndSpend(int cost) {
    _refill();
    return _spend(cost);
  }

  void _refill() {
    final now = _timer.timeElapsed();
    final timeSinceRefill = now - _lastUpdateTime;
    if (timeSinceRefill <= 0) return;

    _lastUpdateTime = now;
    _tokenCount += timeSinceRefill * _refillRate / 1000;
    if (_tokenCount > _maxTokens) _tokenCount = _maxTokens;
  }

  bool _spend(int cost) {
    if (cost <= _tokenCount) {
      _tokenCount -= cost;
      return true;
    }
    return false;
  }

  void _runTasks() {
    _timeout?.cancel();
    _timeout = null;

    while (_pendingTaskRecords.isNotEmpty) {
      final nextRecord = _pendingTaskRecords.removeAt(0);

      if (nextRecord.cost > _maxTokens) {
        throw Exception(
            'Task cost ${nextRecord.cost} is greater than bucket limit $_maxTokens');
      }

      if (_refillAndSpend(nextRecord.cost)) {
        nextRecord.wrappedTask();
      } else {
        _pendingTaskRecords.insert(0, nextRecord);
        final tokensNeeded =
            (nextRecord.cost - _tokenCount).clamp(0, double.infinity);
        final estimatedWait = Duration(
            milliseconds: ((1000 * tokensNeeded / _refillRate).ceil()));
        _timeout = Timer(estimatedWait, _runTasks);
        return;
      }
    }
  }
}
