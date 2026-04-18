// lib/vm/engine/runtime.dart
//
// Lightweight Dart runtime modeled after Scratch VM's surface API.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'dart:math';
import 'target.dart'; // Use your Target class
import 'sequencer.dart';
import 'storage.dart' as st;
import 'thread.dart';
import '../../models/block_model.dart';
import '../../core/blocks/logic/logic_blocks_vm.dart';
import '../../core/blocks/logic/logic_blocks_factory.dart';

/// --- Renderer stub ---
class RendererStub {
  final Random _rnd = Random();
  final Map<int, Map<String, dynamic>> _drawables = {};
  final Map<int, Map<String, dynamic>> _skins = {};
  int _drawableCounter = 1;
  int _skinCounter = 1;

  int createDrawable(int layer) {
    final id = _drawableCounter++;
    _drawables[id] = {
      'layer': layer,
      'pos': [0, 0],
      'skinId': null,
    };
    return id;
  }

  void destroyDrawable(int drawableId, int layer) {
    _drawables.remove(drawableId);
  }

  int createTextSkin(
      String type, String text, bool onSpriteRight, List<num> offset) {
    final id = _skinCounter++;
    _skins[id] = {
      'type': type,
      'text': text,
      'onRight': onSpriteRight,
      'offset': offset,
    };
    return id;
  }

  void updateTextSkin(int skinId, String type, String text, bool onSpriteRight,
      List<num> offset) {
    final skin = _skins[skinId];
    if (skin != null) {
      skin['type'] = type;
      skin['text'] = text;
      skin['onRight'] = onSpriteRight;
      skin['offset'] = offset;
    }
  }

  void updateDrawableSkinId(int drawableId, int skinId) {
    final d = _drawables[drawableId];
    if (d != null) d['skinId'] = skinId;
  }

  void destroySkin(int skinId) {
    _skins.remove(skinId);
  }

  List<num> getCurrentSkinSize(int drawableId) {
    final d = _drawables[drawableId];
    final skinId = d == null ? null : d['skinId'];
    if (skinId != null && _skins.containsKey(skinId)) {
      final text = _skins[skinId]!['text']?.toString() ?? '';
      final w = (max(30, text.length * 7)).toDouble();
      final h = 24.0;
      return [w, h];
    }
    return [80, 24];
  }

  List<num> getNativeSize() => [480, 360];

  void updateDrawablePosition(int drawableId, List<num> pos) {
    final d = _drawables[drawableId];
    if (d != null) d['pos'] = pos;
  }

  void requestRedraw() {}
}

/// --- Monitor blocks stub ---
class MonitorBlocks {
  void changeBlock(Map<String, dynamic> change, dynamic runtime) {}
}

/// --- Clock device ---
class ClockDevice {
  final DateTime _start = DateTime.now();
  double projectTimer = 0.0;

  double time() => DateTime.now().difference(_start).inMilliseconds.toDouble();
  double projectTimerSeconds() => time() / 1000.0;
  void resetProjectTimer() {}
}

/// --- Mouse ---
class MouseDevice {
  double _x = 0.0;
  double _y = 0.0;
  bool _isDown = false;

  double getScratchX() => _x;
  double getScratchY() => _y;
  bool getIsDown() => _isDown;

  void setPosition(double x, double y) {
    _x = x;
    _y = y;
  }

  void setDown(bool v) => _isDown = v;
}

/// --- Keyboard ---
class KeyboardDevice {
  final Set<String> _keysDown = {};
  bool getKeyIsDown(String key) => _keysDown.contains(key.toLowerCase());

  void setKey(String key, bool down) {
    if (down)
      _keysDown.add(key.toLowerCase());
    else
      _keysDown.remove(key.toLowerCase());
  }
}

/// --- User data ---
class UserDataDevice {
  String username = 'anon';
  String getUsername() => username;
}

/// --- Cloud ---
class CloudDevice {
  final Map<String, dynamic> _vars = {};
  bool canAddCloudVariable() => true;

  void addCloudVariable(String name) => _vars[name] = 0;
  void removeCloudVariable(String name) => _vars.remove(name);
  bool hasCloudVariables() => _vars.isNotEmpty;

  Future<void> requestUpdateVariable(String name, dynamic value) async {
    _vars[name] = value;
  }
}

/// --- Audio engine ---
class AudioEngineStub {
  double getLoudness() => 0.0;
}

/// --- Runtime ---
class Runtime {
  static const int STAGE_WIDTH = 480;
  static const int STAGE_HEIGHT = 360;
  final List<Block> _blocks = [];
  // Runtime.dart → inside Runtime class
  final LogicBlocksVM logicVM = LogicBlocksVM();

  final Map<String, List<Function>> _listeners = {};
  final List<Target> targets = [];
  final List<Thread> threads = [];
  bool stopRequested = false;

  /// --- Scratch primitive registry ---
  final Map<String, Function> _primitives = {};

  final RendererStub renderer = RendererStub();
  final MonitorBlocks monitorBlocks = MonitorBlocks();
  final ClockDevice clock = ClockDevice();
  final MouseDevice mouse = MouseDevice();
  final KeyboardDevice keyboard = KeyboardDevice();
  final UserDataDevice userData = UserDataDevice();
  final CloudDevice cloud = CloudDevice();
  final AudioEngineStub? audioEngine = AudioEngineStub();

  Sequencer? sequencer;
  st.Storage? storage;
  void Function(Map<String, dynamic>)? onBlockEvent;

  double? currentStepTime = 16.666;
  final Random _rnd = Random();

