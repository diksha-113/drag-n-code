// lib/blocks_vertical/data.dart
import '../util/cast.dart';
import '../engine/runtime.dart';
import '../engine/util.dart';
import '../extension_support/block_type.dart';
import '../extension_support/argument_type.dart';

class Scratch3DataBlocks {
  final Runtime runtime;

  Scratch3DataBlocks(this.runtime);

  /// Block primitives mapping
  Map<String, Map<String, dynamic>> getPrimitivesMetadata() {
    return {
      'data_variable': {
        'func': getVariable,
        'type': BlockType.reporter.value,
        'arguments': {'VARIABLE': ArgumentType.string.value},
      },
      'data_setvariableto': {
        'func': setVariableTo,
        'type': BlockType.command.value,
        'arguments': {
          'VARIABLE': ArgumentType.string.value,
          'VALUE': ArgumentType.number.value
        },
      },
      'data_changevariableby': {
        'func': changeVariableBy,
        'type': BlockType.command.value,
        'arguments': {
          'VARIABLE': ArgumentType.string.value,
          'VALUE': ArgumentType.number.value
        },
      },
      'data_hidevariable': {
        'func': hideVariable,
        'type': BlockType.command.value,
        'arguments': {'VARIABLE': ArgumentType.string.value},
      },
      'data_showvariable': {
        'func': showVariable,
        'type': BlockType.command.value,
        'arguments': {'VARIABLE': ArgumentType.string.value},
      },
      'data_listcontents': {
        'func': getListContents,
        'type': BlockType.reporter.value,
        'arguments': {'LIST': ArgumentType.string.value},
      },
      'data_addtolist': {
        'func': addToList,
        'type': BlockType.command.value,
        'arguments': {
          'LIST': ArgumentType.string.value,
          'ITEM': ArgumentType.string.value
        },
      },
      'data_deleteoflist': {
        'func': deleteOfList,
        'type': BlockType.command.value,
        'arguments': {
          'LIST': ArgumentType.string.value,
          'INDEX': ArgumentType.number.value
        },
      },
      'data_deletealloflist': {
        'func': deleteAllOfList,
        'type': BlockType.command.value,
        'arguments': {'LIST': ArgumentType.string.value},
      },
      'data_insertatlist': {
        'func': insertAtList,
        'type': BlockType.command.value,
        'arguments': {
          'LIST': ArgumentType.string.value,
          'INDEX': ArgumentType.number.value,
          'ITEM': ArgumentType.string.value
        },
      },
      'data_replaceitemoflist': {
        'func': replaceItemOfList,
        'type': BlockType.command.value,
        'arguments': {
          'LIST': ArgumentType.string.value,
          'INDEX': ArgumentType.number.value,
          'ITEM': ArgumentType.string.value
        },
      },
      'data_itemoflist': {
        'func': getItemOfList,
        'type': BlockType.reporter.value,
        'arguments': {
          'LIST': ArgumentType.string.value,
          'INDEX': ArgumentType.number.value
        },
      },
      'data_itemnumoflist': {
        'func': getItemNumOfList,
        'type': BlockType.reporter.value,
        'arguments': {
          'LIST': ArgumentType.string.value,
          'ITEM': ArgumentType.string.value
        },
      },
      'data_lengthoflist': {
        'func': lengthOfList,
        'type': BlockType.reporter.value,
        'arguments': {'LIST': ArgumentType.string.value},
      },
      'data_listcontainsitem': {
        'func': listContainsItem,
        'type': BlockType.reporter.value,
        'arguments': {
          'LIST': ArgumentType.string.value,
          'ITEM': ArgumentType.string.value
        },
      },
      'data_hidelist': {
        'func': hideList,
        'type': BlockType.command.value,
        'arguments': {'LIST': ArgumentType.string.value},
      },
      'data_showlist': {
        'func': showList,
        'type': BlockType.command.value,
        'arguments': {'LIST': ArgumentType.string.value},
      },
    };
  }

  // ---------------- VARIABLES ----------------

  dynamic getVariable(Map<String, dynamic> args, Util util) {
    final variable = util.target
        .lookupOrCreateVariable(args['VARIABLE'].id, args['VARIABLE'].name);
    return variable.value;
  }

  void setVariableTo(Map<String, dynamic> args, Util util) {
    final variable = util.target
        .lookupOrCreateVariable(args['VARIABLE'].id, args['VARIABLE'].name);
    variable.value = args['VALUE'];

    if (variable.isCloud) {
      util.ioQuery(
          'cloud', 'requestUpdateVariable', [variable.name, args['VALUE']]);
    }
  }

