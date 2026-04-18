//
// Dart conversion of the VM Thread + _StackFrame logic.
// Keeps behavior as in the original JS version (including the same
// stack frame recycling semantics).

import 'dart:collection';
import '../util/timer.dart' as local_timer;

/// Public alias so other files can refer to StackFrame
typedef StackFrame = _StackFrame;

/// Recycle bin for empty stackFrame objects.
final List<_StackFrame> _stackFrameFreeList = <_StackFrame>[];

/// A frame used for each level of the stack. A general purpose
/// place to store a bunch of execution context and parameters.
class _StackFrame {
  /// Whether this level of the stack is a loop.
  bool isLoop = false;

  /// Whether this level is in warp mode.
  bool warpMode;

  /// Reported value from just executed block.
  dynamic justReported;

  /// The active block that is waiting on a promise.
  String reporting = '';

  /// Persists reported inputs during async block.
  dynamic reported;

  /// Name of waiting reporter.
  String? waitingReporter;

  /// Procedure parameters.
  Map<String, dynamic>? params;

  /// A context passed to block implementations.
  Map<String, dynamic>? executionContext;

  /// Loop counter for repeat/repeatUntil/repeatWhile
  int? loopCounter;

  /// Index for for-each loops
  int? index;

  _StackFrame(this.warpMode);

  /// Reset all properties of the frame to pristine null and false states.
  _StackFrame reset() {
    isLoop = false;
    warpMode = false;
    justReported = null;
    reported = null;
    waitingReporter = null;
    params = null;
    executionContext = null;
    reporting = '';
    loopCounter = null;
    index = null;
    return this;
  }

  /// Reuse an active stack frame in the stack.
  _StackFrame reuse([bool? warpMode]) {
    reset();
    this.warpMode = warpMode ?? this.warpMode;
    return this;
  }

  /// Create or recycle a stack frame object.
  static _StackFrame create(bool warpMode) {
    if (_stackFrameFreeList.isNotEmpty) {
      final frame = _stackFrameFreeList.removeLast();
      frame.warpMode = warpMode;
      return frame;
    }
    return _StackFrame(warpMode);
  }

  /// Put a stack frame object into the recycle bin for reuse.
  static void release(_StackFrame? stackFrame) {
    if (stackFrame != null) {
      _stackFrameFreeList.add(stackFrame.reset());
    }
  }
}

/// A thread is a running stack context and all the metadata needed.
class Thread {
  /// Unique thread ID
  String id = '';

  /// Current executing block ID
  String blockId = '';

  /// Arbitrary context / arguments
  Map<String, dynamic> args = {};

  /// ID of top block of the thread.
  String? topBlock;

  /// Stack for the thread.
  final List<String> stack = <String>[];

  /// Stack frames for the thread.
  final List<_StackFrame> stackFrames = <_StackFrame>[];

  /// Status of the thread, one of Thread.STATUS_* constants.
  int status = STATUS_RUNNING;

  /// Whether the thread is killed in the middle of execution.
  bool isKilled = false;

  /// Target of this thread.
  dynamic target;

  /// The Blocks this thread will execute.
  dynamic blockContainer;

  /// Whether the thread requests its script to glow during this frame.
  bool requestScriptGlowInFrame = false;

  /// Which block ID should glow during this frame, if any.
  String? blockGlowInFrame;

  /// A timer for warp mode execution.
  local_timer.TimerUtil? warpTimer;

  /// Last reported value pushed by a reporter.
  dynamic justReported;

  /// Flag used in execute.dart to detect if this thread was triggered by a click.
  bool stackClick = false;

  /// Flag used for monitor updates.
  bool updateMonitor = true;

  Thread({
    this.topBlock,
    this.id = '',
    this.blockId = '',
    this.target,
    Map<String, dynamic>? args,
  }) : args = args ?? {};

