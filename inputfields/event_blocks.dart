import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/block_model.dart';

const Color eventOrange = Color(0xFFFFBF00);
const Color eventOrangeLight = Color(0xFFFFD966);
const Color eventOrangeDark = Color(0xFFC79600);

/// =============================================================
/// EVENT BLOCK BUILDER
/// =============================================================
Future<Widget> buildEventBlock(
  Block block, {
  required void Function(String field, String val) onChanged,
  required String projectId,
  double verticalOffset = 0,
  double indent = 0,
}) async {
  /// ------------------ Hive ------------------
  const boxName = 'event_blocks';
  final box =
      Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);

  /// ------------------ Init controllers ------------------
  block.arguments.forEach((k, v) {
    if (v is! Block) {
      final saved = box.get('${projectId}_${block.id}_$k') as String?;
      block.controllers.putIfAbsent(
        k,
        () => TextEditingController(text: saved ?? v.toString()),
      );
      block.arguments[k] = block.controllers[k]!.text;
    }
  });

  /// =============================================================
  /// INPUT SLOT
  /// =============================================================
  Widget inputSlot(String key, {double width = 44}) {
    final val = block.arguments[key];
    return Container(
      height: 26,
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 1, offset: Offset(0, 1))
        ],
      ),
      child: val is Block
          ? FutureBuilder<Widget>(
              future: buildEventBlock(
                val,
                onChanged: onChanged,
                projectId: projectId,
                indent: indent + 12,
              ),
              builder: (_, s) => s.data ?? const SizedBox.shrink(),
            )
          : TextField(
              controller: block.controllers[key],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) {
                block.arguments[key] = v;
                box.put('${projectId}_${block.id}_$key', v);
                onChanged(key, v);
              },
            ),
    );
  }

  /// =============================================================
  /// DROPDOWN SLOT
  /// =============================================================
  Widget dropdownSlot(String key, List<String> items) {
    block.arguments.putIfAbsent(
      key,
      () =>
          (box.get('${projectId}_${block.id}_$key') as String?) ?? items.first,
    );

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 1, offset: Offset(0, 1))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: block.arguments[key] as String,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: const TextStyle(fontSize: 13, color: Colors.black),
          onChanged: (v) {
            if (v == null) return;
            block.arguments[key] = v;
            box.put('${projectId}_${block.id}_$key', v);
            onChanged(key, v);
          },
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  /// =============================================================
  /// CHILD STACK
  /// =============================================================
  List<Widget> buildInnerBlocks() {
    return block.subStack.map((child) {
      return FutureBuilder<Widget>(
        future: buildEventBlock(
          child,
          onChanged: onChanged,
          projectId: projectId,
          indent: indent + 12,
        ),
        builder: (_, s) => s.data ?? const SizedBox.shrink(),
      );
    }).toList();
  }

  /// =============================================================
  /// BLOCK SHELL (STACKABLE)
  /// =============================================================
  Widget shell(Widget content) {
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomPaint(
            painter: ScratchEventHatPainter(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: content,
            ),
          ),
          ...buildInnerBlocks(),
        ],
      ),
    );
  }

  /// =============================================================
  /// BLOCK TYPES
  /// =============================================================
  switch (block.type) {
    case 'event_whenflagclicked':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.flag, size: 16, color: Colors.white),
          SizedBox(width: 6),
          _Label('when green flag clicked'),
        ],
      ));

    case 'event_whenkeypressed':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Label('when key'),
          dropdownSlot('KEY_OPTION', [
            'any',
            'space',
            'up arrow',
            'down arrow',
            'left arrow',
            'right arrow',
          ]),
          const _Label('pressed'),
        ],
      ));

    case 'event_whenthisspriteclicked':
      return shell(const _Label('when this sprite clicked'));

    case 'event_whengreaterthan':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Label('when'),
          dropdownSlot('WHENGREATERTHANMENU', ['timer', 'loudness']),
          const _Label('>'),
          inputSlot('VALUE', width: 40),
        ],
      ));

    case 'event_whenbroadcastreceived':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Label('when I receive'),
          dropdownSlot('BROADCAST_OPTION', ['message1', 'message2']),
        ],
      ));

    default:
      return shell(_Label(block.uiLabel));
  }
}

/// =============================================================
/// LABEL
/// =============================================================
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// =============================================================
/// SCRATCH EVENT HAT + STACK NOTCH PAINTER
/// =============================================================
class ScratchEventHatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const r = 12.0;
    const notchW = 20.0;
    const notchH = 6.0;

    final path = Path()
      ..moveTo(r, 0)
      ..quadraticBezierTo(size.width * .15, -10, size.width * .3, 0) // hat
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - notchH)
      ..lineTo(size.width / 2 + notchW / 2, size.height - notchH)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 - notchW / 2, size.height - notchH)
      ..lineTo(r, size.height - notchH)
      ..quadraticBezierTo(0, size.height - notchH, 0, size.height - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0);

    canvas.drawPath(path, Paint()..color = eventOrange);
    canvas.drawPath(
      path.shift(const Offset(0, 1)),
      Paint()..color = eventOrangeLight.withOpacity(.35),
    );
    canvas.drawPath(
      path.shift(const Offset(0, -1)),
      Paint()..color = eventOrangeDark.withOpacity(.4),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
