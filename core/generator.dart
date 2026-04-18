// lib/engine/generator.dart
//
// Dart port of Blockly's generator.js -> Generator

import 'dart:core';

/// Base class for a code generator that translates blocks into a language.
class Generator {
  final String name;

  // Fields (mirroring original JS)
  String? infiniteLoopTrap;
  String? statementPrefix;
  String indent = '  ';
  int commentWrap = 60;
  List<List<int>> orderOverrides = [];

  static const String nameType = 'generated_function';

  // Placeholder used when generating function bodies.
  final String functionNamePlaceholder = '{leCUI8hutHZI4480Dc}';
  late final RegExp functionNamePlaceholderRegExp;

  // Generated helper/function store
  final Map<String, String> definitions_ = {};
  final Map<String, String> functionNames_ = {};

  // Variable DB placeholder/object that should provide getDistinctName(name, type)
  dynamic variableDB_;

  // For reserved words
  String reservedWords = '';

  Generator(this.name) {
    functionNamePlaceholderRegExp =
        RegExp(RegExp.escape(functionNamePlaceholder));
  }

  // ------------------------
  // Public API
  // ------------------------

  /// Generate code for all top-level blocks in the workspace.
  String workspaceToCode(dynamic workspace) {
    if (workspace == null) {
      throw ArgumentError('workspace is required for workspaceToCode');
    }

    final List<String> codeLines = [];
    init(workspace);

    final List<dynamic> blocks = workspace.getTopBlocks(true);
    for (var block in blocks) {
      var line = blockToCode(block);
      if (line is List && line.isNotEmpty) {
        line = line[0];
      }
      if (line != null && line != '') {
        if (block.outputConnection != null && scrubNakedValue != null) {
          line = scrubNakedValue!(line as String);
        }
        codeLines.add(line as String);
      }
    }

    var code = codeLines.join('\n');
    code = finish(code);

    // Whitespace scrubbing
    code = code.replaceFirst(RegExp(r'^\s+\n'), '');
    code = code.replaceFirst(RegExp(r'\n\s+$'), '\n');
    code = code.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    return code;
  }

  /// Prepend a common prefix onto each line of text.
  String prefixLines(String text, String prefix) {
    return '$prefix${text.replaceAllMapped(RegExp(r'(?!\n$)\n'), (m) => '\n$prefix')}';
  }

  /// Return all nested comments within a block tree.
  String allNestedComments(dynamic block) {
    final List<String> comments = [];
    final List<dynamic> blocks = block.getDescendants(true);
    for (var b in blocks) {
      final String? comment = b.getCommentText();
      if (comment != null && comment.isNotEmpty) {
        comments.add(comment);
      }
    }
    if (comments.isNotEmpty) comments.add('');
    return comments.join('\n');
  }

  /// Generate code for a particular block & its attached chain.
  dynamic blockToCode(dynamic block) {
    if (block == null) return '';

    if (block.disabled == true) {
      return blockToCode(block.getNextBlock());
    }

    final func = callGeneratorFunction(block.type);
    if (func == null) {
      throw StateError(
          'Language "$name" does not know how to generate code for block type "${block.type}".');
    }

    final dynamic code = func(block);

    if (code is List) {
      assert(block.outputConnection != null,
          'Expecting string from statement block "${block.type}".');
      return [scrub_(block, code[0]), code[1]];
    } else if (code is String) {
      final String id = block.id.replaceAll(r'$', r'$$$$');
      if (statementPrefix != null) {
        final prefix = statementPrefix!.replaceAll('%1', '\'$id\'');
        return scrub_(block, '$prefix$code');
      }
      return scrub_(block, code);
    } else if (code == null) {
      return '';
    } else {
      throw StateError('Invalid code generated: $code');
    }
  }

  /// Generate code for a value input on a block.
  String valueToCode(dynamic block, String name, num outerOrder) {
    if (outerOrder.isNaN) {
      throw StateError('Expecting valid order from block "${block.type}".');
    }
    final targetBlock = block.getInputTargetBlock(name);
    if (targetBlock == null) return '';
    final tuple = blockToCode(targetBlock);
    if (tuple == '') return '';
    if (tuple is! List || tuple.length < 2) {
      throw StateError(
          'Expecting tuple from value block "${targetBlock.type}".');
    }
    String code = tuple[0] as String;
    final num innerOrder = tuple[1] as num;
    if (innerOrder.isNaN) {
      throw StateError(
          'Expecting valid order from block "${targetBlock.type}".');
    }
    if (code.isEmpty) return '';

    bool parensNeeded = false;
    final int outerOrderClass = outerOrder.floor();
    final int innerOrderClass = innerOrder.floor();
    if (outerOrderClass <= innerOrderClass) {
      if (!(outerOrderClass == innerOrderClass &&
          (outerOrderClass == 0 || outerOrderClass == 99))) {
        parensNeeded = true;
        for (var pair in orderOverrides) {
          if (pair.length >= 2 &&
              pair[0] == outerOrder &&
              pair[1] == innerOrder) {
            parensNeeded = false;
            break;
          }
        }
      }
    }
    if (parensNeeded) code = '($code)';
    return code;
  }

  /// Statement input generator (indentation applied).
  String statementToCode(dynamic block, String name) {
    final targetBlock = block.getInputTargetBlock(name);
    final code = blockToCode(targetBlock);
    String text = (code ?? '') as String;
    if (text.isNotEmpty) {
      text = prefixLines(text, indent);
    }
    return text;
  }

  /// Add an infinite loop trap and statement prefix to branch code.
  String addLoopTrap(String branch, String id) {
    final escapedId = id.replaceAll(r'$', r'$$$$');
    if (infiniteLoopTrap != null) {
      branch = infiniteLoopTrap!.replaceAll('%1', '\'$escapedId\'') + branch;
    }
    if (statementPrefix != null) {
      branch += prefixLines(
          statementPrefix!.replaceAll('%1', '\'$escapedId\''), indent);
    }
    return branch;
  }

  /// Add reserved words (comma-separated)
  void addReservedWords(String words) {
    reservedWords = '$reservedWords$words,';
  }

  /// Provide a function (helper) used in generated code.
  String provideFunction_(String desiredName, List<String> code) {
    if (!definitions_.containsKey(desiredName)) {
      if (variableDB_ == null) {
        throw StateError(
            'variableDB_ is not set. provideFunction_ requires a variable DB.');
      }
      final functionName = variableDB_.getDistinctName(desiredName, nameType);
      functionNames_[desiredName] = functionName;
      var codeText = code
          .join('\n')
          .replaceAll(functionNamePlaceholderRegExp, functionName);

      String old;
      do {
        old = codeText;
        codeText = codeText.replaceAllMapped(
            RegExp(r'^(( {2})*) {2}', multiLine: true), (m) => '${m[1]}\u0000');
      } while (old != codeText);
      codeText = codeText.replaceAll('\u0000', indent);

      definitions_[desiredName] = codeText;
    }
    return functionNames_[desiredName]!;
  }

  // ------------------------
  // Hooks & helpers (override in subclasses)
  // ------------------------

  void init(dynamic workspace) {
    // Optionally override
  }

  String scrub_(dynamic block, String code) {
    return code;
  }

  String finish(String code) {
    return code;
  }

  String Function(String)? scrubNakedValue;

  dynamic callGeneratorFunction(String type) {
    return null;
  }

  void setInfiniteLoopTrap(String trapCode) {
    infiniteLoopTrap = trapCode;
  }

  void setStatementPrefix(String prefix) {
    statementPrefix = prefix;
  }
}
