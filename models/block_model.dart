// lib/models/block_model.dart
import 'package:flutter/material.dart';
import '../core/workspace.dart' as ws;
import '../screens/editor_screen.dart';

/// Enum for block types (matches JS vertical extensions)
enum BlockInputType {
  statement,
  hat,
  end,
  outputNumber,
  outputString,
  outputBoolean,
}

enum ScratchBlockShape {
  hat,
  stack,
  c,
  cElse,
  reporter,
  boolean,
}

/// Enum for output shapes
enum BlockOutputShape {
  square,
  round,
  puzzle,
  boolean,
}

/// Device categories for WeDo / Hardware blocks
enum BlockDeviceType {
  wedo,
  wedoMotor,
  wedoSensor,
  microbit,
  arduino,
  none,
}

/// Generic Scratch-style Block Types
enum BlockType {
  statement,
  boolean,
  number,
  reporter,
  dynamic,
  logicAnd,
  logicOr,
  logicNot,
  logicTrue,
  logicFalse,

  controlIf,
  controlIfElse,
}

enum ConnectionType {
  previous,
  next,
  input,
  output,
}

/// Generic Block Input Structure
enum BlockInputCustomType {
  text,
  number,
  dropdown,
  colorPicker,
  blockSlot,
  angle,
}

/// A single connection point on a block
class BlockConnection {
  final ConnectionType type;

  /// What this connection accepts: boolean / statement / value
  final String accepts;

  /// Which block is connected here (block id)
  String? connectedBlockId;

  BlockConnection({
    required this.type,
    required this.accepts,
    this.connectedBlockId,
  });
}

class BlockInput {
  final String name;
  final BlockInputCustomType type;
  final List<String>? options;
  final String? _defaultValue;

  BlockInput._({
    required this.name,
    required this.type,
    this.options,
    String? defaultValue,
  }) : _defaultValue = defaultValue;

  String? get defaultValue => _defaultValue;

  // ------------------ FACTORY CONSTRUCTORS ------------------
  factory BlockInput.text({required String name}) {
    return BlockInput._(name: name, type: BlockInputCustomType.text);
  }

  factory BlockInput.number({required String name}) {
    return BlockInput._(name: name, type: BlockInputCustomType.number);
  }

  factory BlockInput.dropdown(
      {required String name, required List<String> options}) {
    return BlockInput._(
        name: name, type: BlockInputCustomType.dropdown, options: options);
  }

  factory BlockInput.colorPicker({required String name}) {
    return BlockInput._(name: name, type: BlockInputCustomType.colorPicker);
  }

  factory BlockInput.blockSlot({required String name}) {
    return BlockInput._(name: name, type: BlockInputCustomType.blockSlot);
  }
}

/// Represents a single Scratch/Blockly block

class BlockModel extends ChangeNotifier {
  final String? id;
  final String? type;
  final String? opcode;
  final String? name;
  final String category;
  final ScratchBlockShape shape;
  double x;
  double y;
  ValueNotifier<int> argumentsNotifier = ValueNotifier(0);
  // Add this field if not already present
  Map<String, dynamic> arguments = {};

// Add this method
  void updateArgument(String key, dynamic value) {
    arguments[key] = value;
    argumentsNotifier.value++; // notify any listeners using ValueNotifier
    notifyListeners(); // notify any ChangeNotifier listeners
  }

  final String? displayName;
  bool isRunning = false;

  double gap = 8;
  dynamic variable;
  Map<String, dynamic>? values;

  /// UI label shown on block
  String? label;

  /// Single-value input (simple blocks)
  String? value;

  /// Multi-input controllers (motion, control blocks)
  Map<String, TextEditingController>? controllers;

  BlockType? blockType;
  List<BlockInput> customInputs = [];

  Color? color;
  Color? secondaryColor;
  Color? tertiaryColor;
  Color? quaternaryColor;

  final String? colour;
  final String? colourSecondary;
  final String? colourTertiary;
  final String? colourQuaternary;

  final BlockInputType? inputType;

  final Map<String, dynamic> inputs;
  final Map<String, dynamic>? inputsMap;

  final List<String>? inputFields;
  final List<String>? dropdownOptions;

  final String? icon;

  final List<Map<String, dynamic>> args;

