import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/block_model.dart';

const Color motionBlue = Color(0xFF4C97FF);
const Color motionBlueLight = Color(0xFF7FB5FF);
const Color motionBlueDark = Color(0xFF3373CC);

/// ================== MOTION BLOCK BUILDER ==================
Future<Widget> buildMotionBlock(
  Block block, {
  required void Function(String field, String val) onChanged,
  required String projectId,
  double verticalOffset = 0,
  double indent = 0,
}) async {
  // ------------------ Hive Initialization ------------------
  const boxName = 'motion_blocks';
  Box box;
  if (Hive.isBoxOpen(boxName)) {
    box = Hive.box(boxName);
  } else {
    box = await Hive.openBox(boxName);
  }

  // Ensure controllers exist
  block.controllers.forEach((k, v) {});

  // Ensure arguments are initialized for primitive values
  block.arguments.forEach((k, v) {
    if (v is! Block) {
      final saved = box.get('${projectId}_${block.id}_$k') as String?;
      block.controllers.putIfAbsent(
          k, () => TextEditingController(text: saved ?? v.toString()));
      block.arguments[k] = block.controllers[k]!.text;
    }
  });

  /// ================== INPUT SLOT ==================
  Widget inputSlot(String key, {double width = 42}) {
    final val = block.arguments[key];
    return Container(
      height: 26,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 1),
            blurRadius: 1,
          )
        ],
      ),
      alignment: Alignment.center,
      child: val is Block
          ? FutureBuilder<Widget>(
              future: buildMotionBlock(
                val,
                onChanged: onChanged,
                projectId: projectId,
                indent: indent + 12,
              ),
              builder: (context, snapshot) {
                return snapshot.data ?? const SizedBox.shrink();
              },
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

  /// ================== DROPDOWN SLOT ==================
  Widget dropdownSlot(String key, List<String> items) {
    block.arguments.putIfAbsent(
        key,
        () =>
            (box.get('${projectId}_${block.id}_$key') as String?) ??
            items.first);

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 1),
            blurRadius: 1,
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: block.arguments[key] as String?,
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

  /// ================== REPORTER ==================
  Widget reporter(String label) {
    return CustomPaint(
      painter: ScratchReporterPainter3D(),
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

  /// ================== RECURSIVE CHILD STACK ==================
  List<Widget> buildInnerBlocks(Block block, double offset, double indent) {
    final widgets = <Widget>[];
    double childOffset = 0;
    for (var child in block.subStack) {
      widgets.add(FutureBuilder<Widget>(
        future: buildMotionBlock(
          child,
          onChanged: onChanged,
          projectId: projectId,
          verticalOffset: offset + childOffset,
          indent: indent + 12,
        ),
        builder: (context, snapshot) =>
            snapshot.data ?? const SizedBox.shrink(),
      ));
      childOffset += child.visualHeight + 8; // prevents overlap
    }
    return widgets;
  }

  /// ================== STACK BLOCK ==================
  Widget shell(Widget child) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: verticalOffset, left: indent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            elevation: indent > 0 ? 2 : 4,
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(
              painter: ScratchStackPainter3D(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: child,
              ),
            ),
          ),
          ...buildInnerBlocks(block, verticalOffset, indent),
        ],
      ),
    );
  }

  /// ================== TYPES ==================
  switch (block.type) {
    case 'motion_movesteps':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('move'),
          inputSlot('value'),
          _label('steps'),
        ],
      ));

    case 'motion_turnright':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('turn right'),
          inputSlot('value'),
          _label('degrees'),
        ],
      ));

    case 'motion_turnleft':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('turn left'),
          inputSlot('value'),
          _label('degrees'),
        ],
      ));

    case 'motion_gotoxy':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('go to x:'),
          inputSlot('x'),
          _label('y:'),
          inputSlot('y'),
        ],
      ));
    case 'motion_setrotationstyle':
      return shell(
        Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _label('set rotation style'),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(0, 1),
                      blurRadius: 1,
                    )
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: block.arguments['value'] as String? ?? 'all around',
                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    onChanged: (v) {
                      if (v == null) return;

                      // Only save the selection in block arguments + Hive
                      block.arguments['value'] = v;
                      if (Hive.isBoxOpen('motion_blocks')) {
                        Hive.box('motion_blocks').put('${block.id}_value', v);
                      }

                      // ✅ Do NOT apply to sprite here
                    },
                    items: [
                      'all around',
                      'left-right',
                      "don't rotate",
                    ]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

    // ================= GLIDE TO X,Y =================
    case 'motion_glidesecstoxy':
      return shell(
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _label('glide'),
            const SizedBox(width: 4),
            Flexible(
              child: SizedBox(
                height: 20, // 👈 key line
                child: inputSlot('t', width: 28),
              ),
            ),
            const SizedBox(width: 4),
            _label('secs'),
            const SizedBox(width: 6),
            _label('to x:'),
            Flexible(
              child: SizedBox(
                height: 20,
                child: inputSlot('x', width: 36),
              ),
            ),
            const SizedBox(width: 6),
            _label('y:'),
            Flexible(
              child: SizedBox(
                height: 20,
                child: inputSlot('y', width: 36),
              ),
            ),
          ],
        ),
      );

