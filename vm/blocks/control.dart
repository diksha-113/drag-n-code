import '../util/cast.dart';
import '../engine/runtime.dart' as rt;
import '../engine/util.dart';
import '../extension_support/block_type.dart';
import '../extension_support/argument_type.dart';
import '../engine/target.dart';

class Scratch3ControlBlocks {
  final rt.Runtime runtime;

  int _counter = 0;

  Scratch3ControlBlocks(this.runtime) {
    runtime.on('RUNTIME_DISPOSED', (_) => clearCounter());
  }

  /// Original primitives map (functions only) for workspace
  Map<String, Function> getPrimitives() {
    return {
      'control_repeat': repeat,
      'control_repeat_until': repeatUntil,
      'control_while': repeatWhile,
      'control_for_each': forEach,
      'control_forever': forever,
      'control_wait': wait,
      'control_wait_until': waitUntil,
      'control_if': ifBlock,
      'control_if_else': ifElse,
      'control_stop': stop,
      'control_create_clone_of': createClone,
      'control_delete_this_clone': deleteClone,
      'control_get_counter': getCounter,
      'control_incr_counter': incrCounter,
      'control_clear_counter': clearCounter,
      'control_all_at_once': allAtOnce,
    };
  }

  /// Hats map
  Map<String, dynamic> getHats() {
    return {
      'control_start_as_clone': {'restartExistingThreads': false},
    };
  }

  /// Metadata for blocks and argument types (for editor / UI)
  Map<String, Map<String, dynamic>> getPrimitivesMetadata() {
    return {
      'control_repeat': {
        'type': BlockType.loop.value,
        'arguments': {'TIMES': ArgumentType.number.value},
      },
      'control_repeat_until': {
        'type': BlockType.loop.value,
        'arguments': {'CONDITION': ArgumentType.boolean.value},
      },
      'control_while': {
        'type': BlockType.loop.value,
        'arguments': {'CONDITION': ArgumentType.boolean.value},
      },
      'control_for_each': {
        'type': BlockType.loop.value,
        'arguments': {
          'VARIABLE': ArgumentType.string.value,
          'VALUE': ArgumentType.number.value
        },
      },
      'control_forever': {
        'type': BlockType.loop.value,
        'arguments': {},
      },
      'control_wait': {
        'type': BlockType.command.value,
        'arguments': {'DURATION': ArgumentType.number.value},
      },
      'control_wait_until': {
        'type': BlockType.command.value,
        'arguments': {'CONDITION': ArgumentType.boolean.value},
      },
      'control_if': {
        'type': BlockType.conditional.value,
        'arguments': {'CONDITION': ArgumentType.boolean.value},
      },
      'control_if_else': {
        'type': BlockType.conditional.value,
        'arguments': {'CONDITION': ArgumentType.boolean.value},
      },
      'control_stop': {
        'type': BlockType.command.value,
        'arguments': {'STOP_OPTION': ArgumentType.string.value},
      },
      'control_create_clone_of': {
        'type': BlockType.command.value,
        'arguments': {'CLONE_OPTION': ArgumentType.string.value},
      },
      'control_delete_this_clone': {
        'type': BlockType.command.value,
        'arguments': {},
      },
      'control_get_counter': {
        'type': BlockType.reporter.value,
        'arguments': {},
      },
      'control_incr_counter': {
        'type': BlockType.command.value,
        'arguments': {},
      },
      'control_clear_counter': {
        'type': BlockType.command.value,
        'arguments': {},
      },
      'control_all_at_once': {
        'type': BlockType.command.value,
        'arguments': {},
      },
    };
  }

  // ---------------- Existing block implementations ----------------
  void repeat(Map<String, dynamic> args, Util util) {
    final times = Cast.toNumber(args['TIMES']).round();
    util.stackFrame.loopCounter ??= times;
    util.stackFrame.loopCounter = util.stackFrame.loopCounter! - 1;

    if (util.stackFrame.loopCounter! >= 0) util.startBranch(1, true);
  }

