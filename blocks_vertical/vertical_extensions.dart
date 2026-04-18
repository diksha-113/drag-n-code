// lib/blocks_vertical/vertical_extensions.dart
import 'package:flutter/material.dart';
import '../models/block_model.dart';

mixin ScratchBlockExtensions {
  /// Set block colours based on category
  void setColoursFromCategory(BlockModel block, String category) {
    final colours = _categoryColours[category];
    if (colours == null) {
      throw Exception('Could not find colours for category "$category"');
    }
    block.color = colours['primary']!;
    block.secondaryColor = colours['secondary']!;
    block.tertiaryColor = colours['tertiary']!;
    block.quaternaryColor = colours['quaternary']!;
  }

  /// Set textfield colour
  void setColourTextField(BlockModel block) {
    block.color = Colors.grey[300]!;
    block.secondaryColor = Colors.grey[300]!;
    block.tertiaryColor = Colors.grey[300]!;
    block.quaternaryColor = Colors.grey[300]!;
  }

  /// Output types
  void outputNumber(BlockModel block) {
    block.blockType = BlockType.number;
    block.outputShape = BlockOutputShape.round;
  }

  void outputString(BlockModel block) {
    block.blockType = BlockType.reporter; // or dynamic
    block.outputShape = BlockOutputShape.round;
  }

  void outputBoolean(BlockModel block) {
    block.blockType = BlockType.boolean;
    block.outputShape = BlockOutputShape.puzzle;
  }
}

/// Category colours (example values)
final Map<String, Map<String, Color>> _categoryColours = {
  'control': {
    'primary': Colors.orange,
    'secondary': Colors.orangeAccent,
    'tertiary': Colors.deepOrange,
    'quaternary': Colors.orange[100]!,
  },
  'data': {
    'primary': Colors.red,
    'secondary': Colors.redAccent,
    'tertiary': Colors.red[700]!,
    'quaternary': Colors.red[100]!,
  },
  'sounds': {
    'primary': Colors.purple,
    'secondary': Colors.purpleAccent,
    'tertiary': Colors.deepPurple,
    'quaternary': Colors.purple[100]!,
  },
  'motion': {
    'primary': Colors.blue,
    'secondary': Colors.lightBlue,
    'tertiary': Colors.blueAccent,
    'quaternary': Colors.blue[100]!,
  },
  'looks': {
    'primary': Colors.pink,
    'secondary': Colors.pinkAccent,
    'tertiary': Colors.deepOrangeAccent,
    'quaternary': Colors.pink[100]!,
  },
  'sensing': {
    'primary': Colors.teal,
    'secondary': Colors.tealAccent,
    'tertiary': Colors.greenAccent,
    'quaternary': Colors.teal[100]!,
  },
  'operators': {
    'primary': Colors.green,
    'secondary': Colors.lightGreen,
    'tertiary': Colors.greenAccent,
    'quaternary': Colors.green[100]!,
  },
};
