/*// lib/core/workspace_dragger.dart
import 'package:flutter/material.dart';
import 'workspace.dart';
import 'block.dart' as ui;

class WorkspaceDragger {
  final Workspace workspace;

  WorkspaceMetrics? startDragMetrics;
  Offset startScrollXY = Offset.zero;
  bool isDraggingWorkspace = false;

  ui.Block? draggingBlock;
  Offset? dragStartOffset;
  bool isDraggingBlock = false;

  WorkspaceDragger(this.workspace);

  // ---------------- Workspace drag methods ----------------
  void startWorkspaceDrag() {
    if (isDraggingBlock) return;
    workspace.deselectBlock();
    startDragMetrics = workspace.getMetrics();
    startScrollXY = workspace.scrollOffset;
    workspace.setupDragSurface();
    isDraggingWorkspace = true;
  }

  void dragWorkspace(Offset delta) {
    if (!isDraggingWorkspace || startDragMetrics == null) return;

    final metrics = startDragMetrics!;
    Offset newXY = startScrollXY + delta;

    double x = newXY.dx.clamp(
      metrics.viewWidth - metrics.contentLeft - metrics.contentWidth,
      -metrics.contentLeft,
    );
    double y = newXY.dy.clamp(
      metrics.viewHeight - metrics.contentTop - metrics.contentHeight,
      -metrics.contentTop,
    );

    x = -x - metrics.contentLeft;
    y = -y - metrics.contentTop;

    workspace.setScroll(Offset(x, y));
  }

  void endWorkspaceDrag(Offset delta) {
    dragWorkspace(delta);
    workspace.resetDragSurface();
    startDragMetrics = null;
    isDraggingWorkspace = false;
  }

  // ---------------- Block drag methods ----------------
  void startBlockDrag(ui.Block block, Offset globalPosition) {
    draggingBlock = block;
    dragStartOffset = globalPosition;

    // ✅ Add UI Block to workspace list (not converting to BlockModel)
    workspace.addUiBlock(block);

    isDraggingBlock = true;
  }

  void dragBlock(Offset globalPosition) {
    if (!isDraggingBlock || draggingBlock == null || dragStartOffset == null) return;

    final dx = globalPosition.dx - dragStartOffset!.dx;
    final dy = globalPosition.dy - dragStartOffset!.dy;

    draggingBlock!.moveBy(dx, dy);

    dragStartOffset = globalPosition;
  }

  void endBlockDrag() {
    if (draggingBlock == null) return;

    draggingBlock!.snapToGrid(10);

    draggingBlock = null;
    dragStartOffset = null;
    isDraggingBlock = false;
  }

  void deleteBlock(ui.Block block) {
    workspace.removeBlockByTarget(block);
  }

  void dispose() {
    draggingBlock = null;
    dragStartOffset = null;
    startDragMetrics = null;
    isDraggingWorkspace = false;
    isDraggingBlock = false;
  }
}

// ---------------- Extension for Workspace ----------------
extension WorkspaceDraggerHelpers on Workspace {
  void deselectBlock() {
    if (selectedBlock != null) {
      selectedBlock!.isSelected = false; // if you have this property
      selectedBlock = null;
    }
  }

  // ✅ New method to add UI Block directly
  void addUiBlock(ui.Block block) {
    if (!uiBlocks.contains(block)) {
      uiBlocks.add(block);
    }
  }
}
*/
