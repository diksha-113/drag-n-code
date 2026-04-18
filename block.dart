import 'package:flutter/material.dart';
import 'models/block_model.dart';
import '../screens/editor_screen.dart';

/// ===============================
/// EDITOR BLOCK (UI MODEL)
/// ===============================
class EditorBlock {
  final String id;
  final String type;
  final String opcode;

  String label;
  String? value;

  double x;
  double y;

  final bool isHat;
  final bool isNote;
  final String? noteText;
  final String category;
  final bool fromPalette;

  EditorBlock? parent;
  EditorBlock? next;
  List<EditorBlock> children = [];

  late final BlockModel modelBlock;

  /// Input controllers (text, dropdowns, etc.)
  Map<String, TextEditingController> controllers = {};

  EditorBlock({
    required this.id,
    required this.type,
    required this.opcode,
    required this.x,
    required this.y,
    required this.isHat,
    required this.isNote,
    required this.noteText,
    required this.category,
    required this.label,
    this.value,
    this.fromPalette = false,
  }) {
    modelBlock = BlockModel(
      id: id,
      type: type,
      opcode: opcode,
      label: label,
      value: value ?? '',
      shape: isHat ? ScratchBlockShape.hat : ScratchBlockShape.stack,
      x: x,
      y: y,
    );
  }

  EditorBlock copyWith({
    double? x,
    double? y,
    String? value,
    String? label,
  }) {
    return EditorBlock(
      id: id,
      type: type,
      opcode: opcode,
      x: x ?? this.x,
      y: y ?? this.y,
      isHat: isHat,
      isNote: isNote,
      noteText: noteText,
      category: category,
      value: value ?? this.value,
      label: label ?? this.label,
    );
  }

  Offset get topConnection => Offset(0, y);
  Offset get bottomConnection => Offset(0, y + EditorScreen.blockHeight);

  bool get canHaveTop => true;
  bool get canHaveBottom => true;
}

/// ===============================
/// EDITOR BLOCK → ENGINE MODEL
/// ===============================
extension EditorBlockToModel on EditorBlock {
  BlockModel toBlockModel() {
    return BlockModel(
      id: id,
      opcode: opcode,
      type: type,
      label: label,
      value: value,
      shape: isHat ? ScratchBlockShape.hat : ScratchBlockShape.stack,
      x: x,
      y: y,
    );
  }
}
