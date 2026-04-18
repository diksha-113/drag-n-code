import 'package:flutter/material.dart';

/// A variable field with dropdown menu, similar to Blockly's FieldVariable.
class FieldVariable extends StatefulWidget {
  final String defaultName;
  final String variableType;
  final List<String> availableVariables;
  final ValueChanged<String>? onChanged;

  const FieldVariable({
    super.key,
    this.defaultName = 'variable',
    this.variableType = '',
    this.availableVariables = const [],
    this.onChanged,
  });

  @override
  FieldVariableState createState() => FieldVariableState();
}

/// Made PUBLIC to avoid "Invalid use of a private type in a public API"
class FieldVariableState extends State<FieldVariable> {
  late String _variableName;
  late String _variableId;
  late List<String> _variables;

  @override
  void initState() {
    super.initState();
    _variableName = widget.defaultName;
    _variableId = UniqueKey().toString();
    _variables = List.from(widget.availableVariables);

    if (!_variables.contains(_variableName)) {
      _variables.add(_variableName);
    }
  }

  void _onItemSelected(String name) async {
    if (name == '__rename__') {
      final newName = await _showRenameDialog();
      if (newName != null && newName.isNotEmpty) {
        setState(() {
          final index = _variables.indexOf(_variableName);
          if (index != -1) _variables[index] = newName;
          _variableName = newName;
          _variableId = UniqueKey().toString();
        });
        widget.onChanged?.call(newName);
      }
    } else if (name == '__delete__') {
      setState(() {
        _variables.remove(_variableName);
        _variableName = _variables.isNotEmpty ? _variables.first : '';
        _variableId = UniqueKey().toString();
      });
      widget.onChanged?.call(_variableName);
    } else if (name == '__new__') {
      final newName = await _showNewVariableDialog();
      if (newName != null && newName.isNotEmpty) {
        setState(() {
          _variables.add(newName);
          _variableName = newName;
          _variableId = UniqueKey().toString();
        });
        widget.onChanged?.call(newName);
      }
    } else {
      setState(() {
        _variableName = name;
        _variableId = UniqueKey().toString();
      });
      widget.onChanged?.call(name);
    }
  }

  Future<String?> _showRenameDialog() async {
    String newName = _variableName;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Variable'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New variable name'),
          onChanged: (val) => newName = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, newName),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showNewVariableDialog() async {
    String newName = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Variable'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Variable name'),
          onChanged: (val) => newName = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, newName),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Get current variable's ID
  String getValue() => _variableId;

  /// Get current variable's name
  String getText() => _variableName;

  /// Set variable programmatically
  void setValue(String id, String name) {
    setState(() {
      _variableId = id;
      _variableName = name;
      if (!_variables.contains(name)) {
        _variables.add(name);
      }
    });
    widget.onChanged?.call(name);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[200],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange[400]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _variableName.isNotEmpty ? _variableName : null,
          items: [
            ..._variables.map(
              (name) => DropdownMenuItem(
                value: name,
                child: Text(name),
              ),
            ),
            const DropdownMenuItem(
              value: '__new__',
              child: Text('+ New Variable'),
            ),
            const DropdownMenuItem(
              value: '__rename__',
              child: Text('Rename Variable'),
            ),
            const DropdownMenuItem(
              value: '__delete__',
              child: Text('Delete Variable'),
            ),
          ],
          onChanged: (val) {
            if (val != null) _onItemSelected(val);
          },
          dropdownColor: Colors.white,
        ),
      ),
    );
  }
}
