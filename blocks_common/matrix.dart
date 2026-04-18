/**
 * Matrix block definition (logic only, not UI)
 */

/// Placeholder for Matrix constants
class MatrixConstants {
  static const outputShapeRound = 'round';
}

/// Base class to mimic Blockly.Block (unique name)
abstract class MatrixBaseBlock {
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
/// Matrix block
/// ===============================
class MatrixBlock extends MatrixBaseBlock {
  MatrixBlock() {
    init();
  }

  void init() {
    jsonInit({
      "message0": "%1",
      "args0": [
        {
          "type": "field_matrix",
          "name": "MATRIX",
        }
      ],
      "outputShape": MatrixConstants.outputShapeRound,
      "output": "Number",
      "extensions": ["colours_pen"],
    });
  }
}
