// lib/vm/engine/sequencer.dart
import '../util/timer.dart';
import 'thread.dart';
import 'execute.dart';

/// Profiler frame names
const String stepThreadProfilerFrame = 'Sequencer.stepThread';
const String stepThreadsInnerProfilerFrame = 'Sequencer.stepThreads#inner';
const String executeProfilerFrame = 'execute';

int stepThreadProfilerId = -1;
int stepThreadsInnerProfilerId = -1;
int executeProfilerId = -1;

class Sequencer {
  final TimerUtil timer = TimerUtil();
  final dynamic runtime; // Replace dynamic with your Runtime class
  Thread? activeThread;

  /// Execution cache
  final Map<String, Map<String, dynamic>> _executeCache = {};

  Sequencer(this.runtime);

  /// 🔔 Start a new thread from a hat block (Scratch-style)
  void startThread(String topBlockId, dynamic target) {
    final thread = Thread(
      topBlock: topBlockId, // use named argument
      target: target, // optional, but better to set here
    );

    runtime.threads.add(thread);
  }

  /// Time to run a warp-mode thread, in ms.
  static const int WARP_TIME = 500;

  /// Step through all threads in `runtime.threads`.
  List<Thread> stepThreads() {
    final workTime = 0.75 * runtime.currentStepTime;
    runtime.updateCurrentMSecs();

    timer.start();
    int numActiveThreads = double.infinity.toInt();
    bool ranFirstTick = false;
    final doneThreads = <Thread>[];

    while (runtime.threads.isNotEmpty &&
        numActiveThreads > 0 &&
        timer.timeElapsed() < workTime &&
        (runtime.turboMode || !runtime.redrawRequested)) {
      if (runtime.profiler != null) {
        stepThreadsInnerProfilerId = stepThreadsInnerProfilerId == -1
            ? runtime.profiler.idByName(stepThreadsInnerProfilerFrame)
            : stepThreadsInnerProfilerId;
        runtime.profiler.start(stepThreadsInnerProfilerId);
      }

      numActiveThreads = 0;
      bool stoppedThread = false;

      final threads = runtime.threads;
      for (int i = 0; i < threads.length; i++) {
        activeThread = threads[i];

        if (activeThread!.stack.isEmpty ||
            activeThread!.status == Thread.STATUS_DONE) {
          stoppedThread = true;
          continue;
        }

        if (activeThread!.status == Thread.STATUS_YIELD_TICK && !ranFirstTick) {
          activeThread!.status = Thread.STATUS_RUNNING;
        }

        if (activeThread!.status == Thread.STATUS_RUNNING ||
            activeThread!.status == Thread.STATUS_YIELD) {
          if (runtime.profiler != null) {
            stepThreadProfilerId = stepThreadProfilerId == -1
                ? runtime.profiler.idByName(stepThreadProfilerFrame)
                : stepThreadProfilerId;
            runtime.profiler.increment(stepThreadProfilerId);
          }
          stepThread(activeThread!);
          activeThread!.warpTimer = null;
          if (activeThread!.isKilled) i--;
        }

        if (activeThread!.status == Thread.STATUS_RUNNING) numActiveThreads++;

        if (activeThread!.stack.isEmpty ||
            activeThread!.status == Thread.STATUS_DONE) {
          stoppedThread = true;
        }
      }

      ranFirstTick = true;
      runtime.profiler?.stop();

      if (stoppedThread) {
        int nextActiveThread = 0;
        for (var thread in runtime.threads) {
          if (thread.stack.isNotEmpty && thread.status != Thread.STATUS_DONE) {
            runtime.threads[nextActiveThread++] = thread;
          } else {
            doneThreads.add(thread);
          }
        }
        runtime.threads.length = nextActiveThread;
      }
    }

    activeThread = null;
    return doneThreads;
  }

