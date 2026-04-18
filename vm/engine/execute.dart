// lib/vm/engine/execute.dart
import 'dart:async';
import 'dart:convert';

import 'block_utility.dart';
import 'blocks_execute_cache.dart' hide BlockCached;
import '../util/log.dart' as log;
import 'thread.dart';

final BlockUtility blockUtility = BlockUtility();

const String _blockFunctionProfilerFrame = 'blockFunction';
int _blockFunctionProfilerId = -1;

bool _isFuture(dynamic value) => value is Future;

BlockCached? _findOpById(List<BlockCached> ops, String id) {
  for (final op in ops) {
    if (op.id == id) return op;
  }
  return null;
}

void _handleReport(
  dynamic resolvedValue,
  dynamic sequencer,
  Thread thread,
  BlockCached blockCached,
  bool lastOperation,
) {
  final currentBlockId = blockCached.id;
  final opcode = blockCached.opcode;
  final isHat = blockCached._isHat;

  thread.pushReportedValue(resolvedValue);

  if (isHat) {
    if (sequencer.runtime?.getIsEdgeActivatedHat(opcode) == true) {
      if (!(thread.stackClick ?? false)) {
        final hasOldEdgeValue =
            thread.target.hasEdgeActivatedValue(currentBlockId);
        final oldEdgeValue = thread.target.updateEdgeActivatedValue(
          currentBlockId,
          resolvedValue,
        );

        final edgeWasActivated = hasOldEdgeValue
            ? (!oldEdgeValue && resolvedValue == true)
            : (resolvedValue == true);

        if (!edgeWasActivated) {
          sequencer.retireThread(thread);
        }
      }
    } else if (resolvedValue != true) {
      sequencer.retireThread(thread);
    }
  } else {
    if (lastOperation && resolvedValue != null && thread.atStackTop()) {
      if (thread.stackClick == true) {
        sequencer.runtime?.visualReport(currentBlockId, resolvedValue);
      }
      if (thread.updateMonitor == true) {
        final monitorBlock =
            sequencer.runtime?.monitorBlocks.getBlock(currentBlockId);
        if (monitorBlock == null) return;
        final targetId = monitorBlock.targetId;
        if (targetId != null &&
            sequencer.runtime?.getTargetById(targetId) == null) {
          return;
        }

        sequencer.runtime?.requestUpdateMonitor({
          'id': currentBlockId,
          'spriteName': targetId != null
              ? sequencer.runtime?.getTargetById(targetId)?.getName()
              : null,
          'value': resolvedValue,
        });
      }
    }
    thread.status = Thread.STATUS_RUNNING;
  }
}

void _handleFuture(
  Future primitiveFuture,
  dynamic sequencer,
  Thread thread,
  BlockCached blockCached,
  bool lastOperation,
) {
  if (thread.status == Thread.STATUS_RUNNING) {
    thread.status = Thread.STATUS_PROMISE_WAIT;
  }

  primitiveFuture.then((resolvedValue) {
    try {
      _handleReport(
          resolvedValue, sequencer, thread, blockCached, lastOperation);

      if (lastOperation) {
        dynamic stackFrame;
        String? nextBlockId;
        while (true) {
          final popped = thread.popStack();
          if (popped == null) return;

          nextBlockId = thread.target.blocks.getNextBlock(popped);
          if (nextBlockId != null) break;

          stackFrame = thread.peekStackFrame();
          if (stackFrame == null || stackFrame.isLoop == true) break;
        }
        if (nextBlockId != null) {
          thread.pushStack(nextBlockId);
        }
      }
    } catch (e, st) {
      log.warn('Error in _handleFuture resolution: $e\n$st');
      thread.status = Thread.STATUS_RUNNING;
      thread.popStack();
    }
  }).catchError((rejection) {
    log.warn('Primitive Future rejected: $rejection');
    thread.status = Thread.STATUS_RUNNING;
    thread.popStack();
  });
}

class BlockCached {
  final String id;
  final String opcode;
  final Map<String, dynamic>? fields;
  final Map<String, dynamic>? inputs;
  final Map<String, dynamic>? mutation;

  dynamic _profiler;
  dynamic _profilerFrame;

  bool _isHat = false;
  dynamic _blockFunction;
  bool _definedBlockFunction = false;

  bool _isShadowBlock = false;
  dynamic _shadowValue;

  final Map<String, dynamic> _fieldsMutable = {};
  final Map<String, dynamic> _inputsMutable = {};
  final Map<String, dynamic> _argValues = {};

  String? _parentKey;
  Map<String, dynamic>? _parentValues;
  final List<BlockCached> _ops = [];

