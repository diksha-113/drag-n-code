import 'package:flutter/material.dart';

typedef TextValidator = String? Function(String);

class FieldTextInput extends StatefulWidget {
  final String initialValue;
  final TextValidator? validator;
  final bool spellcheck;
  final ValueChanged<String>? onChanged;

  const FieldTextInput({
    super.key,
    this.initialValue = '',
    this.validator,
    this.spellcheck = true,
    this.onChanged,
  });

  @override
  State<FieldTextInput> createState() => _FieldTextInputState();
}

class _FieldTextInputState extends State<FieldTextInput> {
  late TextEditingController _controller;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_validate);
  }

  void _validate() {
    final text = _controller.text;
    final validatedText = widget.validator?.call(text);

    setState(() {
      _isValid = validatedText != null;
    });

    if (validatedText != null && validatedText != text) {
      _controller.value = _controller.value.copyWith(
        text: validatedText,
        selection: TextSelection.collapsed(offset: validatedText.length),
      );
    }

    widget.onChanged?.call(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
        errorText: _isValid ? null : 'Invalid input',
      ),
      keyboardType: TextInputType.text,
      autocorrect: widget.spellcheck,
      enableSuggestions: widget.spellcheck,
    );
  }
}

/// ------------------------------------------------------------
/// Example Validators
/// ------------------------------------------------------------

String? numberValidator(String text) {
  text = text.replaceAll(RegExp(r'[O,o]'), '0');
  text = text.replaceAll(',', '');
  return double.tryParse(text) != null ? text : null;
}

String? nonNegativeIntegerValidator(String text) {
  final n = numberValidator(text);
  if (n != null) {
    final value = int.tryParse(double.parse(n).toStringAsFixed(0)) ?? 0;
    return value >= 0 ? value.toString() : '0';
  }
  return null;
}
