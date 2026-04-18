class VariableRef {
  dynamic referencingField;

  VariableRef(this.referencingField);
}

class VariableUtil {
  /// Merge two variable reference maps
  static Map<String, List<dynamic>> _mergeVarRefObjects(
      Map<String, List<dynamic>> accum, Map<String, List<dynamic>> obj2) {
    obj2.forEach((id, value) {
      if (accum.containsKey(id)) {
        accum[id] = [...accum[id]!, ...value];
      } else {
        accum[id] = value;
      }
    });
    return accum;
  }

  /// Get all variable/list references in the given list of targets
  /// [targets]: list of targets in the project
  /// [shouldIncludeBroadcast]: whether to include broadcast message fields
  static Map<String, List<dynamic>> getAllVarRefsForTargets(
      List<dynamic> targets, bool shouldIncludeBroadcast) {
    return targets
        .map((t) => t.blocks.getAllVariableAndListReferences(
            null, shouldIncludeBroadcast) as Map<String, List<dynamic>>)
        .fold<Map<String, List<dynamic>>>(
            {}, (accum, obj) => _mergeVarRefObjects(accum, obj));
  }

  /// Update variable references with a new ID and optionally a new name
  /// [referencesToUpdate]: list of references to update
  /// [newId]: new variable ID
  /// [optNewName]: optional new variable name
  static void updateVariableIdentifiers(
      List<VariableRef> referencesToUpdate, String newId,
      [String? optNewName]) {
    for (var ref in referencesToUpdate) {
      ref.referencingField.id = newId;
      if (optNewName != null && optNewName.isNotEmpty) {
        ref.referencingField.value = optNewName;
      }
    }
  }
}
