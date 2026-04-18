import 'package:flutter/material.dart';
import '../../../models/block_model.dart';

/// =============================================================
/// DRAGGABLE LOGIC BLOCK
/// =============================================================
class DraggableLogicBlock extends StatefulWidget {
  final BlockModel block;
  final Widget child;
  final Offset initialPosition;
  final ValueChanged<Offset>? onDragEnd;

  const DraggableLogicBlock({
    super.key,
    required this.block,
    required this.child,
    this.initialPosition = const Offset(40, 40),
    this.onDragEnd,
  });

  @override
  State<DraggableLogicBlock> createState() => _DraggableLogicBlockState();
}

class _DraggableLogicBlockState extends State<DraggableLogicBlock> {
  late Offset position;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable<BlockModel>(
        data: widget.block,
        feedback: Material(
          color: Colors.transparent,
          child: widget.child,
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: widget.child),
        onDragEnd: (details) {
          setState(() => position = details.offset);
          widget.onDragEnd?.call(position);
        },
        child: widget.child,
      ),
    );
  }
}

/// =============================================================
/// DROPDOWN SOCKET
/// =============================================================
class DropdownValueSocket extends StatelessWidget {
  final BlockModel parent;
  final String keyName;
  final List<String> options;

  const DropdownValueSocket({
    super.key,
    required this.parent,
    required this.keyName,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final current = parent.inputs[keyName]?.value as String?;
    return Container(
      width: 50,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: current,
        underline: const SizedBox(),
        items: options
            .map((e) => DropdownMenuItem(
                value: e, child: Text(e, style: const TextStyle(fontSize: 12))))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            parent.inputs[keyName] =
                LogicBlocks.createBooleanOrOperatorBlock(v);
          }
        },
      ),
    );
  }
}

/// =============================================================
/// LOGIC BLOCK WIDGET
/// =============================================================
class LogicBlockWidget extends StatelessWidget {
  final String label;
  final ScratchBlockShape shape;
  final List<Widget> inputs;
  final List<Widget> body;
  final Color color;

