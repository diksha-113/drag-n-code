// field_colour.dart
import 'package:flutter/material.dart';

/// A colour input field widget similar to Blockly's FieldColour.
/// Allows selecting a color from a grid and notifies parent on change.
class FieldColour extends StatefulWidget {
  final String initialColor;
  final ValueChanged<String>? onColorChanged;

  const FieldColour({
    super.key,
    required this.initialColor,
    this.onColorChanged,
  });

  @override
  State<FieldColour> createState() => _FieldColourState();
}

class _FieldColourState extends State<FieldColour> {
  late Color _currentColor;

  static const List<String> defaultPalette = [
    "#000000",
    "#434343",
    "#666666",
    "#999999",
    "#B7B7B7",
    "#CCCCCC",
    "#FFFFFF",
    "#980000",
    "#FF0000",
    "#FF9900",
    "#FFFF00",
    "#00FF00",
    "#00FFFF",
    "#4A86E8",
    "#0000FF",
    "#9900FF",
    "#FF00FF"
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = _hexToColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openColorPicker,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _currentColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black12),
        ),
      ),
    );
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pick a Colour"),
        content: SizedBox(
          width: 250,
          height: 200,
          child: GridView.count(
            crossAxisCount: 6,
            children: [
              for (final hex in defaultPalette)
                GestureDetector(
                  onTap: () => _selectColor(hex),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _hexToColor(hex),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectColor(String hex) {
    Navigator.pop(context);
    setState(() {
      _currentColor = _hexToColor(hex);
    });
    widget.onColorChanged?.call(hex);
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }
}
