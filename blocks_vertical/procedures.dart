// lib/blocks_vertical/procedures.dart
/// Utility class that mimics Scratch's Procedure (My Blocks) logic.
/// Lightweight version for Flutter Scratch engine.
class ProcedureUtils {
  String procCode = '';
  List<String> argumentIds = [];
  List<String> displayNames = [];
  List<String> argumentDefaults = [];
  bool warp = false;
  bool generateShadows = true;

  // ----------------------------------------------------------
  // BASIC INTERNAL UI HELPERS
  // ----------------------------------------------------------

  void updateDisplay() {}
  Map<String, dynamic> disconnectOldBlocks() => {};
  void removeAllInputs() {}
  void createAllInputs(Map<String, dynamic> connectionMap) {}
  void deleteShadows(Map<String, dynamic> connectionMap) {}
  void addLabelField(String text) {}
  void addLabelEditor(String text) {}
  String buildShadowDom(String type) =>
      type == 'n' ? 'math_number_shadow' : 'text_shadow';
  void attachShadow(String input, String argumentType) {}
  void createArgumentReporter(String type, String displayName) {}

  // ----------------------------------------------------------
  // POPULATE ARGUMENTS
  // ----------------------------------------------------------

  void populateArgumentOnCaller(
    String type,
    int index,
    Map<String, dynamic> connectionMap,
    String id,
    String input,
  ) {}

  void populateArgumentOnPrototype(
    String type,
    int index,
    Map<String, dynamic> connectionMap,
    String id,
    String input,
  ) {}

  void populateArgumentOnDeclaration(
    String type,
    int index,
    Map<String, dynamic> connectionMap,
    String id,
    String input,
  ) {}

  bool checkOldTypeMatches(String oldType, String type) {
    if ((type == 'n' || type == 's') &&
        oldType == 'argument_reporter_string_number') {
      return true;
    }
    if (type == 'b' && oldType == 'argument_reporter_boolean') {
      return true;
    }
    return false;
  }

  void createArgumentEditor(String type, String displayName) {}
  void updateDeclarationProcCode() {}
  void focusLastEditor() {}

  // ----------------------------------------------------------
  // EXTERNAL ADD METHODS (UI BUTTONS)
  // ----------------------------------------------------------

  void addLabelExternal() {
    procCode += ' label text';
    updateDisplay();
    focusLastEditor();
  }

  void addBooleanExternal() {
    procCode += ' %b';
    displayNames.add('boolean');
    argumentIds.add(DateTime.now().millisecondsSinceEpoch.toString());
    argumentDefaults.add('false');
    updateDisplay();
    focusLastEditor();
  }

  void addStringNumberExternal() {
    procCode += ' %s';
    displayNames.add('number or text');
    argumentIds.add(DateTime.now().millisecondsSinceEpoch.toString());
    argumentDefaults.add('');
    updateDisplay();
    focusLastEditor();
  }

  bool getWarp() => warp;
  void setWarp(bool value) => warp = value;
}

/// Represents a Procedure Declaration Block (the main "define block").
class ProcedureDeclarationBlock {
  final ProcedureUtils utils = ProcedureUtils();

  void init() {
    utils.procCode = '';
    utils.argumentIds = [];
    utils.argumentDefaults = [];
    utils.displayNames = [];
    utils.warp = false;
  }

  void addBoolean() => utils.addBooleanExternal();
  void addStringNumber() => utils.addStringNumberExternal();
  void addLabel() => utils.addLabelExternal();
}

/// Represents a Procedure Call Block (the pink block).
class ProcedureCallBlock {
  final ProcedureUtils utils = ProcedureUtils();

  void init() {
    utils.procCode = '';
    utils.argumentIds = [];
    utils.warp = false;
  }
}
