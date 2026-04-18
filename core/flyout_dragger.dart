// lib/engine/flyout_dragger.dart

import 'package:flutter/widgets.dart';
import '../core/flyout_base.dart';

/// Drags a Flyout workspace (scrolling the block list).
/// Equivalent of Blockly.FlyoutDragger
class FlyoutDragger {
  final Flyout flyout;
  Offset? dragStartPos;
  Offset dragDelta = Offset.zero;
  bool isDragging = false;

  FlyoutDragger(this.flyout);

  /// Call on pointer down / mouse down
  void onPointerDown(PointerDownEvent e) {
    dragStartPos = e.position;
    dragDelta = Offset.zero;
    isDragging = false;
  }

  /// Call on pointer move / mouse move
  void onPointerMove(PointerMoveEvent e) {
    if (dragStartPos == null) return;

    final moveDelta = e.position - dragStartPos!;
    if (!isDragging && moveDelta.distance > 2) {
      // Start dragging after small threshold
      isDragging = true;
    }

    if (isDragging) {
      dragDelta = moveDelta;

      // Apply scroll to flyout workspace
      if (flyout.horizontalLayout) {
        final newScroll = -(flyout.workspace.scrollX - moveDelta.dx);
        flyout.scrollbar.set(newScroll);
      } else {
        final newScroll = -(flyout.workspace.scrollY - moveDelta.dy);
        flyout.scrollbar.set(newScroll);
      }
    }
  }

  /// Call on pointer up / mouse up
  void onPointerUp(PointerUpEvent e) {
    dragStartPos = null;
    dragDelta = Offset.zero;
    isDragging = false;
  }

  /// Update called on each frame (optional animation)
  void step() {
    flyout.stepScrollAnimation();
  }

  /// Reset flyout position (optional)
  void reset() {
    dragStartPos = null;
    dragDelta = Offset.zero;
    isDragging = false;
  }
}
