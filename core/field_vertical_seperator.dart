import 'package:flutter/material.dart';

/// A vertical separator widget for block fields.
class FieldVerticalSeparator extends StatelessWidget {
  final double height;
  final double width;
  final Color color;

  const FieldVerticalSeparator({
    super.key, // ✅ super parameter used
    this.height = 24.0, // default block icon separator height
    this.width = 1.0,
    this.color = const Color(0xFFBDBDBD), // default secondary block color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color,
    );
  }
}
