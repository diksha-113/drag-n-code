// lib/core/blocks/logic/logic_blocks_factory.dart
import 'package:flutter/material.dart';
import '../../../models/block_model.dart';

class LogicBlocksFactory {
  /// Generic logic block creator
  static BlockModel create({
    required String opcode,
    double x = 40,
    double y = 40,
    bool isHat = false,
    ScratchBlockShape shape = ScratchBlockShape.stack,
    Map<String, dynamic>? inputs,
    Color? color,
    BlockOutputShape? outputShape,
  }) {
    return BlockModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      opcode: opcode,
      type: 'logic',
      label: opcode.replaceAll('_', ' '),
      shape: shape,
      inputs: inputs ?? {},
      x: x,
      y: y,
      category: 'logic',
      color: color ?? Colors.redAccent,
      outputShape: outputShape,
    );
  }

  // -------------------- LOGIC BLOCKS --------------------

  static BlockModel andBlock({double x = 40, double y = 40}) => create(
        opcode: 'logic_and',
        x: x,
        y: y,
        inputs: {'A': null, 'B': null},
        shape: ScratchBlockShape.boolean,
        outputShape: BlockOutputShape.boolean,
      );

  static BlockModel orBlock({double x = 40, double y = 40}) => create(
        opcode: 'logic_or',
        x: x,
        y: y,
        inputs: {'A': null, 'B': null},
        shape: ScratchBlockShape.boolean,
        outputShape: BlockOutputShape.boolean,
      );

  static BlockModel notBlock({double x = 40, double y = 40}) => create(
        opcode: 'logic_not',
        x: x,
        y: y,
        inputs: {'BOOL': null},
        shape: ScratchBlockShape.boolean,
        outputShape: BlockOutputShape.boolean,
      );

  static BlockModel trueBlock({double x = 40, double y = 40}) => create(
        opcode: 'logic_true',
        x: x,
        y: y,
        shape: ScratchBlockShape.boolean,
        outputShape: BlockOutputShape.boolean,
      );

  static BlockModel falseBlock({double x = 40, double y = 40}) => create(
        opcode: 'logic_false',
        x: x,
        y: y,
        shape: ScratchBlockShape.boolean,
        outputShape: BlockOutputShape.boolean,
      );

  // -------------------- CONTROL BLOCKS --------------------

  static BlockModel ifBlock({double x = 40, double y = 40}) => create(
        opcode: 'control_if',
        x: x,
        y: y,
        shape: ScratchBlockShape.c,
        inputs: {'CONDITION': null, 'SUBSTACK': []},
        color: Colors.blueAccent,
      );

  static BlockModel ifElseBlock({double x = 40, double y = 40}) => create(
        opcode: 'control_if_else',
        x: x,
        y: y,
        shape: ScratchBlockShape.cElse,
        inputs: {'CONDITION': null, 'SUBSTACK': [], 'ELSE_SUBSTACK': []},
        color: Colors.blueAccent,
      );
}
