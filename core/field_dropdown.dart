import 'package:flutter/material.dart';

/// A simplified, Flutter-based version of Blockly's FieldDropdown.
/// This widget behaves like a dropdown field inside a block.
class FieldDropdown extends StatefulWidget {
  /// Options for the dropdown.
  /// Example:  [ ["Move 10 steps", "MOVE_10"], ["Turn 15°", "TURN_15"] ]
  final List<List<String>> options;

  /// Called when user selects a new value.
  final ValueChanged<String>? onChanged;

  /// Initial selected value.
  final String initialValue;

  const FieldDropdown({
    super.key,
    required this.options,
    required this.initialValue,
    this.onChanged,
  });

  @override
  State<FieldDropdown> createState() => _FieldDropdownState();
}

class _FieldDropdownState extends State<FieldDropdown> {
  late String selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getLabel(selected),
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  void _showDropdown() {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset pos = box.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        pos.dx,
        pos.dy + box.size.height,
        pos.dx + box.size.width,
        pos.dy,
      ),
      items: widget.options
          .map((item) => PopupMenuItem<String>(
                value: item[1],
                child: Text(item[0]),
              ))
          .toList(),
    ).then((value) {
      if (value != null) {
        setState(() => selected = value);
        widget.onChanged?.call(value);
      }
    });
  }

  String _getLabel(String value) {
    for (var item in widget.options) {
      if (item[1] == value) return item[0];
    }
    return value;
  }
}