  final List<Map<String, dynamic>>? fields;

  final List<String> extensions;

  final bool? previousStatement;
  final bool? nextStatement;

  final bool? checkboxInFlyout;

  final String? lastDummyAlign;

  BlockOutputShape? outputShape;

  final String? message;

  final BlockDeviceType? deviceType;
  bool get isNote => false; // default false
  String get noteText => ''; // default empty

  bool isInsertionMarker = false;
  BlockModel? next;
  String? nextBlockId;

  BlockModel? parent;

  // -------------------------
// DETACH FROM OLD CONNECTION
// -------------------------
  void detach() {
    // Remove from parent cavities
    parent?.innerBlocks.remove(this);
    parent?.elseBlocks.remove(this);

    // Fix vertical chain
    if (snappedTo != null) {
      snappedTo!.next = next;
    }

    next = null;
    snappedTo = null;
    parent = null;
  }

  void insertIntoCavity(BlockModel block) {
    block.detach();
    innerBlocks.add(block);
    block.parent = this;

    block.position = Offset(
      position.dx + 24, // Scratch indent
      position.dy +
          44 +
          innerBlocks
              .take(innerBlocks.length - 1)
              .fold(0, (s, b) => s + b.dynamicHeight + gap),
    );
  }

// -------------------------
// SNAP BELOW ANOTHER BLOCK
// -------------------------
  void snapBelow(BlockModel target) {
    detach();
    next = target.next;
    target.next = this;
    parent = target.parent;
    snappedTo = target; // 🔥 REQUIRED
  }

// -------------------------
// INSERT INTO ELSE CAVITY
// -------------------------
  void insertIntoElse(BlockModel block) {
    block.detach();
    elseBlocks.add(block);
    block.parent = this;
    double yOffset =
        44 + innerBlocks.fold(0, (s, b) => s + b.dynamicHeight + 4);
    block.position = Offset(
        position.dx + 24,
        position.dy +
            yOffset +
            elseBlocks.fold(0, (s, b) => s + b.dynamicHeight + 4));
  }

  /// Whether the block is collapsed in the workspace
  bool isCollapsed = false;

  bool get isEvent => type?.startsWith('event_') ?? false;
  bool get isControl =>
      shape == ScratchBlockShape.c || shape == ScratchBlockShape.cElse;

  bool get isHat => shape == ScratchBlockShape.hat;
  bool get isStatement => shape == ScratchBlockShape.stack;

  // Connection rules
  bool get canHaveTop => shape != ScratchBlockShape.hat;
  bool get canHaveBottom =>
      shape != ScratchBlockShape.hat && shape != ScratchBlockShape.boolean;

  dynamic uiBlock;

  String? _comment;

  /// Prototype block
  final dynamic proto;

  void ensureControllers() {
    controllers ??= {};

    for (final input in customInputs) {
      if (!controllers!.containsKey(input.name)) {
        controllers![input.name] =
            TextEditingController(text: input.defaultValue ?? '');
      }
    }
  }

  BlockModel({
    String? id,
    this.type,
    this.opcode,
    this.name,
    double? x, // ✅ NOT required
    double? y,
    String? category,
    this.displayName,
    this.variable,
    this.values,
    this.blockType,
    List<BlockInput>? customInputs,
    this.color,
    this.secondaryColor,
    this.tertiaryColor,
    this.quaternaryColor,
    this.colour,
    this.colourSecondary,
    this.colourTertiary,
    this.colourQuaternary,
    this.inputType,
    Map<String, dynamic>? inputs,
    this.inputsMap,
    this.inputFields,
    this.dropdownOptions,
    this.icon,
    List<Map<String, dynamic>>? args,
    this.fields,
    List<String>? extensions,
    this.previousStatement,
    this.nextStatement,
    this.checkboxInFlyout,
    this.lastDummyAlign,
    this.outputShape,
    this.message,
    this.deviceType,
    this.isInsertionMarker = false,
    this.uiBlock,
    this.proto,
    this.value,
    required this.shape,
    String? label,
  })  : id = id ?? UniqueKey().toString(), // ✅ auto-generate ID if null
        x = x ?? 40, // ✅ DEFAULT X
        y = y ?? 40, // ✅ DEFAULT Y
        inputs = inputs ?? {},
        args = args ?? [],
        extensions = extensions ?? [],
        customInputs = customInputs ?? [],
        category = category ?? 'default',
        label = label;
  static BlockModel fromBlock(
    Block block,
    String spriteId, {
    double x = 40,
    double y = 40,
  }) {
    final model = BlockModel(
      id: block.id,
      type: block.type,
      opcode: block.type,
      label: block.uiLabel,
      value: block.value,
      category: 'default',
      shape: block.type.startsWith('event_')
          ? ScratchBlockShape.hat
          : ScratchBlockShape.stack,
      inputs: Map<String, dynamic>.from(block.arguments),
      x: block.x, // ✅ add this
      y: block.y,
    );

    model.x = x;
    model.y = y;

    return model;
  }

