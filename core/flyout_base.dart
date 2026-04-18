// lib/engine/flyout_base.dart
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:xml/xml.dart';

/// -------------------- STUBS --------------------
class WorkspaceSvg {
  bool isFlyout = false;

  // newBlock function
  Block Function(String type, [String? id]) newBlock =
      (String type, [String? id]) => Block(WorkspaceSvg(), type);

  // Added field for variableMap
  dynamic variableMap;

  double scrollX = 0;
  double scrollY = 0;
  double? scale = 1.0;
  WorkspaceSvg? targetWorkspace;

  void dispose() {}
  void setResizesEnabled(bool enabled) {}
  void addChangeListener(VoidCallback listener) {}
  void removeChangeListener(VoidCallback listener) {}
  dynamic getGesture;
  dynamic getVariableMap() => {};
  void createPotentialVariableMap() {}
  dynamic getPotentialVariableMap() => {};
  List<Block> getTopBlocks(bool all) => [];

  // FIXED: return a function, not a list
  List<dynamic> Function(WorkspaceSvg?)? getToolboxCategoryCallback(
      String name) {
    return (WorkspaceSvg? ws) => <dynamic>[];
  }
}

class Scrollbar {
  final WorkspaceSvg workspace;
  final bool horizontal;
  bool visible;
  String? cssClass;

  Scrollbar(this.workspace, this.horizontal,
      {this.visible = true, this.cssClass});

  void dispose() {}
  void setContainerVisible(bool visible) {}
  void set(double value) {}
}

class Utils {
  static Block domToBlock(XmlElement xml, WorkspaceSvg ws) {
    final type = xml.getAttribute('type') ?? 'block';
    return Block(ws, type);
  }
}

class Block {
  final WorkspaceSvg workspace;
  final String type;
  String? id;
  bool disabled = false;

  Block(this.workspace, this.type, {this.id});

  void dispose(
      {bool recursive = true, bool heal = true, bool animate = true}) {}
  void moveBy(double dx, double dy) {}
  Map<String, double> getRelativeToSurfaceXY() => {'x': 0, 'y': 0};
  void setPosition(double x, double y) {}
}

class FlyoutButton {
  FlyoutButton(WorkspaceSvg ws, WorkspaceSvg? targetWs, XmlElement xml,
      {bool isLabel = false});

  void dispose() {}
  bool getIsCategoryLabel() => false;
  String getText() => '';
  Offset getPosition() => Offset.zero;
}

class FlyoutExtensionCategoryHeader extends FlyoutButton {
  FlyoutExtensionCategoryHeader(
    super.ws,
    super.targetWs,
    super.xml,
  );
}

/// -------------------- FLYOUT CLASS --------------------
class Flyout {
  WorkspaceSvg get workspace => workspace_;
  Scrollbar get scrollbar => scrollbar_!;
  bool get horizontalLayout => horizontalLayout_;

  static const int cornerRadius = 0;
  static const double margin = 12.0;
  static const double gapX = margin * 3;
  static const double gapY = margin;
  static const double scrollbarPadding = 2.0;

  double scrollAnimationFraction = 0.3;
  int dragAngleRange = 70;

  final WorkspaceSvg workspace_;
  final bool rtl;
  final bool horizontalLayout_;
  final int toolboxPosition_;
  final List<List<dynamic>> eventWrappers_ = [];
  final List<Rect> backgroundButtons_ = [];
  final List<FlyoutButton> buttons_ = [];
  final List<dynamic> listeners_ = [];
  final List<Block> permanentlyDisabled_ = [];
  Toolbox? parentToolbox_;
  double? scrollTarget;
  final List<Block> recycleBlocks_ = [];

  bool autoClose = false;
  bool _isVisible = false;
  bool _containerVisible = true;

  double width_ = 0;
  double height_ = 0;
  double contentWidth_ = 0;
  double contentHeight_ = 0;
  double verticalOffset_ = 0;

  bool recyclingEnabled_ = true;

  Scrollbar? scrollbar_;
  WorkspaceSvg? targetWorkspace_;
  List<Map<String, dynamic>> categoryScrollPositions = [];
  VoidCallback? reflowWrapper_;
  WorkspaceSvg? get targetWorkspace => targetWorkspace_;

  Flyout({required Map<String, dynamic> workspaceOptions})
      : workspace_ = WorkspaceSvg(),
        rtl = workspaceOptions['RTL'] == true,
        horizontalLayout_ = workspaceOptions['horizontalLayout'] == true,
        toolboxPosition_ = workspaceOptions['toolboxPosition'] ?? 0 {
    workspace_.isFlyout = true;

    // Save old function and reassign safely
    final oldNewBlock = workspace_.newBlock;
    workspace_.newBlock = (String type, [String? id]) {
      return oldNewBlock(type, id ?? type);
    };
  }

