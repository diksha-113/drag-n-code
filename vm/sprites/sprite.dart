import 'dart:convert';
import '../engine/blocks.dart';

/// Represents a Scratch-style Sprite or Stage
class Sprite {
  final String name;
  final bool isStage;

  // Variables, lists, watchers, and comments
  final Map<String, dynamic> variables = {};
  final Map<String, dynamic> lists = {};
  final Map<String, dynamic> watchers = {};
  final Map<String, dynamic> comments = {};

  // Blocks container for this sprite
  late final Blocks blocks;

  // Threads for running scripts
  final List<Map<String, dynamic>> threads = [];

  // Scratch-like features
  double x = 0.0;
  double y = 0.0;
  double direction = 90.0; // default pointing right
  double size = 100.0; // percent
  bool visible = true;
  bool draggable = false;
  int currentCostume = 0;
  String rotationStyle = ROTATION_STYLE_ALL_AROUND;
  List<String> costumes = [];
  Map<String, double> effects = {
    'color': 0.0,
    'fisheye': 0.0,
    'whirl': 0.0,
    'pixelate': 0.0,
    'mosaic': 0.0,
    'brightness': 0.0,
    'ghost': 0.0,
  };

// Add these:
  double width = 100.0; // default width in pixels
  double height = 100.0; // default height in pixels

  // Event listeners for green flag, key press, broadcasts
  final Map<String, List<Function>> eventListeners = {};

  // Sounds
  final Map<String, Function> sounds = {};

  Sprite({required this.name, this.isStage = false}) {
    blocks = Blocks(this); // initialize Blocks with this sprite runtime
  }

  // ------------------ Event system ------------------
  void onEvent(String eventName, Function callback) {
    eventListeners[eventName] ??= [];
    eventListeners[eventName]!.add(callback);
  }

  void triggerEvent(String eventName, [dynamic arg1, dynamic arg2]) {
    if (eventListeners[eventName] != null) {
      for (var cb in eventListeners[eventName]!) {
        cb(arg1, arg2);
      }
    }
  }

  // ------------------ Costume / visual ------------------
  void setCostume(int index) {
    if (costumes.isEmpty) return;
    currentCostume = index.clamp(0, costumes.length - 1);
  }

  void nextCostume() {
    if (costumes.isEmpty) return;
    currentCostume = (currentCostume + 1) % costumes.length;
  }

  void setPosition(double newX, double newY) {
    x = newX;
    y = newY;
  }

  void setDirection(double newDir) {
    direction = newDir;
  }

  void setSize(double newSize) {
    size = newSize;
  }

  void setVisible(bool value) {
    visible = value;
  }

  void setDraggable(bool value) {
    draggable = value;
  }

  void setEffect(String effectName, double value) {
    if (effects.containsKey(effectName)) effects[effectName] = value;
  }

  void clearEffects() {
    effects.updateAll((key, value) => 0.0);
  }

  // ------------------ Sounds ------------------
  void addSound(String soundName, Function playSound) {
    sounds[soundName] = playSound;
  }

  void playSound(String soundName) {
    sounds[soundName]?.call();
  }

  // ------------------ Existing methods ------------------
  Sprite? getEditingTarget() => this;
  Sprite getTargetForStage() => this;

  void emitProjectChanged() {
    print('Project changed on sprite: $name');
  }

  void emitBlockDragUpdate(bool isOutside) {}
  void emitBlockEndDrag(List<dynamic> newBlocks, String? blockId) {}

  void toggleScript(String? blockId, Map<String, dynamic> options) {
    print('Toggle script called for block: $blockId');
  }

  void quietGlow(String? blockId) {}

  dynamic lookupVariableById(String varId) => variables[varId];
  void createVariable(String varId, String name, String type, bool isCloud) {
    variables[varId] = {'name': name, 'type': type, 'isCloud': isCloud};
  }

  void renameVariable(String varId, String newName) {
    if (variables.containsKey(varId)) variables[varId]['name'] = newName;
  }

  void deleteVariable(String varId) => variables.remove(varId);

  void createComment(String commentId, String blockId, String text, double x,
      double y, double width, double height, bool minimized) {
    comments[commentId] = {
      'blockId': blockId,
      'text': text,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'minimized': minimized,
    };
  }

  void deleteComment(String commentId) => comments.remove(commentId);

  void changeComment(String commentId, Map<String, dynamic> changes) {
    if (comments.containsKey(commentId)) comments[commentId].addAll(changes);
  }

  void moveComment(String commentId, double x, double y) {
    if (comments.containsKey(commentId)) {
      comments[commentId]['x'] = x;
      comments[commentId]['y'] = y;
    }
  }

  void startScripts(List<String> topBlockIds) {
    for (var blockId in topBlockIds) {
      print('Starting script: $blockId on sprite: $name');
    }
  }

  void blocklyListen(Map<String, dynamic> e) {
    blocks.blocklyListen(e);
  }

  void updateVariableValue(String varId, dynamic value) {
    if (variables.containsKey(varId)) variables[varId]['value'] = value;
  }

  dynamic lookupListById(String listId) => lists[listId];
  void createList(String listId, String name) {
    lists[listId] = {'name': name, 'items': []};
  }

  void deleteList(String listId) => lists.remove(listId);

  void addListItem(String listId, dynamic item) {
    if (lists.containsKey(listId)) lists[listId]['items'].add(item);
  }

  void deleteListItem(String listId, int index) {
    if (lists.containsKey(listId)) {
      if (index >= 0 && index < lists[listId]['items'].length) {
        lists[listId]['items'].removeAt(index);
      }
    }
  }

  void updateListItem(String listId, int index, dynamic value) {
    if (lists.containsKey(listId)) {
      if (index >= 0 && index < lists[listId]['items'].length) {
        lists[listId]['items'][index] = value;
      }
    }
  }

  // ------------------ Rotation constants ------------------
  static const String ROTATION_STYLE_ALL_AROUND = 'all around';
  static const String ROTATION_STYLE_LEFT_RIGHT = 'left-right';
  static const String ROTATION_STYLE_NONE = "don't rotate";
}
