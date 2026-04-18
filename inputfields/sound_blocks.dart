import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/block_model.dart';
import '../core/workspace.dart';

/// ================== COLORS ==================
const soundPink = Color(0xFFCF63CF);
const soundPinkLight = Color(0xFFE6A0E6);
const soundPinkDark = Color(0xFF9E3E9E);

/// ================== MAIN BUILDER ==================
Future<Widget> buildSoundBlocks(
  Block block, {
  required Sprite sprite,
  required void Function(String field, String val) onChanged,
  required void Function(String soundName) onPreviewSound,
  required String projectId,
  double verticalOffset = 0,
  double indent = 0,
}) async {
  const boxName = 'sound_blocks';
  Box box =
      Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);

  /// ---------- INIT CONTROLLERS ----------
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

  /// ---------- INPUT SLOT ----------
  Widget inputSlot(String key, {double width = 42}) {
    return Container(
      height: 26,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: _whiteSlotDecoration(),
      alignment: Alignment.center,
      child: TextField(
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

  // ---------- DROPDOWN SLOT ----------
  Widget dropdownSlot(
    String key,
    List<Map<String, dynamic>> soundList, {
    required Sprite sprite,
  }) {
    final items = soundList.isNotEmpty
        ? soundList.map((s) => s['name'].toString()).toList()
        : ['No sounds'];

    final saved = box.get('${projectId}_${block.id}_$key') as String?;
    final defaultValue = items.first;

    // ✅ DO NOT overwrite on rebuild
    block.arguments[key] ??= saved ?? defaultValue;

    // 🔴 CRITICAL: restore SOUND_ID when rebuilding
    if (key == 'SOUND_MENU' &&
        block.arguments[key] != null &&
        block.arguments['SOUND_ID'] == null &&
        block.arguments[key] != 'No sounds') {
      final sound = soundList.firstWhere(
        (s) => s['name'] == block.arguments[key],
        orElse: () => {},
      );
      if (sound.isNotEmpty) {
        block.arguments['SOUND_ID'] = sound['soundId'] as String;
      }
    }

    final valueInItems = items.contains(block.arguments[key])
        ? block.arguments[key]
        : defaultValue;

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: _whiteSlotDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valueInItems,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: const TextStyle(fontSize: 13, color: Colors.black),
          onChanged: (v) {
            if (v == null) return;

            // ✅ Update label
            block.arguments[key] = v;
            box.put('${projectId}_${block.id}_$key', v);

            // ✅ Update SOUND_ID (NO preview, Scratch-like)
            if (key == 'SOUND_MENU' && v != 'No sounds') {
              final sound = soundList.firstWhere(
                (s) => s['name'] == v,
                orElse: () => {},
              );
              if (sound.isNotEmpty) {
                block.arguments['SOUND_ID'] = sound['soundId'] as String;
              }
            }

            onChanged(key, v);
          },
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

// ---------- DROPDOWN SLOT FOR STRING LISTS (EFFECT, etc.) ----------
  Widget dropdownSlotString(String key, List<String> items) {
    final safeItems = items.isNotEmpty ? items : ['None'];
    final saved = box.get('${projectId}_${block.id}_$key') as String?;
    final defaultValue = safeItems.first;

    // ✅ DO NOT overwrite on rebuild
    block.arguments[key] ??= saved ?? defaultValue;

    final valueInItems = safeItems.contains(block.arguments[key])
        ? block.arguments[key]
        : defaultValue;

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: _whiteSlotDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valueInItems,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: const TextStyle(fontSize: 13, color: Colors.black),
          onChanged: (v) {
            if (v == null) return;
            block.arguments[key] = v;
            box.put('${projectId}_${block.id}_$key', v);
            onChanged(key, v);
          },
          items: safeItems
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  /// ---------- STACK SHELL ----------
  Widget shell(Widget child) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: verticalOffset, left: indent),
      child: Material(
        elevation: indent > 0 ? 2 : 4,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: ScratchSoundStackPainter3D(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: child,
          ),
        ),
      ),
    );
  }

  /// ---------- REPORTER ----------
  Widget reporter(String label) {
    return CustomPaint(
      painter: ScratchSoundReporterPainter3D(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// ================== BLOCK SWITCH ==================
  switch (block.type) {
    case 'sound_play':
      return shell(Row(children: [
        _soundLabel('start sound'),
        dropdownSlot('SOUND_MENU', sprite.sounds, sprite: sprite),
      ]));

    case 'sound_playuntildone':
      return shell(Row(children: [
        _soundLabel('play sound'),
        dropdownSlot('SOUND_MENU', sprite.sounds, sprite: sprite),
        _soundLabel('until done'),
      ]));

    case 'sound_stopallsounds':
      return shell(_soundLabel('stop all sounds'));

    case 'sound_seteffectto':
      return shell(Row(children: [
        _soundLabel('set'),
        dropdownSlotString('EFFECT', ['pitch', 'pan']),
        _soundLabel('to'),
        inputSlot('VALUE'),
      ]));

    case 'sound_changeeffectby':
      return shell(Row(children: [
        _soundLabel('change'),
        dropdownSlotString('EFFECT', ['pitch', 'pan']),
        _soundLabel('by'),
        inputSlot('VALUE'),
      ]));

    case 'sound_cleareffects':
      return shell(_soundLabel('clear sound effects'));

    case 'sound_setvolumeto':
      return shell(Row(children: [
        _soundLabel('set volume to'),
        inputSlot('VOLUME'),
        _soundLabel('%'),
      ]));

    case 'sound_changevolumeby':
      return shell(Row(children: [
        _soundLabel('change volume by'),
        inputSlot('VOLUME'),
        _soundLabel('%'),
      ]));

    case 'sound_volume':
      return reporter('volume');

    default:
      return shell(Text(
        block.uiLabel,
        style: const TextStyle(color: Colors.white),
      ));
  }
}

/// ================== HELPERS ==================
Widget _soundLabel(String t) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        t,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

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

/// ================== STACK PAINTER ==================
class ScratchSoundStackPainter3D extends CustomPainter {
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

    canvas.drawPath(path, Paint()..color = soundPink);
    canvas.drawPath(path.shift(const Offset(0, 1)),
        Paint()..color = soundPinkLight.withOpacity(0.4));
    canvas.drawPath(path.shift(const Offset(0, -1)),
        Paint()..color = soundPinkDark.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(_) => false;
}

/// ================== REPORTER PAINTER ==================
class ScratchSoundReporterPainter3D extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = soundPink);
    canvas.drawRRect(rect.shift(const Offset(0, 1)),
        Paint()..color = soundPinkLight.withOpacity(0.4));
    canvas.drawRRect(rect.shift(const Offset(0, -1)),
        Paint()..color = soundPinkDark.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(_) => false;
}
