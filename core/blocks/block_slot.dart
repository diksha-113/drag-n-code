import 'package:flutter/material.dart';

class BlockSlot extends StatelessWidget {
  final GlobalKey slotKey;
  final double height;

  const BlockSlot({
    super.key,
    required this.slotKey,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: slotKey,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
