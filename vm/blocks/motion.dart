import 'dart:math' as math;
import '../util/cast.dart';
import '../util/math_util.dart';
import '../util/timer.dart';
import '../engine/runtime.dart';

class Scratch3MotionBlocks {
  final Runtime runtime;

  Scratch3MotionBlocks(this.runtime);

  Map<String, Function> getPrimitives() {
    return {
      'motion_movesteps': moveSteps,
      'motion_gotoxy': goToXY,
      'motion_goto': goTo,
      'motion_turnright': turnRight,
      'motion_turnleft': turnLeft,
      'motion_pointindirection': pointInDirection,
      'motion_pointtowards': pointTowards,
      'motion_glidesecstoxy': glide,
      'motion_glideto': glideTo,
      'motion_ifonedgebounce': ifOnEdgeBounce,
      'motion_setrotationstyle': setRotationStyle,
      'motion_changexby': changeX,
      'motion_setx': setX,
      'motion_changeyby': changeY,
      'motion_sety': setY,
      'motion_xposition': getX,
      'motion_yposition': getY,
      'motion_direction': getDirection,
      'motion_scroll_right': () {},
      'motion_scroll_up': () {},
      'motion_align_scene': () {},
      'motion_xscroll': () {},
      'motion_yscroll': () {},
    };
  }

  Map<String, dynamic> getMonitored() {
    return {
      'motion_xposition': {
        'isSpriteSpecific': true,
        'getId': (String id) => '${id}_xposition'
      },
      'motion_yposition': {
        'isSpriteSpecific': true,
        'getId': (String id) => '${id}_yposition'
      },
      'motion_direction': {
        'isSpriteSpecific': true,
        'getId': (String id) => '${id}_direction'
      }
    };
  }

  // ---------------- Motion functions ----------------

  dynamic moveSteps(Map args, dynamic util) {
    final steps = Cast.toNumber(args['STEPS']).toDouble();
    final radians = MathUtil.degToRad((90 - util.target.direction).toDouble());
    final dx = (steps * math.cos(radians)).toDouble();
    final dy = (steps * math.sin(radians)).toDouble();
    util.target.setXY(util.target.x + dx, util.target.y + dy);
  }

  dynamic goToXY(Map args, dynamic util) {
    final x = Cast.toNumber(args['X']).toDouble();
    final y = Cast.toNumber(args['Y']).toDouble();
    util.target.setXY(x, y);
  }

  List<double>? getTargetXY(dynamic targetName, dynamic util) {
    double targetX = 0;
    double targetY = 0;

    if (targetName == '_mouse_') {
      targetX = (util.ioQuery('mouse', 'getScratchX') as num).toDouble();
      targetY = (util.ioQuery('mouse', 'getScratchY') as num).toDouble();
    } else if (targetName == '_random_') {
      final stageWidth = Runtime.STAGE_WIDTH;
      final stageHeight = Runtime.STAGE_HEIGHT;
      targetX = (stageWidth * (MathUtil.random() - 0.5)).toDouble();
      targetY = (stageHeight * (MathUtil.random() - 0.5)).toDouble();
    } else {
      targetName = Cast.toStringValue(targetName);
      final goToTarget = runtime.getSpriteTargetByName(targetName);
      if (goToTarget == null) return null;
      targetX = (goToTarget.x as num).toDouble();
      targetY = (goToTarget.y as num).toDouble();
    }

    return [targetX, targetY];
  }

  dynamic goTo(Map args, dynamic util) {
    final xy = getTargetXY(args['TO'], util);
    if (xy != null) util.target.setXY(xy[0], xy[1]);
  }

  dynamic turnRight(Map args, dynamic util) {
    final degrees = Cast.toNumber(args['DEGREES']).toDouble();
    util.target.setDirection((util.target.direction + degrees).toDouble());
  }

  dynamic turnLeft(Map args, dynamic util) {
    final degrees = Cast.toNumber(args['DEGREES']).toDouble();
    util.target.setDirection((util.target.direction - degrees).toDouble());
  }

  dynamic pointInDirection(Map args, dynamic util) {
    final direction = Cast.toNumber(args['DIRECTION']).toDouble();
    util.target.setDirection(direction);
  }

