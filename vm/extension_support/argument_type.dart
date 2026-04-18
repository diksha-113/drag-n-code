// lib/vm/extension_support/argument_type.dart

/// Block argument types for Scratch blocks.
enum ArgumentType {
  /// Numeric value with angle picker
  angle,

  /// Boolean value with hexagonal placeholder
  boolean,

  /// Numeric value with color picker
  color,

  /// Numeric value with text field
  number,

  /// String value with text field
  string,

  /// String value with matrix field
  matrix,

  /// MIDI note number with note picker (piano) field
  note,

  /// Inline image on block (as part of the label)
  image,
}

/// Extension to get string values matching the original JS
extension ArgumentTypeValue on ArgumentType {
  String get value {
    switch (this) {
      case ArgumentType.angle:
        return 'angle';
      case ArgumentType.boolean:
        return 'Boolean';
      case ArgumentType.color:
        return 'color';
      case ArgumentType.number:
        return 'number';
      case ArgumentType.string:
        return 'string';
      case ArgumentType.matrix:
        return 'matrix';
      case ArgumentType.note:
        return 'note';
      case ArgumentType.image:
        return 'image';
    }
  }
}
