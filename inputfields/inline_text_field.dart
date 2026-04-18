import 'package:flutter/material.dart';

/// InlineTextField behaves like Scratch bubble input:
/// - Shows a floating bubble
/// - Accepts text or numeric input
/// - Calls `onChanged` when user types
class InlineTextField extends StatefulWidget {
  final String value;
  final double width;
  final String hint;
  final bool numeric;
  final ValueChanged<String> onChanged;

  const InlineTextField({
    Key? key,
    required this.value,
    required this.width,
    required this.onChanged,
    this.hint = '',
    this.numeric = false,
  }) : super(key: key);

  @override
  _InlineTextFieldState createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<InlineTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();

    // Update bubble text when user types
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType:
            widget.numeric ? TextInputType.number : TextInputType.text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: widget.hint,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
      ),
    );
  }
}