  dynamic pointTowards(Map args, dynamic util) {
    double targetX = 0;
    double targetY = 0;

    if (args['TOWARDS'] == '_mouse_') {
      targetX = (util.ioQuery('mouse', 'getScratchX') as num).toDouble();
      targetY = (util.ioQuery('mouse', 'getScratchY') as num).toDouble();
    } else if (args['TOWARDS'] == '_random_') {
      util.target.setDirection(((MathUtil.random() * 360) - 180).toDouble());
      return;
    } else {
      args['TOWARDS'] = Cast.toStringValue(args['TOWARDS']);
      final target = runtime.getSpriteTargetByName(args['TOWARDS']);
      if (target == null) return;
      targetX = (target.x as num).toDouble();
      targetY = (target.y as num).toDouble();
    }

    final dx = (targetX - (util.target.x as num)).toDouble();
    final dy = (targetY - (util.target.y as num)).toDouble();

    final direction = (90 - MathUtil.radToDeg(math.atan2(dy, dx))).toDouble();
    util.target.setDirection(direction);
  }

  dynamic glide(Map args, dynamic util) {
    if (util.stackFrame['timer'] != null) {
      final TimerUtil timer = util.stackFrame['timer'];
      final elapsed = timer.timeElapsed();

      if (elapsed < util.stackFrame['duration'] * 1000) {
        final frac =
            (elapsed / (util.stackFrame['duration'] * 1000)).toDouble();
        final dx =
            (frac * (util.stackFrame['endX'] - util.stackFrame['startX']))
                .toDouble();
        final dy =
            (frac * (util.stackFrame['endY'] - util.stackFrame['startY']))
                .toDouble();

        util.target.setXY(
          (util.stackFrame['startX'] + dx).toDouble(),
          (util.stackFrame['startY'] + dy).toDouble(),
        );
        return util.yield_();
      } else {
        util.target.setXY(
          (util.stackFrame['endX']).toDouble(),
          (util.stackFrame['endY']).toDouble(),
        );
      }
    } else {
      util.stackFrame['timer'] = (TimerUtil()..start());
      util.stackFrame['duration'] = Cast.toNumber(args['SECS']).toDouble();
      util.stackFrame['startX'] = (util.target.x as num).toDouble();
      util.stackFrame['startY'] = (util.target.y as num).toDouble();
      util.stackFrame['endX'] = Cast.toNumber(args['X']).toDouble();
      util.stackFrame['endY'] = Cast.toNumber(args['Y']).toDouble();

      if (util.stackFrame['duration'] <= 0) {
        util.target.setXY(util.stackFrame['endX'], util.stackFrame['endY']);
        return;
      }
      return util.yield_();
    }
  }

  dynamic glideTo(Map args, dynamic util) {
    final xy = getTargetXY(args['TO'], util);
    if (xy != null) {
      return glide({'SECS': args['SECS'], 'X': xy[0], 'Y': xy[1]}, util);
    }
  }

  dynamic ifOnEdgeBounce(Map args, dynamic util) {
    final bounds = util.target.getBounds();
    if (bounds == null) return;

    final stageWidth = Runtime.STAGE_WIDTH;
    final stageHeight = Runtime.STAGE_HEIGHT;

    final distLeft =
        ((stageWidth / 2 + bounds.left)).clamp(0, double.infinity).toDouble();
    final distTop =
        (((stageHeight / 2) - bounds.top)).clamp(0, double.infinity).toDouble();
    final distRight = (((stageWidth / 2) - bounds.right))
        .clamp(0, double.infinity)
        .toDouble();
    final distBottom = ((stageHeight / 2 + bounds.bottom))
        .clamp(0, double.infinity)
        .toDouble();

    String nearest = '';
    double min = double.infinity;

    if (distLeft < min) {
      min = distLeft;
      nearest = 'left';
    }
    if (distTop < min) {
      min = distTop;
      nearest = 'top';
    }
    if (distRight < min) {
      min = distRight;
      nearest = 'right';
    }
    if (distBottom < min) {
      min = distBottom;
      nearest = 'bottom';
    }

    if (min > 0) return;

    final radians =
        MathUtil.degToRad((90 - (util.target.direction as num)).toDouble());
    double dx = math.cos(radians).toDouble();
    double dy = (-math.sin(radians)).toDouble();

    if (nearest == 'left') {
      dx = dx.abs().clamp(0.2, 1.0).toDouble();
    } else if (nearest == 'top') {
      dy = dy.abs().clamp(0.2, 1.0).toDouble();
    } else if (nearest == 'right') {
      dx = (-dx.abs().clamp(0.2, 1.0)).toDouble();
    } else if (nearest == 'bottom') {
      dy = (-dy.abs().clamp(0.2, 1.0)).toDouble();
    }

    final newDir = MathUtil.radToDeg(math.atan2(-dy, dx)).toDouble();
    util.target.setDirection((90 - newDir).toDouble());
  }

