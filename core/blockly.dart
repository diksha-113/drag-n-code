// lib/core/blockly.dart

/// ------------------- MAIN BLOCKLY -------------------
class Blockly {
  static Workspace? mainWorkspace;
  static Block? selected;
  static List<dynamic> draggingConnections = [];
  static dynamic clipboardXml;
  static Workspace? clipboardSource;
  static bool? cache3dSupported;
  static Themes theme_ = Themes.classic;

  /// Convert hue to hex color
  static String hueToRgb(num hue, {num saturation = 1, num value = 1}) {
    hue = hue % 360;
    double c = (value * saturation).toDouble();
    double x = (c * (1 - ((hue / 60) % 2 - 1).abs())).toDouble();
    double m = (value - c).toDouble();
    double r = 0, g = 0, b = 0;

    if (hue < 60) {
      r = c;
      g = x;
    } else if (hue < 120) {
      r = x;
      g = c;
    } else if (hue < 180) {
      g = c;
      b = x;
    } else if (hue < 240) {
      g = x;
      b = c;
    } else if (hue < 300) {
      r = x;
      b = c;
    } else {
      r = c;
      b = x;
    }

    int ri = ((r + m) * 255).round();
    int gi = ((g + m) * 255).round();
    int bi = ((b + m) * 255).round();

    return '#${ri.toRadixString(16).padLeft(2, '0')}'
        '${gi.toRadixString(16).padLeft(2, '0')}'
        '${bi.toRadixString(16).padLeft(2, '0')}';
  }

  static Workspace? getMainWorkspace() => mainWorkspace;

  static void svgResize(Workspace workspace) {
    var mainWs = workspace;
    while (mainWs.options.parentWorkspace != null) {
      mainWs = mainWs.options.parentWorkspace!;
    }
    mainWs.resize();
  }

  static Themes get theme => theme_;
  static void setTheme(Themes theme) {
    theme_ = (theme == Themes.catBlocks) ? Themes.catBlocks : Themes.classic;
  }

  /// ------------------- CHAFF / TOOLTIP -------------------
  static void hideChaff([bool allowToolbox = false]) {
    Tooltip.hide();
    DropDownDiv.hideWithoutAnimation();
    WidgetDiv.hide(true);
  }

  static void hideChaffOnResize([bool allowToolbox = false]) {
    hideChaff(allowToolbox);
    WidgetDiv.repositionForWindowResize?.call();
  }

  /// ------------------- KEYBOARD HANDLERS -------------------
  static void onKeyDown(dynamic e) {
    if (mainWorkspace == null ||
        mainWorkspace!.options.readOnly ||
        (mainWorkspace!.rendered && !mainWorkspace!.isVisible())) {
      return;
    }

    bool deleteBlock = false;

    final int? keyCode = e?['keyCode'] as int?;
    final bool altKey = e?['altKey'] == true;
    final bool ctrlKey = e?['ctrlKey'] == true;
    final bool metaKey = e?['metaKey'] == true;
    final bool shiftKey = e?['shiftKey'] == true;

    if (keyCode == 27) {
      hideChaff();
      DropDownDiv.hide();
      return;
    }

    if (keyCode == 8 || keyCode == 46) {
      if (mainWorkspace!.isDragging) return;
      if (selected != null && selected!.isDeletable()) {
        deleteBlock = true;
      }
    } else if (altKey || ctrlKey || metaKey) {
      if (mainWorkspace!.isDragging) return;

      if (selected != null &&
          selected!.isDeletable() &&
          selected!.isMovable()) {
        if (keyCode == 67) {
          hideChaff();
          copy(selected!);
          return;
        } else if (keyCode == 88 && !(selected!.workspace.isFlyout)) {
          copy(selected!);
          deleteBlock = true;
        }
      }

      if (keyCode == 86) {
        if (clipboardXml != null) {
          Events.setGroup(true);
          var workspace = clipboardSource ?? mainWorkspace!;
          if (workspace.isFlyout) workspace = workspace.targetWorkspace!;
          workspace.paste(clipboardXml);
          Events.setGroup(false);
        }
        return;
      } else if (keyCode == 90) {
        hideChaff();
        mainWorkspace!.undo(shiftKey);
        return;
      }
    }

    if (deleteBlock && selected != null && !selected!.workspace.isFlyout) {
      Events.setGroup(true);
      hideChaff();
      selected!.dispose(heal: true, animate: true);
      Events.setGroup(false);
    }
  }

