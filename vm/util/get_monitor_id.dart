/// Returns a unique ID string for a monitored block.
/// Handles dynamic/nested field values.
///
/// [id] is the base ID for different monitor blocks.
/// [fields] is a map representing the block's fields, where
/// each value is expected to have a `value` property.
String getMonitorIdForBlockWithArgs(String id, Map<String, dynamic> fields) {
  String fieldString = '';

  fields.forEach((fieldKey, fieldObj) {
    dynamic fieldValue = fieldObj['value'] ?? ''; // Simplified null handling

    // Normalize CURRENTMENU to lowercase if it's a string
    if (fieldKey == 'CURRENTMENU' && fieldValue is String) {
      fieldValue = fieldValue.toLowerCase();
    }

    // Convert any other types to string
    fieldString += '_${fieldValue.toString()}';
  });

  return '$id$fieldString';
}