  void init(WorkspaceSvg targetWorkspace) {
    targetWorkspace_ = targetWorkspace;
    workspace_.targetWorkspace = targetWorkspace;

    scrollbar_ = Scrollbar(workspace_, horizontalLayout_);

    position();

    workspace_.getGesture = targetWorkspace.getGesture;
    workspace_.variableMap = targetWorkspace.variableMap;
    workspace_.createPotentialVariableMap();
  }

  void dispose() {
    hide();
    scrollbar_?.dispose();
    scrollbar_ = null;

    workspace_.targetWorkspace = null;
    workspace_.dispose();

    parentToolbox_ = null;
    targetWorkspace_ = null;
  }

  void setParentToolbox(Toolbox toolbox) {
    parentToolbox_ = toolbox;
  }

  bool isVisible() => _isVisible;

  void setVisible(bool visible) {
    bool visibilityChanged = (visible != isVisible());
    _isVisible = visible;
    if (visibilityChanged) updateDisplay_();
  }

  void setContainerVisible(bool visible) {
    bool visibilityChanged = (visible != _containerVisible);
    _containerVisible = visible;
    if (visibilityChanged) updateDisplay_();
  }

  void updateDisplay_() {
    bool show = _containerVisible && _isVisible;
    scrollbar_?.setContainerVisible(show);
  }

  void hide() {
    if (!isVisible()) return;
    setVisible(false);

    listeners_.clear();
    if (reflowWrapper_ != null) {
      workspace_.removeChangeListener(reflowWrapper_!);
      reflowWrapper_ = null;
    }
  }

  void show(List<dynamic> xmlList) {
    workspace_.setResizesEnabled(false);
    hide();
    clearOldBlocks_();

    setVisible(true);

    final List<Map<String, dynamic>> contents = [];
    final List<double> gaps = [];
    permanentlyDisabled_.clear();

    for (int i = 0; i < xmlList.length; i++) {
      var xml = xmlList[i];

      if (xml is String) {
        final fnToApply =
            workspace_.targetWorkspace?.getToolboxCategoryCallback(xml);
        if (fnToApply != null) {
          final newList = fnToApply(workspace_.targetWorkspace);
          xmlList.removeAt(i);
          xmlList.insertAll(i, newList);
          xml = xmlList[i];
        }
      }

      if (xml == null) continue;

      if (xml is XmlElement) {
        final tagName = xml.name.local.toUpperCase();
        final defaultGap = horizontalLayout_ ? gapX : gapY;

        if (tagName == 'BLOCK') {
          final id = xml.getAttribute('id') ?? xml.getAttribute('type');
          int recycledIndex = recycleBlocks_.indexWhere((b) => b.id == id);

          Block curBlock;
          if (recycledIndex > -1) {
            curBlock = recycleBlocks_.removeAt(recycledIndex);
          } else {
            curBlock = Utils.domToBlock(xml, workspace_);
          }

          if (curBlock.disabled) permanentlyDisabled_.add(curBlock);
          contents.add({'type': 'block', 'block': curBlock});

          final gap = xml.getAttribute('gap') != null
              ? double.tryParse(xml.getAttribute('gap')!) ?? defaultGap
              : defaultGap;
          gaps.add(gap);
        } else if (tagName == 'SEP') {
          final newGap = xml.getAttribute('gap') != null
              ? double.tryParse(xml.getAttribute('gap')!)
              : null;
          if (newGap != null && gaps.isNotEmpty) {
            gaps[gaps.length - 1] = newGap;
          } else {
            gaps.add(defaultGap);
          }
        } else if (tagName == 'LABEL' &&
            xml.getAttribute('showStatusButton') == 'true') {
          final curButton = FlyoutExtensionCategoryHeader(
              workspace_, workspace_.targetWorkspace!, xml);
          contents.add({'type': 'button', 'button': curButton});
          gaps.add(defaultGap);
        } else if (tagName == 'BUTTON' || tagName == 'LABEL') {
          final isLabel = tagName == 'LABEL';
          final curButton = FlyoutButton(
              workspace_, workspace_.targetWorkspace!, xml,
              isLabel: isLabel);
          contents.add({'type': 'button', 'button': curButton});
          gaps.add(defaultGap);
        }
      }
    }

    emptyRecycleBlocks_();
    layout_(contents, gaps);

    workspace_.setResizesEnabled(true);
    reflow();

    reflowWrapper_ = () => reflow();
    workspace_.addChangeListener(reflowWrapper_!);

    recordCategoryScrollPositions_();
  }

  void emptyRecycleBlocks_() {
    final oldBlocks = List<Block>.from(recycleBlocks_);
    recycleBlocks_.clear();
    for (var b in oldBlocks) {
      b.dispose(recursive: false, heal: false, animate: false);
    }
  }

