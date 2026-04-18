// lib/vm/engine/comment.dart

import 'package:flutter/foundation.dart';

/// Simple UID generator (replacement for JS uid())
String generateUid() => UniqueKey().toString();

/// XML escape helper (replacement for xml-escape.js)
String xmlEscape(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

/// ------------------------------------------------------------
/// COMMENT MODEL  (Equivalent to comment.js)
/// ------------------------------------------------------------

class Comment {
  String id;
  String text;
  double x;
  double y;
  double width;
  double height;
  bool minimized;
  String? blockId; // null = not pinned to any block

  /// Constructor
  Comment({
    String? id,
    required this.text,
    required this.x,
    required this.y,
    required double width,
    required double height,
    this.minimized = false,
    this.blockId,
  })  : id = id ?? generateUid(),
        width = width < Comment.minWidth ? Comment.minWidth : width,
        height = height < Comment.minHeight ? Comment.minHeight : height;

  /// Convert comment → Scratch XML
  String toXML() {
    return '''
<comment 
    id="$id" 
    x="$x" 
    y="$y" 
    w="$width" 
    h="$height" 
    pinned="${blockId != null}" 
    minimized="$minimized">
    ${xmlEscape(text)}
</comment>
''';
  }

  /// ----------- CONSTANTS (Exact match with JS version) ------------

  static double get minWidth => 20;
  static double get minHeight => 20;

  static double get defaultWidth => 100;
  static double get defaultHeight => 100;
}