  Runtime() {
    storage = st.Storage();
    sequencer = Sequencer(this);

    // Add stage target
    final stage = createTarget(id: 'stage', name: 'Stage', isStage: true);
    targets.add(stage);
  }
  // ✅ Add this to integrate with EditorScreen
  void loadBlocks(List<Block> blocks) {
    _blocks.clear();
    _blocks.addAll(blocks);
  }

  void attachWorkspace(dynamic workspace) {}

  void on(String eventName, Function callback) {
    _listeners.putIfAbsent(eventName, () => []).add(callback);
  }

  void off(String eventName, Function callback) {
    final list = _listeners[eventName];
    if (list != null) list.remove(callback);
  }

  void registerPrimitives(Map<String, Function> primitives) {
    _primitives.addAll(primitives);
  }

  dynamic executeOpcode(
    String opcode,
    Map<String, dynamic> args,
    dynamic util,
  ) {
    final fn = _primitives[opcode];
    if (fn == null) {
      print('⚠️ Unknown opcode: $opcode');
      return null;
    }
    return fn(args, util);
  }

  void emit(String eventName,
      [dynamic arg1, dynamic arg2, dynamic arg3, dynamic arg4]) {
    final list = _listeners[eventName];
    if (list != null) {
      final handlers = List<Function>.from(list);
      for (final h in handlers) {
        try {
          h(arg1, arg2, arg3, arg4);
        } catch (_) {}
      }
    }
  }

  // ---------------- Targets ----------------
  Target createTarget(
      {required String id, required String name, bool isStage = false}) {
    final target = Target(this, null);
    target.setCustomState('id', id);
    target.setCustomState('name', name);
    if (isStage) target.visible = true;
    targets.add(target);
    return target;
  }

  Target? getTarget(String id) =>
      targets.firstWhereOrNull((t) => t.getCustomState('id') == id);

  Target getTargetForStage() => targets.firstWhere((t) => t.isStage,
      orElse: () => createTarget(id: 'stage', name: 'Stage', isStage: true));

  Target? getSpriteTargetByName(String name) =>
      targets.firstWhereOrNull((t) => t.getName() == name && !t.isStage);

  void addTarget(Target t) => targets.add(t);

  void disposeTarget(Target t) => targets.removeWhere((x) => x == t);

  void stopForTarget(Target t) {
    threads.removeWhere((th) => th.target == t);
  }

  /// Returns the topmost sprite (non-stage target) under the given (x, y) coordinate
  Target? getSpriteUnder(double x, double y) {
    // Reverse iterate so topmost sprite is found first
    for (var i = targets.length - 1; i >= 0; i--) {
      final target = targets[i];
      if (target.isStage) continue;

      // simple bounding box check (adjust according to your sprite size)
      const double SPRITE_WIDTH = 80;
      const double SPRITE_HEIGHT = 80;

      final left = target.x - SPRITE_WIDTH / 2;
      final right = target.x + SPRITE_WIDTH / 2;
      final top = target.y + SPRITE_HEIGHT / 2;
      final bottom = target.y - SPRITE_HEIGHT / 2;

      if (x >= left && x <= right && y >= bottom && y <= top) {
        return target;
      }
    }
    return null;
  }

  // ---------------- Execution ----------------
  void start(List<dynamic> topBlocks) {
    threads.clear();
    for (final block in topBlocks) {
      if (block.type == 'event_whenflagclicked') {
        // Create a new thread for the sprite
        final thread = Thread(
          topBlock: block.id,
          target: getSpriteTargetByName('Sprite1') ??
              targets.firstWhere((t) => !t.isStage),
        );

        threads.add(thread);
      }
    }
  }

  void startHats(String opcode, [Map<String, dynamic>? matchFields]) {
    if (sequencer == null) return;

    for (final target in targets) {
      final blocks = target.getCustomState('blocks');
      if (blocks == null || blocks is! Map) continue;

      for (final block in blocks.values) {
        if (block.opcode != opcode) continue;

        if (matchFields != null) {
          bool matches = true;
          matchFields.forEach((key, value) {
            if (block.fields[key]?.value != value) matches = false;
          });
          if (!matches) continue;
        }

        sequencer!.startThread(block.id, target);
      }
    }
  }

  void stopAll() => threads.clear();

  void requestRedraw() => renderer.requestRedraw();

  bool isWaitingThread(Thread thread) => thread.isWaiting && !thread.done;

  // ---------------- IO ----------------
  dynamic ioQuery(String deviceName, String funcName, [List<dynamic>? args]) {
    switch (deviceName) {
      case 'clock':
        if (funcName == 'projectTimer') return clock.projectTimerSeconds();
        if (funcName == 'resetProjectTimer') {
          clock.resetProjectTimer();
          return null;
        }
        return null;
      case 'mouse':
        if (funcName == 'getScratchX') return mouse.getScratchX();
        if (funcName == 'getScratchY') return mouse.getScratchY();
        if (funcName == 'getIsDown') return mouse.getIsDown();
        return null;
      case 'keyboard':
        if (funcName == 'getKeyIsDown')
          return keyboard
              .getKeyIsDown(args != null && args.isNotEmpty ? args[0] : '');
        return null;
      case 'userData':
        if (funcName == 'getUsername') return userData.getUsername();
        return null;
      case 'cloud':
        if (funcName == 'requestUpdateVariable') {
          final name = args != null && args.length > 0 ? args[0] : null;
          final value = args != null && args.length > 1 ? args[1] : null;
          return cloud.requestUpdateVariable(name, value);
        }
        return null;
      default:
        return null;
    }
  }

  double nowMillis() => DateTime.now().millisecondsSinceEpoch.toDouble();
  double get currentMSecs => nowMillis();
}

/// Extension for firstWhereOrNull
extension FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final e in this) if (test(e)) return e;
    return null;
  }
}