  /// Convert from EditorBlock to BlockModel
  factory BlockModel.fromEditorBlock(EditorBlock e) {
    return BlockModel(
      id: e.id,
      type: e.type,
      opcode: e.type,
      label: e.label ?? e.type,
      value: e.value,
      shape: e.type.startsWith('control_')
          ? ScratchBlockShape.c
          : ScratchBlockShape.boolean, // choose default
      x: e.x,
      y: e.y,
      category: e.category ?? 'default',
      inputs: {}, // map inputs if needed
      customInputs: [], // fill if needed
    );
  }

  /// Evaluate logic blocks and control structures
  dynamic evaluate() {
    switch (type) {
      case 'logic_true':
        return true;
      case 'logic_false':
        return false;
      case 'logic_negate':
        final inputBlock = inputs['A'] as BlockModel?;
        return !(inputBlock?.evaluate() ?? false);
      case 'logic_operation':
        final a = (inputs['A'] as BlockModel?)?.evaluate() ?? false;
        final b = (inputs['B'] as BlockModel?)?.evaluate() ?? false;
        return value == 'AND' ? (a && b) : (a || b);
      case 'control_if':
        final condition =
            (inputs['condition'] as BlockModel?)?.evaluate() ?? false;
        if (condition) {
          for (var b in innerBlocks) b.evaluate();
        }
        return null;
      case 'control_if_else':
        final condition =
            (inputs['condition'] as BlockModel?)?.evaluate() ?? false;
        final blocksToRun = condition ? innerBlocks : elseBlocks;
        for (var b in blocksToRun) b.evaluate();
        return null;
      default:
        return value; // return stored value for other blocks
    }
  }

  // -------------------- Factory: fromMap --------------------
  factory BlockModel.fromMap(Map<String, dynamic> map) {
    final block = BlockModel(
      id: map['id'],
      opcode: map['opcode'],
      type: map['opcode'],
      category: map['category'] ?? 'default',
      shape: map['shape']?.toString().contains('hat') == true
          ? ScratchBlockShape.hat
          : ScratchBlockShape.stack,
      values: Map<String, dynamic>.from(map['inputs'] ?? {}),
      x: (map['x'] ?? 40).toDouble(),
      y: (map['y'] ?? 40).toDouble(),
    );

    block.x = (map['x'] ?? 0).toDouble();
    block.y = (map['y'] ?? 0).toDouble();
    block.nextBlockId = map['nextBlockId'];

    return block;
  }

