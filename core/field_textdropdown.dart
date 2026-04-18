import 'package:flutter/material.dart';

typedef TextDropdownValidator = String? Function(String value);

class FieldTextDropdown extends StatefulWidget {
  final String initialValue;
  final List<String> options;
  final TextDropdownValidator? validator;
  final ValueChanged<String>? onChanged;

  const FieldTextDropdown({
    Key? key,
    this.initialValue = '',
    required this.options,
    this.validator,
    this.onChanged,
  }) : super(key: key);

  @override
  State<FieldTextDropdown> createState() => _FieldTextDropdownState();
}

class _FieldTextDropdownState extends State<FieldTextDropdown> {
  late TextEditingController _controller;
  String currentValue = '';

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
    _controller = TextEditingController(text: currentValue);
  }

  void _updateValue(String value) {
    String? validated = widget.validator?.call(value);
    if (validated != null) {
      value = validated;
    }
    setState(() {
      currentValue = value;
      _controller.text = value;
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length));
    });
    widget.onChanged?.call(value);
  }

  void _selectOption(String option) {
    _updateValue(option);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: _updateValue,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: widget.options.map((o) {
            return ElevatedButton(
              onPressed: () => _selectOption(o),
              child: Text(o),
            );
          }).toList(),
        )
      ],
    );
  }
}
