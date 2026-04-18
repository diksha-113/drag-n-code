import 'package:flutter/material.dart';

/// Flutter version of Blockly.FieldImage
///
/// Used for showing images/icons inside blocks (like Scratch flag icon,
/// motion arrow, looks icons, sound icon, etc.)
class FieldImage extends StatelessWidget {
  final String src; // Image path
  final double width; // Image width
  final double height; // Image height
  final String? altText; // Optional alt text
  final bool flipRTL; // Should flip icon in RTL?
  final bool visible; // Should be visible? (same as Blockly.visible_)

  const FieldImage({
    super.key,
    required this.src,
    required this.width,
    required this.height,
    this.altText,
    this.flipRTL = false,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    Widget img = Image.asset(
      src,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );

    // Flip horizontally for RTL
    if (flipRTL && Directionality.of(context) == TextDirection.rtl) {
      img = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(3.1415),
        child: img,
      );
    }

    return img;
  }
}
