import 'dart:math';

/// Blockly constants placeholder (equivalent to Blockly.constants)
class ColourConstants {
  static const outputShapeRound = 'round';
}

/// Pick a random colour.
/// @return {string} #RRGGBB for random colour.
String randomColour() {
  final num = Random().nextInt(pow(2, 24).toInt());
  return '#${num.toRadixString(16).padLeft(6, '0')}';
}

/// Unique Colour Block class (renamed to avoid BlocklyBlock conflict)
class ColourBlock {
  late Map<String, dynamic> json;

  /// Dart version of init()
  void init() {
    json = {
      "message0": "%1",
      "args0": [
        {
          "type": "field_colour_slider",
          "name": "COLOUR",
          "colour": randomColour(),
        }
      ],
      "outputShape": ColourConstants.outputShapeRound,
      "output": "Colour",
    };
  }

  /// Constructor auto-calls init()
  ColourBlock() {
    init();
  }
}
