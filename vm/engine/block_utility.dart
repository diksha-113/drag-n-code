import 'thread.dart';
import 'sequencer.dart';
import '../util/timer.dart' as local_timer;

/// Dart translation of JS BlockUtility
/// Provides helper functions for blocks to interact with threads, timers, and procedures
class BlockUtility {
  Sequencer? sequencer;
  Thread? thread;

  BlockUtility({this.sequencer, this.thread});

  /// ------------------------------------------------------------------------
  /// Target this block is working on
  /// ------------------------------------------------------------------------
  dynamic get target => thread!.target;

  /// ------------------------------------------------------------------------
  /// Runtime from the sequencer
  /// ------------------------------------------------------------------------
  dynamic get runtime => sequencer!.runtime;

  /// ------------------------------------------------------------------------
  /// Stack frame for loop state, execution context, etc.
  /// Initializes executionContext when needed
  /// ------------------------------------------------------------------------
  Map<String, dynamic> get stackFrame {
    final frame = thread!.peekStackFrame()!;
    frame.executionContext ??= <String, dynamic>{};
    return frame.executionContext!;
  }

  /// ------------------------------------------------------------------------
  /// Stack Timer helpers
  /// ------------------------------------------------------------------------
  bool stackTimerFinished() {
    final timer = stackFrame['timer'] as local_timer.TimerUtil?;
    if (timer == null) return true;
    final timeElapsed = timer.timeElapsed();
    return timeElapsed >= (stackFrame['duration'] ?? 0);
  }

  bool stackTimerNeedsInit() {
    return stackFrame['timer'] == null;
  }

  void startStackTimer(int duration) {
    final timer = local_timer.TimerUtil();
    stackFrame['timer'] = timer;
    stackFrame['duration'] = duration;
    timer.start();
  }

  /// ------------------------------------------------------------------------
  /// Thread control actions
  /// ------------------------------------------------------------------------
  void yieldThread() {
    thread!.status = Thread.STATUS_YIELD;
  }

  void yieldTick() {
    thread!.status = Thread.STATUS_YIELD_TICK;
  }

  void startBranch(int branchNum, bool isLoop) {
    sequencer!.stepToBranch(thread!, branchNum, isLoop);
  }

  void stopAll() {
    sequencer!.runtime.stopAll();
  }

  void stopOtherTargetThreads() {
    sequencer!.runtime.stopForTarget(thread!.target, thread!);
  }

  void stopThisScript() {
    thread!.stopThisScript();
  }

  void startProcedure(String procedureCode) {
    sequencer!.stepToProcedure(thread!, procedureCode);
  }

  /// ------------------------------------------------------------------------
  /// Procedures
  /// ------------------------------------------------------------------------
  List<dynamic> getProcedureParamNamesAndIds(String code) {
    return thread!.target.blocks.getProcedureParamNamesAndIds(code);
  }

  List<dynamic> getProcedureParamNamesIdsAndDefaults(String code) {
    return thread!.target.blocks.getProcedureParamNamesIdsAndDefaults(code);
  }

  void initParams() {
    thread!.initParams();
  }

  void pushParam(String paramName, dynamic value) {
    thread!.pushParam(paramName, value);
  }

  dynamic getParam(String paramName) {
    return thread!.getParam(paramName);
  }

  /// ------------------------------------------------------------------------
  /// Hat blocks triggering
  /// ------------------------------------------------------------------------
  List<Thread> startHats(
    String requestedHat, [
    Map<String, dynamic>? optMatchFields,
    dynamic optTarget,
  ]) {
    final callerThread = thread;
    final callerSequencer = sequencer;

    final result = sequencer!.runtime.startHats(
      requestedHat,
      optMatchFields,
      optTarget,
    );

    // Restore calling context
    thread = callerThread;
    sequencer = callerSequencer;

    return result;
  }

  /// ------------------------------------------------------------------------
  /// IO Query
  /// ------------------------------------------------------------------------
  dynamic ioQuery(String device, String func, List<dynamic> args) {
    final ioDevices = sequencer!.runtime.ioDevices;

    if (ioDevices[device] != null && ioDevices[device][func] != null) {
      final dev = ioDevices[device];
      return Function.apply(dev[func], args);
    }

    return null;
  }
}