  // -------------------- Factory: fromJson --------------------
  factory BlockModel.fromJson(Map<String, dynamic> json) {
    // Convert shape string to ScratchBlockShape
    ScratchBlockShape shape;
    final shapeStr = json['shape']?.toString() ?? 'stack';
    if (shapeStr.contains('hat')) {
      shape = ScratchBlockShape.hat;
    } else if (shapeStr.contains('cElse')) {
      shape = ScratchBlockShape.cElse;
    } else if (shapeStr.contains('c')) {
      shape = ScratchBlockShape.c;
    } else {
      shape = ScratchBlockShape.stack;
    }

    return BlockModel(
      id: json['id'] ?? UniqueKey().toString(),
      type: json['type'] ?? json['opcode'] ?? 'unknown',
      opcode: json['opcode'] ?? '',
      name: json['name'] ?? json['type'] ?? json['opcode'] ?? '',
      category: json['category'] ?? 'default',
      values: json['values'] != null
          ? Map<String, dynamic>.from(json['values'])
          : {},
      inputs: json['inputs'] != null
          ? Map<String, dynamic>.from(json['inputs'])
          : {},
      args: json['args'] != null
          ? List<Map<String, dynamic>>.from(json['args'])
          : [],
      dropdownOptions: json['dropdownOptions'] != null
          ? List<String>.from(
              (json['dropdownOptions'] as Iterable).map((e) => e.toString()))
          : [],
      x: (json['x'] ?? 40).toDouble(),
      y: (json['y'] ?? 40).toDouble(),
      shape: shape,
    )..nextBlockId = json['nextBlockId'] ?? '';
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'opcode': opcode,
      'type': type,
      'name': name,
      'category': category,
      'values': values,
      'inputs': inputs,
      'dropdownOptions': dropdownOptions,
      'shape': shape.toString(),
      'nextBlockId': nextBlockId,
    };
  }

  // -------------------- POSITION & SNAPPING -------------------

  /// Standard block height (used for snapping)
  static const double blockHeight = 48;

  /// Base visual height (can grow for control blocks)
  double baseHeight = blockHeight;

  /// Dynamic Scratch-style height
  double get dynamicHeight {
    double h = baseHeight;
    for (final b in innerBlocks) {
      h += b.dynamicHeight + gap;
    }
    for (final b in elseBlocks) {
      h += b.dynamicHeight + gap;
    }
    return h + ((innerBlocks.isNotEmpty || elseBlocks.isNotEmpty) ? 10 : 0);
  }

  /// Connection points
  Offset get topConnection => Offset(x + 80, y); // approx center top

  Offset get bottomConnection => Offset(x + 80, y + dynamicHeight);

  /// Workspace position (single source of truth)
  Offset get position => Offset(x, y);
  set position(Offset p) {
    x = p.dx;
    y = p.dy;
  }

  /// Parent block this block is snapped into
  BlockModel? snappedTo;

  /// Blocks snapped inside this block (control cavities)
  List<BlockModel> innerBlocks = [];

  /// Blocks snapped inside ELSE cavity (for if-else)
  List<BlockModel> elseBlocks = [];

  bool get hasCavity =>
      shape == ScratchBlockShape.c || shape == ScratchBlockShape.cElse;

  // -------------------- NEW GETTERS / METHODS --------------------

  bool get isDeletable => true;

  List<dynamic> getConnections([bool forStack = false]) {
    if (uiBlock != null && uiBlock.getConnections != null) {
      return uiBlock.getConnections(forStack);
    }
    return [];
  }

  dynamic lastConnectionInStack() {
    if (uiBlock != null && uiBlock.lastConnectionInStack != null) {
      return uiBlock.lastConnectionInStack();
    }
    return null;
  }

  dynamic get nextConnection {
    if (uiBlock != null && uiBlock.nextConnection != null) {
      return uiBlock.nextConnection;
    }
    return null;
  }

  /// Display name priority: displayName → label → name → type
  String get uiLabel {
    return displayName ?? label ?? name ?? type ?? 'block';
  }

  // -------------------- Factories --------------------

  factory BlockModel.createButton(
    dynamic workspace,
    String label,
    String variableType, {
    required String category,
    double x = 40, // default position
    double y = 40, // default position
  }) {
    return BlockModel(
      type: "create_button",
      name: label,
      category: category,
      shape: ScratchBlockShape.stack,
      x: x,
      y: y,
      values: {
        "workspace": workspace,
        "varType": variableType,
      },
    );
  }

  factory BlockModel.separator({
    required String category,
    double x = 40, // default position
    double y = 40, // default position
  }) {
    return BlockModel(
      type: "separator",
      category: category,
      shape: ScratchBlockShape.stack,
      x: x,
      y: y,
    );
  }

  // -------------------- Inputs --------------------

  void addInput(BlockInput input) => customInputs.add(input);

  bool removeInput(String name) {
    final initialLength = customInputs.length;
    customInputs.removeWhere((i) => i.name == name);
    return customInputs.length < initialLength;
  }

  BlockInput? getInput(String name) {
    try {
      return customInputs.firstWhere((i) => i.name == name);
    } catch (_) {
      return null;
    }
  }

  // -------------------- Colors --------------------

  void setColor(Color newColor) => color = newColor;
  void setSecondaryColor(Color newColor) => secondaryColor = newColor;
  void setTertiaryColor(Color newColor) => tertiaryColor = newColor;
  void setQuaternaryColor(Color newColor) => quaternaryColor = newColor;

  // -------------------- Block Type & Output --------------------

  void setBlockType(BlockType type) => blockType = type;
  void setOutputShape(BlockOutputShape shape) => outputShape = shape;

  // -------------------- Comments --------------------

  bool get hasComment => _comment != null && _comment!.isNotEmpty;
  void addComment(String text) => _comment = text;
  void removeComment() => _comment = null;

  // -------------------- Duplicates --------------------

  BlockModel duplicate() {
    // 1️⃣ Create a new copy of this block
    final copy = BlockModel(
      id: UniqueKey().toString(),
      type: type,
      opcode: opcode,
      name: name,
      category: category,
      displayName: displayName,
      variable: variable,
      values: values != null ? Map.from(values!) : null,
      blockType: blockType,
      customInputs: List.from(customInputs),
      color: color,
      secondaryColor: secondaryColor,
      tertiaryColor: tertiaryColor,
      quaternaryColor: quaternaryColor,
      colour: colour,
      colourSecondary: colourSecondary,
      colourTertiary: colourTertiary,
      colourQuaternary: colourQuaternary,
      inputType: inputType,
      inputs: Map.from(inputs),
      inputsMap: inputsMap != null ? Map.from(inputsMap!) : null,
      inputFields: inputFields != null ? List.from(inputFields!) : null,
      dropdownOptions:
          dropdownOptions != null ? List.from(dropdownOptions!) : null,
      icon: icon,
      args: List.from(args),
      fields: fields != null ? List.from(fields!) : null,
      extensions: List.from(extensions),
      previousStatement: previousStatement,
      nextStatement: nextStatement,
      checkboxInFlyout: checkboxInFlyout,
      lastDummyAlign: lastDummyAlign,
      outputShape: outputShape,
      message: message,
      deviceType: deviceType,
      isInsertionMarker: false,
      uiBlock: null,
      proto: proto,
      shape: shape,
      x: x,
      y: y,
    );

    // 2️⃣ Ensure the new copy has controllers initialized
    copy.ensureControllers();

    // 3️⃣ Return the copy
    return copy;
  }

  void dispose() {
    uiBlock = null;
    customInputs.clear();
    controllers?.forEach((_, c) => c.dispose());
    controllers?.clear();
  }
}

