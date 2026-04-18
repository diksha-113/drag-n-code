// logic_blocks_vm.dart
import 'package:flutter/foundation.dart';

/// -------------------- RUNTIME LOGIC BLOCK --------------------
class LogicBlock {
  final String id;
  final String type; // 'if', 'else if', 'else'
  String value; // 'true' or 'false'
  final List<LogicBlock> subStack; // THEN / ELSE IF stack
  final List<LogicBlock> elseSubStack; // ELSE stack

  LogicBlock({
    required this.id,
    required this.type,
    this.value = 'true',
    this.subStack = const [],
    this.elseSubStack = const [],
  });
}

/// -------------------- LOGIC BLOCK VM --------------------
class LogicBlocksVM extends ChangeNotifier {
  /// Execute a single logic block and return true if executed
  bool executeBlock(LogicBlock block) {
    switch (block.type) {
      case 'if':
        if (_isTrue(block.value)) {
          debugPrint('✅ IF block executed');
          _executeStack(block.subStack);
          return true;
        } else {
          // Try else-if chain first
          for (final child in block.subStack) {
            if (child.type == 'else if' && executeBlock(child)) {
              return true;
            }
          }
          // Execute ELSE stack if nothing matched
          _executeStack(block.elseSubStack);
          return false;
        }

      case 'else if':
        if (_isTrue(block.value)) {
          debugPrint('✅ ELSE IF block executed');
          _executeStack(block.subStack);
          return true;
        }
        return false;

      case 'else':
        debugPrint('✅ ELSE block executed');
        _executeStack(block.subStack);
        return true;

      default:
        return false;
    }
  }

  /// =========================
  /// Evaluate a list of logic blocks (workspace)
  /// =========================
  Future<void> runLogicBlocks(List<LogicBlock> blocks) async {
    for (final block in blocks) {
      final cond = _isTrue(block.value);

      if (cond) {
        debugPrint('✅ Block ${block.id} executed (IF condition true)');
        await _executeStack(block.subStack);
      } else {
        debugPrint('🔹 Block ${block.id} ELSE executed');
        await _executeStack(block.elseSubStack);
      }
    }
  }

  void runWorkspace(List<LogicBlock> blocks) {
    for (final block in blocks) {
      executeBlock(block);
    }
  }

  /// Recursively execute a stack of logic blocks
  Future<void> _executeStack(List<LogicBlock> stack) async {
    for (final block in stack) {
      final cond = _isTrue(block.value);

      if (cond) {
        await _executeStack(block.subStack);
      } else {
        await _executeStack(block.elseSubStack);
      }
    }
  }

  /// Utility to check if the block's value is "true"
  bool _isTrue(String? value) => value?.toLowerCase() == 'true';
}

/// -------------------- UTILITY --------------------
class LogicBlockConverter {
  static LogicBlock fromJson(Map<String, dynamic> json) {
    return LogicBlock(
      id: json['id'] ?? UniqueKey().toString(),
      type: json['type'] ?? 'if',
      value: json['value'] ?? 'true',
      subStack: (json['subStack'] as List<dynamic>? ?? [])
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
      elseSubStack: (json['elseSubStack'] as List<dynamic>? ?? [])
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Map<String, dynamic> toJson(LogicBlock block) {
    return {
      'id': block.id,
      'type': block.type,
      'value': block.value,
      'subStack': block.subStack.map(toJson).toList(),
      'elseSubStack': block.elseSubStack.map(toJson).toList(),
    };
  }
}
