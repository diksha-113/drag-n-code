import 'dart:convert';

class StringUtil {
  /// Removes trailing digits from a string
  static String withoutTrailingDigits(String s) {
    int i = s.length - 1;
    while (i >= 0 && '0123456789'.contains(s[i])) {
      i--;
    }
    return s.substring(0, i + 1);
  }

  /// Returns a unique name not in [existingNames]
  static String unusedName(String name, List<String> existingNames) {
    if (!existingNames.contains(name)) return name;

    name = withoutTrailingDigits(name);
    int i = 2;
    while (existingNames.contains('$name$i')) {
      i++;
    }
    return '$name$i';
  }

  /// Splits [text] at the first occurrence of [separator]
  static List<String?> splitFirst(String text, String separator) {
    final index = text.indexOf(separator);
    if (index >= 0) {
      return [
        text.substring(0, index),
        text.substring(index + separator.length)
      ];
    }
    return [text, null];
  }

  /// Converts [obj] to JSON string safely
  static String stringify(dynamic obj) {
    return jsonEncode(obj, toEncodable: (value) {
      if (value is num && (value.isInfinite || value.isNaN)) return 0;
      return value;
    });
  }

  /// Replaces unsafe HTML/XML characters with their entity equivalents
  static String replaceUnsafeChars(dynamic unsafe) {
    String input;

    if (unsafe is String) {
      input = unsafe;
    } else if (unsafe is List) {
      input = unsafe.join(',');
    } else {
      input = unsafe.toString();
    }

    const escapeMap = {
      '<': '&lt;',
      '>': '&gt;',
      '&': '&amp;',
      "'": '&apos;',
      '"': '&quot;',
    };

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      buffer.write(escapeMap[char] ?? char);
    }

    return buffer.toString();
  }
}
