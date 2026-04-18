import 'log.dart'; // your logging utility

/// Escape a string to be safe for XML content.
String xmlEscape(dynamic unsafe) {
  String input;

  // Convert input to string
  if (unsafe is String) {
    input = unsafe;
  } else if (unsafe is List) {
    input = unsafe.join(',');
  } else {
    Log.error('Unexpected input received in xmlEscape');
    input = unsafe.toString();
  }

  // Map of characters to XML entities
  const Map<String, String> escapeMap = {
    '<': '&lt;',
    '>': '&gt;',
    '&': '&amp;',
    "'": '&apos;',
    '"': '&quot;',
  };

  // Build escaped string manually (safe for nulls)
  final buffer = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    final char = input[i];
    buffer.write(escapeMap[char] ?? char);
  }

  return buffer.toString();
}
