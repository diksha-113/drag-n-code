// core_extensions.dart
// Optimized Flutter-style port of core/extensions.js
// This file implements a lightweight, idiomatic Dart version of Blockly
// Extensions: registering, mixing-in, mutators, and tooltip helpers.

// -----------------------------
// Minimal Block API (placeholder)
// -----------------------------
class Block {
  final String id;
  String? type;
  final Map<String, dynamic> _fields = {};
  final Map<String, dynamic> _props = {};
  Function? _tooltipFn;

  Block(this.id, {this.type});

  void mixin(Map<String, dynamic> mixinObj) {
    _props.addAll(mixinObj);
  }

  void setField(String name, dynamic value) => _fields[name] = value;
  dynamic getFieldValue(String name) => _fields[name];
  bool hasField(String name) => _fields.containsKey(name);

  void setTooltip(Function tooltipFn) {
    _tooltipFn = tooltipFn;
  }

  String? get tooltip => _tooltipFn == null ? null : _tooltipFn!();

  bool get hasDomToMutation => _props['domToMutation'] != null;
  bool get hasMutationToDom => _props['mutationToDom'] != null;
  bool get hasCompose => _props['compose'] != null;
  bool get hasDecompose => _props['decompose'] != null;

  @override
  String toString() => 'Block(id: $id, type: $type)';
}

// -----------------------------
// Mutator abstraction
// -----------------------------
class Mutator {
  final Function? domToMutation;
  final Function? mutationToDom;
  final Function? compose;
  final Function? decompose;

  Mutator(
      {this.domToMutation, this.mutationToDom, this.compose, this.decompose});
}

// -----------------------------
// Extensions core
// -----------------------------
typedef ExtensionFn = void Function(Block block);

class Extensions {
  static final Map<String, ExtensionFn> _registry = {};

