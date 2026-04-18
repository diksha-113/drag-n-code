import 'package:flutter/material.dart';
import '../vm/engine/variable.dart';
import '../models/block_model.dart';
import '../core/workspace.dart';

const variableOrange = Color(0xFFFF8C1A);
const variableOrangeDark = Color(0xFFE67A00);

class DataBlockContainer extends StatelessWidget {
  final List<Widget> children;

  const DataBlockContainer({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [variableOrange, variableOrangeDark],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: children
              .map((child) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: child,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class VariableCapsule extends StatelessWidget {
  final Variable variable;
  final void Function()? onTap;
  final bool showListLength;

  const VariableCapsule({
    super.key,
    required this.variable,
    this.onTap,
    this.showListLength = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ValueListenableBuilder(
        valueListenable: variable.notifier,
        builder: (_, value, __) {
          String display = value.toString();

          if (showListLength && value is List) {
            display = value.length.toString();
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: variableOrangeDark, width: 2),
            ),
            child: Text(
              display,
              style: const TextStyle(
                color: variableOrangeDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget buildDataBlocks(
  Block block, {
  required Sprite sprite,
  required void Function(String field, dynamic val) onChanged,
  required BuildContext context,
}) {
  /// ✅ CRITICAL FIX: Only allow real Variable objects
  final List<Variable> variables = sprite.variables.values
      .where((v) => v is Variable)
      .cast<Variable>()
      .toList();

  Variable? getVariable(bool isList) {
    final key = isList ? 'LIST' : 'VARIABLE';
    final selectedName = block.arguments[key] as String?;

    final filtered = variables.where((v) => v.isList == isList).toList();

    if (filtered.isEmpty) return null;

    // If selected exists
    if (selectedName != null) {
      for (final v in filtered) {
        if (v.name == selectedName) return v;
      }
    }

    // Auto select first if not selected
    final first = filtered.first;
    block.arguments[key] = first.name;
    return first;
  }

  Widget inputField(String key, {bool isNumber = false}) {
    block.controllers.putIfAbsent(
      key,
      () => TextEditingController(text: block.arguments[key]?.toString() ?? ''),
    );

    final controller = block.controllers[key]!;

    return SizedBox(
      width: 70,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            borderSide: BorderSide.none,
          ),
          isDense: true,
        ),
        onChanged: (v) {
          dynamic parsed = v;
          if (isNumber) parsed = int.tryParse(v) ?? 0;

          block.arguments[key] = parsed;
          onChanged(key, parsed);
        },
      ),
    );
  }

  void showVariablePicker(bool isList) {
    final filtered = variables.where((v) => v.isList == isList).toList();

    if (filtered.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isList ? "Select List" : "Select Variable"),
        content: ListView(
          shrinkWrap: true,
          children: filtered
              .map((v) => ListTile(
                    title: Text(v.name),
                    onTap: () {
                      final key = isList ? 'LIST' : 'VARIABLE';
                      block.arguments[key] = v.name;
                      onChanged(key, v.name);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget blockBox(List<Widget> children) {
    return DataBlockContainer(children: children);
  }

  switch (block.type) {
    case 'data_variable':
      final v = getVariable(false);
      if (v == null) return const SizedBox();
      return VariableCapsule(
        variable: v,
        onTap: () => showVariablePicker(false),
      );

    case 'data_setvariableto':
      final v = getVariable(false);
      if (v == null) return const SizedBox();
      return blockBox([
        const Text("set", style: TextStyle(color: Colors.white)),
        VariableCapsule(
          variable: v,
          onTap: () => showVariablePicker(false),
        ),
        const Text("to", style: TextStyle(color: Colors.white)),
        inputField('VALUE', isNumber: true),
      ]);

    case 'data_changevariableby':
      final v = getVariable(false);
      if (v == null) return const SizedBox();
      return blockBox([
        const Text("change", style: TextStyle(color: Colors.white)),
        VariableCapsule(
          variable: v,
          onTap: () => showVariablePicker(false),
        ),
        const Text("by", style: TextStyle(color: Colors.white)),
        inputField('VALUE', isNumber: true),
      ]);

    case 'data_addtolist':
      final l = getVariable(true);
      if (l == null) return const SizedBox();
      return blockBox([
        const Text("add", style: TextStyle(color: Colors.white)),
        inputField('ITEM'),
        const Text("to", style: TextStyle(color: Colors.white)),
        VariableCapsule(
          variable: l,
          showListLength: true,
          onTap: () => showVariablePicker(true),
        ),
      ]);

    case 'data_deleteoflist':
      final l = getVariable(true);
      if (l == null) return const SizedBox();
      return blockBox([
        const Text("delete", style: TextStyle(color: Colors.white)),
        inputField('INDEX', isNumber: true),
        const Text("of", style: TextStyle(color: Colors.white)),
        VariableCapsule(
          variable: l,
          showListLength: true,
          onTap: () => showVariablePicker(true),
        ),
      ]);

    case 'data_lengthoflist':
      final l = getVariable(true);
      if (l == null) return const SizedBox();
      return VariableCapsule(
        variable: l,
        showListLength: true,
        onTap: () => showVariablePicker(true),
      );

    default:
      return blockBox([
        Text(block.uiLabel, style: const TextStyle(color: Colors.white)),
      ]);
  }
}
