/*import 'package:flutter/material.dart';
import 'block.dart';
import 'bubble.dart' as engine;

/// Warning icon attached to a block
class Warning {
  final Block block;
  final Map<String, String> _texts = {};
  engine.Bubble? _bubble;

  Warning({required this.block});

  /// Whether warning is visible
  bool get isVisible => _bubble != null;

  /// Build the warning icon widget
  Widget buildIcon() {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _WarningPainter(),
    );
  }

  /// Set or update warning text
  void setText(String text, String id) {
    if (_texts[id] == text) return;

    if (text.isNotEmpty) {
      _texts[id] = text;
    } else {
      _texts.remove(id);
    }

    if (isVisible) {
      hide();
      show();
    }
  }

  /// Combined warning text
  String getText() => _texts.values.join('\n');

  /// Show warning bubble
  void show() {
    if (_bubble != null) return;

    _bubble = engine.Bubble(
      workspace: block.workspace,
      content: Text(
        getText(),
        style: const TextStyle(color: Colors.black),
      ),
      anchorXY: block.position,
      block: block,
    );
  }

  /// Hide warning bubble
  void hide() {
    _bubble?.dispose();
    _bubble = null;
  }

  /// Cleanup
  void dispose() {
    hide();
  }
}

/// Painter for the warning triangle icon
class _WarningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.yellow.shade700;

    final path = Path()
      ..moveTo(2, 15)
      ..lineTo(0.5, 12)
      ..lineTo(6.5, 1.7)
      ..lineTo(9.5, 1.7)
      ..lineTo(15.5, 12)
      ..lineTo(14, 15)
      ..close();

    canvas.drawPath(path, paint);

    final exPaint = Paint()..color = Colors.black;
    canvas.drawRect(const Rect.fromLTWH(7, 4.8, 2, 5.4), exPaint);
    canvas.drawRect(const Rect.fromLTWH(7, 11, 2, 2), exPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
*/
