/// Placeholder for Text constants
class TextConstants {
  static const outputShapeRound = 'round';
}

/// Placeholder colours for Text blocks
class TextColours {
  static const textField = '#000000'; // replace with project colours
}

/// Base class similar to Blockly.Block (unique name)
abstract class TextBaseBlock {
  late Map<String, dynamic> json;
  Map<String, dynamic> inputs = {};
  List<dynamic>? nextBlocks;
  String? id;

  void jsonInit(Map<String, dynamic> config) {
    json = config;
  }

  void execute() {} // placeholder for execution logic
}

/// ===============================
/// Text block
/// ===============================
class TextBlock extends TextBaseBlock {
  void init() {
    jsonInit({
      "message0": "%1",
      "args0": [
        {
          "type": "field_input",
          "name": "TEXT",
        }
      ],
      "output": "String",
      "outputShape": TextConstants.outputShapeRound,
      "colour": TextColours.textField,
      "colourSecondary": TextColours.textField,
      "colourTertiary": TextColours.textField,
      "colourQuaternary": TextColours.textField,
    });
  }

  TextBlock() {
    init();
  }
}
