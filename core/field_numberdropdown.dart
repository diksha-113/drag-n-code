import 'package:flutter/material.dart';

typedef NumberDropdownValidator = String? Function(String value);

class FieldNumberDropdown extends StatefulWidget {
  final double? initialValue;
  final List<String> options;
  final double? min;
  final double? max;
  final double? precision;
  final NumberDropdownValidator? validator;
  final ValueChanged<double>? onChanged;

  const FieldNumberDropdown({
    super.key, // Using super.key to remove warning
    this.initialValue,
    required this.options,
    this.min,
    this.max,
    this.precision,
    this.validator,
    this.onChanged,
  });

  @override
  State<FieldNumberDropdown> createState() => _FieldNumberDropdownState();
}

class _FieldNumberDropdownState extends State<FieldNumberDropdown> {
  late TextEditingController _controller;
  double? currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue ?? 0;
    _controller = TextEditingController(text: currentValue.toString());
  }

  void _updateValue(String text) {
    double? value = double.tryParse(text);
    if (value == null) return;

    if (widget.min != null && value < widget.min!) value = widget.min!;
    if (widget.max != null && value > widget.max!) value = widget.max!;
    if (widget.precision != null && widget.precision! > 0) {
      value = (value / widget.precision!).round() * widget.precision!;
    }

    setState(() {
      currentValue = value;
      _controller.text = value.toString();
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length));
    });

    widget.onChanged?.call(value);
  }

  void _selectOption(String option) {
    _controller.text = option;
    _updateValue(option);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
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
