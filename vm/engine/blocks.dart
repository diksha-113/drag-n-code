import 'dart:convert';

import 'adapter.dart'; // You must implement this
import 'mutation_adapter.dart'; // You must implement this
import '../util/xml_escape.dart';
import 'monitor_record.dart';
import '../util/color.dart';
import 'blocks_execute_cache.dart';
import 'blocks_runtime_cache.dart';
import '../util/log.dart';
import '../util/variable_util.dart';
import '../util/get_monitor_id.dart';

/// Temporary Clone object to avoid errors during JS→Dart conversion.
class Clone {
  static dynamic simple(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List) return List<dynamic>.from(value);
    return value;
  }
}

class Blocks {
  final dynamic runtime;
  final bool forceNoGlow;
  String blocksXml = '<xml></xml>';

  Map<String, dynamic> _blocks = {};
  List<String> _scripts = [];

  Map<String, dynamic> _cache = {};

  Blocks(this.runtime, [bool? optNoGlow]) : forceNoGlow = optNoGlow ?? false {
    _cache = {
      'inputs': <String, dynamic>{},
      'procedureParamNames': <String, dynamic>{},
      'procedureDefinitions': <String, dynamic>{},
      '_executeCached': <String, dynamic>{},
      '_monitored': null,
      'scripts': <String, dynamic>{},
    };
  }

  // Public getters
  Map<String, dynamic> get allBlocks => _blocks;
  List<String> get allScripts => _scripts;

  static String get branchInputPrefix => 'SUBSTACK';

  Map<String, dynamic>? getBlock(String blockId) =>
      _blocks[blockId] as Map<String, dynamic>?;

  List<String> getScripts() => _scripts;

  String? getNextBlock(String? id) =>
      id == null ? null : _blocks[id]?['next'] as String?;

  String? getBranch(String? id, [int branchNum = 1]) {
    if (id == null) return null;
    final block = _blocks[id];
    if (block == null) return null;

    var inputName = branchInputPrefix;
    if (branchNum > 1) inputName += branchNum.toString();

    return (block['inputs'] as Map<String, dynamic>?)?[inputName]?['block']
        as String?;
  }

  String? getOpcode(Map<String, dynamic>? block) => block?['opcode'] as String?;

  Map<String, dynamic>? getFields(Map<String, dynamic>? block) =>
      block?['fields'] as Map<String, dynamic>?;

  Map<String, dynamic>? getInputs(Map<String, dynamic>? block) {
    if (block == null) return null;

    final inputsCache = _cache['inputs'] as Map<String, dynamic>;
    final blockId = block['id'] as String?;

    if (blockId != null && inputsCache.containsKey(blockId)) {
      return inputsCache[blockId] as Map<String, dynamic>?;
    }

    final result = <String, dynamic>{};
    final inputs = block['inputs'] as Map<String, dynamic>? ?? {};

    inputs.forEach((inputName, inputValue) {
      if (!inputName.startsWith(branchInputPrefix)) {
        result[inputName] = inputValue;
      }
    });

    if (blockId != null) inputsCache[blockId] = result;
    return result;
  }

  Map<String, dynamic>? getMutation(Map<String, dynamic>? block) =>
      block?['mutation'] as Map<String, dynamic>?;

  String? getTopLevelScript(String? id) {
    if (id == null) return null;
    var block = _blocks[id];
    if (block == null) return null;

    while (block['parent'] != null) {
      final parentId = block['parent'] as String?;
      if (parentId == null) break;
      block = _blocks[parentId];
      if (block == null) return null;
    }
    return block['id'] as String?;
  }

  String? getProcedureDefinition(String name) {
    final procDefs = _cache['procedureDefinitions'] as Map<String, dynamic>;
    if (procDefs.containsKey(name)) return procDefs[name] as String?;

    for (final entry in _blocks.entries) {
      final id = entry.key;
      final block = entry.value as Map<String, dynamic>;
      if (block['opcode'] == 'procedures_definition') {
        final internal = _getCustomBlockInternal(block);
        if (internal != null &&
            internal['mutation'] != null &&
            internal['mutation']['proccode'] == name) {
          procDefs[name] = id;
          return id;
        }
      }
    }

    procDefs[name] = null;
    return null;
  }

  List<dynamic>? getProcedureParamNamesAndIds(String name) {
    final all = getProcedureParamNamesIdsAndDefaults(name);
    return all?.sublist(0, 2);
  }

