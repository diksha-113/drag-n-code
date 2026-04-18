import 'package:flutter/material.dart';

/// A field that displays a variable's name and can be set
/// programmatically or via a dropdown (Blockly-style variable field).
class FieldVariableGetter extends StatefulWidget {
  final String initialName;
  final String variableType;
  final List<String> availableVariables;
  final ValueChanged<String>? onChanged;

  const FieldVariableGetter({
    super.key, // ✅ super parameter
    required this.initialName,
    this.variableType = '',
    this.availableVariables = const [],
    this.onChanged,
  });

  @override
  FieldVariableGetterState createState() => FieldVariableGetterState();
}

/// ✅ Made PUBLIC to avoid "private type in public API"
class FieldVariableGetterState extends State<FieldVariableGetter> {
  late String _variableName;
  String? _variableId;

  @override
  void initState() {
    super.initState();
    _variableName = widget.initialName;
    _variableId = UniqueKey().toString(); // simulated variable ID
  }

  /// Get the variable ID (Blockly-style)
  String getValue() => _variableId ?? '';

  /// Get the variable name
  String getText() => _variableName;

  /// Programmatically set variable (ID + name)
  void setValue(String id, String name) {
    setState(() {
      _variableId = id;
      _variableName = name;
    });
    widget.onChanged?.call(name);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _variableName,
          items: widget.availableVariables
              .map(
                (name) => DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (newName) {
            if (newName != null) {
              setState(() {
                _variableName = newName;
                _variableId = UniqueKey().toString();
              });
              widget.onChanged?.call(newName);
            }
          },
          style: const TextStyle(color: Colors.black),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }
}
