import 'dart:math';

class RGB {
  final int r;
  final int g;
  final int b;
  final int a;

  const RGB(this.r, this.g, this.b, {this.a = 255});
}

class ColorUtil {
  /// Clamp value between 0–1
  static double _clamp(double v) => v.clamp(0.0, 1.0);

  /// Convert HSV → RGB
  static RGB hsvToRgb(double h, double s, double v) {
    h = h % 360;
    if (h < 0) h += 360;

    s = _clamp(s / 100);
    v = _clamp(v / 100);

    double c = v * s;
    double x = c * (1 - ((h / 60) % 2 - 1).abs());
    double m = v - c;

    double r = 0, g = 0, b = 0;
    int i = h ~/ 60;

    switch (i) {
      case 0:
        r = c;
        g = x;
        b = 0;
        break;
      case 1:
        r = x;
        g = c;
        b = 0;
        break;
      case 2:
        r = 0;
        g = c;
        b = x;
        break;
      case 3:
        r = 0;
        g = x;
        b = c;
        break;
      case 4:
        r = x;
        g = 0;
        b = c;
        break;
      case 5:
        r = c;
        g = 0;
        b = x;
        break;
      default:
        r = c;
        g = x;
        b = 0;
        break;
    }

    return RGB(
      ((r + m) * 255).round(),
      ((g + m) * 255).round(),
      ((b + m) * 255).round(),
      a: 255,
    );
  }

  /// Convert RGB → HSV
  static Map<String, double> rgbToHsv(int r, int g, int b) {
    double rd = r / 255.0;
    double gd = g / 255.0;
    double bd = b / 255.0;

    double maxV = max(rd, max(gd, bd));
    double minV = min(rd, min(gd, bd));
    double delta = maxV - minV;

    double h = 0;
    if (delta == 0) {
      h = 0;
    } else if (maxV == rd) {
      h = 60 * (((gd - bd) / delta) % 6);
    } else if (maxV == gd) {
      h = 60 * (((bd - rd) / delta) + 2);
    } else {
      h = 60 * (((rd - gd) / delta) + 4);
    }

    if (h < 0) h += 360;

    double s = maxV == 0 ? 0 : delta / maxV;

    return {"h": h, "s": s * 100, "v": maxV * 100};
  }

  /// Convert RGB → Hex string
  static String rgbToHex(int r, int g, int b) {
    String toHex(int v) => v.toRadixString(16).padLeft(2, '0');
    return "#${toHex(r)}${toHex(g)}${toHex(b)}";
  }

  /// Convert Hex string → RGB object
  static RGB hexToRgb(String hex) {
    hex = hex.replaceAll("#", "").toUpperCase();

    if (hex.length == 3) {
      hex = "${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}";
    }

    int value = int.parse(hex, radix: 16);

    return RGB(
      (value >> 16) & 255,
      (value >> 8) & 255,
      value & 255,
      a: 255,
    );
  }

  /// Convert Hex → HSV
  static Map<String, double> hexToHsv(String hex) {
    final rgb = hexToRgb(hex);
    return rgbToHsv(rgb.r, rgb.g, rgb.b);
  }

  /// Convert HSV → Hex
  static String hsvToHex(double h, double s, double v) {
    final rgb = hsvToRgb(h, s, v);
    return rgbToHex(rgb.r, rgb.g, rgb.b);
  }

  /// Convert decimal Scratch color → RGB object
  static RGB decimalToRgb(int decimal) {
    final r = (decimal >> 16) & 0xFF;
    final g = (decimal >> 8) & 0xFF;
    final b = decimal & 0xFF;
    return RGB(r, g, b, a: 255);
  }
}
