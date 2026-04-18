//
// Dart conversion of Scratch3SensingBlocks (sensing.js)
// Logic preserved exactly, with safe Scratch-like argument handling.
//

import 'dart:async';
import 'dart:math';

import '../util/cast.dart';
import '../util/timer.dart';
import '../util/get_monitor_id.dart';
import '../extension_support/target_type.dart';

class Scratch3SensingBlocks {
  final dynamic runtime;

  String _answer = '';
  final TimerUtil _timer = TimerUtil();
  double _cachedLoudness = -1;
  double _cachedLoudnessTimestamp = 0;

  final List<List<dynamic>> _questionList = [];

  Scratch3SensingBlocks(this.runtime) {
    _timer.start();
    runtime.on('ANSWER', _onAnswer);
    runtime.on('PROJECT_START', _resetAnswer);
    runtime.on('PROJECT_STOP_ALL', _clearAllQuestions);
    runtime.on('STOP_FOR_TARGET', _clearTargetQuestions);
    runtime.on('RUNTIME_DISPOSED', _resetAnswer);
  }

  /// -------------------- SAFE getPrimitives --------------------
  Map<String, Function> getPrimitives() {
    final Map<String, Function> primitives = {
      'sensing_touchingobject': touchingObject,
      'sensing_touchingcolor': touchingColor,
      'sensing_coloristouchingcolor': colorTouchingColor,
      'sensing_distanceto': distanceTo,
      'sensing_timer': getTimer,
      'sensing_resettimer': resetTimer,
      'sensing_of': getAttributeOf,
      'sensing_mousex': getMouseX,
      'sensing_mousey': getMouseY,
      'sensing_setdragmode': setDragMode,
      'sensing_mousedown': getMouseDown,
      'sensing_keypressed': getKeyPressed,
      'sensing_current': current,
      'sensing_dayssince2000': daysSince2000,
      'sensing_loudness': getLoudness,
      'sensing_loud': isLoud,
      'sensing_askandwait': askAndWait,
      'sensing_answer': (_, __) => getAnswer(),
      'sensing_username': getUsername,
      'sensing_userid': (_, __) {},
    };

    final Map<String, Function> safePrimitives = {};

    primitives.forEach((opcode, func) {
      safePrimitives[opcode] = (Map<String, dynamic> args, [util]) {
        final typeInfo =
            blockTypes[opcode]?['arguments'] as Map<String, dynamic>?;

        if (typeInfo != null) {
          for (final key in typeInfo.keys) {
            if (!args.containsKey(key)) {
              args[key] = _getDefaultValue(typeInfo[key]);
            }
          }
        }

        return func(args, util);
      };
    });

    return safePrimitives;
  }

  dynamic _getDefaultValue(String type) {
    switch (type) {
      case 'string':
        return '';
      case 'color':
        return '#000000';
      case 'number':
        return 0;
      default:
        return '';
    }
  }

  /// -------------------- Block types --------------------
  Map<String, Map<String, dynamic>> blockTypes = {
    'sensing_touchingobject': {
      'blockType': 'boolean',
      'arguments': {'TOUCHINGOBJECTMENU': 'string'}
    },
    'sensing_touchingcolor': {
      'blockType': 'boolean',
      'arguments': {'COLOR': 'color'}
    },
    'sensing_coloristouchingcolor': {
      'blockType': 'boolean',
      'arguments': {'COLOR': 'color', 'COLOR2': 'color'}
    },
    'sensing_distanceto': {
      'blockType': 'reporter',
      'arguments': {'DISTANCETOMENU': 'string'}
    },
    'sensing_timer': {'blockType': 'reporter', 'arguments': {}},
    'sensing_resettimer': {'blockType': 'command', 'arguments': {}},
    'sensing_of': {
      'blockType': 'reporter',
      'arguments': {'OBJECT': 'string', 'PROPERTY': 'string'}
    },
    'sensing_mousex': {'blockType': 'reporter', 'arguments': {}},
    'sensing_mousey': {'blockType': 'reporter', 'arguments': {}},
    'sensing_setdragmode': {
      'blockType': 'command',
      'arguments': {'DRAG_MODE': 'string'}
    },
    'sensing_mousedown': {'blockType': 'boolean', 'arguments': {}},
    'sensing_keypressed': {
      'blockType': 'boolean',
      'arguments': {'KEY_OPTION': 'string'}
    },
    'sensing_current': {
      'blockType': 'reporter',
      'arguments': {'CURRENTMENU': 'string'}
    },
    'sensing_dayssince2000': {'blockType': 'reporter', 'arguments': {}},
    'sensing_loudness': {'blockType': 'reporter', 'arguments': {}},
    'sensing_loud': {'blockType': 'boolean', 'arguments': {}},
    'sensing_askandwait': {
      'blockType': 'command',
      'arguments': {'QUESTION': 'string'}
    },
    'sensing_answer': {'blockType': 'reporter', 'arguments': {}},
    'sensing_username': {'blockType': 'reporter', 'arguments': {}},
    'sensing_userid': {'blockType': 'reporter', 'arguments': {}},
  };

  /// -------------------- Blocks --------------------

  Future<void> askAndWait(Map<String, dynamic> args, dynamic util) async {
    final target = util['target'];
    final questionText = args['QUESTION'].toString();
    final completer = Completer<void>();
    final wasQuestionAsked = _questionList.isNotEmpty;

    _enqueueAsk(questionText, completer.complete, target, target.visible,
        target.type == TargetType.stage);

    if (!wasQuestionAsked) _askNextQuestion();
    return completer.future;
  }

