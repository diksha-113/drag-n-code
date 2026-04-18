/*// lib/engine/workspace_comment_widget.dart
import 'package:flutter/material.dart';
import '../core/workspace_comment.dart';

class WorkspaceCommentWidget extends StatefulWidget {
  final WorkspaceComment comment;
  final Function()? onDelete;
  final Function(Offset newPosition)? onMove;

  const WorkspaceCommentWidget({
    super.key,
    required this.comment,
    this.onDelete,
    this.onMove,
  });

  @override
  State<WorkspaceCommentWidget> createState() => _WorkspaceCommentWidgetState();
}

class _WorkspaceCommentWidgetState extends State<WorkspaceCommentWidget> {
  late Offset position;
  late Size size;
  bool isDragging = false;
  bool isResizing = false;
  bool isMinimized = false;
  late TextEditingController controller;

  static const double minWidth = 50;
  static const double minHeight = 50;
  static const double topBarHeight = 32;
  static const double borderWidth = 1;
  static const double resizeHandleSize = 16;

  @override
  void initState() {
    super.initState();
    position = widget.comment.getXY();
    size = Size(widget.comment.getWidth(), widget.comment.getHeight());
    isMinimized = widget.comment.isMinimized();
    controller = widget.comment.controller;
  }

  void toggleMinimize() {
    setState(() {
      isMinimized = !isMinimized;
      widget.comment.setMinimized(isMinimized);
      if (isMinimized) {
        size = Size(200, topBarHeight);
      } else {
        size = Size(widget.comment.getWidth(), widget.comment.getHeight());
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    final local = details.localPosition;
    if (!isMinimized &&
        local.dx > size.width - resizeHandleSize &&
        local.dy > size.height - resizeHandleSize) {
      isResizing = true;
    } else if (local.dy <= topBarHeight) {
      isDragging = true;
    } else if (isMinimized && local.dy <= topBarHeight) {
      isDragging = true;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (isDragging) {
        position += details.delta;
        widget.comment.setPosition(position.dx, position.dy);
        if (widget.onMove != null) widget.onMove!(position);
      } else if (isResizing) {
        size = Size(
          (size.width + details.delta.dx).clamp(minWidth, double.infinity),
          (size.height + details.delta.dy).clamp(minHeight, double.infinity),
        );
        widget.comment.setSize(size.width, size.height);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    isDragging = false;
    isResizing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          width: size.width,
          height: isMinimized ? topBarHeight : size.height,
          decoration: BoxDecoration(
            color: Colors.yellow[200],
            border: Border.all(width: borderWidth, color: Colors.black),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              // Top bar
              Container(
                height: topBarHeight,
                decoration: BoxDecoration(
                  color: Colors.orange[300],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        isMinimized ? Icons.expand_more : Icons.expand_less,
                      ),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      onPressed: toggleMinimize,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ),
              // Text area
              if (!isMinimized)
                Positioned(
                  top: topBarHeight,
                  left: borderWidth,
                  right: borderWidth,
                  bottom: borderWidth,
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),
              // Resize handle
              if (!isMinimized)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(Icons.drag_handle, size: resizeHandleSize),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
