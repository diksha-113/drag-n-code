import 'dart:math';
import '../../vm/util/clone.dart';
import '../util/math_util.dart';
import '../util/string_util.dart';
import '../engine/target.dart';
import '../engine/stage_layering.dart';

/// RenderedTarget: instance of a sprite (clone), or the stage
class RenderedTarget extends Target {
  final dynamic sprite;
  dynamic renderer;
  int? drawableID;
  bool dragging = false;

  Map<String, double> effects = {
    'color': 0.0,
    'fisheye': 0.0,
    'whirl': 0.0,
    'pixelate': 0.0,
    'mosaic': 0.0,
    'brightness': 0.0,
    'ghost': 0.0,
  };

  bool isOriginal = true;
  bool isStage = false;
  double x = 0.0;
  double y = 0.0;
  double direction = 90.0;
  bool draggable = false;
  bool visible = true;
  double size = 100.0;
  int currentCostume = 0;
  String rotationStyle = ROTATION_STYLE_ALL_AROUND;
  double volume = 100.0;
  double tempo = 60.0;
  double videoTransparency = 50.0;
  String videoState = VIDEO_STATE_ON;
  String? textToSpeechLanguage;

  RenderedTarget(this.sprite, runtime) : super(runtime, sprite.blocks) {
    renderer = runtime?.renderer;
  }

  /// Minimal emit implementation
  void emit(String eventName, dynamic target,
      [dynamic arg1, dynamic arg2, dynamic arg3]) {
    runtime?.emit(eventName, target, arg1, arg2, arg3);
  }

  /// Initialize the drawable
  void initDrawable(int layerGroup) {
    if (renderer != null) {
      drawableID = renderer.createDrawable(layerGroup);
    }
    if (!isOriginal) {
      runtime.startHats('control_start_as_clone', {'target': this});
    }
  }

  Map<String, dynamic> get audioPlayer {
    final bank = sprite.soundBank;
    return {
      'playSound': (int soundId) => bank.play(this, soundId),
    };
  }

  void initAudio() {}

  void setXY(double newX, double newY, [bool force = false]) {
    if (isStage || (dragging && !force)) return;

    final oldX = x;
    final oldY = y;

    if (renderer != null && drawableID != null) {
      final pos =
          renderer.getFencedPositionOfDrawable(drawableID!, [newX, newY]);
      x = (pos[0] as num).toDouble();
      y = (pos[1] as num).toDouble();
      renderer.updateDrawablePosition(drawableID!, [x, y]);
    } else {
      x = newX;
      y = newY;
    }

    emit(EVENT_TARGET_MOVED, this, oldX, oldY, force);
    runtime.requestTargetsUpdate(this);
  }

  Map<String, dynamic> _getRenderedDirectionAndScale() {
    double finalDirection = direction;
    List<double> finalScale = [size, size];

    if (rotationStyle == ROTATION_STYLE_NONE) {
      finalDirection = 90.0;
    } else if (rotationStyle == ROTATION_STYLE_LEFT_RIGHT) {
      finalDirection = 90.0;
      double scaleFlip = direction < 0.0 ? -1.0 : 1.0;
      finalScale = [scaleFlip * size, size];
    }

    return {
      'direction': finalDirection,
      'scaleX': finalScale[0],
      'scaleY': finalScale[1]
    };
  }

  void setDirection(double newDirection) {
    if (isStage || !newDirection.isFinite) return;

    // Use wrapClampDouble for proper double handling
    direction = MathUtil.wrapClampDouble(newDirection, -179.0, 180.0);
    if (renderer != null && drawableID != null) {
      final rendered = _getRenderedDirectionAndScale();
      renderer.updateDrawableDirectionScale(drawableID!, rendered['direction'],
          [rendered['scaleX'], rendered['scaleY']]);
    }
    runtime.requestTargetsUpdate(this);
  }

  void setDraggable(bool value) {
    if (isStage) return;
    draggable = value;
    runtime.requestTargetsUpdate(this);
  }

  void setVisible(bool value) {
    if (isStage) return;
    visible = value;
    renderer?.updateDrawableVisible(drawableID!, visible);
    runtime.requestTargetsUpdate(this);
  }

  void setSize(double newSize) {
    if (isStage) return;
    size = newSize;
    runtime.requestTargetsUpdate(this);
  }

  void setEffect(String effectName, double value) {
    if (!effects.containsKey(effectName)) return;
    effects[effectName] = value;
  }

  void clearEffects() {
    for (var key in effects.keys) {
      effects[key] = 0.0;
    }
  }

  void setCostume(int index) {
    // Use wrapClampInt for proper int handling
    currentCostume =
        MathUtil.wrapClampInt(index, 0, sprite.costumes.length - 1);
  }

  void startDrag() => dragging = true;
  void stopDrag() => dragging = false;

  /// Bounds for bubbles
  Map<String, num> getBoundsForBubble() {
    return {
      'left': x - size / 2,
      'right': x + size / 2,
      'top': y + size / 2,
      'bottom': y - size / 2,
    };
  }

  Map<String, dynamic> toJson() {
    final costumes = sprite.costumes;
    return {
      'id': id,
      'name': sprite.name,
      'isStage': isStage,
      'x': x,
      'y': y,
      'size': size,
      'direction': direction,
      'draggable': draggable,
      'currentCostume': currentCostume,
      'costume': costumes[currentCostume],
      'costumeCount': costumes.length,
      'visible': visible,
      'rotationStyle': rotationStyle,
      'blocks': blocks.allBlocks, // updated getter
      'variables': variables,
      'costumes': costumes,
      'sounds': sprite.sounds,
      'textToSpeechLanguage': textToSpeechLanguage,
      'tempo': tempo,
      'volume': volume,
      'videoTransparency': videoTransparency,
      'videoState': videoState,
    };
  }

  void dispose() {
    runtime.changeCloneCounter(-1);
    runtime.stopForTarget(this);
    runtime.removeExecutable(this);
  }

  // ---------- Constants ----------
  static const String EVENT_TARGET_MOVED = 'TARGET_MOVED';
  static const String EVENT_TARGET_VISUAL_CHANGE = 'TARGET_VISUAL_CHANGE';
  static const String ROTATION_STYLE_ALL_AROUND = 'all around';
  static const String ROTATION_STYLE_LEFT_RIGHT = 'left-right';
  static const String ROTATION_STYLE_NONE = "don't rotate";
  static const String VIDEO_STATE_OFF = 'off';
  static const String VIDEO_STATE_ON = 'on';
  static const String VIDEO_STATE_ON_FLIPPED = 'on-flipped';
}
