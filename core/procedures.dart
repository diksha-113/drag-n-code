/*import 'workspace.dart';
import 'block_svg.dart' as svg;
import 'events.dart';
import 'package:xml/xml.dart';

class Procedures {
  /// Ensure unique procedure names.
  static String findLegalName(String name, svg.BlockSvg block) {
    if (block.isInFlyout) return name;

    while (!isLegalName(name, block.workspace, block)) {
      var match = RegExp(r'^(.*?)(\d+)$').firstMatch(name);
      if (match == null) {
        name += '2';
      } else {
        name = '${match[1]}${int.parse(match[2]!) + 1}';
      }
    }
    return name;
  }

  /// Check if name is legal
  static bool isLegalName(
    String name,
    Workspace ws, [
    svg.BlockSvg? exclude,
  ]) {
    return !isNameUsed(name, ws, exclude);
  }

  /// Return if the given name is used
  static bool isNameUsed(
    String name,
    Workspace ws, [
    svg.BlockSvg? exclude,
  ]) {
    for (var block in ws.getAllBlocks(true)) {
      if (block == exclude) continue;

      final def = block.getProcedureDef();
      if (def != null && def[0] == name) return true;
    }
    return false;
  }

  /// Return all procedure definitions
  static List<List<List<dynamic>>> allProcedures(Workspace ws) {
    List<List<dynamic>> noReturn = [];
    List<List<dynamic>> withReturn = [];

    for (var block in ws.getAllBlocks(true)) {
      final tuple = block.getProcedureDef();
      if (tuple != null) {
        (tuple[2] ? withReturn : noReturn).add(tuple);
      }
    }

    noReturn.sort((a, b) => a[0].compareTo(b[0]));
    withReturn.sort((a, b) => a[0].compareTo(b[0]));

    return [noReturn, withReturn];
  }

  /// Return all callers of a procedure
  static List<svg.BlockSvg> getCallers(
    String name,
    Workspace ws,
    svg.BlockSvg defBlock, {
    bool allowRecursive = false,
  }) {
    final List<svg.BlockSvg> allBlocks = [];

    for (var block in ws.getTopBlocks(true)) {
      if (block.id == defBlock.id && !allowRecursive) continue;

      allBlocks.addAll(
        block.getDescendants(true).whereType<svg.BlockSvg>(), // ✅ FIX
      );
    }

    return allBlocks
        .where(
          (b) =>
              b.prototypeName == 'procedures_call' && b.getProcCode() == name,
        )
        .toList();
  }

  /// Create a mutation for a new procedure
  static XmlElement newProcedureMutation() {
    return XmlDocument.parse('''
<mutation
  proccode="doSomething"
  argumentids="[]"
  argumentnames="[]"
  argumentdefaults="[]"
  warp="false"/>
''').rootElement;
  }

  /// Flyout category blocks for procedures
  static List<XmlElement> flyoutCategory(Workspace ws) {
    final xmlList = <XmlElement>[];

    addCreateButton(ws, xmlList);

    final mutations = allProcedureMutations(ws)
      ..sort(
        (a, b) =>
            a.getAttribute('proccode')!.compareTo(b.getAttribute('proccode')!),
      );

    for (var mutation in mutations) {
      final block = XmlElement(XmlName('block'));
      block.setAttribute('type', 'procedures_call');
      block.setAttribute('gap', '16');
      block.children.add(mutation);
      xmlList.add(block);
    }

    return xmlList;
  }

  static void addCreateButton(Workspace ws, List<XmlElement> xmlList) {
    final button = XmlElement(XmlName('button'));
    button.setAttribute('text', 'Make a Block...');
    button.setAttribute('callbackKey', 'CREATE_PROCEDURE');

    ws.registerButtonCallback('CREATE_PROCEDURE', () {
      createProcedureDefCallback(ws);
    });

    xmlList.add(button);
  }

  static void createProcedureDefCallback(Workspace ws) {
    externalProcedureDefCallback(
      newProcedureMutation(),
      (_) {},
    );
  }

  static void externalProcedureDefCallback(
    XmlElement mutation,
    void Function(XmlElement) callback,
  ) {
    print('External procedure editor must be overridden.');
  }

  static List<XmlElement> allProcedureMutations(Workspace ws) {
    return [];
  }
}

/// -------------------- BlockSvg PROCEDURE STUBS --------------------
extension ProcedureBlockStub on svg.BlockSvg {
  /// [name, args, hasReturn]
  List<dynamic>? getProcedureDef() {
    final proto = prototypeName;
    if (proto != null && proto.startsWith('procedures_')) {
      return [proto, [], false];
    }
    return null;
  }

  String? getProcCode() {
    if (prototypeName == 'procedures_call') return id;
    return null;
  }

  bool get isInFlyout => workspace.isFlyout;
}
*/
