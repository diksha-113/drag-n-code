// lib/engine/flyout_horizontal.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'flyout_base.dart';
import 'flyout_extension_category_header.dart' as ext;

/// -------------------- STUBS --------------------
class Events {
  static void hideWidgetDiv(bool _) {}
  static void hideDropDownDivWithoutAnimation() {}
}

class ScrollbarPair {
  final double width;
  final double height;
  final ScrollbarStub hScroll = ScrollbarStub();
  ScrollbarPair({required this.width, required this.height});
}

class ScrollbarStub {
  void setOrigin(Offset o) {}
  void resize() {}
  void set(double value) {}
}

class Utils {
  static bool isGecko = false;
}

/// -------------------- HORIZONTAL FLYOUT --------------------
class HorizontalFlyout extends Flyout {
  HorizontalFlyout({required Map<String, dynamic> workspaceOptions})
      : super(workspaceOptions: {
          ...workspaceOptions,
          'horizontalLayout': true,
        });

  double dragStartX = 0.0;
  double dragStartScrollX = 0.0;

  FlyoutDragger? dragger;
  ScrollbarPair? customScrollbars;

  void initDragger() {
    dragger = FlyoutDragger(this);
  }

  void startDrag(Offset globalPosition) {
    dragger?.startDrag(globalPosition);
  }

  void dragUpdate(Offset globalPosition) {
    dragger?.dragUpdate(globalPosition);
  }

  void endDrag() {
    dragger?.endDrag();
  }

  @override
  void position() {
    if (!isVisible()) return;

    customScrollbars ??= ScrollbarPair(width: width_, height: height_);
    try {
      customScrollbars?.hScroll.setOrigin(const Offset(0, 0));
      customScrollbars?.hScroll.resize();
    } catch (_) {}

    _updateScrollPosition();
  }

  void scrollToStart() {
    scrollTarget = 0.0;
    _updateScrollPosition();
  }

  void scrollTo(double pos) {
    scrollTarget = pos;
    _updateScrollPosition();
  }

  void _updateScrollPosition() {
    final metrics = getMetrics_();
    if (metrics == null) return;

    final contentWidth = metrics['contentWidth'] ?? 1.0;
    final viewWidth = metrics['viewWidth'] ?? 1.0;

    double st = scrollTarget ?? 0.0;
    st = math.max(0.0, math.min(st, contentWidth - viewWidth));
    scrollTarget = st;

    // Removed unnecessary cast
    workspace_.scrollX = scrollTarget ?? 0.0;

    try {
      customScrollbars?.hScroll.set(st / contentWidth);
    } catch (_) {}
  }

  /// -------------------- METRICS --------------------
  Map<String, double>? getMetrics_() {
    if (!isVisible()) return null;

    final scale = workspace_.scale ?? 1.0;

    return {
      'viewWidth': width_,
      'viewHeight': height_,
      'contentWidth': width_ * scale + 2 * Flyout.margin,
      'contentHeight': height_ * scale + 2 * Flyout.margin,
      'viewLeft': -workspace_.scrollX,
      'viewTop': -workspace_.scrollY,
      'contentLeft': 0.0,
      'contentTop': 0.0,
      'absoluteLeft': Flyout.scrollbarPadding,
      'absoluteTop': Flyout.scrollbarPadding,
    };
  }

  /// -------------------- LAYOUT (CLEANED) --------------------
  @override
  void layout_(List<Map<String, dynamic>> contents, List<double> gaps) {
    double cursorX = Flyout.margin;
    double cursorY = Flyout.margin;

    for (int i = 0; i < contents.length; i++) {
      final item = contents[i];
      final gap = (i < gaps.length) ? gaps[i] : Flyout.gapX;

      if (item['type'] == 'extension_header') {
        final ext.FlyoutExtensionCategoryHeader header =
            item['header'] as ext.FlyoutExtensionCategoryHeader;

        // Header consumes fixed horizontal space
        cursorX += header.flyoutWidth + gap;
      } else if (item['type'] == 'block') {
        final Block block = item['block'] as Block;
        block.setPosition(cursorX, cursorY);
        cursorX += 120.0 + gap;
      } else if (item['type'] == 'button') {
        // Button width added without storing variable
        cursorX += 140.0 + gap;
      }
    }

    contentWidth_ = cursorX + Flyout.margin;
  }
}

/// -------------------- DRAGGER --------------------
class FlyoutDragger {
  final HorizontalFlyout flyout;
  double startX = 0.0;
  double startScroll = 0.0;

  FlyoutDragger(this.flyout);

  void startDrag(Offset position) {
    startX = position.dx;
    startScroll = flyout.scrollTarget ?? 0.0;
  }

  void dragUpdate(Offset position) {
    flyout.scrollTarget = startScroll + (startX - position.dx);
    flyout._updateScrollPosition();
  }

  void endDrag() {
    startX = 0.0;
    startScroll = 0.0;
  }
}
