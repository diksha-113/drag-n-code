// lib/vm/extension_support/block_type.dart

/// Types of Scratch blocks.
enum BlockType {
  /// Boolean reporter with hexagonal shape
  boolean,

  /// A button (not an actual block) for some special action, like making a variable
  button,

  /// Command block
  command,

  /// Specialized command block which may or may not run a child branch
  /// The thread continues with the next block whether or not a child branch ran.
  conditional,

  /// Specialized hat block with no implementation function
  /// This stack only runs if the corresponding event is emitted by other code.
  event,

  /// Hat block which conditionally starts a block stack
  hat,

  /// Specialized command block which may or may not run a child branch
  /// If a child branch runs, the thread evaluates the loop block again.
  loop,

  /// General reporter with numeric or string value
  reporter,
}

/// Extension to get string values matching the original JS
extension BlockTypeValue on BlockType {
  String get value {
    switch (this) {
      case BlockType.boolean:
        return 'Boolean';
      case BlockType.button:
        return 'button';
      case BlockType.command:
        return 'command';
      case BlockType.conditional:
        return 'conditional';
      case BlockType.event:
        return 'event';
      case BlockType.hat:
        return 'hat';
      case BlockType.loop:
        return 'loop';
      case BlockType.reporter:
        return 'reporter';
    }
  }
}
