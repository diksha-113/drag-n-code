/*// lib/models/variables.dart
import 'variable_model.dart';
import 'workspace.dart';
import 'utils.dart';
import '../core/block.dart'; // Make sure Block is imported

class Variables {
  /// Prefix for cloud variables
  static const String cloudPrefix = '☁ ';

  /// Return text to display when no variable is selected
  static String noVariableText() => "No variable selected";

  /// Get all user-created variables in a workspace or block
  static List<String> allUsedVariables(dynamic root) {
    List<Block> blocks;
    if (root is Block) {
      blocks = root.getDescendants(false);
    } else if (root is Workspace) {
      blocks = root.getAllBlocks();
    } else {
      throw Exception('Not Block or Workspace: $root');
    }

    final ignorableName = noVariableText().toLowerCase();
    final variableHash = <String, String>{};

    for (var block in blocks) {
      var blockVars = block.getVarModels();
      if (blockVars != null) {
        for (var variable in blockVars) {
          if (variable.getId().isNotEmpty &&
              variable.name.toLowerCase() != ignorableName) {
            variableHash[variable.name.toLowerCase()] = variable.name;
          }
        }
      }
    }

    return variableHash.values.toList();
  }

  /// Get all variables in a workspace
  static List<VariableModel> allVariables(Workspace workspace) {
    return workspace.variableMap.getAllVariables();
  }

  /// Get all developer variables
  static List<String> allDeveloperVariables(Workspace workspace) {
    final blocks = workspace.getAllBlocks();
    final hash = <String, String>{};

    for (var block in blocks) {
      final devVars = block.getDeveloperVars();
      if (devVars != null) {
        for (var v in devVars) {
          hash[v] = v;
        }
      }
    }

    return hash.values.toList();
  }

  /// Generate a unique variable name for the workspace
  static String generateUniqueName(Workspace workspace) {
    final variableList = workspace.variableMap.getAllVariables();
    if (variableList.isEmpty) return 'i';

    const letters = 'ijkmnopqrstuvwxyzabcdefgh'; // No 'l'
    var letterIndex = 0;
    var nameSuffix = 1;
    var newName = '';

    while (newName.isEmpty) {
      var potName = letters[letterIndex];
      if (nameSuffix > 1) potName += nameSuffix.toString();

      final inUse = variableList.any((v) => v.name.toLowerCase() == potName);
      if (!inUse) {
        newName = potName;
      } else {
        letterIndex++;
        if (letterIndex == letters.length) {
          letterIndex = 0;
          nameSuffix++;
        }
      }
    }

    return newName;
  }

  /// Trim leading/trailing whitespace
  static String trimName(String name) => name.trim();

  /// Get or create variable in workspace
  static VariableModel getOrCreateVariable(Workspace workspace,
      {String? id, String? name, String? type}) {
    var variable = getVariable(workspace, id: id, name: name, type: type);
    if (variable == null) {
      variable = createVariable(workspace, id: id, name: name, type: type);
    }
    return variable;
  }

  /// Lookup variable by ID or name + type
  static VariableModel? getVariable(Workspace workspace,
      {String? id, String? name, String? type}) {
    final potentialMap = workspace.getPotentialVariableMap();

    VariableModel? variable;
    if (id != null) {
      variable = workspace.variableMap.getVariableById(id) ??
          potentialMap?.getVariableById(id);
    } else if (name != null) {
      if (type == null)
        throw Exception('Must provide type when looking up by name');
      variable = workspace.variableMap.getVariable(name, type) ??
          potentialMap?.getVariable(name, type);
    }

    return variable;
  }

  /// Create variable in workspace
  static VariableModel createVariable(Workspace workspace,
      {String? id, String? name, String? type}) {
    final potentialMap = workspace.getPotentialVariableMap();
    var variableName = name ?? generateUniqueName(workspace);

    VariableModel variable;
    if (potentialMap != null) {
      variable = potentialMap.createVariable(
        variableName,
        type: type ?? '',
        id: id,
      );
    } else {
      variable = workspace.variableMap.createVariable(
        variableName,
        type: type ?? '',
        id: id,
      );
    }
    return variable;
  }

  /// Get variables added to workspace after creating a block
  static List<VariableModel> getAddedVariables(
      Workspace workspace, List<VariableModel> originalVariables) {
    final allCurrent = workspace.variableMap.getAllVariables();
    return allCurrent.where((v) => !originalVariables.contains(v)).toList();
  }
}
*/