// -------------------- XML Export Extension --------------------
extension BlockModelXml on BlockModel {
  /// Export this block (and its inputs recursively) to XML
  String toXml() {
    final buffer = StringBuffer();
    buffer.write('<block type="$type"');
    if (id != null) buffer.write(' id="$id"');
    buffer.write('>');

    // Export inputs (customInputs)
    for (var input in customInputs) {
      // Only handle BlockInput that could have nested blocks
      if (input.type == BlockInputCustomType.blockSlot) {
        final nested = values != null && values![input.name] is BlockModel
            ? values![input.name] as BlockModel
            : null;
        if (nested != null) {
          buffer.write('<input name="${input.name}" type="blockSlot">');
          buffer.write(nested.toXml());
          buffer.write('</input>');
        }
      } else {
        // Simple value input
        buffer.write(
            '<input name="${input.name}" type="${input.type.toString().split('.').last}"/>');
      }
    }

    buffer.write('</block>');
    return buffer.toString();
  }

  /// Recursively get all descendant IDs
  List<String> getDescendantIds() {
    List<String> ids = [];
    for (var input in customInputs) {
      final nested = values != null && values![input.name] is BlockModel
          ? values![input.name] as BlockModel
          : null;
      if (nested != null) {
        if (nested.id != null) ids.add(nested.id!);
        ids.addAll(nested.getDescendantIds());
      }
    }
    return ids;
  }
}

// -------------------- ENGINE BLOCK CLASS --------------------

/// Simple engine-friendly Block class
class Block {
  final String type;
  final String targetId;
  final bool isNote;
  final String noteText;
  final String id;
  List<Block> elseSubStack = [];
  bool isRunning = false;
  dynamic reporterValue;
  double x = 0; // position X
  double y = 0; // position Y
  bool isHat = false; // whether this is a hat block

