// lib/constants/constants.dart

class BlocklyConstants {
  // Drag radius
  static const double dragRadius = 3.0;
  static const double flyoutDragRadius = 10.0;

  // Snap radius
  static const double snapRadius = 48.0;
  static const double connectingSnapRadius = 68.0;

  // Connection preference
  static const double currentConnectionPreference = 20.0;

  // Delay for bumping blocks
  static const int bumpDelay = 0;

  // Collapse characters
  static const int collapseChars = 30;

  // Long press duration
  static const int longPress = 750;

  // Line scroll multiplier
  static const int lineScrollMultiplier = 15;

  // Sound rate limiting
  static const int soundLimit = 100;

  // Drag stack
  static const bool dragStack = true;

  // Block color properties
  static const double hsvSaturation = 0.45;
  static const double hsvValue = 0.65;

  // Sprite info
  static const sprite = {'width': 96, 'height': 124, 'url': 'sprites.png'};

  // Namespaces
  static const String svgNs = 'http://www.w3.org/2000/svg';
  static const String htmlNs = 'http://www.w3.org/1999/xhtml';

  // Connection types
  static const int inputValue = 1;
  static const int outputValue = 2;
  static const int nextStatement = 3;
  static const int previousStatement = 4;
  static const int dummyInput = 5;

  // Alignment
  static const int alignLeft = -1;
  static const int alignCentre = 0;
  static const int alignRight = 1;

  // Drag enums
  static const int dragNone = 0;
  static const int dragSticky = 1;
  static const int dragBegin = 1;
  static const int dragFree = 2;

  // Opposite connection types
  static const Map<int, int> oppositeType = {
    inputValue: outputValue,
    outputValue: inputValue,
    nextStatement: previousStatement,
    previousStatement: nextStatement
  };

  // Toolbox positions
  static const int toolboxAtTop = 0;
  static const int toolboxAtBottom = 1;
  static const int toolboxAtLeft = 2;
  static const int toolboxAtRight = 3;

  // Output shapes
  static const int outputShapeHexagonal = 1;
  static const int outputShapeRound = 2;
  static const int outputShapeSquare = 3;

  // Categories
  static const Map<String, String> categories = {
    "motion": "motion",
    "looks": "looks",
    "sound": "sounds",
    "pen": "pen",
    "data": "data",
    "dataLists": "data-lists",
    "event": "events",
    "control": "control",
    "sensing": "sensing",
    "operators": "operators",
    "more": "more",
  };

  // Delete area enums
  static const deleteAreaNone = null;
  static const int deleteAreaTrash = 1;
  static const int deleteAreaToolbox = 2;

  // Special category names
  static const String variableCategoryName = 'VARIABLE';
  static const String procedureCategoryName = 'PROCEDURE';

  // Variable dropdown options
  static const String renameVariableId = 'RENAME_VARIABLE_ID';
  static const String deleteVariableId = 'DELETE_VARIABLE_ID';
  static const String newBroadcastMessageId = 'NEW_BROADCAST_MESSAGE_ID';
  static const String broadcastMessageVariableType = 'broadcast_msg';
  static const String listVariableType = 'list';
  static const String scalarVariableType = '';

  // Procedure block types
  static const String proceduresDefinitionBlockType = 'procedures_definition';
  static const String proceduresPrototypeBlockType = 'procedures_prototype';
  static const String proceduresCallBlockType = 'procedures_call';

  // Flyout button states
  static const Map<String, String> statusButtonState = {
    "READY": "ready",
    "NOT_READY": "not ready",
  };

  // Themes
  static const Map<String, String> themes = {
    "CLASSIC": "classic",
    "CAT_BLOCKS": "catblocks",
  };
}
