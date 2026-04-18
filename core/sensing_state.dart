import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class SensingState {
  double timerStart = DateTime.now().millisecondsSinceEpoch.toDouble();
  String answer = '';

  final Set<LogicalKeyboardKey> pressedKeys = {};
  Offset mousePosition = Offset.zero;
  bool mouseDown = false;

  double loudness = 0;

  // Scratch-style getters
  bool get loud => loudness > 50;
  double get mouseX => mousePosition.dx;
  double get mouseY => mousePosition.dy;
}