  void changeVariableBy(Map<String, dynamic> args, Util util) {
    final variable = util.target
        .lookupOrCreateVariable(args['VARIABLE'].id, args['VARIABLE'].name);
    final num castedValue = Cast.toNumber(variable.value);
    final num dValue = Cast.toNumber(args['VALUE']);
    final num newValue = castedValue + dValue;
    variable.value = newValue;

    if (variable.isCloud) {
      util.ioQuery('cloud', 'requestUpdateVariable', [variable.name, newValue]);
    }
  }

  void changeMonitorVisibility(String id, bool visible) {
    runtime.monitorBlocks.changeBlock({
      'id': id,
      'element': 'checkbox',
      'value': visible,
    }, runtime);
  }

  void showVariable(Map<String, dynamic> args) {
    changeMonitorVisibility(args['VARIABLE'].id, true);
  }

  void hideVariable(Map<String, dynamic> args) {
    changeMonitorVisibility(args['VARIABLE'].id, false);
  }

  // ---------------- LISTS ----------------

  void showList(Map<String, dynamic> args) {
    changeMonitorVisibility(args['LIST'].id, true);
  }

  void hideList(Map<String, dynamic> args) {
    changeMonitorVisibility(args['LIST'].id, false);
  }

  dynamic getListContents(Map<String, dynamic> args, Util util) {
    final list =
        util.target.lookupOrCreateList(args['LIST'].id, args['LIST'].name);

    if (util.thread.updateMonitor) {
      if (list.monitorUpToDate) return list.value;
      list.monitorUpToDate = true;
      return List.from(list.value);
    }

    bool allSingleLetters =
        list.value.every((item) => item is String && item.length == 1);
    return allSingleLetters ? list.value.join('') : list.value.join(' ');
  }

  void addToList(Map<String, dynamic> args, Util util) {
    final list =
        util.target.lookupOrCreateList(args['LIST'].id, args['LIST'].name);
    if (list.value.length < listItemLimit) {
      list.value.add(args['ITEM']);
      list.monitorUpToDate = false;
    }
  }

  void deleteOfList(Map<String, dynamic> args, Util util) {
    final list =
        util.target.lookupOrCreateList(args['LIST'].id, args['LIST'].name);
    final index = Cast.toListIndex(args['INDEX'], list.value.length, true);
    if (index == Cast.listInvalid) return;
    if (index == Cast.listAll) {
      list.value.clear();
      return;
    }
    list.value.removeAt(index - 1);
    list.monitorUpToDate = false;
  }

  void deleteAllOfList(Map<String, dynamic> args, Util util) {
    final list =
        util.target.lookupOrCreateList(args['LIST'].id, args['LIST'].name);
    list.value.clear();
  }

  void insertAtList(Map<String, dynamic> args, Util util) {
    final list =
        util.target.lookupOrCreateList(args['LIST'].id, args['LIST'].name);
    final index = Cast.toListIndex(args['INDEX'], list.value.length + 1, false);
    if (index == Cast.listInvalid || index > listItemLimit) return;

    list.value.insert(index - 1, args['ITEM']);
    if (list.value.length > listItemLimit) list.value.removeLast();
    list.monitorUpToDate = false;
  }

  void replaceItemOfList(Map<String, dynamic> args, Util util) {
    final list =
        util.target.lookupOrCreateList(args['LIST'].id, args['LIST'].name);
    final index = Cast.toListIndex(args['INDEX'], list.value.length, false);
    if (index == Cast.listInvalid) return;

    list.value[index - 1] = args['ITEM'];
    list.monitorUpToDate = false;
  }

  dynamic getItemOfList(Map<String, dynamic> args, Util util) {
    final list =
        util.target.lookupOrCreateList(args['LIST'].id, args['LIST'].name);
    final index = Cast.toListIndex(args['INDEX'], list.value.length, false);
    if (index == Cast.listInvalid) return '';
    return list.value[index - 1];
  }

  int getItemNumOfList(Map<String, dynamic> args, Util util) {
    final list =
        util.target.lookupOrCreateList(args['LIST'].id, args['LIST'].name);
    final item = args['ITEM'];

    for (int i = 0; i < list.value.length; i++) {
      if (Cast.compare(list.value[i], item) == 0) return i + 1;
    }
    return 0;
  }

  int lengthOfList(Map<String, dynamic> args, Util util) {
    final list =
        util.target.lookupOrCreateList(args['LIST'].id, args['LIST'].name);
    return list.value.length;
  }

  bool listContainsItem(Map<String, dynamic> args, Util util) {
    final list =
        util.target.lookupOrCreateList(args['LIST'].id, args['LIST'].name);
    final item = args['ITEM'];

    if (list.value.contains(item)) return true;
    return list.value.any((element) => Cast.compare(element, item) == 0);
  }

  /// Max number of items in a list
  static const int listItemLimit = 200000;
}
