/*import 'package:flutter/material.dart';
import 'workspace.dart';
import 'events.dart';
import 'workspace_comment.dart';

class ScratchBubble extends StatefulWidget {
  final WorkspaceComment comment;
  final double width;
  final double height;
  final double x;
  final double y;
  final bool minimized;

  const ScratchBubble({
    required this.comment,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    this.minimized = false,
    Key? key,
  }) : super(key: key);

  @override
  _ScratchBubbleState createState() => _ScratchBubbleState();
}

class _ScratchBubbleState extends State<ScratchBubble> {
  late double width;
  late double height;
  late bool isMinimized;
  late Offset position;

  late TextEditingController controller;

  @override
  void initState() {
    super.initState();

    width = widget.width;
    height = widget.height;
    isMinimized = widget.minimized;
    position = Offset(widget.x, widget.y);

    // ✅ FIX: use getText()
    controller = TextEditingController(text: widget.comment.getText());

    controller.addListener(() {
      widget.comment.setText(controller.text);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // -----------------------------
  // Actions
  // -----------------------------

  void toggleMinimize() {
    setState(() {
      isMinimized = !isMinimized;
    });
    widget.comment.setMinimized(isMinimized);
  }

  void deleteBubble() {
    widget.comment.dispose();
  }

  void resizeBubble(DragUpdateDetails details) {
    setState(() {
      width = (width + details.delta.dx).clamp(50.0, 500.0);
      height = (height + details.delta.dy).clamp(32.0, 400.0);
    });

    widget.comment.setSize(width, height);
    Events.fireCommentMove(widget.comment);
  }

  void moveBubble(DragUpdateDetails details) {
    setState(() {
      position += details.delta;
    });

    // ✅ FIX: use setPosition instead of moveTo
    widget.comment.setPosition(position.dx, position.dy);
    Events.fireCommentMove(widget.comment);
  }

  // -----------------------------
  // UI
  // -----------------------------

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: moveBubble,
        child: Container(
          width: width,
          height: isMinimized ? ScratchBubbleConstants.topBarHeight : height,
          decoration: BoxDecoration(
            color: Colors.yellow[200],
            border: Border.all(
              color: Colors.orange,
              width: ScratchBubbleConstants.borderWidth,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: ScratchBubbleConstants.topBarHeight,
                child: Container(
                  color: Colors.orange[300],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          isMinimized
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                        onPressed: toggleMinimize,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: deleteBubble,
                      ),
                    ],
                  ),
                ),
              ),

              // Editor
              if (!isMinimized)
                Positioned(
                  top: ScratchBubbleConstants.topBarHeight,
                  left: 0,
                  right: 0,
                  bottom: ScratchBubbleConstants.resizeSize,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    color: Colors.yellow[100],
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

              // Resize handle
              if (!isMinimized)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: resizeBubble,
                    child: const Icon(
                      Icons.drag_handle,
                      size: ScratchBubbleConstants.resizeSize,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------
// Constants
// ---------------------------------

class ScratchBubbleConstants {
  static const double borderWidth = 1;
  static const double topBarHeight = 32;
  static const double resizeSize = 16;
}
*/
