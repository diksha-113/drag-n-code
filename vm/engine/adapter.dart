// lib/vm/engine/adapter.dart

import 'package:xml/xml.dart';
import '../util/uid.dart';
import './mutation_adapter.dart';

/// Representation of a converted block
class Block {
  String id;
  String? opcode;
  Map<String, dynamic> inputs = {};
  Map<String, dynamic> fields = {};
  String? next;
  bool topLevel;
  String? parent;
  bool shadow;
  String? x;
  String? y;
  String? comment;
  dynamic mutation;

  Block({
    required this.id,
    this.opcode,
    required this.topLevel,
    this.parent,
    required this.shadow,
    this.x,
    this.y,
  });
}

/// ---------------------------------------------------------------------------
/// Convert a single <block> or <shadow> XML DOM node into a Block object tree.
/// Equivalent to JS domToBlock
/// ---------------------------------------------------------------------------
void domToBlock(
  XmlElement blockDOM,
  Map<String, Block> blocks,
  bool isTopBlock,
  String? parent,
) {
  // Ensure ID exists
  var id = blockDOM.getAttribute('id') ?? uid();
  var type = blockDOM.getAttribute('type');
  var x = blockDOM.getAttribute('x');
  var y = blockDOM.getAttribute('y');

  // Create block model
  final block = Block(
    id: id,
    opcode: type,
    topLevel: isTopBlock,
    parent: parent,
    shadow: blockDOM.name.local == 'shadow',
    x: x,
    y: y,
  );

  blocks[id] = block;

  // Process children
  for (final xmlChild in blockDOM.children.whereType<XmlElement>()) {
    XmlElement? childBlockNode;
    XmlElement? childShadowNode;

    // Look for <block> or <shadow> inside the child
    for (final gc in xmlChild.children.whereType<XmlElement>()) {
      final name = gc.name.local.toLowerCase();
      if (name == 'block') childBlockNode = gc;
      if (name == 'shadow') childShadowNode = gc;
    }

    // Use shadow if no real block
    childBlockNode ??= childShadowNode;

    switch (xmlChild.name.local.toLowerCase()) {
      case 'field':
        final fieldName = xmlChild.getAttribute('name');
        final fieldId = xmlChild.getAttribute('id');
        final fieldValue = xmlChild.text;

        if (fieldName != null) {
          block.fields[fieldName] = {
            'name': fieldName,
            'id': fieldId,
            'value': fieldValue,
          };

          final varType = xmlChild.getAttribute('variabletype');
          if (varType != null) {
            block.fields[fieldName]['variableType'] = varType;
          }
        }
        break;

      case 'comment':
        block.comment = xmlChild.getAttribute('id');
        break;

      case 'value':
      case 'statement':
        if (childBlockNode != null) {
          domToBlock(childBlockNode!, blocks, false, block.id);

          if (childShadowNode != null && childShadowNode != childBlockNode) {
            domToBlock(childShadowNode!, blocks, false, block.id);
          }
        }

        final inputName = xmlChild.getAttribute('name');
        if (inputName != null && childBlockNode != null) {
          block.inputs[inputName] = {
            'name': inputName,
            'block': childBlockNode!.getAttribute('id'),
            'shadow': childShadowNode?.getAttribute('id'),
          };
        }
        break;

      case 'next':
        if (childBlockNode != null) {
          domToBlock(childBlockNode!, blocks, false, block.id);
          block.next = childBlockNode!.getAttribute('id');
        }
        break;

      case 'mutation':
        block.mutation = mutationAdapter(xmlChild);
        break;
    }
  }
}

/// ---------------------------------------------------------------------------
/// Convert all <block> elements inside the workspace into a list of Blocks.
/// Equivalent to JS domToBlocks
/// ---------------------------------------------------------------------------
List<Block> domToBlocks(List<XmlNode> blocksDOM) {
  final blocks = <String, Block>{};

  for (final node in blocksDOM.whereType<XmlElement>()) {
    final name = node.name.local.toLowerCase();
    if (name == 'block' || name == 'shadow') {
      domToBlock(node, blocks, true, null);
    }
  }

  return blocks.values.toList();
}

/// ---------------------------------------------------------------------------
/// Main adapter function — SAME as JS module.exports = adapter;
/// e.xml.outerHTML must exist
/// ---------------------------------------------------------------------------
List<Block>? adapter(dynamic e) {
  if (e == null || e.xml == null) return null;

  final xmlString = e.xml.outerHTML;
  final parsedDoc = XmlDocument.parse(xmlString);

  return domToBlocks(parsedDoc.children);
}
