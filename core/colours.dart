// lib/core/colours.dart
import 'package:flutter/material.dart';

class BlocklyColours {
  // Category colours
  static Map<String, Map<String, Color>> categories = {
    "motion": {
      "primary": Color(0xFF4C97FF),
      "secondary": Color(0xFF4280D7),
      "tertiary": Color(0xFF3373CC),
      "quaternary": Color(0xFF3373CC),
    },
    "looks": {
      "primary": Color(0xFF9966FF),
      "secondary": Color(0xFF855CD6),
      "tertiary": Color(0xFF774DCB),
      "quaternary": Color(0xFF774DCB),
    },
    "sounds": {
      "primary": Color(0xFFCF63CF),
      "secondary": Color(0xFFC94FC9),
      "tertiary": Color(0xFFBD42BD),
      "quaternary": Color(0xFFBD42BD),
    },
    "control": {
      "primary": Color(0xFFFFAB19),
      "secondary": Color(0xFFEC9C13),
      "tertiary": Color(0xFFCF8B17),
      "quaternary": Color(0xFFCF8B17),
    },
    "event": {
      "primary": Color(0xFFFFBF00),
      "secondary": Color(0xFFE6AC00),
      "tertiary": Color(0xFFCC9900),
      "quaternary": Color(0xFFCC9900),
    },
    "sensing": {
      "primary": Color(0xFF5CB1D6),
      "secondary": Color(0xFF47A8D1),
      "tertiary": Color(0xFF2E8EB8),
      "quaternary": Color(0xFF2E8EB8),
    },
    "pen": {
      "primary": Color(0xFF0FBD8C),
      "secondary": Color(0xFF0DA57A),
      "tertiary": Color(0xFF0B8E69),
      "quaternary": Color(0xFF0B8E69),
    },
    "operators": {
      "primary": Color(0xFF59C059),
      "secondary": Color(0xFF46B946),
      "tertiary": Color(0xFF389438),
      "quaternary": Color(0xFF389438),
    },
    "data": {
      "primary": Color(0xFFFF8C1A),
      "secondary": Color(0xFFFF8000),
      "tertiary": Color(0xFFDB6E00),
      "quaternary": Color(0xFFDB6E00),
    },
    "data_lists": {
      "primary": Color(0xFFFF661A),
      "secondary": Color(0xFFFF5500),
      "tertiary": Color(0xFFE64D00),
      "quaternary": Color(0xFFE64D00),
    },
    "more": {
      "primary": Color(0xFFFF6680),
      "secondary": Color(0xFFFF4D6A),
      "tertiary": Color(0xFFFF3355),
      "quaternary": Color(0xFFFF3355),
    },
  };

  // UI / Misc colours
  static Color text = Colors.white;
  static Color workspace = Color(0xFFF9F9F9);
  static Color toolboxHover = Color(0xFF4C97FF);
  static Color toolboxSelected = Color(0xFFE9EEF2);
  static Color toolboxText = Color(0xFF575E75);
  static Color toolbox = Colors.white;
  static Color flyout = Color(0xFFF9F9F9);
  static Color scrollbar = Color(0xFFCECDCE);
  static Color scrollbarHover = Color(0xFFCECDCE);
  static Color textField = Colors.white;
  static Color textFieldText = Color(0xFF575E75);
  static Color insertionMarker = Colors.black;
  static double insertionMarkerOpacity = 0.2;
  static double dragShadowOpacity = 0.3;
  static Color stackGlow = Color(0xFFFFF200);
  static double stackGlowSize = 4;
  static double stackGlowOpacity = 1;
  static Color replacementGlow = Colors.white;
  static double replacementGlowSize = 2;
  static double replacementGlowOpacity = 1;
  static Color colourPickerStroke = Colors.white;
  static Color fieldShadow = Color.fromRGBO(0, 0, 0, 0.1);
  static Color dropDownShadow = Color.fromRGBO(0, 0, 0, 0.3);
  static Color numPadBackground = Color(0xFF547AB2);
  static Color numPadBorder = Color(0xFF435F91);
  static Color numPadActiveBackground = Color(0xFF435F91);
  static Color numPadText = Colors.white;
  static Color valueReportBackground = Colors.white;
  static Color valueReportBorder = Color(0xFFAAAAAA);
  static Color menuHover = Color.fromRGBO(0, 0, 0, 0.2);

  /// Override category or UI colours dynamically
  static void overrideColours(Map<String, dynamic> newColours) {
    newColours.forEach((key, value) {
      if (categories.containsKey(key) && value is Map<String, String>) {
        value.forEach((subKey, subValue) {
          if (categories[key]!.containsKey(subKey)) {
            categories[key]![subKey] =
                Color(int.parse(subValue.replaceFirst('#', '0xFF'), radix: 16));
          }
        });
      } else if (value is String) {
        // UI colour override
        switch (key) {
          case 'text':
            text = Color(int.parse(value.replaceFirst('#', '0xFF'), radix: 16));
            break;
          case 'workspace':
            workspace =
                Color(int.parse(value.replaceFirst('#', '0xFF'), radix: 16));
            break;
          // Add more as needed...
        }
      }
    });
  }
}