  void recordCategoryScrollPositions_() {
    categoryScrollPositions = [];
    for (var button in buttons_) {
      if (button.getIsCategoryLabel()) {
        final categoryLabel = button;
        categoryScrollPositions.add({
          'categoryName': categoryLabel.getText(),
          'position': horizontalLayout_
              ? categoryLabel.getPosition().dx
              : categoryLabel.getPosition().dy
        });
      }
    }
  }

  void stepScrollAnimation() {
    if (scrollTarget == null) return;
    final scrollPos =
        horizontalLayout_ ? -workspace_.scrollX : -workspace_.scrollY;
    final diff = scrollTarget! - scrollPos;
    if (diff.abs() < 1) {
      scrollbar_?.set(scrollTarget!);
      scrollTarget = null;
      return;
    }
    scrollbar_?.set(scrollPos + diff * scrollAnimationFraction);
  }

  double getScrollPos() {
    final pos = horizontalLayout_ ? -workspace_.scrollX : -workspace_.scrollY;
    return pos / (workspace_.scale ?? 1.0);
  }

  void setScrollPos(double pos) {
    scrollbar_?.set(pos * (workspace_.scale ?? 1.0));
  }

  void setRecyclingEnabled(bool recycle) {
    recyclingEnabled_ = recycle;
  }

  void clearOldBlocks_() {
    final oldBlocks = workspace_.getTopBlocks(false);
    for (var block in oldBlocks) {
      if (block.workspace == workspace_) {
        if (recyclingEnabled_ && blockIsRecyclable(block)) {
          recycleBlock_(block);
        } else {
          block.dispose(heal: false, animate: false);
        }
      }
    }

    backgroundButtons_.clear();
    for (var b in buttons_) {
      b.dispose();
    }
    buttons_.clear();
    workspace_.getPotentialVariableMap().clear();
  }

  bool blockIsRecyclable(Block block) => true;

  void recycleBlock_(Block block) {
    final xy = block.getRelativeToSurfaceXY();
    block.moveBy(-xy['x']!, -xy['y']!);
    recycleBlocks_.add(block);
  }

  void layout_(List<Map<String, dynamic>> contents, List<double> gaps) {
    double cursorMain = margin;
    double maxCross = 0;

    buttons_.clear();
    backgroundButtons_.clear();

    for (int i = 0; i < contents.length; i++) {
      final item = contents[i];
      final gap =
          (i < gaps.length) ? gaps[i] : (horizontalLayout_ ? gapX : gapY);

      if (item['type'] == 'block') {
        final Block block = item['block'] as Block;
        const double estimatedBlockWidth = 120.0;
        const double estimatedBlockHeight = 36.0;

        double mainPos = cursorMain;
        double crossPos = margin;

        if (horizontalLayout_) {
          block.setPosition(mainPos, crossPos);
          cursorMain += estimatedBlockWidth + gap;
          maxCross = math.max(maxCross, estimatedBlockHeight + 2 * margin);
        } else {
          block.setPosition(crossPos, mainPos);
          cursorMain += estimatedBlockHeight + gap;
          maxCross = math.max(maxCross, estimatedBlockWidth + 2 * margin);
        }
      } else if (item['type'] == 'button') {
        final FlyoutButton btn = item['button'] as FlyoutButton;

        const double estimatedButtonWidth = 140.0;
        const double estimatedButtonHeight = 28.0;

        double mainPos = cursorMain;
        double crossPos = margin;

        if (horizontalLayout_) {
          final rect = Rect.fromLTWH(
              mainPos, crossPos, estimatedButtonWidth, estimatedButtonHeight);
          backgroundButtons_.add(rect);
          buttons_.add(btn);
          cursorMain += estimatedButtonWidth + gap;
          maxCross = math.max(maxCross, estimatedButtonHeight + 2 * margin);
        } else {
          final rect = Rect.fromLTWH(
              crossPos, mainPos, estimatedButtonWidth, estimatedButtonHeight);
          backgroundButtons_.add(rect);
          buttons_.add(btn);
          cursorMain += estimatedButtonHeight + gap;
          maxCross = math.max(maxCross, estimatedButtonWidth + 2 * margin);
        }
      }
    }

    if (horizontalLayout_) {
      contentWidth_ = cursorMain + margin;
      contentHeight_ = maxCross;
    } else {
      contentHeight_ = cursorMain + margin;
      contentWidth_ = maxCross;
    }
  }

  void position() {}
  void reflow() {}
}

/// Minimal Toolbox stub
class Toolbox {
  Map<String, dynamic>? getCategoryByIndex(int i) => {};
  void selectCategoryById(String id) {}
}