  void repeatUntil(Map<String, dynamic> args, Util util) {
    final condition = Cast.toBoolean(args['CONDITION']);
    if (!condition) util.startBranch(1, true);
  }

  void repeatWhile(Map<String, dynamic> args, Util util) {
    final condition = Cast.toBoolean(args['CONDITION']);
    if (condition) util.startBranch(1, true);
  }

  void forEach(Map<String, dynamic> args, Util util) {
    final variable = util.target.lookupOrCreateVariable(
      args['VARIABLE']['id'],
      args['VARIABLE']['name'],
    );

    util.stackFrame.index ??= 0;

    if (util.stackFrame.index! < Cast.toNumber(args['VALUE'])) {
      util.stackFrame.index = util.stackFrame.index! + 1;
      variable.value = util.stackFrame.index;
      util.startBranch(1, true);
    }
  }

  void waitUntil(Map<String, dynamic> args, Util util) {
    final condition = Cast.toBoolean(args['CONDITION']);
    if (!condition) util.yieldExecution();
  }

  void forever(Map<String, dynamic> args, Util util) {
    util.startBranch(1, true);
  }

  void wait(Map<String, dynamic> args, Util util) {
    if (util.stackTimerNeedsInit()) {
      final duration =
          (Cast.toNumber(args['DURATION']) * 1000).clamp(0, double.infinity);
      util.startStackTimer(duration.toInt());
      runtime.requestRedraw();
      util.yieldExecution();
    } else if (!util.stackTimerFinished()) {
      util.yieldExecution();
    }
  }

  void ifBlock(Map<String, dynamic> args, Util util) {
    final condition = Cast.toBoolean(args['CONDITION']);
    if (condition) util.startBranch(1, false);
  }

  void ifElse(Map<String, dynamic> args, Util util) {
    final condition = Cast.toBoolean(args['CONDITION']);
    if (condition) {
      util.startBranch(1, false);
    } else {
      util.startBranch(2, false);
    }
  }

  void stop(Map<String, dynamic> args, Util util) {
    final option = args['STOP_OPTION'];
    if (option == 'all') {
      util.stopAll();
    } else if (option == 'other scripts in sprite' ||
        option == 'other scripts in stage') {
      util.stopOtherTargetThreads();
    } else if (option == 'this script') {
      util.stopThisScript();
    }
  }

  void createClone(Map<String, dynamic> args, Util util) {
    final cloneOption = Cast.toStringValue(args['CLONE_OPTION']);
    Target? runtimeCloneSource;

    if (cloneOption == '_myself_') {
      runtimeCloneSource = runtime.getTarget(util.target.id);
      runtimeCloneSource ??=
          runtime.getSpriteTargetByName(util.target.getName());
    } else {
      runtimeCloneSource = runtime.getSpriteTargetByName(cloneOption);
    }

    if (runtimeCloneSource == null) return;

    final newClone = runtimeCloneSource.makeClone();
    if (newClone == null) return;

    runtime.addTarget(newClone);

    try {
      newClone.goBehindOther(runtimeCloneSource);
    } catch (_) {}
  }

  void deleteClone(Map<String, dynamic> args, Util util) {
    Target? runtimeTarget = runtime.getTarget(util.target.id);

    if (runtimeTarget == null) return;
    if (runtimeTarget.isOriginal) return;

    runtime.disposeTarget(runtimeTarget);
    runtime.stopForTarget(runtimeTarget);
  }

  int getCounter([Map<String, dynamic>? args, Util? util]) => _counter;

  void clearCounter([Map<String, dynamic>? args, Util? util]) {
    _counter = 0;
  }

  void incrCounter([Map<String, dynamic>? args, Util? util]) {
    _counter++;
  }

  void allAtOnce(Map<String, dynamic> args, Util util) {
    util.startBranch(1, false);
  }
}
