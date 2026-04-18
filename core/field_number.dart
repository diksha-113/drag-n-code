import 'package:flutter/material.dart';

typedef NumberValidator = String? Function(String value);

class FieldNumber extends StatefulWidget {
  final double? initialValue;
  final double? min;
  final double? max;
  final double? precision;
  final NumberValidator? validator;
  final ValueChanged<double>? onChanged;

  const FieldNumber({
    Key? key,
    this.initialValue,
    this.min,
    this.max,
    this.precision,
    this.validator,
    this.onChanged,
  }) : super(key: key);

  @override
  State<FieldNumber> createState() => _FieldNumberState();
}

class _FieldNumberState extends State<FieldNumber> {
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

  void _insertKey(String key) {
    final text = _controller.text;
    final selection = _controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, key);
    _controller.text = newText;
    _controller.selection =
        TextSelection.collapsed(offset: selection.start + key.length);
    _updateValue(_controller.text);
  }

  void _deleteKey() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.start == 0 && selection.end == 0) return;

    final start = selection.start == selection.end
        ? selection.start - 1
        : selection.start;
    final end = selection.end;

    final newText = text.replaceRange(start, end, '');
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: start);
    _updateValue(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      '7',
      '8',
      '9',
      '4',
      '5',
      '6',
      '1',
      '2',
      '3',
      '.',
      '0',
      '-',
      'DEL'
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onChanged: _updateValue,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: buttons.map((b) {
            return SizedBox(
              width: 60,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (b == 'DEL') {
                    _deleteKey();
                  } else {
                    _insertKey(b);
                  }
                },
                child: Text(b, style: const TextStyle(fontSize: 18)),
              ),
            );
          }).toList(),
        )
      ],
    );
  }
}
