// lib/vm/blocks/event.dart
import '../util/cast.dart';
import '../engine/runtime.dart';
import '../extension_support/block_type.dart';
import '../extension_support/argument_type.dart';

class Scratch3EventBlocks {
  final Runtime runtime;

  Scratch3EventBlocks(this.runtime) {
    // KEY PRESSED LISTENER
    runtime.on('KEY_PRESSED', (key) {
      runtime.startHats('event_whenkeypressed', {
        'KEY_OPTION': key,
      });
      runtime.startHats('event_whenkeypressed', {
        'KEY_OPTION': 'any',
      });
    });
  }

  /// Mapping of opcode → function (primitives)
  Map<String, Map<String, dynamic>> getPrimitivesMetadata() {
    return {
      'event_whentouchingobject': {
        'func': touchingObject,
        'type': BlockType.boolean.value,
        'arguments': {'TOUCHINGOBJECTMENU': ArgumentType.string.value},
      },
      'event_broadcast': {
        'func': broadcast,
        'type': BlockType.command.value,
        'arguments': {'BROADCAST_OPTION': ArgumentType.string.value},
      },
      'event_broadcastandwait': {
        'func': broadcastAndWait,
        'type': BlockType.command.value,
        'arguments': {'BROADCAST_OPTION': ArgumentType.string.value},
      },
      'event_whengreaterthan': {
        'func': hatGreaterThanPredicate,
        'type': BlockType.boolean.value,
        'arguments': {
          'WHENGREATERTHANMENU': ArgumentType.string.value,
          'VALUE': ArgumentType.number.value
        },
      },
    };
  }

  /// Hat metadata used by the engine
  Map<String, dynamic> getHats() {
    return {
      'event_whenflagclicked': {
        'restartExistingThreads': true,
        'type': BlockType.hat.value,
        'arguments': {},
      },
      'event_whenkeypressed': {
        'restartExistingThreads': false,
        'type': BlockType.hat.value,
        'arguments': {'KEY_OPTION': ArgumentType.string.value},
      },
      'event_whenthisspriteclicked': {
        'restartExistingThreads': true,
        'type': BlockType.hat.value,
        'arguments': {},
      },
      'event_whentouchingobject': {
        'restartExistingThreads': false,
        'edgeActivated': true,
        'type': BlockType.hat.value,
        'arguments': {'TOUCHINGOBJECTMENU': ArgumentType.string.value},
      },
      'event_whenstageclicked': {
        'restartExistingThreads': true,
        'type': BlockType.hat.value,
        'arguments': {},
      },
      'event_whenbackdropswitchesto': {
        'restartExistingThreads': true,
        'type': BlockType.hat.value,
        'arguments': {},
      },
      'event_whengreaterthan': {
        'restartExistingThreads': false,
        'edgeActivated': true,
        'type': BlockType.hat.value,
        'arguments': {
          'WHENGREATERTHANMENU': ArgumentType.string.value,
          'VALUE': ArgumentType.number.value
        },
      },
      'event_whenbroadcastreceived': {
        'restartExistingThreads': true,
        'type': BlockType.hat.value,
        'arguments': {'BROADCAST_OPTION': ArgumentType.string.value},
      }
    };
  }

  // -----------------------------
  // Block Implementations
  // -----------------------------

  dynamic touchingObject(Map<String, dynamic> args, dynamic util) {
    return util.target.isTouchingObject(args['TOUCHINGOBJECTMENU']);
  }

  dynamic hatGreaterThanPredicate(Map<String, dynamic> args, dynamic util) {
    final option =
        Cast.toStringValue(args['WHENGREATERTHANMENU']).toLowerCase();
    final value = Cast.toNumber(args['VALUE']);

    switch (option) {
      case 'timer':
        return util.ioQuery('clock', 'projectTimer') > value;
      case 'loudness':
        return runtime.audioEngine != null &&
            runtime.audioEngine!.getLoudness() > value;
      default:
        return false;
    }
  }

  dynamic broadcast(Map<String, dynamic> args, dynamic util) {
    final msg = util.runtime.getTargetForStage().lookupBroadcastMsg(
        args['BROADCAST_OPTION']['id'], args['BROADCAST_OPTION']['name']);

    if (msg != null) {
      util.startHats(
          'event_whenbroadcastreceived', {'BROADCAST_OPTION': msg.name});
    }
  }

  dynamic broadcastAndWait(Map<String, dynamic> args, dynamic util) {
    // Cache broadcast variable
    util.stackFrame.putIfAbsent(
      'broadcastVar',
      () => util.runtime.getTargetForStage().lookupBroadcastMsg(
          args['BROADCAST_OPTION']['id'], args['BROADCAST_OPTION']['name']),
    );

    final broadcastVar = util.stackFrame['broadcastVar'];
    if (broadcastVar == null) return;

    final broadcastOption = broadcastVar.name;

    // First execution: start threads
    if (util.stackFrame['startedThreads'] == null) {
      util.stackFrame['startedThreads'] = util.startHats(
        'event_whenbroadcastreceived',
        {'BROADCAST_OPTION': broadcastOption},
      );

      if ((util.stackFrame['startedThreads'] as List).isEmpty) {
        return;
      }
    }

    final startedThreads = util.stackFrame['startedThreads'] as List;

    final waiting =
        startedThreads.any((thread) => runtime.threads.contains(thread));

    if (waiting) {
      final allWaiting =
          startedThreads.every((thread) => runtime.isWaitingThread(thread));

      if (allWaiting) {
        util.yieldTick();
      } else {
        util.yield_();
      }
    }
  }
}
