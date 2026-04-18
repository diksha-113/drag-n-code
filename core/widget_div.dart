import 'package:flutter/material.dart';

/// Singleton manager for floating UI widgets (like Scratch/Blockly's WidgetDiv)
class WidgetDiv {
  static final WidgetDiv _instance = WidgetDiv._internal();
  factory WidgetDiv() => _instance;
  WidgetDiv._internal();

  OverlayEntry? _overlayEntry;
  Object? _owner;
  VoidCallback? _disposeCallback;

  /// Show the widget overlay. Replaces any existing widget.
  void show({
    required BuildContext context,
    required Widget child,
    required Object owner,
    VoidCallback? dispose,
    Offset? position, // optional position
  }) {
    hide();

    _owner = owner;
    _disposeCallback = dispose;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: position?.dx ?? 50,
          top: position?.dy ?? 50,
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hide the widget overlay if currently visible
  void hide() {
    if (_overlayEntry != null) {
      _disposeCallback?.call();
      _overlayEntry?.remove();
      _overlayEntry = null;
      _owner = null;
      _disposeCallback = null;
    }
  }

  /// Hide only if the given owner owns the widget
  void hideIfOwner(Object owner) {
    if (_owner == owner) hide();
  }

  /// Check if a widget is currently visible
  bool isVisible() => _overlayEntry != null;

  /// Reposition the overlay if needed (optional in Flutter)
  void reposition(Offset newPosition) {
    if (_overlayEntry != null) {
      // In Flutter, repositioning is easier by removing and re-inserting
      // the overlay entry with new position.
      final oldOwner = _owner;
      final oldDispose = _disposeCallback;
      hide();
      // Caller must call show() again with new position
    }
  }

  // ---------------- STATIC HELPERS FOR INJECT_HELPERS ----------------
  /// Create a container widget (Flutter equivalent of DOM)
  static Widget createDom(dynamic options) {
    return Container(); // simple placeholder container
  }

  /// Hide temporary UI elements (tooltips, dropdowns) on resize
  static void hideChaffOnResize() {
    WidgetDiv().hide();
  }
}
