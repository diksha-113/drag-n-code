/*// lib/engine/workspace_comments_manager.dart
import 'package:flutter/material.dart';
import '../core/workspace_comment.dart';
import 'workspace_comment_widget.dart';

class WorkspaceCommentsManager extends StatefulWidget {
  final List<WorkspaceComment> comments;

  const WorkspaceCommentsManager({super.key, required this.comments});

  @override
  State<WorkspaceCommentsManager> createState() =>
      _WorkspaceCommentsManagerState();
}

class _WorkspaceCommentsManagerState extends State<WorkspaceCommentsManager> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widget.comments
          .map((comment) => WorkspaceCommentWidget(
                comment: comment,
                onDelete: () {
                  setState(() {
                    comment.dispose();
                    widget.comments.remove(comment);
                  });
                },
                onMove: (newPos) {
                  setState(() {
                    comment.setPosition(newPos.dx, newPos.dy);
                  });
                },
              ))
          .toList(),
    );
  }
}
*/
