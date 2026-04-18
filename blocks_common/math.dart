/// Placeholder for Math constants
class MathConstants {
  static const outputShapeRound = 'round';
}

/// Placeholder colours equivalent to Blockly.Colours
class MathColours {
  static const textField = '#000000'; // Replace with real colours later
}

/// Base class to mimic Blockly.Block behavior (unique name)
abstract class MathBlock {
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
/// math_number
/// ===============================
class MathNumberBlock extends MathBlock {
  void init() {
    jsonInit({
      "message0": "%1",
      "args0": [
        {
          "type": "field_number",
          "name": "NUM",
          "value": "0",
        }
      ],
      "output": "Number",
      "outputShape": MathConstants.outputShapeRound,
      "colour": MathColours.textField,
      "colourSecondary": MathColours.textField,
      "colourTertiary": MathColours.textField,
      "colourQuaternary": MathColours.textField,
    });
  }

  MathNumberBlock() {
    init();
  }
}

/// ===============================
/// math_integer
/// ===============================
class MathIntegerBlock extends MathBlock {
  void init() {
    jsonInit({
      "message0": "%1",
      "args0": [
        {
          "type": "field_number",
          "name": "NUM",
          "precision": 1,
        }
      ],
      "output": "Number",
      "outputShape": MathConstants.outputShapeRound,
      "colour": MathColours.textField,
      "colourSecondary": MathColours.textField,
      "colourTertiary": MathColours.textField,
      "colourQuaternary": MathColours.textField
    });
  }

  MathIntegerBlock() {
    init();
  }
}

/// ===============================
/// math_whole_number
/// ===============================
class MathWholeNumberBlock extends MathBlock {
  void init() {
    jsonInit({
      "message0": "%1",
      "args0": [
        {"type": "field_number", "name": "NUM", "min": 0, "precision": 1}
      ],
      "output": "Number",
      "outputShape": MathConstants.outputShapeRound,
      "colour": MathColours.textField,
      "colourSecondary": MathColours.textField,
      "colourTertiary": MathColours.textField,
      "colourQuaternary": MathColours.textField
    });
  }

  MathWholeNumberBlock() {
    init();
  }
}

/// ===============================
/// math_positive_number
/// ===============================
class MathPositiveNumberBlock extends MathBlock {
  void init() {
    jsonInit({
      "message0": "%1",
      "args0": [
        {"type": "field_number", "name": "NUM", "min": 0}
      ],
      "output": "Number",
      "outputShape": MathConstants.outputShapeRound,
      "colour": MathColours.textField,
      "colourSecondary": MathColours.textField,
      "colourTertiary": MathColours.textField,
      "colourQuaternary": MathColours.textField
    });
  }

  MathPositiveNumberBlock() {
    init();
  }
}

/// ===============================
/// math_angle
/// ===============================
class MathAngleBlock extends MathBlock {
  void init() {
    jsonInit({
      "message0": "%1",
      "args0": [
        {
          "type": "field_angle",
          "name": "NUM",
          "value": 90,
        }
      ],
      "output": "Number",
      "outputShape": MathConstants.outputShapeRound,
      "colour": MathColours.textField,
      "colourSecondary": MathColours.textField,
      "colourTertiary": MathColours.textField,
      "colourQuaternary": MathColours.textField
    });
  }

  MathAngleBlock() {
    init();
  }
}
