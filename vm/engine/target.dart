// lib/vm/engine/target.dart

import 'blocks.dart';
import 'variable.dart';
import 'comment.dart' hide generateUid; // hide generateUid from comment.dart
import '../util/uid.dart'; // use generateUid from uid.dart

class Target {
  final String id;
  final Blocks blocks;
  final Map<String, Variable> variables = {};
  final Map<String, Comment> comments = {};
  final Map<String, dynamic> _customState = {};
  final Map<String, dynamic> _edgeActivatedHatValues = {};

  final dynamic runtime; // Replace with your Runtime type when available

  // Fields for movement / display (needed for Scratch-like opcodes)
  double x = 0.0;
  double y = 0.0;
  double direction = 90.0;
  String say = '';
  bool visible = true;

  // Fields needed for mouse interactions
  int? drawableID; // Renderer pick ID
  bool draggable = false; // Determines click hat activation behavior

  // -------------------- Clone support --------------------
  bool isOriginal = true; // mark if this is the original or a clone

  Target(this.runtime, Blocks? blocksInstance)
      : blocks = blocksInstance ?? Blocks(runtime),
        id = generateUid(); // uses uid.dart generateUid

  // -------------------- Lifecycle / Overridable Methods --------------------
  void onGreenFlag() {}
  void postSpriteInfo() {}
  void dispose() {
    _customState.clear();
    runtime?.removeExecutable(this);
  }

  void goBehindOther(Target other) {
    // In a real renderer, you'd adjust the drawable/layer order.
    // Here we just leave a placeholder.
  }

  String getName() => id;

  // -------------------- Edge-Activated Hats --------------------
  dynamic updateEdgeActivatedValue(String blockId, dynamic newValue) {
    final oldValue = _edgeActivatedHatValues[blockId];
    _edgeActivatedHatValues[blockId] = newValue;
    return oldValue;
  }

  bool hasEdgeActivatedValue(String blockId) =>
      _edgeActivatedHatValues.containsKey(blockId);

  void clearEdgeActivatedValues() {
    _edgeActivatedHatValues.clear();
  }

  // -------------------- Variable Lookup / Creation --------------------
  Variable lookupOrCreateVariable(String id, String name) {
    final variable = lookupVariableById(id) ??
        lookupVariableByNameAndType(name, Variable.SCALAR_TYPE);
    if (variable != null) return variable;

    final newVariable = Variable(
      id: id,
      name: name,
      type: Variable.SCALAR_TYPE,
      isCloud: false,
    );
    variables[id] = newVariable;
    return newVariable;
  }

  Variable? lookupVariableById(String id) {
    if (variables.containsKey(id)) return variables[id];
    if (runtime != null && !isStage) {
      final stage = runtime.getTargetForStage();
      if (stage != null && stage.variables.containsKey(id)) {
        return stage.variables[id];
      }
    }
    return null;
  }

  Variable? lookupVariableByNameAndType(String name, String type,
      {bool skipStage = false}) {
    for (final varObj in variables.values) {
      if (varObj.name == name && varObj.type == type) return varObj;
    }
    if (!skipStage && runtime != null && !isStage) {
      final stage = runtime.getTargetForStage();
      if (stage != null) {
        for (final varObj in stage.variables.values) {
          if (varObj.name == name && varObj.type == type) return varObj;
        }
      }
    }
    return null;
  }

  Variable lookupOrCreateList(String id, String name) {
    final listVar = lookupVariableById(id) ??
        lookupVariableByNameAndType(name, Variable.LIST_TYPE);
    if (listVar != null) return listVar;

    final newList = Variable(
      id: id,
      name: name,
      type: Variable.LIST_TYPE,
      isCloud: false,
    );
    variables[id] = newList;
    return newList;
  }

  // -------------------- Custom State --------------------
  dynamic getCustomState(String stateId) => _customState[stateId];

  void setCustomState(String stateId, dynamic newValue) =>
      _customState[stateId] = newValue;

  // -------------------- Clone / Helpers --------------------
  Target? makeClone() {
    final clone = Target(runtime, blocks);

    // Copy basic state
    clone.x = x;
    clone.y = y;
    clone.direction = direction;
    clone.say = say;
    clone.visible = visible;

    // Copy variables
    for (var entry in variables.entries) {
      clone.variables[entry.key] = Variable(
        id: entry.value.id,
        name: entry.value.name,
        type: entry.value.type,
        isCloud: entry.value.isCloud,
        value: entry.value.value,
        list: entry.value.isList,
      );
    }

    clone.isOriginal = false; // mark as clone
    return clone;
  }

  bool get isStage => false; // Override in Stage subclass if needed
}