  /// ------------------- CLIPBOARD -------------------
  static void copy(Block toCopy) {
    dynamic xml;
    try {
      xml = toCopy.toXmlWithXY() ?? toCopy.toXml();
      var xy = toCopy.getRelativeToSurfaceXY();
      if (xml is Map) {
        xml['x'] = toCopy.rtl == true ? -xy['x'] : xy['x'];
        xml['y'] = xy['y'];
      }
    } catch (_) {
      xml = toCopy.toXml();
    }
    clipboardXml = xml;
    clipboardSource = toCopy.workspace;
  }

  static void duplicate(Block toDuplicate) {
    final backupXml = clipboardXml;
    final backupSource = clipboardSource;

    copy(toDuplicate);
    if (clipboardXml != null) {
      toDuplicate.workspace.paste(clipboardXml);
    }

    clipboardXml = backupXml;
    clipboardSource = backupSource;
  }

  /// ------------------- UTILITIES -------------------
  static bool onContextMenu(dynamic e) => !Utils.isTargetInput(e);

  static void alert(String message, [Function? optCallback]) {
    if (optCallback != null) optCallback();
  }

  static void confirm(String message, Function(bool) callback) {
    callback(true);
  }

  static void prompt(
    String message,
    String defaultValue,
    Function(String) callback, [
    String? optTitle,
    String? optVarType,
  ]) {
    callback(defaultValue);
  }

  static void statusButtonCallback(String id) {}

  static void refreshStatusButtons(Workspace workspace) {
    var buttons = workspace.getFlyout()?.buttons_ ?? [];
    for (var b in buttons) {
      if (b is FlyoutExtensionCategoryHeader) {
        b.refreshStatus();
      }
    }
  }
}

enum Themes { classic, catBlocks }

/// ------------------- STUB CLASSES -------------------

class DropDownDiv {
  static void hide() {}
  static void hideWithoutAnimation() {}
}

class WidgetDiv {
  static void hide([bool arg = false]) {}
  static void Function()? repositionForWindowResize;
}

class Tooltip {
  static void hide() {}
}

class Events {
  static void setGroup(bool val) {}
}

/// ------------------- WORKSPACE / BLOCK STUBS -------------------

class WorkspaceOptions {
  Workspace? parentWorkspace;
  bool? isFlyout;
  bool readOnly = false;
  Toolbox? toolbox;
}

class Workspace {
  WorkspaceOptions options = WorkspaceOptions();
  bool rendered = false;
  dynamic toolboxPosition;

  void resize() {}
  bool isVisible() => true;
  bool get isDragging => false;

  void paste(dynamic xml) {}
  void undo(bool redo) {}

  Toolbox? get toolbox {
    if (options.toolbox == null && toolboxPosition != null) {
      options.toolbox = Toolbox();
    }
    return options.toolbox;
  }

  dynamic getFlyout() => toolbox?.flyout_;
  Workspace? get targetWorkspace => options.parentWorkspace;
  bool get isFlyout => options.isFlyout ?? false;
}

class Block {
  Workspace get workspace => Workspace();
  bool isDeletable() => true;
  bool isMovable() => true;
  bool? isComment;
  dynamic toXmlWithXY() => {};
  dynamic toXml() => {};
  Map<String, dynamic> getRelativeToSurfaceXY() => {'x': 0, 'y': 0};
  bool? rtl;

  void dispose({bool heal = true, bool animate = true}) {}
}

/// ------------------- TOOLBOX / FLYOUT -------------------

class Toolbox {
  dynamic flyout_;
  void clearSelection() {}
}

class FlyoutHorizontal {}

class VerticalFlyoutWidget {}

class FlyoutExtensionCategoryHeader {
  void refreshStatus() {}
}

/// ------------------- TOUCH / UTILS -------------------

class Touch {
  static List<dynamic> splitEventByTouches(dynamic e) => [e];
  static void setClientFromTouch(dynamic e) {}
}

class Utils {
  static bool isTargetInput(dynamic e) => false;
}