  dynamic setRotationStyle(Map args, dynamic util) {
    util.target.setRotationStyle(args['STYLE']);
  }

  dynamic changeX(Map args, dynamic util) {
    final dx = Cast.toNumber(args['DX']).toDouble();
    util.target.setXY((util.target.x as num) + dx, util.target.y);
  }

  dynamic setX(Map args, dynamic util) {
    final x = Cast.toNumber(args['X']).toDouble();
    util.target.setXY(x, util.target.y);
  }

  dynamic changeY(Map args, dynamic util) {
    final dy = Cast.toNumber(args['DY']).toDouble();
    util.target.setXY(util.target.x, (util.target.y as num) + dy);
  }

  dynamic setY(Map args, dynamic util) {
    final y = Cast.toNumber(args['Y']).toDouble();
    util.target.setXY(util.target.x, y);
  }

  dynamic getX(Map args, dynamic util) => (util.target.x as num).toDouble();
  dynamic getY(Map args, dynamic util) => (util.target.y as num).toDouble();
  dynamic getDirection(Map args, dynamic util) =>
      (util.target.direction as num).toDouble();

  // ---------------- Block Types / Arguments ----------------
  Map<String, Map<String, dynamic>> blockTypes = {
    'motion_movesteps': {
      'blockType': 'command',
      'arguments': {'STEPS': 'number'}
    },
    'motion_gotoxy': {
      'blockType': 'command',
      'arguments': {'X': 'number', 'Y': 'number'}
    },
    'motion_goto': {
      'blockType': 'command',
      'arguments': {'TO': 'string'}
    },
    'motion_turnright': {
      'blockType': 'command',
      'arguments': {'DEGREES': 'number'}
    },
    'motion_turnleft': {
      'blockType': 'command',
      'arguments': {'DEGREES': 'number'}
    },
    'motion_pointindirection': {
      'blockType': 'command',
      'arguments': {'DIRECTION': 'number'}
    },
    'motion_pointtowards': {
      'blockType': 'command',
      'arguments': {'TOWARDS': 'string'}
    },
    'motion_glidesecstoxy': {
      'blockType': 'command',
      'arguments': {'SECS': 'number', 'X': 'number', 'Y': 'number'}
    },
    'motion_glideto': {
      'blockType': 'command',
      'arguments': {'SECS': 'number', 'TO': 'string'}
    },
    'motion_ifonedgebounce': {'blockType': 'command', 'arguments': {}},
    'motion_setrotationstyle': {
      'blockType': 'command',
      'arguments': {'STYLE': 'string'}
    },
    'motion_changexby': {
      'blockType': 'command',
      'arguments': {'DX': 'number'}
    },
    'motion_setx': {
      'blockType': 'command',
      'arguments': {'X': 'number'}
    },
    'motion_changeyby': {
      'blockType': 'command',
      'arguments': {'DY': 'number'}
    },
    'motion_sety': {
      'blockType': 'command',
      'arguments': {'Y': 'number'}
    },
    'motion_xposition': {'blockType': 'reporter', 'arguments': {}},
    'motion_yposition': {'blockType': 'reporter', 'arguments': {}},
    'motion_direction': {'blockType': 'reporter', 'arguments': {}},
  };
}
