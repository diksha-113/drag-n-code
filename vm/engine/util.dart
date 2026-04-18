// lib/vm/engine/util.dart
import 'runtime.dart' as rt;
import 'thread.dart' as vm;
import 'sequencer.dart' as seq;
import 'target.dart';

/// Utility class passed to primitive block functions.
/// Provides helpers for starting branches, yielding,
/// timers, stopping scripts, accessing stack frames, etc.
class Util {
  rt.Runtime? runtime;

  Util({this.runtime});

  // Set externally before execute()
  seq.Sequencer? _sequencer;
  set sequencer(seq.Sequencer? s) => _sequencer = s;

  vm.Thread? _thread;
  set thread(vm.Thread? t) => _thread = t;

  /// Getter for thread (needed in blocks like data.dart)
  vm.Thread get thread => _thread!;

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  rt.Runtime? get _runtime => runtime ?? _sequencer?.runtime;
  vm.Thread get _thr => _thread!;
  seq.Sequencer get _seq => _sequencer!;
  Target get target => _thr.target;

  /// Access the VM internal stack frame (StackFrame)
  vm.StackFrame get stackFrame => _thr.peekStackFrame()!;

  // ---------------------------------------------------------------------------
  // CONTROL FLOW
  // ---------------------------------------------------------------------------

  /// Start running the branch with the given index (1-based).
  /// `isLoop` determines if the VM should return to this block afterwards.
  void startBranch(int branch, bool isLoop) {
    _seq.stepToBranch(_thr, branch, isLoop);
  }

  /// Yield execution of the script until next tick.
  void yieldExecution() {
    _thr.status = vm.Thread.STATUS_YIELD;
  }

  // ---------------------------------------------------------------------------
  // TIMER SYSTEM (for "wait" blocks)
  // Stores timer info in frame.executionContext map.
  // ---------------------------------------------------------------------------

  void _ensureTimer() {
    stackFrame.executionContext ??= {};
    stackFrame.executionContext!['_timerStart'] ??= null;
    stackFrame.executionContext!['_timerDur'] ??= null;
  }

  bool stackTimerNeedsInit() {
    _ensureTimer();
    return stackFrame.executionContext!['_timerStart'] == null;
  }

  void startStackTimer(int durationMs) {
    _ensureTimer();
    final now = DateTime.now().millisecondsSinceEpoch;
    stackFrame.executionContext!['_timerStart'] = now;
    stackFrame.executionContext!['_timerDur'] = durationMs;
  }

  bool stackTimerFinished() {
    _ensureTimer();
    final start = stackFrame.executionContext!['_timerStart'];
    final dur = stackFrame.executionContext!['_timerDur'];
    if (start == null || dur == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - start >= dur;
  }

  // ---------------------------------------------------------------------------
  // STOPPING SCRIPTS
  // ---------------------------------------------------------------------------

  /// Stop this script immediately.
  void stopThisScript() {
    _seq.retireThread(_thr);
  }

  /// Stop all scripts except this one in the same target.
  void stopOtherTargetThreads() {
    _seq.runtime.threads
        .where((t) => t != _thr && t.target == target)
        .forEach((t) => _seq.retireThread(t));
  }

  /// Stop all scripts in the entire project.
  void stopAll() {
    _seq.runtime.threads.forEach((t) => _seq.retireThread(t));
  }

  // ---------------------------------------------------------------------------
  // RUNTIME FUNCTIONS
  // ---------------------------------------------------------------------------

  void requestRedraw() {
    _runtime?.requestRedraw();
  }

  /// For block functions needing to return a value
  void report(dynamic value) {
    _thr.justReported = value;
  }

  // ---------------------------------------------------------------------------
  // IO / Cloud Helper
  // ---------------------------------------------------------------------------

  /// Stub for blocks that use ioQuery (e.g., cloud variables)
  dynamic ioQuery(String category, String method, List<dynamic> args) {
    // Implement cloud/network behavior as needed
    // For now, just print to console
    print('ioQuery called: $category.$method(${args.join(', ')})');
    return null;
  }
}
