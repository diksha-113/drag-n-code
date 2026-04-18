import 'dart:async';
import 'dart:math' as math;

import '../util/cast.dart';
import '../sprites/rendered_target.dart';
import '../util/uid.dart';
import '../engine/stage_layering.dart';
import '../util/get_monitor_id.dart';
import '../util/math_util.dart';

/// Bubble state attached to a target.
class BubbleState {
  bool onSpriteRight;
  int? drawableId;
  int? skinId;
  String text;
  String type; // "say" or "think"
  String? usageId;

  BubbleState({
    this.onSpriteRight = true,
    this.drawableId,
    this.skinId,
    this.text = '',
    this.type = 'say',
    this.usageId,
  });

  BubbleState copy() => BubbleState(
        onSpriteRight: onSpriteRight,
        drawableId: drawableId,
        skinId: skinId,
        text: text,
        type: type,
        usageId: usageId,
      );
}

class Scratch3LooksBlocks {
  final dynamic runtime;
  Timer? _bubbleTimeout;

  Scratch3LooksBlocks(this.runtime) {
    runtime.on('PROJECT_STOP_ALL', _onResetBubbles);
    runtime.on('targetWasRemoved', _onTargetWillExit);

    runtime.on(Scratch3LooksBlocks.sayOrThink,
        (dynamic target, String type, dynamic text) {
      _updateBubble(target, type, text);
    });
  }

  // ---------- Static constants ----------
  static BubbleState get defaultBubbleState => BubbleState();
  static String get stateKey => 'Scratch.looks';
  static String get sayOrThink => 'SAY';
  static int get sayBubbleLimit => 330;
  static Map<String, double> get effectGhostLimit => {'min': 0.0, 'max': 100.0};
  static Map<String, double> get effectBrightnessLimit =>
      {'min': -100.0, 'max': 100.0};

  // ---------- Internal helpers ----------
  BubbleState _getBubbleState(dynamic target) {
    var bubbleState = target.getCustomState(stateKey) as BubbleState?;
    if (bubbleState == null) {
      bubbleState = defaultBubbleState.copy();
      target.setCustomState(stateKey, bubbleState);
    }
    return bubbleState;
  }

  void _onTargetChanged(dynamic target) {
    final bubbleState = _getBubbleState(target);
    if (bubbleState.drawableId != null) _positionBubble(target);
  }

  void _onTargetWillExit(dynamic target) {
    final bubbleState = _getBubbleState(target);
    if (bubbleState.drawableId != null && bubbleState.skinId != null) {
      runtime.renderer
          .destroyDrawable(bubbleState.drawableId, StageLayering.SPRITE_LAYER);
      runtime.renderer.destroySkin(bubbleState.skinId);
      bubbleState.drawableId = null;
      bubbleState.skinId = null;
      runtime.requestRedraw();
    }
    try {
      target.removeListener(
          RenderedTarget.EVENT_TARGET_VISUAL_CHANGE, _onTargetChanged);
    } catch (_) {}
  }

  void _onResetBubbles([_]) {
    for (final t in runtime.targets as List) {
      final bubbleState = _getBubbleState(t);
      bubbleState.text = '';
      _onTargetWillExit(t);
    }
    _bubbleTimeout?.cancel();
    _bubbleTimeout = null;
  }