  BlockCached(dynamic blockContainer, Map<String, dynamic> cached)
      : id = cached['id'] as String,
        opcode = cached['opcode'] as String,
        fields = (cached['fields'] as Map?)?.cast<String, dynamic>(),
        inputs = (cached['inputs'] as Map?)?.cast<String, dynamic>(),
        mutation = (cached['mutation'] as Map?)?.cast<String, dynamic>() {
    _profiler = null;
    _profilerFrame = null;

    _fieldsMutable.addAll(fields ?? {});
    _inputsMutable.addAll(inputs ?? {});
    _argValues['mutation'] = mutation ?? {};

    final runtime = blockUtility.sequencer?.runtime;

    _isHat = runtime?.getIsHat(opcode) == true;
    _blockFunction = runtime?.getOpcodeFunction(opcode);
    _definedBlockFunction = _blockFunction != null;

    final fieldKeys = fields?.keys.toList() ?? <String>[];
    _isShadowBlock = (!_definedBlockFunction &&
        fieldKeys.length == 1 &&
        (inputs?.isEmpty ?? true));
    if (_isShadowBlock && fieldKeys.isNotEmpty) {
      final key = fieldKeys[0];
      _shadowValue = fields?[key]?['value'];
    }

    fields?.forEach((fieldName, fieldValue) {
      if (fieldName == 'VARIABLE' ||
          fieldName == 'LIST' ||
          fieldName == 'BROADCAST_OPTION') {
        _argValues[fieldName] = {
          'id': fieldValue?['id'],
          'name': fieldValue?['value']?.toString(),
        };
      } else {
        _argValues[fieldName] = fieldValue?['value']?.toString();
      }
    });

    _inputsMutable.remove('custom_block');

    if (_inputsMutable.containsKey('BROADCAST_INPUT')) {
      _argValues['BROADCAST_OPTION'] = {'id': null, 'name': null};
      final broadcastInput = _inputsMutable['BROADCAST_INPUT'];
      final shadowId = broadcastInput?['shadow'];
      if (shadowId != null && broadcastInput?['block'] == shadowId) {
        final shadowCached =
            BlocksExecuteCache.getCached(blockContainer, shadowId as String);
        if (shadowCached != null) {
          final broadcastField =
              (shadowCached as BlockCached).fields?['BROADCAST_OPTION'];
          if (broadcastField != null) {
            _argValues['BROADCAST_OPTION']?['id'] = broadcastField['id'];
            _argValues['BROADCAST_OPTION']?['name'] =
                broadcastField['value']?.toString();
          }
          _inputsMutable.remove('BROADCAST_INPUT');
        }
      }
    }

    _inputsMutable.forEach((inputName, inputObj) {
      final blockId = inputObj?['block'];
      if (blockId != null) {
        final inputCached =
            BlocksExecuteCache.getCached(blockContainer, blockId as String);
        if (inputCached == null) return;
        final childCached = inputCached as BlockCached;
        if (childCached._isHat) return;

        _ops.addAll(childCached._ops);
        childCached._parentKey = inputName;
        childCached._parentValues = _argValues;

        if (childCached._isShadowBlock) {
          _argValues[inputName] = childCached._shadowValue;
        }
      }
    });

    if (_definedBlockFunction) {
      _ops.add(this);
    }
  }
}

void _prepareBlockProfiling(dynamic profiler, BlockCached blockCached) {
  blockCached._profiler = profiler;
  if (_blockFunctionProfilerId == -1 && profiler != null) {
    if (profiler.idByName is Function) {
      _blockFunctionProfilerId =
          profiler.idByName(_blockFunctionProfilerFrame) as int;
    }
  }

  for (var op in blockCached._ops) {
    if (profiler != null && profiler.frame is Function) {
      op._profilerFrame = profiler.frame(_blockFunctionProfilerId, op.opcode);
    }
  }
}

