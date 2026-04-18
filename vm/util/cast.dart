// lib/vm/util/cast.dart
import 'dart:math';
import 'color.dart';

class Cast {
  /// Scratch cast to number.
  /// Treats NaN as 0.
  static double toNumber(dynamic value) {
    if (value is num) {
      return value.isNaN ? 0 : value.toDouble();
    }

    if (value == null) return 0;
    final n = double.tryParse(value.toString());
    return n == null || n.isNaN ? 0 : n;
  }

  /// Scratch cast to int
  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Scratch cast to boolean.
  static bool toBoolean(dynamic value) {
    if (value is bool) return value;

    if (value is String) {
      final s = value.toLowerCase();
      if (s.isEmpty || s == '0' || s == 'false') return false;
      return true;
    }

    if (value is num) return value != 0;

    return value != null;
  }

  /// Scratch cast to string.
  /// Replaces the erroneous Cast.toString calls.
  static String toStringValue(dynamic value) {
    return value?.toString() ?? '';
  }

  /// Convert to [r, g, b]
  static List<int> toRgbColorList(dynamic value) {
    final c = toRgbColorObject(value);
    return [c.r, c.g, c.b];
  }

  /// Convert to RGB object
  static RGB toRgbColorObject(dynamic value) {
    if (value is String && value.startsWith('#')) {
      return ColorUtil.hexToRgb(value);
    }

    // Convert numeric value to RGB
    final dec = toNumber(value).round();
    return ColorUtil.decimalToRgb(dec);
  }

  /// Is whitespace / empty / null
  static bool isWhiteSpace(dynamic val) {
    return val == null || (val is String && val.trim().isEmpty);
  }

  /// Scratch compare
  static int compare(dynamic v1, dynamic v2) {
    double? n1 = double.tryParse(v1?.toString() ?? '');
    double? n2 = double.tryParse(v2?.toString() ?? '');

    if ((n1 == 0 && isWhiteSpace(v1)) || (n2 == 0 && isWhiteSpace(v2))) {
      n1 = double.nan;
      n2 = double.nan;
    }

    if (n1!.isNaN || n2!.isNaN) {
      final s1 = v1?.toString().toLowerCase() ?? '';
      final s2 = v2?.toString().toLowerCase() ?? '';
      return s1.compareTo(s2);
    }

    // Handle Infinity
    if ((n1 == double.infinity && n2 == double.infinity) ||
        (n1 == double.negativeInfinity && n2 == double.negativeInfinity)) {
      return 0;
    }

    return n1.compareTo(n2);
  }

  /// Check if looks like integer
  static bool isInt(dynamic val) {
    if (val is num) {
      return val.isNaN || val == val.toInt();
    }

    if (val is bool) return true;

    if (val is String) {
      return !val.contains('.');
    }

    return false;
  }

  /// Constants for list indices
  static const int listInvalid = -1;
  static const int listAll = -2;

  /// Convert Scratch index
  static int toListIndex(dynamic index, int length, bool acceptAll) {
    if (index is String) {
      final s = index.toLowerCase();
      if (acceptAll && s == 'all') return listAll;
      if (s == 'last') return length > 0 ? length : listInvalid;
      if (s == 'random' || s == 'any') {
        return length > 0 ? 1 + Random().nextInt(length) : listInvalid;
      }
    }

    final n = toNumber(index).floor();
    if (n < 1 || n > length) return listInvalid;
    return n;
  }
}
