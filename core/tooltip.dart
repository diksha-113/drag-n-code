// lib/ui/tooltip.dart
import 'dart:async';
import 'package:flutter/material.dart';

class TooltipManager {
  static final TooltipManager _instance = TooltipManager._internal();

  factory TooltipManager() => _instance;

  TooltipManager._internal();

  OverlayEntry? _overlayEntry;
  Timer? _showTimer;
  Timer? _hideTimer;
  Offset _lastPosition = Offset.zero;
  bool _visible = false;
  bool _blocked = false;
  dynamic _currentTarget;

  static const double offsetX = 0;
  static const double offsetY = 10;
  static const double radiusOk = 10;
  static const int hoverMs = 750;

  void bindHover({
    required BuildContext context,
    required Widget target,
    required dynamic tooltip,
    required void Function(Widget) onHoverWidget,
  }) {
    // GestureDetector wraps the target to detect mouse events
    onHoverWidget(
      MouseRegion(
        onEnter: (e) => _onMouseOver(context, e.position, tooltip),
        onHover: (e) => _onMouseMove(context, e.position, tooltip),
        onExit: (e) => _onMouseOut(),
        child: target,
      ),
    );
  }

  void _onMouseOver(BuildContext context, Offset position, dynamic tooltip) {
    if (_blocked) return;

    _currentTarget = tooltip;
    _lastPosition = position;
    _hideTooltip();
    _showTimer?.cancel();
    _showTimer = Timer(Duration(milliseconds: hoverMs), () {
      _showTooltip(context, position, tooltip);
    });
  }

  void _onMouseMove(BuildContext context, Offset position, dynamic tooltip) {
    if (_blocked) return;
    if (_visible) {
      final dx = (_lastPosition.dx - position.dx).abs();
      final dy = (_lastPosition.dy - position.dy).abs();
      if (dx * dx + dy * dy > radiusOk * radiusOk) {
        _hideTooltip();
      }
    } else {
      _lastPosition = position;
    }
  }

  void _onMouseOut() {
    _showTimer?.cancel();
    _hideTooltip();
    _currentTarget = null;
  }

  void _showTooltip(BuildContext context, Offset position, dynamic tooltip) {
    if (_blocked || _currentTarget != tooltip) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: position.dx + offsetX,
          top: position.dy + offsetY,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tooltip is Function ? tooltip() : tooltip.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context)?.insert(_overlayEntry!);
    _visible = true;
  }

  void _hideTooltip() {
    if (_visible) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _visible = false;
    }
  }

  void block() {
    _blocked = true;
    _hideTooltip();
  }

  void unblock() {
    _blocked = false;
  }
}