  const LogicBlockWidget({
    super.key,
    required this.label,
    required this.shape,
    this.inputs = const [],
    this.body = const [],
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: ScratchLogicBlockPainter3D(shape: shape, color: color),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (label.isNotEmpty)
                    Text(label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                  const SizedBox(width: 6),
                  ...inputs,
                ],
              ),
              if (body.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 16, top: 6),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(children: body),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================== 3D PAINTER ==================
class ScratchLogicBlockPainter3D extends CustomPainter {
  final ScratchBlockShape shape;
  final Color color;

  ScratchLogicBlockPainter3D({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    const radius = 6.0;
    const notchW = 18.0;
    const notchH = 6.0;

    path.moveTo(radius, 0);
    if (shape != ScratchBlockShape.boolean &&
        shape != ScratchBlockShape.reporter) {
      path.lineTo(20, 0);
      path.lineTo(20 + notchW / 2, notchH);
      path.lineTo(20 + notchW, 0);
    }
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    if (shape == ScratchBlockShape.c || shape == ScratchBlockShape.cElse) {
      path.lineTo(20 + notchW, size.height);
      path.lineTo(20 + notchW / 2, size.height + notchH);
      path.lineTo(20, size.height);
    }
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawShadow(path, Colors.black.withOpacity(0.4), 4, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// =============================================================
/// LOGIC BLOCK FACTORY
/// =============================================================
class LogicBlocks {
  /// ---------- BOOLEAN BLOCKS ----------
  static BlockModel trueBlock() => BlockModel(
      type: 'logic_true', shape: ScratchBlockShape.boolean, value: 'true');

  static BlockModel falseBlock() => BlockModel(
      type: 'logic_false', shape: ScratchBlockShape.boolean, value: 'false');

  /// ---------- LOGIC OPERATIONS ----------
  static BlockModel andBlock(BlockModel a, BlockModel b) => BlockModel(
      type: 'logic_operation',
      shape: ScratchBlockShape.boolean,
      value: 'AND',
      inputs: {'A': a, 'B': b});

  static BlockModel orBlock(BlockModel a, BlockModel b) => BlockModel(
      type: 'logic_operation',
      shape: ScratchBlockShape.boolean,
      value: 'OR',
      inputs: {'A': a, 'B': b});

  static BlockModel notBlock(BlockModel input) => BlockModel(
      type: 'logic_negate',
      shape: ScratchBlockShape.boolean,
      inputs: {'A': input});

  static BlockModel nullBlock() => BlockModel(
      type: 'null_block', shape: ScratchBlockShape.boolean, value: '');

  /// ---------- CONTROL ----------
  static BlockModel ifBlock(BlockModel condition, List<BlockModel> thenBlocks) {
    final block = BlockModel(
        type: 'control_if',
        shape: ScratchBlockShape.c,
        inputs: {'condition': condition});
    block.innerBlocks.addAll(thenBlocks);
    return block;
  }

  static BlockModel ifElseBlock(BlockModel condition,
      List<BlockModel> thenBlocks, List<BlockModel> elseBlocks) {
    final block = BlockModel(
        type: 'control_if_else',
        shape: ScratchBlockShape.cElse,
        inputs: {'condition': condition});
    block.innerBlocks.addAll(thenBlocks);
    block.elseBlocks.addAll(elseBlocks);
    return block;
  }

  /// ---------- HELPER: DROPDOWN BLOCKS ----------
  static BlockModel createBooleanOrOperatorBlock(String value) {
    switch (value) {
      case 'true':
        return trueBlock();
      case 'false':
        return falseBlock();
      case 'AND':
        return BlockModel(
            type: 'logic_operation',
            shape: ScratchBlockShape.boolean,
            value: 'AND');
      case 'OR':
        return BlockModel(
            type: 'logic_operation',
            shape: ScratchBlockShape.boolean,
            value: 'OR');
      default:
        return nullBlock();
    }
  }

  /// ---------- RECURSIVE WIDGET BUILDER ----------
  static Widget buildWidget(BlockModel block, {double indent = 0}) {
    // Determine color based on block type
    Color color = _getBlockColor(block);

    // Inputs
    List<Widget> inputWidgets = [];
    if (block.inputs.containsKey('A')) {
      inputWidgets.add(DropdownValueSocket(
          parent: block,
          keyName: 'A',
          options: ['true', 'false', 'AND', 'OR']));
    }
    if (block.inputs.containsKey('B')) {
      inputWidgets.add(const SizedBox(width: 6));
      inputWidgets.add(DropdownValueSocket(
          parent: block,
          keyName: 'B',
          options: ['true', 'false', 'AND', 'OR']));
    }

    // Inner and else blocks
    List<Widget> bodyWidgets = [];
    if (block.innerBlocks.isNotEmpty) {
      bodyWidgets.addAll(
          block.innerBlocks.map((b) => buildWidget(b, indent: indent + 16)));
    }
    if (block.elseBlocks.isNotEmpty) {
      bodyWidgets.add(const Divider(color: Colors.white, thickness: 1.5));
      bodyWidgets.addAll(
          block.elseBlocks.map((b) => buildWidget(b, indent: indent + 16)));
    }

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 6),
      child: LogicBlockWidget(
        label: block.uiLabel,
        shape: block.shape,
        inputs: inputWidgets,
        body: bodyWidgets,
        color: color,
      ),
    );
  }

  static Color _getBlockColor(BlockModel block) {
    switch (block.type) {
      case 'logic_true':
      case 'logic_false':
        return Colors.green.shade700;
      case 'logic_operation':
      case 'logic_negate':
        return Colors.orange.shade700;
      case 'control_if':
      case 'control_if_else':
        return Colors.purple.shade700;
      default:
        return Colors.blue.shade700;
    }
  }
}