  /// Thread status constants
  static const int STATUS_RUNNING = 0;
  static const int STATUS_PROMISE_WAIT = 1;
  static const int STATUS_YIELD = 2;
  static const int STATUS_YIELD_TICK = 3;
  static const int STATUS_DONE = 4;

  /// Push stack and update stack frames appropriately.
  void pushStack(String blockId) {
    stack.add(blockId);
    if (stack.length > stackFrames.length) {
      final parent = stackFrames.isNotEmpty ? stackFrames.last : null;
      final bool parentWarp = parent != null && parent.warpMode;
      stackFrames.add(_StackFrame.create(parentWarp));
    }
  }

  /// Reset the stack frame for next block reuse.
  void reuseStackForNextBlock(String blockId) {
    if (stack.isNotEmpty) {
      stack[stack.length - 1] = blockId;
      stackFrames[stackFrames.length - 1].reuse();
    } else {
      pushStack(blockId);
    }
  }

  /// Pop last block on the stack and its stack frame.
  String popStack() {
    final frame = stackFrames.removeLast();
    _StackFrame.release(frame);
    return stack.removeLast();
  }

  /// Pop back down the stack frame until we hit a procedure call or empty stack.
  void stopThisScript() {
    String? blockID = peekStack();
    while (blockID != null) {
      final block = target.blocks.getBlock(blockID);
      if (block != null && block.opcode == 'procedures_call') break;
      popStack();
      blockID = peekStack();
    }

    if (stack.isEmpty) {
      requestScriptGlowInFrame = false;
      status = STATUS_DONE;
    }
  }

  /// Get top stack item.
  String? peekStack() => stack.isNotEmpty ? stack.last : null;

  /// Get top stack frame.
  _StackFrame? peekStackFrame() =>
      stackFrames.isNotEmpty ? stackFrames.last : null;

  /// Get stack frame above the current top.
  _StackFrame? peekParentStackFrame() =>
      stackFrames.length > 1 ? stackFrames[stackFrames.length - 2] : null;

  /// Push a reported value.
  void pushReportedValue(dynamic value) {
    justReported = value;
  }

  /// Initialize procedure parameters.
  void initParams() {
    final frame = peekStackFrame();
    if (frame != null && frame.params == null) {
      frame.params = <String, dynamic>{};
    }
  }

  /// Add a parameter to the stack frame.
  void pushParam(String paramName, dynamic value) {
    final frame = peekStackFrame();
    if (frame != null) {
      frame.params ??= <String, dynamic>{};
      frame.params![paramName] = value;
    }
  }

  /// Get a parameter from the lowest stack frame.
  dynamic getParam(String paramName) {
    for (int i = stackFrames.length - 1; i >= 0; i--) {
      final frame = stackFrames[i];
      if (frame.params != null && frame.params!.containsKey(paramName)) {
        return frame.params![paramName];
      }
    }
    return null;
  }

  /// Whether at top of the stack.
  bool atStackTop() => peekStack() == topBlock;

  /// Move to the next block.
  void goToNextBlock() {
    final nextBlockId = target.blocks.getNextBlock(peekStack());
    reuseStackForNextBlock(nextBlockId);
  }

  /// Check for recursive procedure call.
  bool isRecursiveCall(String procedureCode) {
    int callCount = 5;
    final sp = stack.length - 1;
    for (int i = sp - 1; i >= 0; i--) {
      final block = stack[i];
      final b = target.blocks.getBlock(block);
      if (b != null &&
          b.opcode == 'procedures_call' &&
          b.mutation != null &&
          b.mutation['proccode'] == procedureCode) {
        return true;
      }
      if (--callCount < 0) return false;
    }
    return false;
  }

  /// Whether the thread is waiting (promise, yield, or yield tick)
  bool get isWaiting =>
      status == STATUS_PROMISE_WAIT ||
      status == STATUS_YIELD ||
      status == STATUS_YIELD_TICK;

  /// Whether the thread has finished execution
  bool get done => status == STATUS_DONE;
}
