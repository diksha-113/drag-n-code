/*import 'package:flutter/material.dart';
import 'workspace.dart'; // Needed for Workspace reference

class WorkspaceComment {
  final Workspace workspace; // Reference to parent workspace
  String id;
  String? blockId; // optional block association
  Offset xy; // x, y position in workspace coordinates
  double width;
  double height;
  bool minimized;
  String content;
  bool deletable;
  bool movable;
  bool rtl;

  // ✅ Added for ScratchBubble
  late TextEditingController controller;

  WorkspaceComment({
    required this.workspace, // required
    this.blockId, // optional
    String? id,
    this.content = '',
    this.height = 100,
    this.width = 100,
    this.minimized = false,
    this.deletable = true,
    this.movable = true,
    this.rtl = false,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        xy = const Offset(0, 0) {
    controller = TextEditingController(text: content);
  }

  /// --- Position ---
  void moveBy(double dx, double dy) {
    xy = xy.translate(dx, dy);
  }

  void setPosition(double x, double y) {
    xy = Offset(x, y);
  }

  Offset get position => xy;

  /// ✅ Added to fix comment_events.dart
  Offset getXY() => xy;

  /// --- NEW: getPosition for workspace.dart sorting ---
  Offset getPosition() => xy;

  /// --- Size ---
  double getHeight() => height;
  void setHeight(double h) => height = h;

  double getWidth() => width;
  void setWidth(double w) => width = w;

  /// ✅ Added setSize to fix comment_events.dart errors
  void setSize(double w, double h) {
    width = w;
    height = h;
  }

  /// ✅ Added to fix 'toXmlWithXY' error
  Map<String, dynamic> toXmlWithXY() => toXml(includeId: true);

  Map<String, double> getHeightWidth() => {'height': height, 'width': width};

  /// --- Flags ---
  bool isDeletable() => deletable;
  void setDeletable(bool d) => deletable = d;

  bool isMovable() => movable;
  void setMovable(bool m) => movable = m;

  bool isMinimized() => minimized;
  void setMinimized(bool m) => minimized = m;

  /// --- Text ---
  String getText() => content;
  void setText(String text) {
    content = text;
    controller.text = text; // keep controller in sync
  }

  String getLabelText() {
    const maxLength = 12;
    if (content.length <= maxLength) return content;
    return rtl
        ? '\u2026' + content.substring(0, maxLength)
        : content.substring(0, maxLength) + '\u2026';
  }

  /// --- Serialization ---
  Map<String, dynamic> toXml({bool includeId = true}) {
    return {
      if (includeId) 'id': id,
      if (blockId != null) 'blockId': blockId,
      'x': xy.dx.round(),
      'y': xy.dy.round(),
      'h': height,
      'w': width,
      'minimized': minimized,
      'text': content,
    };
  }

  static WorkspaceComment fromXml(Map<String, dynamic> xml, Workspace ws) {
    final comment = WorkspaceComment(
      workspace: ws,
      blockId: xml['blockId'],
      id: xml['id'] as String?,
      content: xml['text'] ?? '',
      height: (xml['h'] ?? 100).toDouble(),
      width: (xml['w'] ?? 100).toDouble(),
      minimized: xml['minimized'] ?? false,
    );

    final x = xml['x'];
    final y = xml['y'];
    if (x != null && y != null) {
      comment.xy = Offset((x as num).toDouble(), (y as num).toDouble());
    }

    // ✅ Keep controller in sync
    comment.controller.text = comment.content;

    return comment;
  }

  /// --- Dispose ---
  void dispose() {
    controller.dispose(); // ✅ Dispose controller
    workspace.removeTopComment(this);
  }
}
*/