  static void register(String name, ExtensionFn initFn) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Invalid extension name: "$name"');
    }
    if (_registry.containsKey(name)) {
      throw ArgumentError('Extension "$name" already registered');
    }
    _registry[name] = initFn;
  }

  static void registerMixin(String name, Map<String, dynamic> mixinObj) {
    register(name, (Block b) => b.mixin(mixinObj));
  }

  static void registerMutator(String name, Map<String, dynamic> mixinObj,
      {Function? helperFn, List<String>? blockList}) {
    final String prefix = 'Error when registering mutator "$name": ';

    _checkHasFunction(prefix, mixinObj['domToMutation'], 'domToMutation');
    _checkHasFunction(prefix, mixinObj['mutationToDom'], 'mutationToDom');

    final hasDialog = _checkMutatorDialog(mixinObj, prefix);

    register(name, (Block block) {
      if (hasDialog) {
        block.mixin({
          '__mutator': Mutator(
            domToMutation: mixinObj['domToMutation'],
            mutationToDom: mixinObj['mutationToDom'],
            compose: mixinObj['compose'],
            decompose: mixinObj['decompose'],
          )
        });
      }
      block.mixin(mixinObj);
      helperFn?.call(block);
    });
  }

  static void apply(String name, Block block, {bool isMutator = false}) {
    final fn = _registry[name];
    if (fn == null) {
      throw ArgumentError('Extension "$name" not found');
    }

    if (isMutator) {
      final props = _getMutatorProperties(block);
      if (props.isNotEmpty) {
        throw StateError(
            'Tried to apply mutator "$name" to a block that already has mutator properties');
      }
      fn(block);
      _checkBlockHasMutatorProperties(
          'Error after applying mutator "$name": ', block);
    } else {
      final oldProps = _getMutatorProperties(block);
      fn(block);
      if (!_mutatorPropertiesMatch(oldProps, block)) {
        throw StateError(
            'Applying non-mutator extension "$name" changed mutator properties');
      }
    }
  }

  static ExtensionFn buildTooltipForDropdown(
      String dropdownName, Map<String, String> lookupTable) {
    final checkedTypes = <String>{};

    return (Block block) {
      if (block.type != null && !checkedTypes.contains(block.type)) {
        _checkDropdownOptionsInTable(block, dropdownName, lookupTable);
        checkedTypes.add(block.type!);
      }

      block.setTooltip(() {
        final value = block.getFieldValue(dropdownName);
        final tooltip = lookupTable[value];
        if (tooltip == null) return null;
        return tooltip;
      });
    };
  }

  static ExtensionFn buildTooltipWithFieldValue(
      String msgTemplate, String fieldName) {
    return (Block block) {
      block.setTooltip(() {
        final replacement = block.getFieldValue(fieldName)?.toString() ?? '';
        return msgTemplate.replaceAll('%1', replacement);
      });
    };
  }

  // -----------------------------
  // Private helpers
  // -----------------------------
  static void _checkHasFunction(
      String errorPrefix, dynamic func, String propertyName) {
    if (func == null) {
      throw ArgumentError(
          '$errorPrefix missing required property "$propertyName"');
    }
    if (func is! Function) {
      throw ArgumentError(
          '$errorPrefix required property "$propertyName" must be a function');
    }
  }

  static bool _checkMutatorDialog(
      Map<String, dynamic> object, String errorPrefix) {
    final hasCompose = object.containsKey('compose');
    final hasDecompose = object.containsKey('decompose');
    if (hasCompose && hasDecompose) {
      if (object['compose'] is! Function) {
        throw ArgumentError('$errorPrefix compose must be a function');
      }
      if (object['decompose'] is! Function) {
        throw ArgumentError('$errorPrefix decompose must be a function');
      }
      return true;
    } else if (!hasCompose && !hasDecompose) {
      return false;
    } else {
      throw ArgumentError(
          '$errorPrefix Must have both or neither of "compose" and "decompose"');
    }
  }

  static void _checkBlockHasMutatorProperties(String errorPrefix, Block block) {
    if (!block.hasDomToMutation || !block.hasMutationToDom) {
      throw StateError(
          '$errorPrefix Applying a mutator didn\'t add required mutation functions');
    }
    if ((block.hasCompose && !block.hasDecompose) ||
        (!block.hasCompose && block.hasDecompose)) {
      throw StateError(
          '$errorPrefix Block must have both or neither of compose and decompose');
    }
  }

  static List<dynamic> _getMutatorProperties(Block block) {
    final result = <dynamic>[];
    if (block.hasDomToMutation) result.add(block._props['domToMutation']);
    if (block.hasMutationToDom) result.add(block._props['mutationToDom']);
    if (block.hasCompose) result.add(block._props['compose']);
    if (block.hasDecompose) result.add(block._props['decompose']);
    return result;
  }

  static bool _mutatorPropertiesMatch(
      List<dynamic> oldProperties, Block block) {
    final newProperties = _getMutatorProperties(block);
    if (oldProperties.length != newProperties.length) return false;
    for (var i = 0; i < oldProperties.length; i++) {
      if (oldProperties[i] != newProperties[i]) return false;
    }
    return true;
  }

  static void _checkDropdownOptionsInTable(
      Block block, String dropdownName, Map<String, String> lookupTable) {
    if (block.hasField(dropdownName)) {
      final current = block.getFieldValue(dropdownName);
      if (current != null && !lookupTable.containsKey(current)) {
        // Warning removed; production should use proper logging
      }
    }
  }
}

// -----------------------------
// Example usage (remove or adapt in production)
// -----------------------------
void main() {
  Extensions.registerMixin('markAsCustom', {'custom': true});
  Extensions.register(
      'fruitTooltip',
      Extensions.buildTooltipForDropdown('fruit', {
        'apple': 'A tasty red fruit',
        'banana': 'A long yellow fruit',
      }));

  final b = Block('b1', type: 'food_block');
  b.setField('fruit', 'apple');

  Extensions.apply('markAsCustom', b);
  Extensions.apply('fruitTooltip', b);

  // print('Tooltip: ${b.tooltip}');  <-- Removed for production
}
