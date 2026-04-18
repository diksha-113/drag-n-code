// lib/vm/engine/mouse.dart

import '../engine/blocks.dart';
import '../engine/variable.dart';
import '../engine/comment.dart'
    as comment_lib; // alias to avoid generateUid conflict
import '../util/uid.dart' as uid_lib; // alias for generateUid
import '../util/string_util.dart';
import '../util/variable_util.dart';

class Target {
  final String id;
  final Blocks blocks;
  final Map<String, Variable> variables = {};
  final Map<String, comment_lib.Comment> comments = {}; // use alias
  final Map<String, dynamic> _customState = {};
  final Map<String, dynamic> _edgeActivatedHatValues = {};

  final dynamic runtime; // Replace with your Runtime type when available

  // Mouse interaction fields
  int drawableID = -1; // Initialized to -1 (no drawable)
  bool draggable = false; // Determines click hat behavior

  Target(this.runtime, Blocks? blocksInstance)
      : blocks = blocksInstance ?? Blocks(runtime),
        id = uid_lib.generateUid(); // Use aliased generateUid

  // -------------------- Abstract / Overridable Methods --------------------
  void onGreenFlag() {}
  void postSpriteInfo() {}
  void dispose() {
    _customState.clear();
    runtime?.removeExecutable(this);
  }

  String getName() => id;

  // -------------------- Edge Activated Hats --------------------
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

  // -------------------- Other Helpers --------------------
  bool get isStage => false; // Override in Stage subclass if needed
}
