// lib/core/block_snapping_engine.dart
import 'package:flutter/material.dart';
import '../models/block_model.dart';

const double blockWidth = 220;
const double blockHeight = 44;
const double snapThreshold = 18;
const double cavityIndent = 24;
const double cavityPadding = 12;
const double blockGap = 4;
const double xSnapTolerance = 16;

/// Scratch-style snapping engine (MODEL-ALIGNED, dynamic cavity, no overlap)
class BlockSnappingEngine {
  final List<BlockModel> blocks;

  BlockSnappingEngine(this.blocks);

  /// =========================
  /// DRAG ENTRY POINT
  /// =========================
  void onDrag(BlockModel dragged, Offset newPos) {
    dragged.position = newPos;

    _detachFromOldParent(dragged);

    // Snap priority: stack first, then cavity
    if (!_trySnapToStack(dragged)) {
      _trySnapIntoCavity(dragged);
    }
  }

  /// =========================
  /// STACK SNAP (TOP/BOTTOM)
  /// =========================
  bool _trySnapToStack(BlockModel dragged) {
    for (final target in blocks) {
      if (target == dragged) continue;
      if (target.hasCavity) continue;

      final double targetBottom = target.position.dy + target.dynamicHeight;

      final bool xAligned =
          (dragged.position.dx - target.position.dx).abs() < xSnapTolerance;
      final bool yAligned =
          (dragged.position.dy - targetBottom).abs() < snapThreshold;

      if (xAligned && yAligned) {
        dragged.snapBelow(target);
        _reflowStack(target);
        return true;
      }
    }
    return false;
  }

  /// =========================
  /// CAVITY SNAP (REAL SCRATCH)
  /// Only snap if block fully fits inside cavity
  /// =========================
  bool _trySnapIntoCavity(BlockModel dragged) {
    for (final parent in blocks) {
      if (!parent.hasCavity) continue;
      if (parent == dragged) continue;

      final Rect innerRect = _dynamicInnerCavityRect(parent);
      final Rect elseRect = parent.type == 'control_if_else'
          ? _dynamicElseCavityRect(parent)
          : Rect.zero;

      final Rect draggedRect = Rect.fromLTWH(
        dragged.position.dx,
        dragged.position.dy,
        blockWidth,
        blockHeight,
      );

      if (_rectFullyInside(draggedRect, innerRect)) {
        parent.insertIntoCavity(dragged);
        _reflowControl(parent);
        return true;
      }

      if (parent.type == 'control_if_else' &&
          _rectFullyInside(draggedRect, elseRect)) {
        parent.insertIntoElse(dragged);
        _reflowControl(parent);
        return true;
      }
    }
    return false;
  }

  /// =========================
  /// GEOMETRY
  /// =========================
  Rect _dynamicInnerCavityRect(BlockModel parent) {
    final double y = parent.position.dy + blockHeight;

    final double innerHeight = parent.innerBlocks.isEmpty
        ? blockHeight * 1.2
        : parent.innerBlocks
                .fold(0.0, (s, b) => s + b.dynamicHeight + blockGap) +
            cavityPadding * 2;

    return Rect.fromLTWH(
      parent.position.dx + cavityIndent,
      y,
      blockWidth - cavityIndent * 2,
      innerHeight,
    );
  }

  Rect _dynamicElseCavityRect(BlockModel parent) {
    final double y = parent.position.dy +
        blockHeight +
        (parent.innerBlocks.isEmpty
            ? blockHeight * 1.2
            : parent.innerBlocks
                .fold(0.0, (s, b) => s + b.dynamicHeight + blockGap)) +
        cavityPadding * 2 +
        blockHeight;

    final double elseHeight = parent.elseBlocks.isEmpty
        ? blockHeight * 1.2
        : parent.elseBlocks
                .fold(0.0, (s, b) => s + b.dynamicHeight + blockGap) +
            cavityPadding * 2;

    return Rect.fromLTWH(
      parent.position.dx + cavityIndent,
      y,
      blockWidth - cavityIndent * 2,
      elseHeight,
    );
  }

  Offset _blockCenter(BlockModel b) =>
      b.position + const Offset(blockWidth / 2, blockHeight / 2);

  /// =========================
  /// SAFE DETACH
  /// =========================
  void _detachFromOldParent(BlockModel block) {
    block.detach();
  }

  /// =========================
  /// REFLOW (NO OVERLAP)
  /// =========================
  void _reflowStack(BlockModel root) {
    double y = root.position.dy + root.dynamicHeight + blockGap;

    BlockModel? current = root.next;
    while (current != null) {
      current.position = Offset(root.position.dx, y);
      y += current.dynamicHeight + blockGap;
      current = current.next;
    }
  }

  void _reflowControl(BlockModel parent) {
    double y = parent.position.dy + blockHeight + cavityPadding;

    // Reflow inner blocks
    for (final b in parent.innerBlocks) {
      b.position = Offset(parent.position.dx + cavityIndent, y);
      y += b.dynamicHeight + blockGap;
    }

    if (parent.type == 'control_if_else') {
      y += blockHeight; // gap before else

      // Reflow else blocks
      for (final b in parent.elseBlocks) {
        b.position = Offset(parent.position.dx + cavityIndent, y);
        y += b.dynamicHeight + blockGap;
      }
    }

    // Reflow next in stack
    if (parent.next != null) {
      parent.next!.position = Offset(parent.position.dx, y + blockGap);
      _reflowStack(parent.next!);
    }
  }

  /// =========================
  /// HELPER: CHECK FULL RECT INSIDE CAVITY
  /// =========================
  bool _rectFullyInside(Rect child, Rect parent) {
    return child.left >= parent.left &&
        child.right <= parent.right &&
        child.top >= parent.top &&
        child.bottom <= parent.bottom;
  }
}

/// =========================
/// RECT HELPER
/// =========================
extension RectCheck on Offset {
  bool within(Rect r) =>
      dx >= r.left && dx <= r.right && dy >= r.top && dy <= r.bottom;
}
