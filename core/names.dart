/*import 'variable_model.dart'; // Contains VariableModel
import 'workspace.dart'; // Contains VariableMap

class Names {
  final String variablePrefix;
  final Map<String, bool> reservedDict = {};
  final Map<String, String> db = {};
  final Map<String, bool> dbReverse = {};
  VariableMap? variableMap;

  static const String developerVariableType = 'DEVELOPER_VARIABLE';

  Names(String reservedWords, {this.variablePrefix = ''}) {
    if (reservedWords.isNotEmpty) {
      for (var word in reservedWords.split(',')) {
        reservedDict[word] = true;
      }
    }
    reset();
  }

  /// Resets all stored names and variable map
  void reset() {
    db.clear();
    dbReverse.clear();
    variableMap = null;
  }

  /// Set the VariableMap to use
  void setVariableMap(VariableMap map) {
    variableMap = map;
  }

  /// Get the user-visible name for a variable by its ID
  String? getNameForUserVariable(String id) {
    if (variableMap == null) return null;
    var variable = variableMap!.getVariableById(id);
    return variable?.name;
  }

  /// Get a safe name for use in generated code or internal references
  String getName(String name, String type) {
    if (type == VariableModel.nameType) {
      var varName = getNameForUserVariable(name);
      if (varName != null) name = varName;
    }

    var normalized = '${name.toLowerCase()}_$type';
    var isVarType =
        type == VariableModel.nameType || type == developerVariableType;
    var prefix = isVarType ? variablePrefix : '';

    if (db.containsKey(normalized)) return prefix + db[normalized]!;

    var safeName = getDistinctName(name, type);
    db[normalized] = safeName.substring(prefix.length);
    return safeName;
  }

  /// Generate a distinct safe name (avoiding collisions and reserved words)
  String getDistinctName(String name, String type) {
    var safeName = safeName_(name);
    var i = '';

    while (dbReverse.containsKey(safeName + i) ||
        reservedDict.containsKey(safeName + i)) {
      i = i.isEmpty ? '2' : (int.parse(i) + 1).toString();
    }

    safeName += i;
    dbReverse[safeName] = true;

    var isVarType =
        type == VariableModel.nameType || type == developerVariableType;
    var prefix = isVarType ? variablePrefix : '';

    return prefix + safeName;
  }

  /// Sanitize the variable name to remove invalid characters
  String safeName_(String name) {
    if (name.isEmpty) name = 'unnamed';

    name = Uri.encodeComponent(name.replaceAll(' ', '_'))
        .replaceAll(RegExp(r'[^\w]'), '_');

    if (RegExp(r'^[0-9]').hasMatch(name)) name = 'my_$name';

    return name;
  }

  /// Case-insensitive comparison of names
  static bool equals(String name1, String name2) {
    return name1.toLowerCase() == name2.toLowerCase();
  }
}
*/
