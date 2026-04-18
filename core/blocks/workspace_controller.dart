import 'package:flutter/material.dart';

class WorkspaceController {
  static const double snapDistance = 24;

  static Offset snapToSlots(
    Offset draggedPos,
    List<GlobalKey> slotKeys,
  ) {
    for (final key in slotKeys) {
      final ctx = key.currentContext;
      if (ctx == null) continue;

      final box = ctx.findRenderObject() as RenderBox;
      final slotPos = box.localToGlobal(Offset.zero);

      if ((draggedPos - slotPos).distance < snapDistance) {
        return slotPos;
      }
    }
    return draggedPos;
  }
}
