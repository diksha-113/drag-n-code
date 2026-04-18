/*// lib/core/variable_map.dart
import 'variable_events.dart';
import 'variable_model.dart';
import 'workspace.dart';
import 'block.dart'; // main Block class
import 'block_svg.dart' as svg; // prefixed import to avoid collision

/// Stub for BlocklyUtils.genUid
class BlocklyUtils {
  static String genUid() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}

/// Stub EventManager
class EventManager {
  static bool currentGroup = false;

  static void setGroup(bool value) {
    currentGroup = value;
  }

  static void fire(dynamic event) {
    print("Event fired: $event");
  }
}

/// -------------------- MAIN VARIABLE MAP --------------------
class VariableMap {
  final Workspace? workspace;
  Workspace? owner;

  final Map<String, List<VariableModel>> _variableMap = {};

  VariableMap(this.workspace);

  void clear() => _variableMap.clear();

  /// Create or return an existing variable.
  VariableModel createVariable(
    String name, {
    String? type,
    String? id,
    bool? isLocal,
    bool? isCloud,
  }) {
    type ??= '';
    var variable = getVariable(name, type);
    if (variable != null) {
      if (id != null && variable.id != id) {
        print(
            'Warning: Variable "$name" exists with id ${variable.id}, conflicts with $id.');
      }
      return variable;
    }

    if (id != null) {
      variable = getVariableById(id);
      if (variable != null) {
        print('Warning: Variable id "$id" is already in use.');
        return variable;
      }
    }

    id ??= BlocklyUtils.genUid();
    variable = VariableModel(workspace!, name,
        type: type, id: id, isLocal: isLocal, isCloud: isCloud);

    _variableMap.putIfAbsent(type, () => []).add(variable);
    return variable;
  }

  void deleteVariable(VariableModel variable) {
    final list = _variableMap[variable.type];
    if (list == null) return;
    list.removeWhere((v) => v.id == variable.id);
    EventManager.fire(VarDeleteEvent(variable));
  }

  void deleteVariableById(String id) {
    final variable = getVariableById(id);
    if (variable == null) {
      print("Can't delete non-existent variable: $id");
      return;
    }
    final uses = getVariableUsesById(id);
    deleteVariableInternal(variable, uses);
  }

  void deleteVariableInternal(VariableModel variable, List<Block> uses) {
    final existingGroup = EventManager.currentGroup;
    if (!existingGroup) EventManager.setGroup(true);

    try {
      for (var block in uses) {
        block.dispose();
      }
      deleteVariable(variable);
    } finally {
      if (!existingGroup) EventManager.setGroup(false);
    }
  }

  VariableModel? getVariable(String name, [String? type]) {
    type ??= '';
    final list = _variableMap[type];
    if (list == null) return null;
    try {
      return list.firstWhere((v) => v.name == name);
    } catch (e) {
      return null;
    }
  }

  VariableModel? getVariableById(String id) {
    for (var list in _variableMap.values) {
      for (var v in list) {
        if (v.id == id) return v;
      }
    }
    return null;
  }

  List<VariableModel> getVariablesOfType([String? type]) {
    type ??= '';
    return _variableMap[type]?.toList() ?? [];
  }

  List<String> getVariableTypes() {
    final types = _variableMap.keys.toList();
    if (!types.contains('')) types.add('');
    return types;
  }

  List<VariableModel> getAllVariables() =>
      _variableMap.values.expand((e) => e).toList();

  /// Returns blocks using a variable id
  List<Block> getVariableUsesById(String id) {
    final uses = <Block>[];
    final blocks = workspace?.getAllBlocks(false) ?? [];

    for (var block in blocks) {
      if (block is svg.BlockSvg) {
        final blockVars = block.getVarModels();
        if (blockVars != null) {
          for (var v in blockVars) {
            if (v.id == id) uses.add(block);
          }
        }
      } else if (block is Block) {
        final blockVars = block.getVariables();
        if (blockVars != null) {
          for (var v in blockVars) {
            if (v.id == id) uses.add(block);
          }
        }
      }
    }
    return uses;
  }

  void renameVariable(VariableModel variable, String newName) {
    final type = variable.type;
    final conflictVar = getVariable(newName, type);
    final blocks = workspace?.getAllBlocks(false) ?? [];

    EventManager.setGroup(true);
    try {
      if (conflictVar == null) {
        renameVariableAndUses(variable, newName, blocks);
      } else {
        print('Unexpected conflict when renaming ${variable.name} → $newName.');
      }
    } finally {
      EventManager.setGroup(false);
    }
  }

  void renameVariableById(String id, String newName) {
    final variable = getVariableById(id);
    if (variable == null) {
      throw Exception('Cannot rename non-existent variable: $id');
    }
    renameVariable(variable, newName);
  }

  void renameVariableAndUses(
      VariableModel variable, String newName, List<Block> blocks) {
    variable.rename(newName);

    for (var block in blocks) {
      if (block is svg.BlockSvg || block is Block) {
        block.updateVarName(variable);
      }
    }
  }
}

/// -------------------- Block Extension --------------------
extension BlockVarExtension on Block {
  List<VariableModel>? getVariables() {
    return [];
  }

  void updateVarName(VariableModel variable) {
    // Do nothing; stub
  }
}
*/
