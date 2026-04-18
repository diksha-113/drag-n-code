import 'dart:math';

class MathUtil {
  static final _random = Random();

  /// Convert degrees → radians
  static double degToRad(double deg) => deg * pi / 180;

  /// Convert radians → degrees
  static double radToDeg(double rad) => rad * 180 / pi;

  /// Clamp a number between min and max
  static double clamp(double n, double min, double max) => n.clamp(min, max);

  /// ---------------- Scratch-like Wrap / Clamp ----------------

  /// Wrap a number between min and max (double)
  static double wrapClampDouble(double n, double min, double max) {
    if (min > max) throw ArgumentError('min should be <= max');
    final range = max - min;
    while (n < min) n += range;
    while (n > max) n -= range;
    return n;
  }

  /// Wrap a number between min and max (int)
  static int wrapClampInt(int n, int min, int max) {
    if (min > max) throw ArgumentError('min should be <= max');
    final range = (max - min) + 1;
    return n - ((n - min) ~/ range) * range;
  }

  /// Unified Scratch-like wrapClamp
  /// Returns int if all inputs are int
  static int wrapClamp(num n, num min, num max) {
    if (n is int && min is int && max is int) {
      return wrapClampInt(n, min, max);
    } else {
      return wrapClampDouble(n.toDouble(), min.toDouble(), max.toDouble())
          .toInt();
    }
  }

  /// ---------------- Scratch-like Random ----------------

  /// Random integer in [lower, upper] excluding `excluded`
  static int inclusiveRandIntWithout(int lower, int upper, int excluded) {
    if (lower > upper) throw ArgumentError('lower must be <= upper');
    if (excluded < lower || excluded > upper)
      return lower + _random.nextInt(upper - lower + 1);
    final possibleOptions = upper - lower;
    int randInt = lower + _random.nextInt(possibleOptions);
    if (randInt >= excluded) randInt += 1;
    return randInt;
  }

  /// Returns a random double between 0.0 (inclusive) and 1.0 (exclusive)
  static double random() => _random.nextDouble();

  /// Scratch-like random integer between low and high inclusive
  static int randomInt(int low, int high) {
    if (low > high) {
      final temp = low;
      low = high;
      high = temp;
    }
    return low + _random.nextInt(high - low + 1);
  }

  /// Scratch-like random double between low (inclusive) and high (exclusive)
  static double randomDouble(double low, double high) {
    if (low > high) {
      final temp = low;
      low = high;
      high = temp;
    }
    return _random.nextDouble() * (high - low) + low;
  }

  /// Scale a number from one range to another
  static double scale(
      double i, double iMin, double iMax, double oMin, double oMax) {
    if (iMax == iMin) throw ArgumentError('Input range cannot be zero');
    final p = (i - iMin) / (iMax - iMin);
    return (p * (oMax - oMin)) + oMin;
  }

  /// ---------------- Scratch-like Trigonometry ----------------

  static double sinDeg(double deg) => sin(degToRad(deg));
  static double cosDeg(double deg) => cos(degToRad(deg));
  static double tan(double deg) => tanDeg(deg);
  static double tanDeg(double angle) {
    angle = angle % 360;
    switch (angle.toInt()) {
      case -270:
      case 90:
        return double.infinity;
      case -90:
      case 270:
        return double.negativeInfinity;
      default:
        return double.parse(tan(degToRad(angle)).toStringAsFixed(10));
    }
  }

  static double asinDeg(double x) => radToDeg(asin(x));
  static double acosDeg(double x) => radToDeg(acos(x));
  static double atanDeg(double x) => radToDeg(atan(x));

  /// ---------------- Scratch-like Log / Exp ----------------

  static double ln(double x) => log(x);
  static double log10(double x) => log(x) / ln(10);
  static double exp(double x) => pow(e, x).toDouble();
  static double pow10(double x) => pow(10, x).toDouble();

  /// ---------------- Reduced sort ordering ----------------

  static List<int> reducedSortOrdering(List<double> elts) {
    final sorted = List<double>.from(elts)..sort();
    return elts.map((e) => sorted.indexOf(e)).toList();
  }
}
