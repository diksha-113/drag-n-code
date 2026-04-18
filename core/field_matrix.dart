import 'package:flutter/material.dart';

/// A Flutter version of Blockly's FieldMatrix.
/// Holds a 5×5 LED matrix represented by a 25-bit string.
class FieldMatrix extends StatefulWidget {
  final String value; // 25-char binary string
  final ValueChanged<String> onChanged; // Callback to parent

  const FieldMatrix({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<FieldMatrix> createState() => _FieldMatrixState();
}

class _FieldMatrixState extends State<FieldMatrix> {
  late List<int> matrix; // 25 LEDs

  @override
  void initState() {
    super.initState();
    matrix = widget.value.split('').map(int.parse).toList();
  }

  /// Convert list → string
  String get matrixString => matrix.join();

  /// Toggle LED
  void toggle(int index) {
    setState(() {
      matrix[index] = matrix[index] == 0 ? 1 : 0;
    });
    widget.onChanged(matrixString);
  }

  /// Clear matrix
  void clear() {
    setState(() {
      matrix = List.filled(25, 0);
    });
    widget.onChanged(matrixString);
  }

  /// Fill matrix
  void fill() {
    setState(() {
      matrix = List.filled(25, 1);
    });
    widget.onChanged(matrixString);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ► The 5×5 grid
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: 25,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final isOn = matrix[index] == 1;

              return GestureDetector(
                onTap: () => toggle(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isOn ? Colors.white : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.black54,
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // ► Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: clear,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: const Text("Clear"),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: fill,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              child: const Text("Fill"),
            ),
          ],
        )
      ],
    );
  }
}
