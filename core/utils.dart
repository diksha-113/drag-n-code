import 'dart:math' as math;

/// General utility functions similar to Blockly utils
class BlocklyUtils {
  /// Generate a globally unique ID
  static String genUid({int length = 20}) {
    const soup =
        '!#\$%()*+,-./:;=?@[]^_`{|}~ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = math.Random();
    return List.generate(length, (_) => soup[rand.nextInt(soup.length)]).join();
  }

  /// Wrap text to the specified width (simple approximation)
  static String wrap(String text, int limit) {
    final lines = text.split('\n');
    final wrapped = lines.map((line) => _wrapLine(line, limit)).join('\n');
    return wrapped;
  }

  static String _wrapLine(String text, int limit) {
    if (text.length <= limit) return text;
    final words = text.trim().split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    var lineLen = 0;
    for (final word in words) {
      if (lineLen + word.length > limit) {
        buffer.write('\n');
        lineLen = 0;
      } else if (lineLen > 0) {
        buffer.write(' ');
        lineLen += 1;
      }
      buffer.write(word);
      lineLen += word.length;
    }
    return buffer.toString();
  }

  /// Degrees to radians
  static double toRadians(double degrees) => degrees * math.pi / 180;

  /// Simple prefix check
  static bool startsWith(String str, String prefix) => str.startsWith(prefix);

  /// Right-click check placeholder (not needed in Flutter, returns false)
  static bool isRightButton() => false;

  /// Remove a value from a list if present
  static bool removeFromList<T>(List<T> list, T value) {
    return list.remove(value);
  }

  /// Add a value to a list if not already present
  static bool addToList<T>(List<T> list, T value) {
    if (list.contains(value)) return false;
    list.add(value);
    return true;
  }

  /// Insert an element after another in a list
  static void insertAfter<T>(List<T> list, T newElement, T refElement) {
    final index = list.indexOf(refElement);
    if (index == -1) {
      list.add(newElement);
    } else {
      list.insert(index + 1, newElement);
    }
  }

  /// Placeholder for “run after page load”
  static void runAfterPageLoad(void Function() fn) {
    fn();
  }
}

/// Simple wrapper class to match old Utils.generateId() usage
class Utils {
  /// Main unique ID generator used by engine
  static String generateId({int length = 20}) {
    return BlocklyUtils.genUid(length: length);
  }

  /// Alias – some old JS ports call Utils.genUid()
  static String genUid({int length = 20}) {
    return BlocklyUtils.genUid(length: length);
  }

  /// Added: Detect Gecko browser (placeholder, always false in Flutter)
  static bool get isGecko => false;
}

/// Represents a 2D coordinate
class Coordinate {
  double x;
  double y;

  Coordinate(this.x, this.y);

  Coordinate operator +(Coordinate other) =>
      Coordinate(x + other.x, y + other.y);

  Coordinate scale(double factor) => Coordinate(x * factor, y * factor);
}

/// Delete area constants
class DeleteArea {
  static const int none = 0;
  static const int trash = 1;
}