  void _positionBubble(dynamic target) {
    if (!target.visible) return;

    final bubbleState = _getBubbleState(target);
    final skinSize =
        runtime.renderer.getCurrentSkinSize(bubbleState.drawableId);
    final double bubbleWidth = skinSize[0].toDouble();
    final double bubbleHeight = skinSize[1].toDouble();

    Map<String, double> targetBounds;
    try {
      targetBounds = target.getBoundsForBubble().map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()));
    } catch (_) {
      targetBounds = {
        'left': target.x.toDouble(),
        'right': target.x.toDouble(),
        'top': target.y.toDouble(),
        'bottom': target.y.toDouble(),
      };
    }

    final stageSize = runtime.renderer.getNativeSize();
    final stageBounds = {
      'left': -stageSize[0] / 2.0,
      'right': stageSize[0] / 2.0,
      'top': stageSize[1] / 2.0,
      'bottom': -stageSize[1] / 2.0
    };

    final onRight = bubbleState.onSpriteRight;
    final fitsOnRight = onRight &&
        (bubbleWidth + targetBounds['right']! > stageBounds['right']!) &&
        (targetBounds['left']! - bubbleWidth > stageBounds['left']!);
    final fitsOnLeft = !onRight &&
        (targetBounds['left']! - bubbleWidth < stageBounds['left']!) &&
        (bubbleWidth + targetBounds['right']! < stageBounds['right']!);

    if (fitsOnRight) {
      bubbleState.onSpriteRight = false;
      _renderBubble(target);
      return;
    } else if (fitsOnLeft) {
      bubbleState.onSpriteRight = true;
      _renderBubble(target);
      return;
    } else {
      final x = bubbleState.onSpriteRight
          ? math.max<double>(
              stageBounds['left']!.toDouble(),
              math.min<double>(stageBounds['right']!.toDouble() - bubbleWidth,
                  targetBounds['right']!.toDouble()))
          : math.min<double>(
              stageBounds['right']!.toDouble() - bubbleWidth,
              math.max<double>(stageBounds['left']!.toDouble(),
                  targetBounds['left']!.toDouble() - bubbleWidth));

      final y = math.min<double>(stageBounds['top']!.toDouble(),
          targetBounds['bottom']!.toDouble() + bubbleHeight);

      runtime.renderer.updateDrawablePosition(bubbleState.drawableId, [x, y]);
      runtime.requestRedraw();
    }
  }

  void _renderBubble(dynamic target) {
    if (runtime.renderer == null) return;

    final bubbleState = _getBubbleState(target);
    final type = bubbleState.type;
    final text = bubbleState.text;

    if (!target.visible || text.isEmpty) {
      _onTargetWillExit(target);
      return;
    }

    if (bubbleState.skinId != null) {
      runtime.renderer.updateTextSkin(bubbleState.skinId, type, text,
          bubbleState.onSpriteRight, [0.0, 0.0]);
    } else {
      try {
        target.addListener(
            RenderedTarget.EVENT_TARGET_VISUAL_CHANGE, _onTargetChanged);
      } catch (_) {}
      bubbleState.drawableId =
          runtime.renderer.createDrawable(StageLayering.SPRITE_LAYER);
      bubbleState.skinId = runtime.renderer
          .createTextSkin(type, text, bubbleState.onSpriteRight, [0.0, 0.0]);
      runtime.renderer
          .updateDrawableSkinId(bubbleState.drawableId, bubbleState.skinId);
    }

    _positionBubble(target);
  }

  String _formatBubbleText(dynamic text) {
    if (text == null || text.toString().isEmpty) return '';

    if (text is num && text.abs() >= 0.01 && text % 1 != 0) {
      text = text.toStringAsFixed(2);
    }

    var s = text.toString();
    if (s.length > sayBubbleLimit) s = s.substring(0, sayBubbleLimit);
    return s;
  }

  void _updateBubble(dynamic target, String type, dynamic text) {
    final bubbleState = _getBubbleState(target);
    bubbleState.type = type;
    bubbleState.text = _formatBubbleText(text);
    bubbleState.usageId = uid();
    _renderBubble(target);
  }

  // ---------- Effects / Size ----------
  double clampEffect(String effect, double value) {
    switch (effect) {
      case 'ghost':
        return MathUtil.clamp(
            value, effectGhostLimit['min']!, effectGhostLimit['max']!);
      case 'brightness':
        return MathUtil.clamp(value, effectBrightnessLimit['min']!,
            effectBrightnessLimit['max']!);
      default:
        return value;
    }
  }

  void changeEffect(Map<String, dynamic> args, dynamic util) {
    final effect = Cast.toStringValue(args['EFFECT']).toLowerCase();
    if (!util.target.effects.containsKey(effect)) return;
    final change = Cast.toNumber(args['CHANGE']).toDouble();
    var newValue = change + util.target.effects[effect];
    newValue = clampEffect(effect, newValue);
    util.target.setEffect(effect, newValue);
  }

  void setEffect(Map<String, dynamic> args, dynamic util) {
    final effect = Cast.toStringValue(args['EFFECT']).toLowerCase();
    var value = Cast.toNumber(args['VALUE']).toDouble();
    value = clampEffect(effect, value);
    util.target.setEffect(effect, value);
  }

  void clearEffects(Map<String, dynamic> args, dynamic util) {
    util.target.clearEffects();
  }

  void changeSize(Map<String, dynamic> args, dynamic util) {
    final change = Cast.toNumber(args['CHANGE']).toDouble();
    util.target.setSize(util.target.size + change);
  }

  void setSize(Map<String, dynamic> args, dynamic util) {
    final size = Cast.toNumber(args['SIZE']).toDouble();
    util.target.setSize(size);
  }

  // ---------- Bubble / Say / Think ----------
  void say(Map<String, dynamic> args, dynamic util) {
    runtime.emit(sayOrThink, util.target, 'say', args['MESSAGE']);
  }

  Future<void> sayForSecs(Map<String, dynamic> args, dynamic util) async {
    say(args, util);
    final target = util.target;
    final usageId = _getBubbleState(target).usageId;
    final secs = Cast.toNumber(args['SECS']).toDouble();
    final completer = Completer<void>();
    _bubbleTimeout?.cancel();
    _bubbleTimeout = Timer(Duration(milliseconds: (1000 * secs).round()), () {
      _bubbleTimeout = null;
      if (_getBubbleState(target).usageId == usageId) {
        _updateBubble(target, 'say', '');
      }
      completer.complete();
    });
    return completer.future;
  }

  void think(Map<String, dynamic> args, dynamic util) {
    runtime.emit(sayOrThink, util.target, 'think', args['MESSAGE']);
  }

  Future<void> thinkForSecs(Map<String, dynamic> args, dynamic util) async {
    think(args, util);
    final target = util.target;
    final usageId = _getBubbleState(target).usageId;
    final secs = Cast.toNumber(args['SECS']).toDouble();
    final completer = Completer<void>();
    _bubbleTimeout?.cancel();
    _bubbleTimeout = Timer(Duration(milliseconds: (1000 * secs).round()), () {
      _bubbleTimeout = null;
      if (_getBubbleState(target).usageId == usageId) {
        _updateBubble(target, 'think', '');
      }
      completer.complete();
    });
    return completer.future;
  }

  void show(Map<String, dynamic> args, dynamic util) {
    util.target.setVisible(true);
    _renderBubble(util.target);
  }

  void hide(Map<String, dynamic> args, dynamic util) {
    util.target.setVisible(false);
    _renderBubble(util.target);
  }

  // ---------- Costumes / Backdrops helpers ----------
  List<dynamic> _setCostume(dynamic target, dynamic requestedCostume,
      [bool optZeroIndex = false]) {
    if (requestedCostume is num) {
      target.setCostume(optZeroIndex
          ? requestedCostume.toInt()
          : requestedCostume.toInt() - 1);
    } else {
      final costumeIndex =
          target.getCostumeIndexByName(requestedCostume.toString());
      if (costumeIndex != -1) {
        target.setCostume(costumeIndex);
      } else if (requestedCostume == 'next costume') {
        target.setCostume(target.currentCostume + 1);
      } else if (requestedCostume == 'previous costume') {
        target.setCostume(target.currentCostume - 1);
      } else if (!(Cast.isWhiteSpace(requestedCostume) ||
          num.tryParse(requestedCostume.toString()) == null)) {
        final v = num.parse(requestedCostume.toString());
        target.setCostume(optZeroIndex ? v.toInt() : v.toInt() - 1);
      }
    }
    return [];
  }

  List<dynamic> _setBackdrop(dynamic stage, dynamic requestedBackdrop,
      [bool optZeroIndex = false]) {
    if (requestedBackdrop is num) {
      stage.setCostume(optZeroIndex
          ? requestedBackdrop.toInt()
          : requestedBackdrop.toInt() - 1);
    } else {
      final costumeIndex =
          stage.getCostumeIndexByName(requestedBackdrop.toString());
      if (costumeIndex != -1) {
        stage.setCostume(costumeIndex);
      } else if (requestedBackdrop == 'next backdrop') {
        stage.setCostume(stage.currentCostume + 1);
      } else if (requestedBackdrop == 'previous backdrop') {
        stage.setCostume(stage.currentCostume - 1);
      } else if (requestedBackdrop == 'random backdrop') {
        final numCostumes = stage.getCostumes().length;
        if (numCostumes > 1) {
          final lowerBound = 0;
          final upperBound = numCostumes - 1;
          final costumeToExclude = stage.currentCostume;
          final nextCostume = MathUtil.inclusiveRandIntWithout(
              lowerBound, upperBound, costumeToExclude);
          stage.setCostume(nextCostume);
        }
      } else if (!(Cast.isWhiteSpace(requestedBackdrop) ||
          num.tryParse(requestedBackdrop.toString()) == null)) {
        final v = num.parse(requestedBackdrop.toString());
        stage.setCostume(optZeroIndex ? v.toInt() : v.toInt() - 1);
      }
    }

    final newName = stage.getCostumes()[stage.currentCostume].name;
    return runtime
        .startHats('event_whenbackdropswitchesto', {'BACKDROP': newName});
  }

  // ---------- Costumes / Backdrops ----------
  void switchCostume(Map<String, dynamic> args, dynamic util) {
    _setCostume(util.target, args['COSTUME']);
  }

  void nextCostume(Map<String, dynamic> args, dynamic util) {
    _setCostume(util.target, util.target.currentCostume + 1, true);
  }

  void switchBackdrop(Map<String, dynamic> args, dynamic util) {
    _setBackdrop(runtime.getTargetForStage(), args['BACKDROP']);
  }

  void switchBackdropAndWait(Map<String, dynamic> args, dynamic util) {
    if (util.stackFrame['startedThreads'] == null) {
      util.stackFrame['startedThreads'] =
          _setBackdrop(runtime.getTargetForStage(), args['BACKDROP']);
      if ((util.stackFrame['startedThreads'] as List).isEmpty) return;
    }

    final instance = this;
    final startedThreads = util.stackFrame['startedThreads'] as List;
    final waiting = startedThreads
        .any((thread) => instance.runtime.threads.indexOf(thread) != -1);

    if (waiting) {
      final allWaiting = startedThreads
          .every((thread) => instance.runtime.isWaitingThread(thread));
      if (allWaiting) {
        util.yieldTick();
      } else {
        util.yield_();
      }
    }
  }

  void nextBackdrop() {
    final stage = runtime.getTargetForStage();
    _setBackdrop(stage, stage.currentCostume + 1, true);
  }

  // ---------- Layers ----------
  void goToFrontBack(Map<String, dynamic> args, dynamic util) {
    if (!util.target.isStage) {
      if (args['FRONT_BACK'] == 'front') {
        util.target.goToFront();
      } else {
        util.target.goToBack();
      }
    }
  }

  void goForwardBackwardLayers(Map<String, dynamic> args, dynamic util) {
    if (!util.target.isStage) {
      final numLayers = Cast.toNumber(args['NUM']).toInt();
      if (args['FORWARD_BACKWARD'] == 'forward') {
        util.target.goForwardLayers(numLayers);
      } else {
        util.target.goBackwardLayers(numLayers);
      }
    }
  }

  int getSize(Map<String, dynamic> args, dynamic util) {
    return util.target.size.round();
  }

  dynamic getBackdropNumberName(Map<String, dynamic> args) {
    final stage = runtime.getTargetForStage();
    if (args['NUMBER_NAME'] == 'number') return stage.currentCostume + 1;
    return stage.getCostumes()[stage.currentCostume].name;
  }

  dynamic getCostumeNumberName(Map<String, dynamic> args, dynamic util) {
    if (args['NUMBER_NAME'] == 'number') return util.target.currentCostume + 1;
    return util.target.getCostumes()[util.target.currentCostume].name;
  }

  // ---------- Monitors ----------
  Map<String, dynamic> getMonitored() {
    return {
      'looks_size': {
        'isSpriteSpecific': true,
        'getId': (String targetId) => '${targetId}_size'
      },
      'looks_costumenumbername': {
        'isSpriteSpecific': true,
        'getId': (String targetId, Map<String, dynamic> fields) =>
            getMonitorIdForBlockWithArgs(
                '${targetId}_costumenumbername', fields)
      },
      'looks_backdropnumbername': {
        'getId': (_, Map<String, dynamic> fields) =>
            getMonitorIdForBlockWithArgs('backdropnumbername', fields)
      }
    };
  }

  // ---------- Primitives / Block Types ----------
  Map<String, Map<String, dynamic>> blockTypes = {
    'looks_say': {
      'blockType': 'command',
      'arguments': {'MESSAGE': 'string'}
    },
    'looks_sayforsecs': {
      'blockType': 'command',
      'arguments': {'MESSAGE': 'string', 'SECS': 'number'}
    },
    'looks_think': {
      'blockType': 'command',
      'arguments': {'MESSAGE': 'string'}
    },
    'looks_thinkforsecs': {
      'blockType': 'command',
      'arguments': {'MESSAGE': 'string', 'SECS': 'number'}
    },
    'looks_show': {'blockType': 'command', 'arguments': {}},
    'looks_hide': {'blockType': 'command', 'arguments': {}},
    'looks_switchcostumeto': {
      'blockType': 'command',
      'arguments': {'COSTUME': 'string'}
    },
    'looks_nextcostume': {'blockType': 'command', 'arguments': {}},
    'looks_switchbackdropto': {
      'blockType': 'command',
      'arguments': {'BACKDROP': 'string'}
    },
    'looks_switchbackdroptoandwait': {
      'blockType': 'command',
      'arguments': {'BACKDROP': 'string'}
    },
    'looks_nextbackdrop': {'blockType': 'command', 'arguments': {}},
    'looks_goforwardbackwardlayers': {
      'blockType': 'command',
      'arguments': {'NUM': 'number', 'FORWARD_BACKWARD': 'string'}
    },
    'looks_costumenumbername': {'blockType': 'reporter', 'arguments': {}},
    'looks_backdropnumbername': {'blockType': 'reporter', 'arguments': {}},
    'looks_size': {'blockType': 'reporter', 'arguments': {}}
  };
  Map<String, Function> getPrimitives() {
    return {
      'looks_say': say,
      'looks_sayforsecs': sayForSecs,
      'looks_think': think,
      'looks_thinkforsecs': thinkForSecs,
      'looks_show': show,
      'looks_hide': hide,
      'looks_switchcostumeto': switchCostume,
      'looks_nextcostume': nextCostume,
      'looks_switchbackdropto': switchBackdrop,
      'looks_switchbackdroptoandwait': switchBackdropAndWait,
      'looks_nextbackdrop': nextBackdrop,
      'looks_goforwardbackwardlayers': goForwardBackwardLayers,
      'looks_costumenumbername': getCostumeNumberName,
      'looks_backdropnumbername': getBackdropNumberName,
      'looks_size': getSize,
    };
  }
}
