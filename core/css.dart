// lib/engine/css.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import '../constants/colors.dart'; // BlocklyColours with coloursMap

class BlocklyCss {
  // Cursor types
  static const cursorOpen = 'handopen';
  static const cursorClosed = 'handclosed';
  static const cursorDelete = 'handdelete';

  static String currentCursor = '';
  static StyleSheet? styleSheet;
  static String mediaPath = '';

  /// Injects CSS into the DOM, replacing placeholders with media paths and colors
  static void inject(bool hasCss, String pathToMedia) {
    // Remove previous CSS if exists
    styleSheet?.ownerNode?.remove();

    mediaPath = pathToMedia.replaceAll(RegExp(r'[\\\/]$'), '');
    String cssText = '';

    if (hasCss) {
      cssText = content.join('\n');
    }

    // Replace path placeholders
    cssText = cssText.replaceAll('<<<PATH>>>', mediaPath);

    // Replace colors dynamically from BlocklyColours map
    BlocklyColours.coloursMap.forEach((key, value) {
      cssText = cssText.replaceAll('\$colour_$key', value);
    });

    // Inject into DOM
    final styleNode = StyleElement()..text = cssText;
    document.head!.insertBefore(styleNode, document.head!.firstChild);
    styleSheet = styleNode.sheet;
  }

  /// Full CSS content
  static const List<String> content = [
    // Workspace and SVG
    '.blocklySvg {',
    '  background-color: \$colour_workspace;',
    '  outline: none;',
    '  overflow: hidden;',
    '  position: absolute;',
    '  display: block;',
    '}',

    // Draggable blocks
    '.blocklyDraggable {',
    '  cursor: url("<<<PATH>>>/handopen.cur"), auto;',
    '  cursor: grab;',
    '  cursor: -webkit-grab;',
    '  cursor: -moz-grab;',
    '}',
    '.blocklyDragging {',
    '  cursor: url("<<<PATH>>>/handclosed.cur"), auto;',
    '  cursor: grabbing;',
    '  cursor: -webkit-grabbing;',
    '  cursor: -moz-grabbing;',
    '}',

    // Block categories
    '.blocklyBlockControl { background-color: \$colour_controlPrimary; }',
    '.blocklyBlockData { background-color: \$colour_dataPrimary; }',
    '.blocklyBlockDataLists { background-color: \$colour_dataLists; }',
    '.blocklyBlockSound { background-color: \$colour_soundPrimary; }',
    '.blocklyBlockMotion { background-color: \$colour_motionPrimary; }',
    '.blocklyBlockLooks { background-color: \$colour_looksPrimary; }',
    '.blocklyBlockEvent { background-color: \$colour_eventPrimary; }',
    '.blocklyBlockSensing { background-color: \$colour_sensingPrimary; }',
    '.blocklyBlockOperators { background-color: \$colour_operatorsPrimary; }',
    '.blocklyBlockPen { background-color: \$colour_penPrimary; }',
    '.blocklyBlockMore { background-color: \$colour_morePrimary; }',

    // Hover/focus effects
    '.blocklyBlockControl:hover,',
    '.blocklyBlockData:hover,',
    '.blocklyBlockMotion:hover {',
    '  filter: brightness(1.1);',
    '}',

    // Selection outline
    '.blocklySelected {',
    '  stroke: #ffa500;',
    '  stroke-width: 2px;',
    '}',

    // Comments
    '.blocklyCommentBubble {',
    '  background-color: #ffffcc;',
    '  border: 1px solid #cccccc;',
    '  padding: 4px;',
    '}'
  ];
}
