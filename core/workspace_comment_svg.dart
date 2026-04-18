// lib/engine/workspace_comment_svg.dart
import 'package:flutter/material.dart';
import '../models/block_model.dart';

class WorkspaceComment extends StatefulWidget {
  final String id;
  final String content;
  final double width;
  final double height;
  final bool minimized;
  final bool movable;

  final Function(String id)? onDelete;
  final Function(String id, Offset newPosition)? onMove;

  const WorkspaceComment({
    Key? key,
    required this.id,
    required this.content,
    this.width = 200,
    this.height = 100,
    this.minimized = false,
    this.movable = true,
    this.onDelete,
    this.onMove,
  }) : super(key: key);

  @override
  _WorkspaceCommentState createState() => _WorkspaceCommentState();
}

class _WorkspaceCommentState extends State<WorkspaceComment> {
  late Offset position;
  bool selected = false;
  bool dragging = false;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    position = const Offset(50, 50); // Default position
    controller = TextEditingController(text: widget.content);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.movable) return;
    setState(() {
      position += details.delta;
    });
    if (widget.onMove != null) widget.onMove!(widget.id, position);
  }

  void _onTap() {
    setState(() {
      selected = !selected;
    });
  }

  void _onDelete() {
    if (widget.onDelete != null) widget.onDelete!(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: _onTap,
        onPanUpdate: _onDragUpdate,
        child: Container(
          width: widget.width,
          height: widget.minimized ? 30 : widget.height,
          decoration: BoxDecoration(
            color: Colors.yellow[200],
            border: Border.all(
              color: selected ? Colors.blue : Colors.orange,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              if (!widget.minimized)
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              Positioned(
                right: 0,
                top: 0,
                child: Row(
                  children: [
                    if (!widget.minimized)
                      IconButton(
                        icon: const Icon(Icons.minimize, size: 16),
                        onPressed: () {
                          setState(() {
                            dragging = false;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: _onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