void execute(dynamic sequencer, Thread thread) {
  blockUtility.sequencer = sequencer;
  blockUtility.thread = thread;

  final runtime = sequencer.runtime;
  final String? currentBlockId = thread.peekStack() as String?;

  if (currentBlockId == null) {
    sequencer.retireThread(thread);
    return;
  }

  final currentStackFrame = thread.peekStackFrame();

  var blockContainer = thread.blockContainer;
  var blockCached =
      BlocksExecuteCache.getCached(blockContainer, currentBlockId);

  if (blockCached == null) {
    blockContainer = runtime?.flyoutBlocks;
    blockCached = BlocksExecuteCache.getCached(blockContainer, currentBlockId);

    if (blockCached == null) {
      sequencer.retireThread(thread);
      return;
    }
  }

  final ops = (blockCached as BlockCached)._ops;
  final length = ops.length;
  var i = 0;

  if (currentStackFrame?.reported != null) {
    final reported = currentStackFrame!.reported!;
    for (; i < reported.length; i++) {
      final rep = reported[i] as Map<String, dynamic>?;
      final oldOpCachedId = rep?['opCached']?.toString();
      final inputValue = rep?['inputValue'];

      final opCached =
          oldOpCachedId != null ? _findOpById(ops, oldOpCachedId) : null;
      if (opCached != null) {
        final inputName = opCached._parentKey;
        final argValues = opCached._parentValues;
        if (inputName == 'BROADCAST_INPUT') {
          argValues?['BROADCAST_OPTION']?['id'] = null;
          argValues?['BROADCAST_OPTION']?['name'] = inputValue?.toString();
        } else {
          if (inputName != null) argValues?[inputName] = inputValue;
        }
      }
    }

    if (reported.isNotEmpty) {
      Map<String, dynamic>? lastExisting;
      for (var j = reported.length - 1; j >= 0; j--) {
        final r = reported[j] as Map<String, dynamic>?;
        final found =
            r != null && ops.any((op) => op.id == r['opCached']?.toString());
        if (found) {
          lastExisting = r;
          break;
        }
      }

      final idx = (() {
        if (lastExisting != null) {
          final opCachedId = lastExisting['opCached']?.toString();
          if (opCachedId != null) {
            return ops.indexWhere((op) => op.id == opCachedId);
          }
        }
        return -1;
      })();

      i = idx >= 0 ? idx + 1 : 0;
    }

    if (thread.justReported != null &&
        i < ops.length &&
        ops[i].id == currentStackFrame.reporting) {
      final opCached = ops[i];
      final inputValue = thread.justReported;
      thread.justReported = null;

      final inputName = opCached._parentKey;
      final argValues = opCached._parentValues;
      if (inputName == 'BROADCAST_INPUT') {
        argValues?['BROADCAST_OPTION']?['id'] = null;
        argValues?['BROADCAST_OPTION']?['name'] = inputValue?.toString();
      } else {
        if (inputName != null) argValues?[inputName] = inputValue;
      }
      i += 1;
    }

    currentStackFrame.reporting = '';
    currentStackFrame.reported = null;
  }

  final start = i;

  for (; i < length; i++) {
    final lastOperation = (i == length - 1);
    final opCached = ops[i];
    final blockFunction = opCached._blockFunction;
    final argValues = opCached._argValues;

    if (!(blockContainer.forceNoGlow ?? false)) {
      thread.requestScriptGlowInFrame = true;
    }

    dynamic primitiveReportedValue;
    try {
      primitiveReportedValue = blockFunction != null
          ? Function.apply(blockFunction, [argValues, blockUtility])
          : null;
    } catch (e, st) {
      log.warn('Error executing primitive $e\n$st');
      primitiveReportedValue = null;
    }

    if (_isFuture(primitiveReportedValue)) {
      _handleFuture(primitiveReportedValue as Future, sequencer, thread,
          opCached, lastOperation);

      thread.justReported = null;
      final reportedList = ops.sublist(0, i).map((reportedCached) {
        final inputName = reportedCached._parentKey;
        final reportedValues = reportedCached._parentValues;
        if (inputName == 'BROADCAST_INPUT') {
          return {
            'opCached': reportedValues?[inputName]?['BROADCAST_OPTION']
                ?['name'],
            'inputValue': reportedValues?[inputName]?['BROADCAST_OPTION']
                ?['name'],
          };
        }
        return {
          'opCached': reportedCached.id,
          'inputValue': reportedValues?[inputName],
        };
      }).toList();

      currentStackFrame?.reporting = ops[i].id;
      currentStackFrame?.reported = reportedList;

      break;
    } else if (thread.status == Thread.STATUS_RUNNING) {
      if (lastOperation) {
        _handleReport(
            primitiveReportedValue, sequencer, thread, opCached, lastOperation);
      } else {
        final inputName = opCached._parentKey;
        final parentValues = opCached._parentValues;
        if (inputName == 'BROADCAST_INPUT') {
          parentValues?['BROADCAST_OPTION']?['id'] = null;
          parentValues?['BROADCAST_OPTION']?['name'] =
              primitiveReportedValue?.toString();
        } else {
          if (inputName != null)
            parentValues?[inputName] = primitiveReportedValue;
        }
      }
    }
  }

  final profiler = runtime?.profiler;
  if (profiler != null) {
    if (blockCached._profiler != profiler) {
      _prepareBlockProfiling(profiler, blockCached);
    }
    final end = (start + (length - start)).clamp(0, length);
    for (var p = start; p < end; p++) {
      final frame = ops[p]._profilerFrame;
      if (frame != null && frame.count is int) {
        frame.count = (frame.count as int) + 1;
      }
    }
  }
}
