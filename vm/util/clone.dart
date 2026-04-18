import 'dart:convert';

/// Deep cloning utilities similar to Scratch VM's clone.js
class Clone {
  /// Deep clone a JSON-serializable object.
  ///
  /// Works exactly like:
  ///   JSON.parse(JSON.stringify(original))
  ///
  /// Non-JSON values (functions, closures, Symbols, etc.)
  /// will be removed or converted to `null`.
  static dynamic simple(dynamic original) {
    try {
      final jsonString = jsonEncode(original);
      return jsonDecode(jsonString);
    } catch (e) {
      // Return null if object cannot be fully JSON cloned
      return null;
    }
  }
}
