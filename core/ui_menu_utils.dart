// lib/utils/ui_menu_utils.dart
import 'package:flutter/widgets.dart';

class UiMenuUtils {
  /// Get the size of a rendered menu widget.
  /// The menu must have a [GlobalKey] assigned to its root container.
  static Size getSize(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return Size.zero;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return Size.zero;

    // Use the actual size including all content.
    return renderBox.size;
  }

  /// Adjust bounding boxes for RTL menus.
  /// In RTL, menus render down and to the left instead of down and right.
  /// This method shifts the anchor and viewport rectangles accordingly.
  static void adjustBBoxesForRTL({
    required Rect viewportBBox,
    required Rect anchorBBox,
    required Size menuSize,
    required bool isRtl,
    required ValueChanged<Rect> onViewportUpdated,
    required ValueChanged<Rect> onAnchorUpdated,
  }) {
    if (!isRtl) return;

    // Shift anchor and viewport positions by menu width.
    final adjustedAnchor = anchorBBox.shift(Offset(menuSize.width, 0));
    final adjustedViewport = viewportBBox.shift(Offset(menuSize.width, 0));

    onAnchorUpdated(adjustedAnchor);
    onViewportUpdated(adjustedViewport);
  }
}
