/*import 'workspace.dart';
import 'utils.dart';

/// Event manager stub (replace with proper logger in production)
class EventManager {
  static bool currentGroup = false;

  static void setGroup(bool value) {
    currentGroup = value;
  }

  static void fire(dynamic event) {
    // Production: use logging framework instead of print
  }
}

/// Variable creation event
class VarCreateEvent {
  final VariableModel variable;
  VarCreateEvent(this.variable);

  @override
  String toString() => 'VarCreateEvent(${variable.name})';
}

/// Variable rename event
class VarRenameEvent {
  final VariableModel variable;
  final String? newName;
  VarRenameEvent(this.variable, [this.newName]);

  @override
  String toString() =>
      'VarRenameEvent(${variable.name}${newName != null ? " → $newName" : ""})';
}

/// Model for a variable
class VariableModel {
  /// LowerCamelCase constant for type
  static const String nameType = 'VARIABLE';

  final Workspace workspace;

  /// Name of the variable
  String name;

  /// Type of variable (optional)
  final String type;

  /// Unique ID of the variable
  final String id;

  /// Whether the variable is local
  final bool isLocal;

  /// Whether the variable is a cloud variable
  final bool isCloud;

  VariableModel(
    this.workspace,
    this.name, {
    String? type,
    String? id,
    bool? isLocal,
    bool? isCloud,
  })  : type = type ?? '',
        id = id ?? BlocklyUtils.genUid(),
        isLocal = isLocal ?? false,
        isCloud = isCloud ?? false {
    EventManager.fire(VarCreateEvent(this));
  }

  /// Get the variable's ID
  String getId() => id;

  /// Compare two variables by name
  static int compareByName(VariableModel var1, VariableModel var2) {
    return ScratchBlocksUtils.compareStrings(var1.name, var2.name);
  }

  /// Rename the variable
  void rename(String newName) {
    name = newName;
    EventManager.fire(VarRenameEvent(this, newName));
  }
}

/// Utility functions (like Blockly.scratchBlocksUtils)
class ScratchBlocksUtils {
  /// Compare two strings lexicographically
  static int compareStrings(String a, String b) => a.compareTo(b);
}*/
