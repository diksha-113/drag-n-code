/*import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // needed for Ticker

import 'workspace_dragger.dart';
import 'workspace_drag_surface.dart';
import 'block_render_svg_horizontal.dart'; // Horizontal renderer
import '../core/block_render_svg_vertical.dart'; // ✅ Vertical renderer (engine)

// ------------------------- BlockWidget (UI for individual block) -------------------------
class BlockWidget extends StatefulWidget {
  final String type;
  final double width;
  final double height;
  Offset position;
  bool isSelected;
  final String? id;

  BlockWidget({
    Key? key,
    required this.type,
    this.width = 100,
    this.height = 40,
    this.position = Offset.zero,
    this.isSelected = false,
    this.id,
  }) : super(key: key);

  @override
  _BlockWidgetState createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> {
  @override
  Widget build(BuildContext context) {
    final metrics = BlockMetrics()
      ..width = widget.width
      ..height = widget.height
      ..startHat = true
      ..fieldRadius = BlockConstants.fieldDefaultCornerRadius;

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: CustomPaint(
        size: Size(widget.width, widget.height),
        painter: HorizontalBlockPainter(metrics),
        child: Center(
          child: Text(
            widget.type,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------- WorkspaceMetrics -------------------------
class WorkspaceMetrics {
  final double contentLeft;
  final double contentTop;
  final double contentWidth;
  final double contentHeight;
  final double viewWidth;
  final double viewHeight;

  WorkspaceMetrics({
    required this.contentLeft,
    required this.contentTop,
    required this.contentWidth,
    required this.contentHeight,
    required this.viewWidth,
    required this.viewHeight,
  });
}

// ------------------------- WorkspaceState & Widget -------------------------
class Workspace extends StatefulWidget {
  final double width;
  final double height;

  const Workspace({
    Key? key,
    this.width = 800,
    this.height = 600,
  }) : super(key: key);

  @override
  WorkspaceState createState() => WorkspaceState();
}

class WorkspaceState extends State<Workspace> {
  Offset scrollOffset = Offset.zero;
  double scale = 1.0;
  double startScale = 1.0;

  List<BlockWidget> blocks = [];

  late WorkspaceSvgDragger dragger;
  late WorkspaceDragSurface dragSurface;

  @override
  void initState() {
    super.initState();
    dragger = WorkspaceSvgDragger(this);
    dragSurface = WorkspaceDragSurface();

    addMathNumberBlock();
    addMathIntegerBlock();
    addMathWholeNumberBlock();
    addMathPositiveNumberBlock();
    addMathAngleBlock();
    addColourBlock();
  }

  void addMathNumberBlock() => addBlock('math_number');
  void addMathIntegerBlock() => addBlock('math_integer');
  void addMathWholeNumberBlock() => addBlock('math_whole_number');
  void addMathPositiveNumberBlock() => addBlock('math_positive_number');
  void addMathAngleBlock() => addBlock('math_angle');
  void addColourBlock() => addBlock('colour_picker');

  void addBlock(String type) {
    final block = BlockWidget(
      type: type,
      position: Offset(
        math.Random().nextDouble() * (widget.width - 120),
        math.Random().nextDouble() * (widget.height - 60),
      ),
    );

    setState(() {
      blocks.add(block);
    });
  }

  void deselectBlock() {
    setState(() {
      for (var block in blocks) {
        block.isSelected = false;
      }
    });
  }

  void setScroll(Offset offset) {
    setState(() {
      scrollOffset = offset;
    });
  }

  WorkspaceMetrics getMetrics() {
    double minX = 0, minY = 0, maxX = widget.width, maxY = widget.height;

    for (var block in blocks) {
      minX = math.min(minX, block.position.dx);
      minY = math.min(minY, block.position.dy);
      maxX = math.max(maxX, block.position.dx + block.width);
      maxY = math.max(maxY, block.position.dy + block.height);
    }

    return WorkspaceMetrics(
      contentLeft: minX,
      contentTop: minY,
      contentWidth: maxX - minX,
      contentHeight: maxY - minY,
      viewWidth: widget.width,
      viewHeight: widget.height,
    );
  }

  void setupDragSurface() {
    dragSurface.setContents(blocks, scale);
  }

  void resetDragSurface() {
    dragSurface.clear();
  }

  void markFocused() {}

  void setScale(double value) {
    setState(() {
      scale = value.clamp(0.2, 3.0);
    });
  }

  void zoomCenter(int direction) {
    const double zoomStep = 0.1;
    setState(() {
      scale += direction * zoomStep;
      if (scale < 0.2) scale = 0.2;
      if (scale > 3.0) scale = 3.0;
    });
  }

  void scrollCenter() {
    setState(() {
      scrollOffset = Offset.zero;
    });
  }

  // ------------------ BACKWARD COMPATIBILITY METHODS ------------------

  /// Provide access to a dummy gesture object for older code
  dynamic get gesture => null;

  /// Recalculate metrics placeholder
  void recalculateMetrics() {}

  /// Provide bounding box for backward compatibility
  Map<String, double> getBlocksBoundingBox() {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var block in blocks) {
      minX = math.min(minX, block.position.dx);
      minY = math.min(minY, block.position.dy);
      maxX = math.max(maxX, block.position.dx + block.width);
      maxY = math.max(maxY, block.position.dy + block.height);
    }

    if (minX == double.infinity || minY == double.infinity) {
      return {'x': 0.0, 'y': 0.0, 'width': 200.0, 'height': 400.0};
    }

    return {
      'x': minX,
      'y': minY,
      'width': maxX - minX,
      'height': maxY - minY,
    };
  }
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => dragger.startDrag(),
      onPanUpdate: (details) => dragger.drag(details.delta),
      onPanEnd: (_) => dragger.endDrag(Offset.zero),
      child: Stack(
        children: [
          Transform.translate(
            offset: scrollOffset,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: Stack(children: blocks),
            ),
          ),
          dragSurface,
        ],
      ),
    );
  }
}

// ------------------------- Dragger -------------------------
class WorkspaceSvgDragger {
  final WorkspaceState workspace;

  WorkspaceSvgDragger(this.workspace);

  void startDrag() {
    workspace.setupDragSurface();
  }

  void drag(Offset delta) {
    workspace.setScroll(workspace.scrollOffset + delta);
  }

  void endDrag(Offset velocity) {
    workspace.resetDragSurface();
  }
}

// ------------------------------------------------------------
// WorkspaceSvg (ENGINE-LEVEL HELPER — NOT A WIDGET)
// ------------------------------------------------------------
class WorkspaceSvg {
  WorkspaceState? targetWorkspace;

  double scale = 1.0;
  double scrollX = 0.0;
  double scrollY = 0.0;

  final BlockSvg verticalBlockRenderer = BlockSvg();

  Path? flyoutBackgroundPath;

  Rect? _clipRect;
  Rect? get clipRect => _clipRect;
  set clipRect(Rect? value) => _clipRect = value;

  bool isFlyout = false;
  Map<String, dynamic> variableMap = {};
  Map<String, dynamic> getVariableMap() => variableMap;

  double get width => targetWorkspace?.widget.width ?? 0.0;
  double get height => targetWorkspace?.widget.height ?? 0.0;

  void translate(double x, double y) {
    scrollX = x;
    scrollY = y;
    targetWorkspace?.setScroll(Offset(x, y));
  }

  WorkspaceMetrics? getMetrics() => targetWorkspace?.getMetrics();

  void resize() {
    if (targetWorkspace == null) return;
    final metrics = targetWorkspace!.getMetrics();
    translate(metrics.contentLeft, metrics.contentTop);
    targetWorkspace!.setupDragSurface();
  }
}

// ---------------------------
// Flyout compatibility helpers (Scratch-style)
// ---------------------------
extension WorkspaceSvgFlyout on WorkspaceSvg {
  BlockWidget newBlock(String type, [String? id]) {
    final workspace = targetWorkspace;
    if (workspace == null) return BlockWidget(type: type);

    const double startX = -150;
    double startY = 20;

    if (workspace.blocks.isNotEmpty) {
      startY =
          workspace.blocks.last.position.dy + workspace.blocks.last.height + 10;
    }

    final blockWidget = BlockWidget(
      type: type,
      position: Offset(startX, startY),
      id: id,
    );

    workspace.setState(() {
      workspace.blocks.add(blockWidget);
    });

    // Animate block sliding in from left
    final targetPosition = Offset(20, startY);
    const duration = Duration(milliseconds: 300);

    late Ticker ticker;
    ticker = Ticker((elapsed) {
      final t =
          (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      blockWidget.position =
          Offset.lerp(Offset(startX, startY), targetPosition, t)!;
      workspace.setState(() {});
      if (t >= 1.0) ticker.stop();
    });

    ticker.start();

    return blockWidget;
  }

  void createPotentialVariableMap() {}

  Map<String, double> getBlocksBoundingBox() {
    final metrics = getMetrics();
    if (metrics != null) {
      return {
        'x': metrics.contentLeft,
        'y': metrics.contentTop,
        'width': metrics.contentWidth,
        'height': metrics.contentHeight,
      };
    }
    return {'x': 0.0, 'y': 0.0, 'width': 200.0, 'height': 400.0};
  }
}
*/
