import 'package:flutter/material.dart';
import '../models/block_model.dart';

// ================== SCRATCH COLORS ==================
const Color operatorGreen = Color(0xFF59C059);
const Color operatorSlotBg = Color(0xFFE1F5E1);
const Color operatorSlotBorder = Color(0xFF3C9D3C);
const Color operatorHighlight = Color(0x66FFFF66);

const TextStyle _labelStyle = TextStyle(
  color: Colors.white,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: 1.0,
);

// ================== BUILD OPERATOR BLOCK ==================
Widget buildOperatorBlock(
  BlockModel block, {
  required void Function(String field, String value) onChanged,
}) {
  block.controllers ??= <String, TextEditingController>{};
  block.values ??= <String, String>{};

  // ------------------- SCRATCH INPUT SLOT -------------------
  Widget scratchInput(
    String key, {
    double width = 44,
    String defaultValue = '',
    TextInputType inputType = TextInputType.number,
  }) {
    block.controllers![key] ??=
        TextEditingController(text: block.values![key] ?? defaultValue);
    block.values![key] ??= defaultValue;

    return Container(
      height: 22,
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: operatorSlotBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: operatorSlotBorder),
      ),
      child: TextField(
        controller: block.controllers![key],
        keyboardType: inputType,
        textAlign: TextAlign.center,
        cursorHeight: 14,
        cursorColor: Colors.black,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          height: 1.1,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) {
          block.values![key] = v;
          onChanged(key, v);
        },
      ),
    );
  }

  // ------------------- BOOLEAN DROPDOWN -------------------
  Widget booleanDropdown(String key) {
    block.values![key] ??= 'true';

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: ShapeDecoration(
        color: operatorSlotBg,
        shape: const StadiumBorder(
          side: BorderSide(color: operatorSlotBorder),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: block.values![key],
          style: const TextStyle(fontSize: 12, color: Colors.black),
          items: const [
            DropdownMenuItem(value: 'true', child: Text('true')),
            DropdownMenuItem(value: 'false', child: Text('false')),
          ],
          onChanged: (v) {
            if (v == null) return;
            block.values![key] = v;
            onChanged(key, v);
          },
        ),
      ),
    );
  }

  // ------------------- OPERATOR BLOCK CONTAINER -------------------
  Widget container(List<Widget> children, {bool highlight = false}) {
    return DragTarget<BlockModel>(
      onWillAccept: (_) => true,
      builder: (_, __, ___) {
        return CustomPaint(
          painter: _OperatorBlockPainter(highlight: highlight),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children
                  .map((w) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: w,
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  // ------------------- OPERATOR TYPES -------------------
  switch (block.type) {
    case 'operator_add':
      return container([
        scratchInput('A'),
        const Text('+', style: _labelStyle),
        scratchInput('B'),
      ]);

    case 'operator_subtract':
      return container([
        scratchInput('A'),
        const Text('-', style: _labelStyle),
        scratchInput('B'),
      ]);

    case 'operator_multiply':
      return container([
        scratchInput('A'),
        const Text('×', style: _labelStyle),
        scratchInput('B'),
      ]);

    case 'operator_divide':
      return container([
        scratchInput('A'),
        const Text('÷', style: _labelStyle),
        scratchInput('B'),
      ]);

    case 'operator_lt':
      return container([
        scratchInput('A'),
        const Text('<', style: _labelStyle),
        scratchInput('B'),
      ]);

    case 'operator_equals':
      return container([
        scratchInput('A'),
        const Text('=', style: _labelStyle),
        scratchInput('B'),
      ]);

    case 'operator_gt':
      return container([
        scratchInput('A'),
        const Text('>', style: _labelStyle),
        scratchInput('B'),
      ]);

    case 'operator_and':
      return container([
        booleanDropdown('A'),
        const Text('and', style: _labelStyle),
        booleanDropdown('B'),
      ]);

    case 'operator_or':
      return container([
        booleanDropdown('A'),
        const Text('or', style: _labelStyle),
        booleanDropdown('B'),
      ]);

    case 'operator_not':
      return container([
        const Text('not', style: _labelStyle),
        booleanDropdown('A'),
      ]);

    case 'operator_random':
      return container([
        const Text('pick random', style: _labelStyle),
        scratchInput('FROM'),
        const Text('to', style: _labelStyle),
        scratchInput('TO'),
      ]);

    case 'operator_join':
      return container([
        const Text('join', style: _labelStyle),
        scratchInput('A', width: 70, inputType: TextInputType.text),
        scratchInput('B', width: 70, inputType: TextInputType.text),
      ]);

    case 'operator_letter_of':
      return container([
        const Text('letter', style: _labelStyle),
        scratchInput('IDX'),
        const Text('of', style: _labelStyle),
        scratchInput('STR', width: 70, inputType: TextInputType.text),
      ]);

    case 'operator_length':
      return container([
        const Text('length of', style: _labelStyle),
        scratchInput('STR', width: 70, inputType: TextInputType.text),
      ]);

    case 'operator_contains':
      return container([
        const Text('contains', style: _labelStyle),
        scratchInput('A', width: 60, inputType: TextInputType.text),
        scratchInput('B', width: 60, inputType: TextInputType.text),
      ]);

    case 'operator_mod':
      return container([
        scratchInput('A'),
        const Text('%', style: _labelStyle),
        scratchInput('B'),
      ]);

    case 'operator_round':
      return container([
        const Text('round', style: _labelStyle),
        scratchInput('NUM'),
      ]);

    case 'operator_mathop':
      return container([
        scratchInput('OP', width: 52, inputType: TextInputType.text),
        scratchInput('NUM'),
      ]);

    default:
      return container([
        Text(block.uiLabel ?? '', style: _labelStyle),
      ]);
  }
}

// ================== CUSTOM PAINTER ==================
class _OperatorBlockPainter extends CustomPainter {
  final bool highlight;
  _OperatorBlockPainter({this.highlight = false});

  @override
  void paint(Canvas canvas, Size size) {
    const r = 12.0;
    const notchW = 18.0;
    const notchH = 6.0;
    const notchX = 24.0;

    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(notchX, 0)
      ..lineTo(notchX + 4, notchH)
      ..lineTo(notchX + notchW - 4, notchH)
      ..lineTo(notchX + notchW, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0);

    canvas.drawPath(
      path,
      Paint()..color = highlight ? operatorHighlight : operatorGreen,
    );
  }

  @override
  bool shouldRepaint(_) => true;
}
