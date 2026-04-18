import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Scratch-like Scrollbar for Workspace / Flyout
class Scrollbar {
  Offset origin = Offset.zero; // top-left position
  double width = 10.0;
  double viewHeight = 100.0; // visible viewport
  double contentHeight = 100.0; // total scrollable content
  double scrollPosition = 0.0; // current scroll position
  double thumbHeight = 20.0; // minimal thumb size

  Scrollbar({
    this.viewHeight = 100,
    this.contentHeight = 100,
    this.width = 10,
  });

  /// --- ADDED FOR FLYOUT COMPATIBILITY ---
  /// Some Flyout implementations expect a `.position` setter.
  set position(double value) => set(value);

  /// Some Flyout implementations expect `.update()`.
  void update() {
    resize(newViewHeight: viewHeight, newContentHeight: contentHeight);
  }

  /// ---------------------------------------

  /// Resize the scrollbar when viewport or content changes
  void resize({double? newViewHeight, double? newContentHeight}) {
    if (newViewHeight != null) viewHeight = newViewHeight;
    if (newContentHeight != null) contentHeight = newContentHeight;

    if (contentHeight <= 0) {
      thumbHeight = viewHeight;
    } else {
      thumbHeight = math.max(20, viewHeight * (viewHeight / contentHeight));
    }

    // Clamp scroll position after resize
    set(scrollPosition);
  }

  /// Set scroll position (clamped to valid range)
  void set(double pos) {
    if (contentHeight <= viewHeight) {
      scrollPosition = 0.0;
    } else {
      scrollPosition = math.max(0.0, math.min(pos, contentHeight - viewHeight));
    }
  }

  /// Drag scrollbar by delta (track-based)
  void drag(double delta) {
    if (contentHeight <= viewHeight) return;
    final scrollDelta = delta * (contentHeight / viewHeight);
    set(scrollPosition + scrollDelta);
  }

  /// Get the rectangle of the scrollbar thumb
  Rect getThumbRect() {
    return Rect.fromLTWH(
      origin.dx,
      origin.dy + (scrollPosition / contentHeight) * viewHeight,
      width,
      thumbHeight,
    );
  }

  /// Paint the scrollbar (track + thumb)
  void paint(Canvas canvas) {
    final paint = Paint();

    // Track
    canvas.drawRect(
      Rect.fromLTWH(origin.dx, origin.dy, width, viewHeight),
      paint..color = Colors.grey.shade300,
    );

    // Thumb
    canvas.drawRect(
      getThumbRect(),
      paint..color = Colors.grey.shade700,
    );
  }
}

/// Pair of scrollbars (horizontal + vertical)
class ScrollbarPair {
  final Scrollbar hScroll;
  final Scrollbar vScroll;

  ScrollbarPair({
    required double width,
    required double height,
  })  : hScroll = Scrollbar(width: width, viewHeight: 14, contentHeight: width),
        vScroll =
            Scrollbar(width: 14, viewHeight: height, contentHeight: height);

  /// Set scroll positions
  void set(double x, double y) {
    hScroll.set(x);
    vScroll.set(y);
  }

  /// Set origins for both scrollbars
  void setOrigin(Offset offset) {
    hScroll.origin = offset;
    vScroll.origin = offset;
  }

  /// Resize both scrollbars
  void resize({double? newWidth, double? newHeight}) {
    hScroll.resize(
      newViewHeight: 14,
      newContentHeight: newWidth ?? hScroll.contentHeight,
    );

    vScroll.resize(
      newViewHeight: newHeight ?? vScroll.viewHeight,
      newContentHeight: newHeight ?? vScroll.contentHeight,
    );
  }
}