  List<dynamic>? getProcedureParamNamesIdsAndDefaults(String name) {
    final procParamCache =
        _cache['procedureParamNames'] as Map<String, dynamic>;
    if (procParamCache.containsKey(name))
      return procParamCache[name] as List<dynamic>?;

    for (final entry in _blocks.entries) {
      final block = entry.value as Map<String, dynamic>;
      if (block['opcode'] == 'procedures_prototype' &&
          block['mutation'] != null &&
          block['mutation']['proccode'] == name) {
        final mutation = block['mutation'] as Map<String, dynamic>;
        final names =
            jsonDecode(mutation['argumentnames'] as String) as List<dynamic>;
        final ids =
            jsonDecode(mutation['argumentids'] as String) as List<dynamic>;
        final defaults =
            jsonDecode(mutation['argumentdefaults'] as String) as List<dynamic>;
        final value = [names, ids, defaults];
        procParamCache[name] = value;
        return value;
      }
    }

    procParamCache[name] = null;
    return null;
  }

  Blocks duplicate() {
    final newBlocks = Blocks(runtime, forceNoGlow);
    newBlocks._blocks = Clone.simple(_blocks) as Map<String, dynamic>;
    newBlocks._scripts = Clone.simple(_scripts) as List<String>;
    return newBlocks;
  }

  List<Map<String, dynamic>> copyBlocks() {
    return _blocks.values.map((b) => Map<String, dynamic>.from(b)).toList();
  }

  /// ===================== Updated blocklyListen =====================
  void blocklyListen(Map<String, dynamic> e, [dynamic workspace]) {
    if (e is! Map) return;
    if (!(e.containsKey('blockId') ||
        e.containsKey('varId') ||
        e.containsKey('commentId'))) return;

    final stage = runtime.getTargetForStage();
    final editingTarget =
        workspace?.runtime.getEditingTarget() ?? runtime.getEditingTarget();

    if (e['element'] == 'stackclick') {
      runtime.toggleScript(e['blockId'], {'stackClick': true});
      return;
    }

    final String? type = e['type'] as String?;
    switch (type) {
      case 'create':
        final newBlocks = adapter(e) as List<dynamic>;
        for (var nb in newBlocks) createBlock(nb as Map<String, dynamic>);
        break;

      case 'change':
        changeBlock({
          'id': e['blockId'],
          'element': e['element'],
          'name': e['name'],
          'value': e['newValue']
        });
        break;

      case 'move':
        moveBlock({
          'id': e['blockId'],
          'oldParent': e['oldParentId'],
          'oldInput': e['oldInputName'],
          'newParent': e['newParentId'],
          'newInput': e['newInputName'],
          'newCoordinate': e['newCoordinate']
        });
        break;

      case 'dragOutside':
        runtime.emitBlockDragUpdate(e['isOutside']);
        break;

      case 'endDrag':
        runtime.emitBlockDragUpdate(false);
        if (e['isOutside'] == true) {
          final newBlocks = adapter(e) as List<dynamic>;
          runtime.emitBlockEndDrag(newBlocks, e['blockId']);
        }
        break;

      case 'delete':
        if (!_blocks.containsKey(e['blockId']) ||
            (_blocks[e['blockId']]?['shadow'] == true)) return;
        if (_blocks[e['blockId']]?['topLevel'] == true)
          runtime.quietGlow(e['blockId']);
        deleteBlock(e['blockId']);
        break;

      case 'var_create':
        final target = editingTarget ?? stage;
        if (!target.lookupVariableById(e['varId'])) {
          target.createVariable(
              e['varId'], e['varName'], e['varType'], e['isCloud']);
          emitProjectChanged();
        }
        break;

      case 'var_rename':
        final target = editingTarget ?? stage;
        target.renameVariable(e['varId'], e['newName']);
        target.blocks.updateBlocksAfterVarRename(e['varId'], e['newName']);
        emitProjectChanged();
        break;

      case 'var_delete':
        final target = editingTarget ?? stage;
        target.deleteVariable(e['varId']);
        emitProjectChanged();
        break;

      case 'comment_create':
      case 'comment_change':
      case 'comment_move':
      case 'comment_delete':
        if (editingTarget != null) {
          workspace?.handleCommentEvent?.call(e, editingTarget);
        }
        emitProjectChanged();
        break;

      default:
        break;
    }
  }

  void resetCache() {
    _cache['inputs'] = <String, dynamic>{};
    _cache['procedureParamNames'] = <String, dynamic>{};
    _cache['procedureDefinitions'] = <String, dynamic>{};
    _cache['_executeCached'] = <String, dynamic>{};
    _cache['_monitored'] = null;
    _cache['scripts'] = <String, dynamic>{};
  }

  void emitProjectChanged() {
    if (!forceNoGlow) runtime.emitProjectChanged();
  }

  // PLACEHOLDER METHODS
  void createBlock(Map<String, dynamic> block) {}
  void changeBlock(Map<String, dynamic> details) {}
  void moveBlock(Map<String, dynamic> details) {}
  void deleteBlock(String blockId) {}

  dynamic _getCustomBlockInternal(Map<String, dynamic> block) => block;
}
