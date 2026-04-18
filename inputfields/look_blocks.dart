import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/block_model.dart';

const Color scratchPurple = Color(0xFF9966FF);

const TextStyle _labelStyle = TextStyle(
  color: Colors.white,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: 1.0,
);

Widget buildLooksBlock(
  BlockModel block, {
  required void Function(String field, String value) onChanged,
}) {
  block.controllers ??= <String, TextEditingController>{};
  block.values ??= <String, String>{};

  // ------------------- HELPER -------------------
  String getControllerText(String key, {String fallback = '1'}) {
    if (block.controllers?[key] != null) {
      final text = block.controllers![key]!.text;
      return text.isEmpty ? fallback : text;
    }
    return fallback;
  }

  // ------------------- INIT *_forsecs BLOCKS -------------------
  if (block.type == 'looks_sayforsecs' || block.type == 'looks_thinkforsecs') {
    block.values!['value'] ??=
        block.type == 'looks_sayforsecs' ? 'Hello!' : 'Hmm...';
    block.values!['secs'] ??= '2';
    block.value = block.values!['value'];
  }

  // ------------------- TEXT FIELD -------------------
  Widget textField(String key, {double width = 110, String defaultValue = ''}) {
    block.controllers![key] ??=
        TextEditingController(text: block.values![key] ?? defaultValue);
    block.values![key] ??= defaultValue;

    return SizedBox(
      width: width,
      height: 22,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: _whiteSlotDecoration(),
        child: TextField(
          controller: block.controllers![key],
          maxLines: 1,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
          ),
          onChanged: (v) {
            block.values![key] = v;
            if (key == 'value') block.value = v;
            onChanged(key, v);
          },
        ),
      ),
    );
  }

  // ------------------- NUMBER FIELD -------------------
  Widget numberField(String key,
      {double width = 38, String defaultValue = '1'}) {
    block.controllers![key] ??=
        TextEditingController(text: block.values![key] ?? defaultValue);
    block.values![key] ??= defaultValue;

    return SizedBox(
      width: width,
      height: 22,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: _whiteSlotDecoration(),
        child: TextField(
          controller: block.controllers![key],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
          ),
          onChanged: (v) {
            block.values![key] = v;
            onChanged(key, v);
          },
        ),
      ),
    );
  }

  // ------------------- DROPDOWN FIELD -------------------
  Widget dropdownField(String key, List<String> options) {
    block.values![key] ??= options.first;

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: _whiteSlotDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: block.values![key],
          style: const TextStyle(fontSize: 12, color: Colors.black),
          onChanged: (v) {
            if (v == null) return;
            block.values![key] = v;
            if (key == 'value') block.value = v;
            onChanged(key, v);
          },
          items: options
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
        ),
      ),
    );
  }

  // ------------------- STACK SHELL -------------------
  Widget looksShell(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: ScratchLooksStackPainter3D(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children
                  .map((w) => Padding(
                      padding: const EdgeInsets.only(right: 6), child: w))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------- LOOKS BLOCKS -------------------
  switch (block.type) {
    case 'looks_say':
      return looksShell([
        const Text('say', style: _labelStyle),
        textField('value', defaultValue: 'Hello!'),
      ]);

    case 'looks_sayforsecs':
      return looksShell([
        const Text('say', style: _labelStyle),
        textField('value'),
        numberField('secs', defaultValue: '2'),
        const Text('seconds', style: _labelStyle),
      ]);

    case 'looks_think':
      return looksShell([
        const Text('think', style: _labelStyle),
        textField('value', defaultValue: 'Hmm...'),
      ]);

    case 'looks_thinkforsecs':
      return looksShell([
        const Text('think', style: _labelStyle),
        textField('value'),
        numberField('secs', defaultValue: '2'),
        const Text('seconds', style: _labelStyle),
      ]);

    case 'looks_show':
      return looksShell([const Text('show', style: _labelStyle)]);

    case 'looks_hide':
      return looksShell([const Text('hide', style: _labelStyle)]);

    case 'looks_nextcostume':
      return looksShell([const Text('next costume', style: _labelStyle)]);

    case 'looks_switchcostumeto':
      return looksShell([
        const Text('switch costume to', style: _labelStyle),
        dropdownField('value', block.dropdownOptions ?? ['costume1']),
      ]);

    case 'looks_switchbackdropto':
      return looksShell([
        const Text('switch backdrop to', style: _labelStyle),
        dropdownField('value', block.dropdownOptions ?? ['backdrop1']),
      ]);

    case 'looks_changeeffectby':
      return looksShell([
        const Text('change effect', style: _labelStyle),
        dropdownField('effect', ['color', 'fisheye']),
        numberField('value', defaultValue: '10'),
      ]);

    case 'looks_seteffectto':
      return looksShell([
        const Text('set effect', style: _labelStyle),
        dropdownField('effect', ['color', 'fisheye']),
        numberField('value', defaultValue: '0'),
      ]);

    case 'looks_cleargraphiceffects':
      return looksShell(
          [const Text('clear graphic effects', style: _labelStyle)]);

    case 'looks_changesizeby':
      return looksShell([
        const Text('change size by', style: _labelStyle),
        numberField('value', defaultValue: '10'),
      ]);

    case 'looks_setsizeto':
      return looksShell([
        const Text('set size to', style: _labelStyle),
        numberField('value', defaultValue: '100'),
      ]);

    case 'looks_gotofrontback':
      return looksShell([
        const Text('go to', style: _labelStyle),
        dropdownField('value', ['front', 'back']),
      ]);

    case 'looks_goforwardbackwardlayers':
      return looksShell([
        const Text('change layer by', style: _labelStyle),
        numberField('value', defaultValue: '1'),
      ]);

    case 'looks_costumename':
      return looksShell([const Text('costume name', style: _labelStyle)]);

    case 'looks_backdropname':
      return looksShell([const Text('backdrop name', style: _labelStyle)]);

    default:
      return looksShell([Text(block.uiLabel, style: _labelStyle)]);
  }
}

/// ------------------- SLOT DECORATION -------------------
BoxDecoration _whiteSlotDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          offset: const Offset(0, 1),
          blurRadius: 1,
        ),
      ],
    );

/// ------------------- STACK PAINTER -------------------
class ScratchLooksStackPainter3D extends CustomPainter {
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

    canvas.drawPath(path, Paint()..color = scratchPurple);
    canvas.drawPath(path.shift(const Offset(0, 1)),
        Paint()..color = scratchPurple.withOpacity(0.35));
    canvas.drawPath(path.shift(const Offset(0, -1)),
        Paint()..color = Colors.black.withOpacity(0.25));
  }

  @override
  bool shouldRepaint(_) => false;
}
