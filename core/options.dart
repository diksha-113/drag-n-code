/*// lib/engine/options.dart
import 'colours.dart';
import 'xml.dart';

class Options {
  final bool RTL;
  final bool oneBasedIndex;
  final bool collapse;
  final bool comments;
  final bool disable;
  final bool readOnly;
  final String pathToMedia;
  final bool hasCategories;
  final bool hasScrollbars;
  final bool hasTrashcan;
  final bool hasSounds;
  final bool hasCss;
  final bool horizontalLayout;
  final dynamic languageTree;
  final Map<String, dynamic> gridOptions;
  final Map<String, dynamic> zoomOptions;
  final String toolboxPosition;

  Options(Map<String, dynamic> options)
      : readOnly = options['readOnly'] ?? false,
        RTL = options['rtl'] ?? false,
        horizontalLayout = options['horizontalLayout'] ?? false,
        hasScrollbars = options['scrollbars'] ?? false,
        hasTrashcan = options['trashcan'] ?? false,
        hasSounds = options['sounds'] ?? true,
        hasCss = options['css'] ?? true,
        oneBasedIndex = options['oneBasedIndex'] ?? true,
        collapse = options['collapse'] ?? false,
        comments = options['comments'] ?? false,
        disable = options['disable'] ?? false,
        pathToMedia = options['media'] ??
            (options['path'] != null
                ? options['path'] + 'media/'
                : 'assets/media/'),
        hasCategories = false,
        languageTree = parseToolboxTree(options['toolbox']),
        gridOptions = parseGridOptions(options),
        zoomOptions = parseZoomOptions(options),
        toolboxPosition = computeToolboxPosition(options['toolboxPosition'],
            options['rtl'], options['horizontalLayout']);

  static Map<String, dynamic> parseZoomOptions(Map<String, dynamic> options) {
    var zoom = options['zoom'] ?? {};
    return {
      'controls': zoom['controls'] ?? false,
      'wheel': zoom['wheel'] ?? false,
      'startScale': (zoom['startScale'] ?? 1).toDouble(),
      'maxScale': (zoom['maxScale'] ?? 3).toDouble(),
      'minScale': (zoom['minScale'] ?? 0.3).toDouble(),
      'scaleSpeed': (zoom['scaleSpeed'] ?? 1.2).toDouble(),
    };
  }

  static Map<String, dynamic> parseGridOptions(Map<String, dynamic> options) {
    var grid = options['grid'] ?? {};
    var spacing = (grid['spacing'] ?? 0).toDouble();
    return {
      'spacing': spacing,
      'colour': grid['colour'] ?? '#888',
      'length': (grid['length'] ?? 1).toDouble(),
      'snap': spacing > 0 && (grid['snap'] ?? false),
    };
  }

  static dynamic parseToolboxTree(dynamic tree) {
    if (tree == null) return null;
    if (tree is String) {
      return XmlEngine.textToDom(tree); // Use your Xml parser for Flutter
    }
    return tree; // Already DOM
  }

  static String computeToolboxPosition(
      String? position, bool rtl, bool horizontalLayout) {
    bool toolboxAtStart = position != 'end';
    if (horizontalLayout) {
      return toolboxAtStart ? 'top' : 'bottom';
    } else {
      return (toolboxAtStart == rtl) ? 'right' : 'left';
    }
  }
}
*/
