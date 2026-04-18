// lib/engine/workspace_comment_render_svg.dart
import 'package:flutter/material.dart';

class WorkspaceComment extends StatefulWidget {
  final String initialText;
  final Offset initialPosition;
  final bool rtl;

  const WorkspaceComment({
    super.key,
    required this.initialText,
    this.initialPosition = const Offset(100, 100),
    this.rtl = false,
  });

  @override
  State<WorkspaceComment> createState() => _WorkspaceCommentState();
}

class _WorkspaceCommentState extends State<WorkspaceComment> {
  late Offset position;
  late Size size;
  bool isMinimized = false;
  late TextEditingController controller;
  bool isDragging = false;
  bool isResizing = false;

  static const double minWidth = 50;
  static const double minHeight = 50;
  static const double topBarHeight = 32;
  static const double borderWidth = 1;
  static const double minimizeWidth = 200;
  static const double resizeHandleSize = 16;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
    size = const Size(200, 120);
    controller = TextEditingController(text: widget.initialText);
  }

  void toggleMinimize() {
    setState(() {
      isMinimized = !isMinimized;
      if (isMinimized) {
        size = Size(minimizeWidth, topBarHeight);
      } else {
        size = const Size(200, 120);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          if (!isMinimized) {
            final local = details.localPosition;
            // Check if touching resize handle
            if (local.dx > size.width - resizeHandleSize &&
                local.dy > size.height - resizeHandleSize) {
              isResizing = true;
            } else if (local.dy <= topBarHeight) {
              isDragging = true;
            }
          } else if (details.localPosition.dy <= topBarHeight) {
            isDragging = true;
          }
        },
        onPanUpdate: (details) {
          setState(() {
            if (isDragging) {
              position += details.delta;
            } else if (isResizing) {
              size = Size(
                (size.width + details.delta.dx)
                    .clamp(minWidth, double.infinity),
                (size.height + details.delta.dy)
                    .clamp(minHeight, double.infinity),
              );
            }
          });
        },
        onPanEnd: (_) {
          isDragging = false;
          isResizing = false;
        },
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: Colors.yellow[200],
            border:
                Border.all(width: borderWidth.toDouble(), color: Colors.black),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Top Bar
              Container(
                height: topBarHeight,
                decoration: BoxDecoration(
                  color: Colors.orange[300],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                          isMinimized ? Icons.expand_more : Icons.expand_less),
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      onPressed: toggleMinimize,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() {
                        size = Size.zero;
                      }),
                    ),
                  ],
                ),
              ),
              // Text Area
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
                      contentPadding: EdgeInsets.all(12),
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
