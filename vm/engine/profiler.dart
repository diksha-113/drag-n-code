import 'dart:core';

/// ---------------------------
/// ProfilerFrame
/// ---------------------------
class ProfilerFrame {
  int id = -1;
  double totalTime = 0;
  double selfTime = 0;
  dynamic arg;
  final int depth;
  int count = 0;

  ProfilerFrame(this.depth);
}

/// ---------------------------
/// Profiler
/// ---------------------------
typedef FrameCallback = void Function(ProfilerFrame frame);

class Profiler {
  // Renamed constants to lowerCamelCase
  static const int startEvent = 0;
  static const int stopEvent = 1;

  static const int startEventSize = 4;
  static const int stopEventSize = 2;

  final FrameCallback onFrame;

  List<dynamic> records = [];
  List<ProfilerFrame?> increments = [];
  List<ProfilerFrame> counters = [];
  final ProfilerFrame nullFrame = ProfilerFrame(-1);
  final List<ProfilerFrame> _stack = [ProfilerFrame(0)];

  Profiler({FrameCallback? onFrame}) : onFrame = onFrame ?? ((_) {});

  void start(int id, [dynamic arg]) {
    final now = DateTime.now().microsecondsSinceEpoch.toDouble();
    records.addAll([startEvent, id, arg, now]);
  }

  void stop() {
    final now = DateTime.now().microsecondsSinceEpoch.toDouble();
    records.addAll([stopEvent, now]);
  }

  void increment(int id) {
    if (id >= increments.length) {
      increments.length = id + 1;
    }
    increments[id] ??= ProfilerFrame(-1)..id = id;
    increments[id]!.count += 1;
  }

  ProfilerFrame frame(int id, dynamic arg) {
    for (var f in counters) {
      if (f.id == id && f.arg == arg) return f;
    }
    final newCounter = ProfilerFrame(-1)
      ..id = id
      ..arg = arg;
    counters.add(newCounter);
    return newCounter;
  }

  void reportFrames() {
    final stack = _stack;
    int depth = 1;

    for (int i = 0; i < records.length;) {
      if (records[i] == startEvent) {
        if (depth >= stack.length) stack.add(ProfilerFrame(depth));

        final frame = stack[depth++];
        frame.id = records[i + 1];
        frame.arg = records[i + 2];
        frame.totalTime = records[i + 3];
        frame.selfTime = 0;

        i += startEventSize;
      } else if (records[i] == stopEvent) {
        final now = records[i + 1];
        final frame = stack[--depth];
        frame.totalTime = now - frame.totalTime;
        frame.selfTime += frame.totalTime;
        if (depth > 0) stack[depth - 1].selfTime -= frame.totalTime;
        frame.count = 1;

        onFrame(frame);
        i += stopEventSize;
      } else {
        records.clear();
        throw Exception('Unable to decode Profiler records.');
      }
    }

    for (var f in increments) {
      if (f != null && f.count > 0) {
        onFrame(f);
        f.count = 0;
      }
    }

    for (var f in counters) {
      if (f.count > 0) {
        onFrame(f);
        f.count = 0;
      }
    }

    records.clear();
  }

  /// ---------------------------
  /// Static mappings
  /// ---------------------------
  static int _nextId = 0;
  static final Map<String, int> _profilerNames = {};

  static int idByName(String name) {
    if (!_profilerNames.containsKey(name)) {
      _profilerNames[name] = _nextId++;
    }
    return _profilerNames[name]!;
  }

  static String? nameById(int id) {
    for (var entry in _profilerNames.entries) {
      if (entry.value == id) return entry.key;
    }
    return null;
  }
}
