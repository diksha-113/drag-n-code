/// Placeholder for Note constants
class NoteConstants {
  static const outputShapeRound = 'round';
}

/// Placeholder colours for Note blocks
class NoteColours {
  static const textField = '#000000'; // replace with real colours later
}

/// Base class similar to Blockly.Block (unique name)
abstract class NoteBaseBlock {
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
/// Note block
/// ===============================
class NoteBlock extends NoteBaseBlock {
  void init() {
    jsonInit({
      "message0": "%1",
      "args0": [
        {
          "type": "field_note",
          "name": "NOTE",
          "value": 60,
        }
      ],
      "outputShape": NoteConstants.outputShapeRound,
      "output": "Number",
      "colour": NoteColours.textField,
      "colourSecondary": NoteColours.textField,
      "colourTertiary": NoteColours.textField,
      "colourQuaternary": NoteColours.textField,
    });
  }

  NoteBlock() {
    init();
  }
}
