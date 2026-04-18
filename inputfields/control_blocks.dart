import 'package:flutter/material.dart';
import '../models/block_model.dart';
import 'operator_blocks.dart';

/// ================== COLORS ==================
const Color controlOrange = Color(0xFFFFAB19);
const Color controlOrangeLight = Color(0xFFFFC65C);
const Color controlOrangeDark = Color(0xFFD98B00);

/// ================== TEXT ==================
const TextStyle controlText = TextStyle(
  color: Colors.white,
  fontSize: 13,
  fontWeight: FontWeight.w600,
);

/// ================== CONTROL BLOCK WIDGET ==================
class ControlBlock extends StatelessWidget {
  final BlockModel block;
  final void Function(String field, dynamic value) onChanged;
  final double indent;
  final double verticalOffset;

  const ControlBlock({
    Key? key,
    required this.block,
    required this.onChanged,
    this.indent = 0,
    this.verticalOffset = 0,
  }) : super(key: key);

  /// ---------- SUBSTACK BUILDER ----------
  List<Widget> buildSubStack(List<BlockModel> stack, double nextIndent) {
    return stack.map((child) {
      return ControlBlock(
        block: child,
        onChanged: onChanged,
        indent: nextIndent,
      );
    }).toList();
  }

  /// ---------- CONTROL SHELL ----------
  Widget shell(Widget header, {bool hasElse = false}) {
    return Padding(
      padding: EdgeInsets.only(left: indent, top: verticalOffset, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MAIN HEADER
          Material(
            elevation: indent > 0 ? 2 : 4,
            borderRadius: BorderRadius.circular(14),
            color: block.isRunning ? Colors.yellow[700] : controlOrange,
            child: CustomPaint(
              painter: ScratchControlPainter3D(hasElse: hasElse),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: header,
              ),
            ),
          ),

          // IF STACK
          ...buildSubStack(
            block.subStack.map((b) => b.toBlockModel()).toList(),
            indent + 18,
          ),

          // ELSE STACK
          if (hasElse)
            ...buildSubStack(
              block.elseSubStack.map((b) => b.toBlockModel()).toList(),
              indent + 18,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case 'control_repeat':
        return shell(Row(
          children: [
            _label('repeat'),
            _numberSlot(block, 'TIMES', onChanged),
          ],
        ));

      case 'control_repeat_until':
        return shell(Row(
          children: [_label('repeat until'), _booleanSlot(block, 'CONDITION')],
        ));

      case 'control_while':
        return shell(Row(
          children: [_label('while'), _booleanSlot(block, 'CONDITION')],
        ));

      case 'control_forever':
        return shell(_label('forever'));

      case 'control_wait':
        return shell(Row(
          children: [
            _label('wait'),
            _numberSlot(block, 'DURATION', onChanged),
            _label('seconds'),
          ],
        ));

      case 'control_wait_until':
        return shell(Row(
          children: [_label('wait until'), _booleanSlot(block, 'CONDITION')],
        ));

      case 'control_if':
        return shell(Row(
          children: [_label('if'), _booleanSlot(block, 'CONDITION')],
        ));

      case 'control_if_else':
        return shell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [_label('if'), _booleanSlot(block, 'CONDITION')]),
              const SizedBox(height: 6),
              _label('else'),
            ],
          ),
          hasElse: true,
        );

      case 'control_stop':
        return shell(Row(
          children: [
            _label('stop'),
            _dropdownSlot(
                block,
                'STOP_OPTION',
                const [
                  'all',
                  'this script',
                  'other scripts in sprite',
                  'other scripts in stage',
                ],
                onChanged), // pass parent onChanged
          ],
        ));

      case 'control_create_clone_of':
        return shell(Row(
          children: [
            _label('create clone of'),
            _dropdownSlot(block, 'CLONE_OPTION', block.menuItems, onChanged),
          ],
        ));

      case 'control_delete_this_clone':
        return shell(_label('delete this clone'));

      case 'control_all_at_once':
        return shell(_label('all at once'));

      case 'control_for_each':
        return shell(Row(
          children: [
            _label('for each'),
            _dropdownSlot(block, 'VARIABLE', block.menuItems, onChanged),
            _label('in'),
            _numberSlot(block, 'VALUE', onChanged),
          ],
        ));

      default:
        return shell(Text(block.uiLabel, style: controlText));
    }
  }
}

/// ================== LABEL ==================
Widget _label(String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: controlText),
    );

/// ================== NUMBER SLOT ==================
Widget _numberSlot(
  BlockModel block,
  String field,
  void Function(String, dynamic) onChanged,
) {
  block.arguments.putIfAbsent(field, () => 10);

  return SizedBox(
    height: 26,
    width: 44,
    child: TextFormField(
      initialValue: block.arguments[field].toString(),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final numValue = int.tryParse(v) ?? 0;
        block.updateArgument(field, numValue);
        onChanged(field, numValue);
        block.argumentsNotifier.notifyListeners();
      },
    ),
  );
}

/// ================== DROPDOWN SLOT ==================
Widget _dropdownSlot(
  BlockModel block,
  String field,
  List<String> items,
  void Function(String, dynamic) onChanged, // new parameter
) {
  if (items.isEmpty) items = [''];
  block.arguments.putIfAbsent(field, () => items.first);

  return Container(
    height: 26,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          offset: const Offset(0, 1),
          blurRadius: 1,
        ),
      ],
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: block.arguments[field],
        style: const TextStyle(fontSize: 13, color: Colors.black),
        onChanged: (v) {
          if (v != null) {
            block.updateArgument(field, v);
            onChanged(field, v);
          }
        },
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
      ),
    ),
  );
}

/// ================== BOOLEAN SLOT ==================
Widget _booleanSlot(BlockModel block, String field) {
  return ValueListenableBuilder(
    valueListenable: block.argumentsNotifier, // add this in BlockModel
    builder: (context, _, __) {
      final val = block.arguments[field];
      return Container(
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: val is BlockModel
            ? buildOperatorBlock(
                val,
                onChanged: (_, __) {},
              )
            : CustomPaint(
                painter: ScratchBooleanPainter(),
                child: const SizedBox(width: 60),
              ),
      );
    },
  );
}

/// ================== CONTROL PAINTER ==================
class ScratchControlPainter3D extends CustomPainter {
  final bool hasElse;
  ScratchControlPainter3D({this.hasElse = false});

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
      ..lineTo(notchX + notchW, size.height)
      ..lineTo(notchX + notchW - 4, size.height + notchH)
      ..lineTo(notchX + 4, size.height + notchH)
      ..lineTo(notchX, size.height)
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0);

    canvas.drawPath(path, Paint()..color = controlOrange);
    canvas.drawPath(path.shift(const Offset(0, 1)),
        Paint()..color = controlOrangeLight.withOpacity(0.35));
    canvas.drawPath(path.shift(const Offset(0, -1)),
        Paint()..color = controlOrangeDark.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(_) => false;
}

/// ================== BOOLEAN SHAPE ==================
class ScratchBooleanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .2, 0)
      ..lineTo(size.width * .8, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width * .8, size.height)
      ..lineTo(size.width * .2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();

    canvas.drawPath(
        path, Paint()..color = const Color.fromARGB(255, 251, 251, 251));
  }

  @override
  bool shouldRepaint(_) => false;
}
