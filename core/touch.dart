// lib/ui/touch_manager.dart
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TouchManager {
  static final TouchManager _instance = TouchManager._internal();

  factory TouchManager() => _instance;

  TouchManager._internal();

  Object? _touchIdentifier;
  Timer? _longPressTimer;
  static const Duration longPressDuration = Duration(milliseconds: 1000);

  /// Start tracking a touch or mouse event.
  void startTouch(Object identifier) {
    if (_touchIdentifier == null) {
      _touchIdentifier = identifier;
    }
  }

  /// Stop tracking a touch.
  void endTouch(Object identifier) {
    if (_touchIdentifier == identifier) {
      _touchIdentifier = null;
    }
    _stopLongPress();
  }

  /// Returns true if this event should be handled.
  bool shouldHandle(Object identifier) {
    return _touchIdentifier == null || _touchIdentifier == identifier;
  }

  /// Schedule a long press callback for context menus, etc.
  void startLongPress(VoidCallback callback, Object identifier) {
    if (!shouldHandle(identifier)) return;

    _stopLongPress();
    _longPressTimer = Timer(longPressDuration, callback);
  }

  /// Cancel any scheduled long press.
  void _stopLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  /// Clear the touch identifier (end drag/gesture).
  void clearTouchIdentifier() {
    _touchIdentifier = null;
  }

  /// Helper to get an identifier for pointer events.
  Object getIdentifier(PointerEvent event) {
    return event.pointer; // Flutter provides a unique pointer id
  }
}
