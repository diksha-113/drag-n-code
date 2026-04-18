// lib/blocks_vertical/procedures.dart
//
// Direct Dart conversion of Scratch3ProcedureBlocks (procedures.js)
// Logic preserved exactly without modification.

class Scratch3ProcedureBlocks {
  final dynamic runtime;

  Scratch3ProcedureBlocks(this.runtime);

  /// Returns mapping of opcode → handler function
  Map<String, Function> getPrimitives() {
    return {
      'procedures_definition': definition,
      'procedures_call': call,
      'argument_reporter_string_number': argumentReporterStringNumber,
      'argument_reporter_boolean': argumentReporterBoolean,
    };
  }

  /// No-op: execute the blocks inside the custom block definition
  dynamic definition(Map<String, dynamic> args, dynamic util) {
    // Scratch VM does nothing here.
    return null;
  }

  /// Call a custom block
  dynamic call(Map<String, dynamic> args, dynamic util) {
    // First time entering this procedure?
    if (util.stackFrame['executed'] != true) {
      final mutation = args['mutation'];
      if (mutation == null) return;

      final String procedureCode = mutation['proccode'];
      final paramInfo =
          util.getProcedureParamNamesIdsAndDefaults(procedureCode);

      // Not found (e.g., moved between sprites)
      if (paramInfo == null) return;

      final List<dynamic> paramNames = paramInfo[0];
      final List<dynamic> paramIds = paramInfo[1];
      final List<dynamic> paramDefaults = paramInfo[2];

      // Always initialize params map for this call
      util.initParams();

      // Push parameter values
      for (int i = 0; i < paramIds.length; i++) {
        final String id = paramIds[i];
        if (args.containsKey(id)) {
          util.pushParam(paramNames[i], args[id]);
        } else {
          util.pushParam(paramNames[i], paramDefaults[i]);
        }
      }

      util.stackFrame['executed'] = true;

      // Begin executing the custom block body
      util.startProcedure(procedureCode);
    }

    return null;
  }

  /// Reporter block for string/number arguments
  dynamic argumentReporterStringNumber(
      Map<String, dynamic> args, dynamic util) {
    final value = util.getParam(args['VALUE']);
    if (value == null) {
      // Scratch default for missing parameter
      return 0;
    }
    return value;
  }

  /// Reporter block for boolean arguments
  dynamic argumentReporterBoolean(Map<String, dynamic> args, dynamic util) {
    final value = util.getParam(args['VALUE']);
    if (value == null) {
      // Scratch default for missing parameter
      return 0;
    }
    return value;
  }
}
