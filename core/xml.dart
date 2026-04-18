/*import 'package:xml/xml.dart';
import 'workspace.dart' as ws;
import 'variable_model.dart';
import 'block.dart';
import 'block_svg.dart' as svg;

class XmlEngine {
  /// ---------------- Workspace → XML ----------------
  static XmlElement workspaceToDom(ws.Workspace workspace) {
    final builder = XmlBuilder();

    builder.element('xml', nest: () {
      // ---------------- Variables ----------------
      builder.element('variables', nest: () {
        for (var variable in workspace.getAllVariables()) {
          builder.element(
            'variable',
            attributes: {
              'type': variable.type ?? '',
              'id': variable.id ?? '',
            },
            nest: variable.name ?? '',
          );
        }
      });

      // ---------------- Top Blocks ----------------
      for (var block in workspace.getTopBlocks(false)) {
        final blockXml = blockToDom(block);
        builder.xml(blockXml.toXmlString());
      }
    });

    return builder.buildDocument().rootElement;
  }

  /// ---------------- Block → XML ----------------
  static XmlElement blockToDom(svg.BlockSvg block) {
    final builder = XmlBuilder();

    builder.element('block', nest: () {
      builder.attribute('type', block.prototypeName ?? 'unknown');
      builder.attribute('id', block.id ?? '');

      // Position
      builder.attribute('x', block.position.dx.toString());
      builder.attribute('y', block.position.dy.toString());

      // Mutation
      final mutation = block.mutationToString();
      if (mutation.isNotEmpty) {
        builder.element('mutation', nest: mutation);
      }

      // Nested children (next, inputs)
      if (block.nextBlock != null) {
        builder.element('next', nest: () {
          builder.xml(blockToDom(block.nextBlock!).toXmlString());
        });
      }

      for (var inputName in block.inputs.keys) {
        final inputBlock = block.inputs[inputName];
        if (inputBlock != null) {
          builder.element('value', attributes: {'name': inputName}, nest: () {
            builder.xml(blockToDom(inputBlock).toXmlString());
          });
        }
      }

      // Statement inputs (like loops or if statements)
      for (var stmtName in block.statementInputs.keys) {
        final stmtBlock = block.statementInputs[stmtName];
        if (stmtBlock != null) {
          builder.element('statement', attributes: {'name': stmtName},
              nest: () {
            builder.xml(blockToDom(stmtBlock).toXmlString());
          });
        }
      }
    });

    return builder.buildDocument().rootElement;
  }

  /// ---------------- DOM → Text ----------------
  static String domToText(XmlElement dom) => dom.toXmlString();

  /// ---------------- Text → DOM ----------------
  static XmlElement textToDom(String xmlText) =>
      XmlDocument.parse(xmlText).rootElement;

  /// ---------------- XML → Workspace ----------------
  static void domToWorkspace(XmlElement xml, ws.Workspace workspace) {
    workspace.clear();

    // Variables
    final variablesNode = xml.getElement('variables');
    if (variablesNode != null) {
      for (final v in variablesNode.findElements('variable')) {
        workspace.createVariable(
          v.text ?? '',
          type: v.getAttribute('type') ?? '',
          id: v.getAttribute('id') ?? '',
        );
      }
    }

    // Blocks
    for (final blockXml in xml.findElements('block')) {
      _domToBlockRecursive(blockXml, workspace);
    }
  }

  /// ---------------- Helper: XML block → Workspace block (recursive) ----------------
  static svg.BlockSvg _domToBlockRecursive(
      XmlElement xml, ws.Workspace workspace) {
    final type = xml.getAttribute('type') ?? 'unknown';
    final id = xml.getAttribute('id') ?? '';
    final block = workspace.newBlock(type, id);

    // Position
    final x = double.tryParse(xml.getAttribute('x') ?? '0') ?? 0;
    final y = double.tryParse(xml.getAttribute('y') ?? '0') ?? 0;
    block.moveBy(x, y);

    workspace.addBlock(block);

    // Mutation
    final mutationNode = xml.getElement('mutation');
    if (mutationNode != null) {
      block.applyMutation(mutationNode.innerText);
    }

    // Handle 'next'
    final nextNode = xml.getElement('next');
    if (nextNode != null) {
      final nextBlockXml = nextNode.getElement('block');
      if (nextBlockXml != null) {
        block.nextBlock = _domToBlockRecursive(nextBlockXml, workspace);
      }
    }

    // Handle 'value' inputs
    for (final valueNode in xml.findElements('value')) {
      final name = valueNode.getAttribute('name');
      final childBlockXml = valueNode.getElement('block');
      if (name != null && childBlockXml != null) {
        block.inputs[name] = _domToBlockRecursive(childBlockXml, workspace);
      }
    }

    // Handle 'statement' inputs
    for (final stmtNode in xml.findElements('statement')) {
      final name = stmtNode.getAttribute('name');
      final childBlockXml = stmtNode.getElement('block');
      if (name != null && childBlockXml != null) {
        block.statementInputs[name] =
            _domToBlockRecursive(childBlockXml, workspace);
      }
    }

    return block;
  }
}
*/
