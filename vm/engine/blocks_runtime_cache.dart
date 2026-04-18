// lib/vm/engine/blocks_runtime_cache.dart

/// A set of cached data about the top block of scripts so that the runtime can
/// iterate a targeted opcode more quickly. Strings are uppercased during cache.
class RuntimeScriptCache {
  /// Container holding block + field/input data.
  final dynamic container;

  /// ID of the block this instance caches.
  final String blockId;

  /// Cached fields (and fields inside input blocks) in uppercased form.
  final Map<String, dynamic> fieldsOfInputs = {};

  RuntimeScriptCache(this.container, this.blockId) {
    final block = container.getBlock(blockId);
    final fields = container.getFields(block);

    // Clone the fields
    fieldsOfInputs.addAll(fields.map((key, value) {
      return MapEntry(key, Map.from(value));
    }));

    // If no direct fields, check input block fields instead
    if (fields.isEmpty) {
      final inputs = container.getInputs(block);
      inputs.forEach((input, inputInfo) {
        final id = inputInfo["block"];
        final inputBlock = container.getBlock(id);
        final inputFields = container.getFields(inputBlock);
        fieldsOfInputs.addAll(inputFields.map((key, value) {
          return MapEntry(key, Map.from(value));
        }));
      });
    }

    // Uppercase every field value that is a string
    fieldsOfInputs.forEach((key, field) {
      if (field["value"] is String) {
        field["value"] = (field["value"] as String).toUpperCase();
      }
    });
  }
}

// ---------------------------------------------------------------------------
// THROW-UNTIL-INITIALIZED BEHAVIOR (Scratch VM uses export override)
// ---------------------------------------------------------------------------

typedef GetScriptsFunc = List<dynamic> Function(
    dynamic container, String opcode);

/// Placeholder until Blocks initializes this module.
List<dynamic> _defaultGetScripts(dynamic container, String opcode) {
  throw Exception("blocks.dart has not initialized BlocksRuntimeCache");
}

/// Function reference that blocks.dart will replace.
GetScriptsFunc getScripts = _defaultGetScripts;

/// Called by blocks.dart to initialize `getScripts`.
void setGetScripts(GetScriptsFunc func) {
  getScripts = func;
}
