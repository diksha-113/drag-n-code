// lib/engine/icon.dart
import 'package:flutter/material.dart';

/// Represents a bubble attached to a block icon.
class Bubble {
  final Widget content;
  final Color color;
  OverlayEntry? _overlayEntry;

  Bubble({required this.content, this.color = Colors.blue});

  /// Show the bubble at the given position.
  void show(BuildContext context, Offset position) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
              ],
            ),
            child: content,
          ),
        ),
      ),
    );

    Overlay.of(context)!.insert(_overlayEntry!);
  }

  /// Hide the bubble.
  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  bool get isVisible => _overlayEntry != null;

  /// Update the bubble's position if visible
  void updatePosition(BuildContext context, Offset position) {
    if (!isVisible) return;
    hide();
    show(context, position);
  }
}

/// Icon attached to a block, similar to Scratch.
class BlockIcon extends StatefulWidget {
  final double size;
  final Color color;
  final bool collapseHidden;
  final Widget iconContent;
  final Bubble? bubble;
  final Offset initialPosition;
  final bool rtl;

  const BlockIcon({
    super.key,
    this.size = 17,
    this.color = Colors.blue,
    this.collapseHidden = true,
    required this.iconContent,
    this.bubble,
    this.initialPosition = Offset.zero,
    this.rtl = false,
  });

  @override
  State<BlockIcon> createState() => _BlockIconState();
}

class _BlockIconState extends State<BlockIcon> {
  Offset iconPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    iconPosition = widget.initialPosition;
  }

  /// Toggle bubble visibility on tap
  void _toggleBubble() {
    if (widget.bubble == null) return;

    if (widget.bubble!.isVisible) {
      widget.bubble!.hide();
    } else {
      final position = iconPosition + Offset(widget.size / 2, widget.size / 2);
      widget.bubble!.show(context, position);
    }
  }

  /// Update the icon's position dynamically
  void updatePosition(Offset newPosition) {
    setState(() {
      iconPosition = newPosition;
    });

    if (widget.bubble?.isVisible ?? false) {
      final bubblePos = iconPosition + Offset(widget.size / 2, widget.size / 2);
      widget.bubble!.updatePosition(context, bubblePos);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.collapseHidden) {
      // You can link this to a block's collapsed state
    }

    return Positioned(
      left: widget.rtl ? null : iconPosition.dx,
      right: widget.rtl ? iconPosition.dx : null,
      top: iconPosition.dy,
      child: GestureDetector(
        onTap: _toggleBubble,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
          child: Center(child: widget.iconContent),
        ),
      ),
    );
  }
}
