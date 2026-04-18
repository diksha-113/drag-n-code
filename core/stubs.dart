import 'package:flutter/widgets.dart';

/// Base workspace (empty)
class Workspace {}

/// Main WorkspaceSvg STUB class (renamed to avoid conflict)
class WorkspaceSvgStub extends Workspace {
  final Map<String, dynamic> options;
  WorkspaceSvgStub(this.options);

  bool isFlyout = false;

  /// REQUIRED
  WorkspaceSvgStub? targetWorkspace;

  double scale = 1.0;
  double scrollX = 0.0;
  double scrollY = 0.0;

  Function getGesture = (dynamic e) => null;
  dynamic variableMap = <String, dynamic>{};

  Block Function(String, [String?]) newBlock =
      (type, [id]) => Block(type: type, id: id);

  void setResizesEnabled(bool value) {}
  void setResizesEnabledWith(bool value) {}
  void dispose() {}

  void addChangeListener(VoidCallback listener) {}
  void removeChangeListener(VoidCallback listener) {}

  List<Block> getTopBlocks(bool ordered) => [];

  void createPotentialVariableMap() {}
  Map<String, dynamic> getPotentialVariableMap() => {};

  dynamic getToolboxCategoryCallback(String category) => null;
  dynamic getAllVariables() => [];
  dynamic getVariableMap() => variableMap;

  WorkspaceSvgStub? getFlyout() => isFlyout ? this : null;

  void reflow() {}

  Offset getOriginOffsetInPixels() => Offset.zero;

  Offset get scrollOffset => Offset(scrollX, scrollY);

  void setupDragSurface() {}
  void resetDragSurface() {}

  void setScroll(Offset offset) {
    scrollX = offset.dx;
    scrollY = offset.dy;
  }

  /// FIXED: now includes all required fields
  WorkspaceMetrics getMetrics() => WorkspaceMetrics(
        contentLeft: 0,
        contentTop: 0,
        contentWidth: 1000,
        contentHeight: 1000,
        viewWidth: 300,
        viewHeight: 500,
      );

  void deselectBlock() {}
}

/// Toolbox stub
class Toolbox {
  void selectCategoryById(String id) {}
  dynamic getCategoryByIndex(int index) => null;
}

/// FIXED SCROLLBAR — now supports `visible:` and `cssClass:`
class Scrollbar {
  final WorkspaceSvgStub workspace;
  final bool horizontalLayout;
  bool visible;
  String? cssClass;

  Scrollbar(
    this.workspace,
    this.horizontalLayout, {
    this.visible = true,
    this.cssClass,
  });

  void setContainerVisible(bool v) {
    visible = v;
  }

  void set(double pos) {
    if (horizontalLayout) {
      workspace.scrollX = pos;
    } else {
      workspace.scrollY = pos;
    }
  }

  bool isVisible() => visible;
  void dispose() {}
}

/// Block class
class Block {
  final String id;
  final String type;
  bool disabled = false;
  WorkspaceSvgStub? workspace;

  Block({required this.type, String? id}) : id = id ?? type;

  Offset getRelativeToSurfaceXY() => Offset.zero;

  dynamic getSvgRoot() => Object();

  void moveBy(double dx, double dy) {}

  void dispose({bool recursive = true, bool healStack = true}) {}

  bool get isDeletable => true;
  bool get isMovable => true;

  Block? getParent() => null;
}

/// Flyout items
class FlyoutButton {
  final WorkspaceSvgStub workspace;
  final WorkspaceSvgStub targetWorkspace;
  final dynamic xml;

  FlyoutButton(
    this.workspace,
    this.targetWorkspace,
    this.xml, {
    bool isLabel = false,
  });

  void dispose() {}
  bool getIsCategoryLabel() => false;
  String getText() => '';
  Offset getPosition() => Offset.zero;
}

class FlyoutExtensionCategoryHeader extends FlyoutButton {
  FlyoutExtensionCategoryHeader(
      WorkspaceSvgStub ws, WorkspaceSvgStub target, dynamic xml)
      : super(ws, target, xml);
}

/// XML Node stub
class XmlNode {
  final Map<String, String> attributes = {};
  String get tagName => 'BLOCK';
  String? getAttribute(String key) => attributes[key];
}

/// XML helpers
class XmlUtils {
  static Block domToBlock(XmlNode xml, WorkspaceSvgStub ws) {
    final id = xml.getAttribute('id');
    final type = xml.tagName;
    final block = Block(type: type, id: id);
    block.workspace = ws;
    return block;
  }

  static XmlNode blockToDom(Block block) => XmlNode();
}

/// Event system
class Events {
  static bool _enabled = true;

  static void disable() => _enabled = false;
  static void enable() => _enabled = true;
  static bool isEnabled() => _enabled;

  static void setGroup(bool value) {}
  static void fire(dynamic e) {}
}

class Create {
  Create(Block block);
}

class VarCreate {
  VarCreate(dynamic v);
}

class Variables {
  static List<dynamic> getAddedVariables(
          WorkspaceSvgStub? ws, List<dynamic> oldVars) =>
      [];
}

/// Metrics class
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

/// Offset extension
extension OffsetScale on Offset {
  Offset scale(double s) => Offset(dx * s, dy * s);
}

class BlockDragger {
  void dispose() {}
}