  void stepThread(Thread thread) {
    var currentBlockId = thread.peekStack();
    if (currentBlockId == null) {
      thread.popStack();
      if (thread.stack.isEmpty) {
        thread.status = Thread.STATUS_DONE;
        return;
      }
    }

    while ((currentBlockId = thread.peekStack()) != null) {
      final stackFrame = thread.peekStackFrame()!;
      bool isWarpMode = stackFrame.warpMode;

      if (isWarpMode && thread.warpTimer == null) {
        thread.warpTimer = TimerUtil()..start();
      }

      if (runtime.profiler != null) {
        executeProfilerId = executeProfilerId == -1
            ? runtime.profiler.idByName(executeProfilerFrame)
            : executeProfilerId;
        runtime.profiler.increment(executeProfilerId);
      }

      if (thread.target == null) {
        retireThread(thread);
      } else {
        execute(this, thread);
      }

      thread.blockGlowInFrame = currentBlockId;

      if (thread.status == Thread.STATUS_YIELD) {
        thread.status = Thread.STATUS_RUNNING;
        if (isWarpMode &&
            (thread.warpTimer?.timeElapsed() ?? 0) <= Sequencer.WARP_TIME) {
          continue;
        }
        return;
      } else if (thread.status == Thread.STATUS_PROMISE_WAIT ||
          thread.status == Thread.STATUS_YIELD_TICK) {
        return;
      }

      if (thread.peekStack() == currentBlockId) {
        thread.goToNextBlock();
      }

      while (thread.peekStack() == null) {
        thread.popStack();
        if (thread.stack.isEmpty) {
          thread.status = Thread.STATUS_DONE;
          return;
        }
        final stackFrame = thread.peekStackFrame()!;
        isWarpMode = stackFrame.warpMode;

        if (stackFrame.isLoop) {
          if (!isWarpMode ||
              (thread.warpTimer?.timeElapsed() ?? 0) > Sequencer.WARP_TIME) {
            return;
          }
          continue;
        } else if (stackFrame.waitingReporter != null) {
          return;
        }
        thread.goToNextBlock();
      }
    }
  }

  void stepToBranch(Thread thread, int branchNum, bool isLoop) {
    branchNum = branchNum == 0 ? 1 : branchNum;
    final currentBlockId = thread.peekStack();
    final branchId = thread.target.blocks.getBranch(currentBlockId, branchNum);
    thread.peekStackFrame()!.isLoop = isLoop;
    thread.pushStack(branchId);
  }

  void stepToProcedure(Thread thread, String procedureCode) {
    final definition =
        thread.target.blocks.getProcedureDefinition(procedureCode);
    if (definition == null) return;

    final isRecursive = thread.isRecursiveCall(procedureCode);
    thread.pushStack(definition);

    final stackFrame = thread.peekStackFrame()!;
    if (stackFrame.warpMode &&
        (thread.warpTimer?.timeElapsed() ?? 0) > Sequencer.WARP_TIME) {
      thread.status = Thread.STATUS_YIELD;
    } else {
      final definitionBlock = thread.target.blocks.getBlock(definition);
      final innerBlock = thread.target.blocks
          .getBlock(definitionBlock.inputs.custom_block.block);
      bool doWarp = false;
      if (innerBlock?.mutation != null) {
        final warp = innerBlock!.mutation!.warp;
        if (warp is bool) doWarp = warp;
        if (warp is String) doWarp = warp.toLowerCase() == 'true';
      }
      if (doWarp) stackFrame.warpMode = true;
      if (isRecursive) thread.status = Thread.STATUS_YIELD;
    }
  }

  /// Get cached execution result for a block
  dynamic getCached(dynamic blockContainer, String blockId) {
    if (blockContainer == null) return null;

    final containerId = blockContainer.id;
    final containerCache = _executeCache[containerId];
    if (containerCache == null) return null;

    return containerCache[blockId];
  }

  /// Store cached execution result for a block
  void setCached(dynamic blockContainer, String blockId, dynamic value) {
    if (blockContainer == null) return;

    final containerId = blockContainer.id;
    _executeCache.putIfAbsent(containerId, () => {});
    _executeCache[containerId]![blockId] = value;
  }

  /// Clear cache for a target / block container
  void clearCachedFor(dynamic blockContainer) {
    if (blockContainer == null) return;
    _executeCache.remove(blockContainer.id);
  }

  void retireThread(Thread thread) {
    thread.stack.clear();
    thread.stackFrames.clear();
    thread.requestScriptGlowInFrame = false;
    thread.status = Thread.STATUS_DONE;
  }
}
