import 'package:flutter/material.dart';

/// Flutter version of Blockly.FieldLabel
///
/// A non-editable text field used inside a block.
/// - Purely visual (not serializable)
/// - Always read-only
/// - Used for titles / static labels
class FieldLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool visible;

  /// Whether the field is editable. Always false (same as Blockly).
  final bool editable = false;

  /// Whether this field is serialized. Blockly.FieldLabel → SERIALIZABLE = false.
  final bool serializable = false;

  const FieldLabel({
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
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}
