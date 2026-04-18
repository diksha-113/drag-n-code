/*// lib/events/variable_event.dart
import 'variable_model.dart';
import 'workspace.dart';

/// Minimal stub for AbstractEvent
abstract class AbstractEvent {
  String get type;

  Map<String, dynamic> toJson() => {};
  void fromJson(Map<String, dynamic> json) {}
  void run(bool forward, Map<String, Workspace> workspaceMap) {}
}

/// Base class for variable events.
abstract class VarBaseEvent extends AbstractEvent {
  String varId;
  String workspaceId;

  VarBaseEvent(VariableModel variable)
      : varId = variable.id,
        workspaceId = variable.workspace.id;

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['varId'] = varId;
    json['workspaceId'] = workspaceId;
    return json;
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    varId = json['varId'];
    workspaceId = json['workspaceId'];
  }

  Workspace getEventWorkspace(Map<String, Workspace> workspaceMap) {
    return workspaceMap[workspaceId]!;
  }
}

/// Event for variable creation.
class VarCreateEvent extends VarBaseEvent {
  String varType;
  String varName;
  bool isLocal;
  bool isCloud;

  VarCreateEvent(VariableModel variable)
      : varType = variable.type,
        varName = variable.name,
        isLocal = variable.isLocal,
        isCloud = variable.isCloud,
        super(variable);

  @override
  String get type => 'VAR_CREATE';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'varType': varType,
      'varName': varName,
      'isLocal': isLocal,
      'isCloud': isCloud,
    });
    return json;
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    super.fromJson(json);
    varType = json['varType'];
    varName = json['varName'];
    isLocal = json['isLocal'];
    isCloud = json['isCloud'];
  }

  @override
  void run(bool forward, Map<String, Workspace> workspaceMap) {
    final workspace = getEventWorkspace(workspaceMap);
    if (forward) {
      // Create variable in workspace using the existing VariableMap
      workspace.variableMap.createVariable(varName,
          type: varType, id: varId, isLocal: isLocal, isCloud: isCloud);
    } else {
      workspace.variableMap.deleteVariableById(varId);
    }
  }
}

/// Event for variable deletion.
class VarDeleteEvent extends VarBaseEvent {
  String varType;
  String varName;
  bool isLocal;
  bool isCloud;

  VarDeleteEvent(VariableModel variable)
      : varType = variable.type,
        varName = variable.name,
        isLocal = variable.isLocal,
        isCloud = variable.isCloud,
        super(variable);

  @override
  String get type => 'VAR_DELETE';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'varType': varType,
      'varName': varName,
      'isLocal': isLocal,
      'isCloud': isCloud,
    });
    return json;
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    super.fromJson(json);
    varType = json['varType'];
    varName = json['varName'];
    isLocal = json['isLocal'];
    isCloud = json['isCloud'];
  }

  @override
  void run(bool forward, Map<String, Workspace> workspaceMap) {
    final workspace = getEventWorkspace(workspaceMap);
    if (forward) {
      workspace.variableMap.deleteVariableById(varId);
    } else {
      workspace.variableMap.createVariable(varName,
          type: varType, id: varId, isLocal: isLocal, isCloud: isCloud);
    }
  }
}

/// Event for variable renaming.
class VarRenameEvent extends VarBaseEvent {
  String oldName;
  String newName;

  VarRenameEvent(VariableModel variable, this.newName)
      : oldName = variable.name,
        super(variable);

  @override
  String get type => 'VAR_RENAME';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['oldName'] = oldName;
    json['newName'] = newName;
    return json;
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    super.fromJson(json);
    oldName = json['oldName'];
    newName = json['newName'];
  }

  @override
  void run(bool forward, Map<String, Workspace> workspaceMap) {
    final workspace = getEventWorkspace(workspaceMap);
    if (forward) {
      workspace.variableMap.renameVariableById(varId, newName);
    } else {
      workspace.variableMap.renameVariableById(varId, oldName);
    }
  }
}
*/
