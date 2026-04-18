import 'package:flutter/material.dart';
import '../../models/block_model.dart';

mixin DraggableSnapMixin {
  Offset offset = Offset.zero;

  /// Drag block by delta
  void drag(Offset delta) {
    offset += delta;
  }

  /// Snap this block below another block
  void snapBelow(BlockModel target) {
    offset = Offset(target.x, target.y + target.dynamicHeight);
    target.next = this as BlockModel;
    (this as BlockModel).snappedTo = target;
  }

  /// Snap into cavity (for IF / IF-ELSE)
  void snapIntoCavity(BlockModel parent, {bool isElse = false}) {
    if (isElse) {
      parent.insertIntoElse(this as BlockModel);
    } else {
      parent.insertIntoCavity(this as BlockModel);
    }
  }
}