// ================= GLIDE TO RANDOM =================
    case 'motion_glidesecstorandom':
      return shell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: _label('glide')), // flexible label
            const SizedBox(width: 4),
            inputSlot('t', width: 30),
            const SizedBox(width: 4),
            Flexible(child: _label('random')), // shorter label & flexible
          ],
        ),
      );

    // ================= POINT IN DIRECTION =================
    case 'motion_pointindirection':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('point in direction'),
          inputSlot('value'),
        ],
      ));

    // ================= POINT TOWARDS =================
    case 'motion_pointtowards':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('point towards'),
          dropdownSlot('target', ['mouse']),
        ],
      ));

    // ================= CHANGE X =================
    case 'motion_changexby':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('change x by'),
          inputSlot('value'),
        ],
      ));

    // ================= SET X =================
    case 'motion_setx':
      return shell(
        Row(
          children: [
            Flexible(
              child: _label('set x to'), // label adapts to space
            ),
            const SizedBox(width: 6),
            Expanded(
              child: inputSlot('value'), // input expands to available space
            ),
          ],
        ),
      );

    // ================= CHANGE Y =================
    case 'motion_changeyby':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('change y by'),
          inputSlot('value'),
        ],
      ));

    // ================= SET Y =================
    case 'motion_sety':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('set y to'),
          inputSlot('value'),
        ],
      ));

    // ================= IF ON EDGE, BOUNCE =================
    case 'motion_ifonedgebounce':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('if on edge, bounce'),
        ],
      ));

    // ================= SPIN 360 (CUSTOM) =================
    case 'motion_spin360':
      return shell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('spin 360°'),
        ],
      ));

    default:
      return shell(
          Text(block.uiLabel, style: const TextStyle(color: Colors.white)));
  }
}

/// ================== LABEL ==================
Widget _label(String t) => Padding(
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

/// ================== STACK PAINTER (REAL 3D) ==================
class ScratchStackPainter3D extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const r = 12.0;
    const notchW = 18.0;
    const notchH = 6.0;
    const notchX = 24.0;

    Path base = Path()
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

    canvas.drawPath(base, Paint()..color = motionBlue);
    canvas.drawPath(base.shift(const Offset(0, 1)),
        Paint()..color = motionBlueLight.withOpacity(0.4));
    canvas.drawPath(base.shift(const Offset(0, -1)),
        Paint()..color = motionBlueDark.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(_) => false;
}

/// ================== REPORTER PAINTER (3D, SCRATCH STYLE) ==================
class ScratchReporterPainter3D extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(6), // matches input field radius
    );
    canvas.drawRRect(rect, Paint()..color = motionBlue);
    canvas.drawRRect(rect.shift(const Offset(0, 1)),
        Paint()..color = motionBlueLight.withOpacity(0.4));
    canvas.drawRRect(rect.shift(const Offset(0, -1)),
        Paint()..color = motionBlueDark.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