  /// Engine-specific fields
  String uiLabel; // <-- add this
  String value; // <-- add this
  List<String>? dropdownOptions; // <-- add this

  /// 🔑 Persistent input controllers (FIXES cursor + bubbles)
  final Map<String, TextEditingController> controllers = {};

  /// Nested reporter blocks (VALUE, CONDITION, etc.)
  Map<String, Block?> inputBlocks = {};

  // For costume / backdrop dropdowns
  List<String>? availableCostumes;
  List<String>? availableBackdrops;

  /// Parsed runtime arguments (numbers, strings)
  Map<String, dynamic> arguments;

  /// ✅ Add this getter to replace 'menuItems'
  List<String> get menuItems => dropdownOptions ?? [];

  /// Returns true if this block reports a value
  bool get isReporter =>
      type.endsWith('_xposition') ||
      type.endsWith('_yposition') ||
      type.endsWith('_getvariable') ||
      type.endsWith('_operator') ||
      type.endsWith('_sensing');

  double visualHeight;

  /// Main vertical chain
  Block? next;

  /// Nested stack (repeat / if / forever)
  List<Block> subStack;

  Block({
    required this.type,
    required this.targetId,
    this.x = 0, // <-- add this
    this.y = 0, // <-- add this
    this.isHat = false, // <-- add this
    String? id,
    this.isNote = false,
    this.noteText = '',
    Map<String, String>? defaultInputs,
    this.next,
    List<Block>? subStack,
    List<String>? availableCostumes,
    List<String>? availableBackdrops,
    this.uiLabel = '',
    this.value = '',
    this.dropdownOptions,
    List<Block>? elseSubStack,
    double? visualHeight,
  })  : id = id ?? UniqueKey().toString(),
        visualHeight = visualHeight ?? 48,
        arguments = {},
        subStack = subStack ?? [],
        elseSubStack = elseSubStack ?? [],
        availableCostumes = availableCostumes ?? [],
        availableBackdrops = availableBackdrops ?? [] {
    // Keep arguments synced
    {
      // Initialize controllers from defaultInputs
      if (defaultInputs != null) {
        for (final entry in defaultInputs.entries) {
          final controller =
              TextEditingController(text: entry.value.toString());

          controllers[entry.key] = controller;
          arguments[entry.key] = _parse(entry.value.toString());

          controller.addListener(() {
            arguments[entry.key] = _parse(controller.text);
          });
        }
      }
    }
  }

  static dynamic _parse(String val) {
    if (val.isEmpty) return 0;
    return int.tryParse(val) ?? double.tryParse(val) ?? val;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'uiLabel': uiLabel,
      'value': value,
      'dropdownOptions': dropdownOptions ?? [],
      'x': x,
      'y': y,
      'isHat': isHat,
      'isNote': isNote,
      'noteText': noteText,
      'subStack': subStack.map((b) => b.toJson()).toList(),
      'elseSubStack': elseSubStack.map((b) => b.toJson()).toList(),
      'next': next?.toJson(),
      'arguments': arguments,
    };
  }

  // ================= FROM JSON =================
  factory Block.fromJson(Map<String, dynamic> json) {
    final block = Block(
      id: json['id'],
      type: json['type'],
      targetId: json['targetId'],
      isNote: json['isNote'] ?? false,
      noteText: json['noteText'] ?? '',
      uiLabel: json['uiLabel'] ?? '',
      value: json['value'] ?? '',
      subStack: (json['subStack'] as List<dynamic>? ?? [])
          .map((e) => Block.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      elseSubStack: (json['elseSubStack'] as List<dynamic>? ?? [])
          .map((e) => Block.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );

    // Restore arguments into controllers
    final args = Map<String, dynamic>.from(json['arguments'] ?? {});
    args.forEach((key, val) {
      if (block.controllers.containsKey(key)) {
        block.controllers[key]!.text = val.toString();
      }
      block.arguments[key] = val;
    });

    // Restore next chain
    if (json['next'] != null) {
      block.next = Block.fromJson(Map<String, dynamic>.from(json['next']));
    }

    return block;
  }

  /// IMPORTANT: dispose when block is deleted
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
  }

  /// Stop this block and all connected blocks
  void stop() {
    isRunning = false;

    // Stop inner blocks (loops / if)
    for (final b in subStack) {
      b.stop();
    }

    // Stop else blocks (if-else)
    for (final b in elseSubStack) {
      b.stop();
    }

    // Stop next block in chain
    next?.stop();
  }

  String get label {
    switch (type) {
      case 'motion_movesteps':
        return 'move';
      case 'motion_turnright':
        return 'turn right';
      case 'motion_turnleft':
        return 'turn left';
      case 'motion_gotoxy':
        return 'go to';
      case 'motion_glidesecsto':
        return 'glide';
      case 'motion_xposition':
        return 'x position';
      case 'motion_yposition':
        return 'y position';
      case 'motion_ifonedgebounce':
        return 'if on edge, bounce';
      case 'motion_setrotationstyle':
        return 'set rotation style';
      default:
        return type.replaceAll('_', ' ');
    }
  }
}

