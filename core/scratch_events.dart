/*// lib/engine/scratch_events.dart
import 'block.dart';

/// Event fired when a block is dragged outside the workspace.
class DragBlockOutsideEvent {
  final Block block;
  bool isOutside = true;
  bool recordUndo = false;

  DragBlockOutsideEvent({required this.block});

  Map<String, dynamic> toJson() {
    return {
      'type': 'drag_outside',
      'blockId': block.id,
      'isOutside': isOutside,
    };
  }

  static DragBlockOutsideEvent fromJson(
      Map<String, dynamic> json, Block block) {
    return DragBlockOutsideEvent(block: block)
      ..isOutside = json['isOutside'] ?? true;
  }
}

/// Event fired when a block drag ends.
class EndBlockDragEvent {
  final Block block;
  bool isOutside;
  String? xml; // kept for compatibility
  bool recordUndo = false;

  EndBlockDragEvent({required this.block, this.isOutside = false}) {
    // ✅ FIX: do NOT serialize Block → BlockModel
    // Just mark state (Scratch-style behavior)
    xml = null;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'end_drag',
      'blockId': block.id,
      'isOutside': isOutside,
      'xml': xml,
    };
  }

  static EndBlockDragEvent fromJson(Map<String, dynamic> json, Block block) {
    return EndBlockDragEvent(
      block: block,
      isOutside: json['isOutside'] ?? false,
    )..xml = json['xml'];
  }
}
*/
