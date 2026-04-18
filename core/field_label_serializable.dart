import 'package:flutter/material.dart';

/// Flutter version of Blockly.FieldLabelSerializable
///
/// This is a simple text label inside a block.
/// - Always serializable.
/// - Not editable.
/// - Can only be modified via code.
class FieldLabelSerializable extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool visible;

  const FieldLabelSerializable({
    super.key,
    required this.text,
    this.style,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Text(
      text,
      style: style ??
          const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
    );
  }

  /// Used when saving block data (serialize)
  Map<String, dynamic> toJson() {
    return {
      'type': 'field_label_serializable',
      'text': text,
    };
  }

  /// Create field from saved data
  factory FieldLabelSerializable.fromJson(Map<String, dynamic> json) {
    return FieldLabelSerializable(
      text: json['text'] ?? '',
    );
  }
}
