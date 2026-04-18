// lib/core/dropdown_div.dart
import 'package:flutter/material.dart';

class DropDownDiv {
  static OverlayEntry? _overlayEntry;
  static Widget? _content;
  static Function? _onHide;
  static bool _visible = false;

  // Constants
  static const double arrowSize = 16.0;
  static const double borderSize = 1.0;
  static const double arrowPadding = 12.0;
  static const double paddingY = 20.0;
  static const Duration animationDuration = Duration(milliseconds: 250);

  static void setContent(Widget content) {
    _content = content;
  }

  static void clearContent() {
    _content = null;
  }

  static bool isVisible() => _visible;

  static void hide({bool animated = true}) {
    if (_overlayEntry != null) {
      if (animated) {
        // Fade out animation
        _overlayEntry!.remove();
      } else {
        _overlayEntry!.remove();
      }
      _overlayEntry = null;
      _visible = false;
      _onHide?.call();
      _onHide = null;
    }
  }

  static void show({
    required BuildContext context,
    required Offset primary,
    Offset? secondary,
    Function? onHide,
    Color backgroundColor = Colors.white,
    Color borderColor = Colors.black,
    double width = 200,
  }) {
    hide(animated: false);
    _onHide = onHide;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        // Decide whether to use primary or secondary position
        Offset pos = primary;
        if (secondary != null) {
          if (primary.dy + width > MediaQuery.of(context).size.height) {
            pos = secondary;
          }
        }

        return Positioned(
          left: pos.dx - width / 2,
          top: pos.dy + paddingY,
          child: Material(
            color: Colors.transparent,
            child: AnimatedOpacity(
              opacity: 1,
              duration: animationDuration,
              child: Container(
                width: width,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border.all(color: borderColor, width: borderSize),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -arrowSize / 2,
                      left: width / 2 - arrowSize / 2,
                      child: Transform.rotate(
                        angle: 0.785398, // 45 degrees
                        child: Container(
                          width: arrowSize,
                          height: arrowSize,
                          color: backgroundColor,
                        ),
                      ),
                    ),
                    _content ?? SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _visible = true;
  }
}
