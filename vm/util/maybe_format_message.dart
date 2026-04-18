/// Placeholder for formatMessage function.
/// Replace this with a proper i18n formatter if needed.
String formatMessage(Map<String, dynamic> message,
    [Map<String, dynamic>? args, String? locale]) {
  // Simple implementation: return default message
  return message['default'] ?? '';
}

/// Check if `maybeMessage` looks like a message object, and if so pass it
/// to `formatMessage`. Otherwise, return `maybeMessage` as-is.
dynamic maybeFormatMessage(dynamic maybeMessage,
    [Map<String, dynamic>? args, String? locale]) {
  if (maybeMessage is Map<String, dynamic> &&
      maybeMessage.containsKey('id') &&
      maybeMessage.containsKey('default')) {
    // Safe to pass directly, no cast needed
    return formatMessage(maybeMessage, args, locale);
  }
  return maybeMessage;
}
