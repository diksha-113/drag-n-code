// lib/core/trashcan.dart
import 'package:flutter/material.dart';

/// ------------------- TrashCan Widget -------------------
class TrashCan extends StatefulWidget {
  final VoidCallback? onTap;
  final double size;
  final bool isOpen;

  const TrashCan({super.key, this.onTap, this.size = 60, this.isOpen = false});

  @override
  State<TrashCan> createState() => _TrashCanState();
}

class _TrashCanState extends State<TrashCan>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0,
      upperBound: 0.3,
    );

    // Set initial lid state
    if (widget.isOpen) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant TrashCan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base trash can
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Lid with rotation animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -0.3 * _controller.value,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: widget.size + 10,
                    height: 10,
                    color: Colors.grey[800],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// ------------------- WorkspaceWithTrash -------------------
class WorkspaceWithTrash extends StatefulWidget {
  const WorkspaceWithTrash({super.key});

  @override
  State<WorkspaceWithTrash> createState() => _WorkspaceWithTrashState();
}

class _WorkspaceWithTrashState extends State<WorkspaceWithTrash> {
  List<String> blocks = ['Block A', 'Block B', 'Block C'];
  bool isHoveringTrash = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Stack(
        children: [
          // Workspace blocks
          ...blocks.asMap().entries.map((entry) {
            int index = entry.key;
            String block = entry.value;
            return Positioned(
              left: 50.0,
              top: 50.0 + index * 70,
              child: Draggable<String>(
                data: block,
                feedback: Material(
                  child: Container(
                    width: 100,
                    height: 50,
                    color: Colors.blueAccent,
                    alignment: Alignment.center,
                    child: Text(block,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
                childWhenDragging: Container(
                  width: 100,
                  height: 50,
                  color: Colors.blue.shade200,
                  alignment: Alignment.center,
                  child: Text(block),
                ),
                child: Container(
                  width: 100,
                  height: 50,
                  color: Colors.blueAccent,
                  alignment: Alignment.center,
                  child:
                      Text(block, style: const TextStyle(color: Colors.white)),
                ),
              ),
            );
          }).toList(),

          // Trash Can with DragTarget
          Positioned(
            bottom: 20,
            right: 20,
            child: DragTarget<String>(
              onWillAccept: (data) {
                setState(() {
                  isHoveringTrash = true;
                });
                return true;
              },
              onLeave: (data) {
                setState(() {
                  isHoveringTrash = false;
                });
              },
              onAccept: (data) {
                setState(() {
                  blocks.remove(data);
                  isHoveringTrash = false;
                });
              },
              builder: (context, candidateData, rejectedData) {
                return TrashCan(
                  isOpen: isHoveringTrash,
                  onTap: () {
                    print('Inspect Trash: ${blocks.length} blocks remaining');
                  },
                  size: 60,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