  String getAnswer() => _answer;

  dynamic touchingObject(Map<String, dynamic> args, dynamic util) =>
      util['target'].isTouchingObject(args['TOUCHINGOBJECTMENU']);

  dynamic touchingColor(Map<String, dynamic> args, dynamic util) {
    final color = Cast.toRgbColorList(args['COLOR']);
    return util['target'].isTouchingColor(color);
  }

  dynamic colorTouchingColor(Map<String, dynamic> args, dynamic util) {
    final maskColor = Cast.toRgbColorList(args['COLOR']);
    final targetColor = Cast.toRgbColorList(args['COLOR2']);
    return util['target'].colorIsTouchingColor(targetColor, maskColor);
  }

  double distanceTo(Map<String, dynamic> args, dynamic util) {
    if (util['target'].type == TargetType.stage) return 10000;

    double targetX = 0;
    double targetY = 0;

    if (args['DISTANCETOMENU'] == '_mouse_') {
      targetX = util['ioQuery']('mouse', 'getScratchX');
      targetY = util['ioQuery']('mouse', 'getScratchY');
    } else {
      final distTarget =
          runtime.getSpriteTargetByName(args['DISTANCETOMENU'].toString());
      if (distTarget == null) return 10000;
      targetX = distTarget.x;
      targetY = distTarget.y;
    }

    final dx = util['target'].x - targetX;
    final dy = util['target'].y - targetY;
    return sqrt(dx * dx + dy * dy);
  }

  void setDragMode(Map<String, dynamic> args, dynamic util) =>
      util['target'].setDraggable(args['DRAG_MODE'] == 'draggable');

  dynamic getTimer(Map<String, dynamic> args, dynamic util) => _timer.time();

  void resetTimer(Map<String, dynamic> args, dynamic util) => _timer.reset();

  dynamic getMouseX(Map<String, dynamic> args, dynamic util) =>
      util['ioQuery']('mouse', 'getScratchX');

  dynamic getMouseY(Map<String, dynamic> args, dynamic util) =>
      util['ioQuery']('mouse', 'getScratchY');

  dynamic getMouseDown(Map<String, dynamic> args, dynamic util) =>
      util['ioQuery']('mouse', 'getIsDown');

  dynamic getKeyPressed(Map<String, dynamic> args, dynamic util) =>
      util['ioQuery']('keyboard', 'getKeyIsDown', [args['KEY_OPTION']]);

  dynamic getUsername(Map<String, dynamic> args, dynamic util) =>
      util['ioQuery']('userData', 'getUsername');

  /// ================= QUESTION SYSTEM =================

  void _onAnswer(dynamic answer) {
    _answer = answer?.toString() ?? '';

    if (_questionList.isNotEmpty) {
      final question = _questionList.removeAt(0);
      final Function resolve = question[1];
      resolve();
    }

    if (_questionList.isNotEmpty) {
      _askNextQuestion();
    }
  }

  void _resetAnswer([dynamic _]) {
    _answer = '';
  }

  void _clearAllQuestions([dynamic _]) {
    _questionList.clear();
  }

  void _clearTargetQuestions(dynamic target) {
    _questionList.removeWhere((q) => q[2] == target);
  }

  void _enqueueAsk(
    String question,
    Function resolve,
    dynamic target,
    bool visible,
    bool isStage,
  ) {
    _questionList.add([question, resolve, target, visible, isStage]);
  }

  void _askNextQuestion() {
    if (_questionList.isEmpty) return;

    final question = _questionList.first;
    final String questionText = question[0];

    runtime.emit('ASK_QUESTION', questionText);
  }

  /// ================= ATTRIBUTE BLOCK =================

  dynamic getAttributeOf(Map<String, dynamic> args, dynamic util) {
    final objectName = args['OBJECT'];
    final property = args['PROPERTY'];

    final target = runtime.getSpriteTargetByName(objectName);

    if (target == null) return 0;

    switch (property) {
      case 'x position':
        return target.x;
      case 'y position':
        return target.y;
      case 'direction':
        return target.direction;
      case 'costume #':
        return target.currentCostume + 1;
      case 'size':
        return target.size;
      default:
        return 0;
    }
  }

  /// ================= CURRENT DATE/TIME =================

  dynamic current(Map<String, dynamic> args, dynamic util) {
    final now = DateTime.now();
    final menu = args['CURRENTMENU'];

    switch (menu) {
      case 'year':
        return now.year;
      case 'month':
        return now.month;
      case 'date':
        return now.day;
      case 'day of week':
        return now.weekday;
      case 'hour':
        return now.hour;
      case 'minute':
        return now.minute;
      case 'second':
        return now.second;
      default:
        return 0;
    }
  }

  /// ================= DAYS SINCE 2000 =================

  double daysSince2000(Map<String, dynamic> args, dynamic util) {
    final now = DateTime.now();
    final start = DateTime(2000, 1, 1);
    return now.difference(start).inMilliseconds / (1000 * 60 * 60 * 24);
  }

  /// ================= LOUDNESS =================

  double getLoudness(Map<String, dynamic> args, dynamic util) {
    final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();

    if (currentTime - _cachedLoudnessTimestamp > 50) {
      _cachedLoudness = util['ioQuery']('microphone', 'getLoudness') ?? 0;
      _cachedLoudnessTimestamp = currentTime;
    }

    return _cachedLoudness;
  }

  bool isLoud(Map<String, dynamic> args, dynamic util) {
    return getLoudness(args, util) > 10;
  }
}
