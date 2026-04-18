import 'package:flutter/material.dart';

typedef RemoveFieldCallback = void Function();

class FieldTextInputRemovable extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String>? onChanged;
  final RemoveFieldCallback? onRemove;

  const FieldTextInputRemovable({
    super.key,
    this.initialValue = '',
    this.onChanged,
    this.onRemove,
  });

  @override
  State<FieldTextInputRemovable> createState() =>
      _FieldTextInputRemovableState();
}

class _FieldTextInputRemovableState extends State<FieldTextInputRemovable> {
  late TextEditingController _controller;
  bool _showRemoveButton = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  void _toggleRemoveButton(bool focused) {
    setState(() {
      _showRemoveButton = focused;
    });
  }

  void _removeField() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onRemove?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: _toggleRemoveButton,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            onChanged: widget.onChanged,
          ),
          if (_showRemoveButton)
            Positioned(
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _removeField,
                tooltip: 'Remove',
              ),
            ),
        ],
      ),
    );
  }
}