extension ToEngineBlock on BlockModel {
  Block toEngineBlock() {
    ensureControllers(); // make sure input controllers exist

    final Map<String, String> defaultInputs = {};

    // Add values from BlockModel.values
    if (values != null) {
      for (var entry in values!.entries) {
        defaultInputs[entry.key] = entry.value.toString();
      }
    }

    // Add controllers
    if (controllers != null) {
      for (var entry in controllers!.entries) {
        defaultInputs[entry.key] = entry.value.text; // overwrite if exists
      }
    }

    final engineBlock = Block(
      id: id,
      type: type ?? 'unknown',
      uiLabel: uiLabel,
      value: value ?? '',
      targetId: proto is BlockModel ? proto.id ?? '' : '',
      defaultInputs: defaultInputs,
      dropdownOptions: dropdownOptions ?? [],
    );

    // vertical chain
    if (next != null) engineBlock.next = next!.toEngineBlock();

    // Control block substack
    if (isControl) {
      if (innerBlocks.isNotEmpty) {
        engineBlock.subStack =
            innerBlocks.map((b) => b.toEngineBlock()).toList();
      }
      if (type == 'control_if_else' && elseBlocks.isNotEmpty) {
        engineBlock.elseSubStack =
            elseBlocks.map((b) => b.toEngineBlock()).toList();
      }
    }

    return engineBlock;
  }
}

// -------------------- ENGINE SHORTCUTS --------------------
extension BlockModelEngineAccess on BlockModel {
  /// Shortcut to engine block's subStack
  List<Block> get subStack => toEngineBlock().subStack;

  /// Shortcut to engine block's elseSubStack
  List<Block> get elseSubStack => toEngineBlock().elseSubStack;

  /// Shortcut to engine block's arguments
  Map<String, dynamic> get arguments => toEngineBlock().arguments;

  /// Shortcut to engine block's menuItems
  List<String> get menuItems => toEngineBlock().menuItems;
}

// ------------------ ENGINE -> BLOCKMODEL HELPERS ------------------
extension BlockEngineToModel on Block {
  BlockModel toBlockModel() {
    return BlockModel(
      id: id,
      type: type,
      opcode: type, // required
      name: uiLabel, // required
      category: 'default', // required
      shape:
          isHat ? ScratchBlockShape.hat : ScratchBlockShape.stack, // required
      x: x,
      y: y,
      value: value,
      displayName: uiLabel,
    );
  }
}

// ------------------ BLOCK HELPERS ------------------
/// Helpers for engine execution (green flag)
extension BlockHelpers on Block {
  /// Get a field value (dropdown, text, number, etc.)
  dynamic getFieldValue(String name) {
    if (controllers.containsKey(name)) {
      return Block._parse(controllers[name]!.text);
    }
    return arguments[name];
  }

  /// Get input blocks (like DO0, ELSE)
  List<Block> getStatements(String name) {
    switch (name) {
      case 'DO0':
        return subStack;
      case 'ELSE':
        return elseSubStack;
      default:
        return [];
    }
  }

  /// Get single input block (like IF0 / condition)
  Block? getInput(String name) {
    if (name == 'IF0' || name == 'condition') {
      return subStack.isNotEmpty ? subStack[0] : null;
    }
    return null;
  }
}
