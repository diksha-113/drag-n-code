import 'package:flutter/material.dart';

/// Represents a single icon option in the menu.
class IconMenuItem {
  final String src;
  final double width;
  final double height;
  final String alt;
  final String value;
  final bool placeholder;

  IconMenuItem({
    required this.src,
    required this.width,
    required this.height,
    required this.alt,
    required this.value,
    this.placeholder = false,
  });
}

/// Flutter version of Blockly.FieldIconMenu
class FieldIconMenu extends StatefulWidget {
  final List<IconMenuItem> icons;
  final ValueChanged<String>? onChanged;
  final String initialValue;

  const FieldIconMenu({
    super.key,
    required this.icons,
    required this.initialValue,
    this.onChanged,
  });

  @override
  State<FieldIconMenu> createState() => _FieldIconMenuState();
}

class _FieldIconMenuState extends State<FieldIconMenu> {
  late String selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showIconMenu,
      child: Row(
        children: [
          Image.asset(
            _iconForValue(selected).src,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }

  IconMenuItem _iconForValue(String value) {
    return widget.icons.firstWhere(
      (icon) => icon.value == value,
      orElse: () => widget.icons[0],
    );
  }

  void _showIconMenu() async {
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: widget.icons.map((icon) {
                if (icon.placeholder) {
                  return SizedBox(
                    width: icon.width,
                    height: icon.height,
                  );
                }

                bool isSelected = (selected == icon.value);

                return GestureDetector(
                  onTap: () => Navigator.pop(context, icon.value),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade200
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.blue.shade300,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      icon.src,
                      width: icon.width,
                      height: icon.height,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (value != null) {
      setState(() => selected = value);
      widget.onChanged?.call(value);
    }
  }
}
