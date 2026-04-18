import 'package:flutter/material.dart';

/// Flyout button OR label (Scratch category labels like MOTION, LOOKS).
///
/// In Scratch:
/// - Labels have no background shadow.
/// - Buttons have rounded rectangles.
/// - Clicking runs a callback.
class FlyoutButton extends StatefulWidget {
  final String text;
  final bool isLabel;
  final bool isCategoryLabel;
  final String? cssClass;
  final Offset position;
  final double height;
  final double margin;
  final VoidCallback? onPressed;

  const FlyoutButton({
    super.key,
    required this.text,
    required this.position,
    this.isLabel = false,
    this.isCategoryLabel = false,
    this.cssClass,
    this.onPressed,
    this.height = 40,
    this.margin = 40,
  });

  /// ---- SAFE SIZE CALCULATORS ----
  double getWidth() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: isLabel ? 14 : 16,
          fontWeight: isCategoryLabel ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.width + (isLabel ? 20 : margin * 2);
  }

  double getHeight() => height;

  @override
  State<FlyoutButton> createState() => _FlyoutButtonState();
}

class _FlyoutButtonState extends State<FlyoutButton> {
  @override
  Widget build(BuildContext context) {
    final width = widget.getWidth();
    final height = widget.getHeight();

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: GestureDetector(
        onTap: () {
          if (!widget.isLabel && widget.onPressed != null) {
            widget.onPressed!();
          }
        },
        child: CustomPaint(
          painter: _FlyoutButtonPainter(
            isLabel: widget.isLabel,
            width: width,
            height: height,
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: Center(
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.isLabel ? 14 : 16,
                  fontWeight: widget.isCategoryLabel
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: widget.isLabel ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlyoutButtonPainter extends CustomPainter {
  final bool isLabel;
  final double width;
  final double height;

  _FlyoutButtonPainter({
    required this.isLabel,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isLabel) {
      // Shadow (fixed deprecation)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, width, height),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.2),
      );
    }

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(4),
      ),
      Paint()
        ..color = isLabel ? Colors.transparent : Colors.blueAccent.shade400,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
