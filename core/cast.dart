class Cast {
  /// Convert any value to boolean
  static bool toBoolean(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true') return true;
      if (lower == 'false' || lower == '') return false;
      final numValue = num.tryParse(value);
      if (numValue != null) return numValue != 0;
    }
    return false;
  }

  /// Convert any value to number (int or double)
  static num toNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  /// Convert any value to string (renamed to avoid conflict)
  static String toStr(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
}
