import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'cast.dart';
import '../main.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/block_model.dart';
import '../vm/dispatch/central_dispatch.dart';
import '../vm/engine/runtime.dart' as rt;
import '../vm/engine/target.dart' as tg;
import '../inputfields/motion_blocks.dart';
import '../vm/blocks/event.dart';
import '../core/sensing_state.dart';
import '../vm/blocks/sensing.dart';
import '../vm/blocks/sound.dart';
import '../vm/engine/sound_bank.dart';
import '../vm/engine/sound_assets.dart';
import '../screens/editor_screen.dart';
import '../core/blocks/logic/logicui.dart';
import '../core/blocks/logic/logic_blocks_vm.dart';
import '../vm/blocks/data.dart';
import '../vm/engine/util.dart';
import '../vm/engine/thread.dart';
import '../vm/engine/sequencer.dart' as seq;
import '../vm/engine/variable.dart';

enum RotationStyle { allAround, leftRight, dontRotate }

// ===== SPRITE CLASS =====
class Sprite {
  double x;
  double y;
  double direction;
  bool visible;
  String name = '';
  String? bubbleText;
  Timer? bubbleTimer;
  bool isSelected;
  bool isOriginal = true;
  // Editor/UI blocks
  List<BlockModel> uiBlocks = [];

  // Engine/runtime blocks
  List<Block> blocks = [];
  bool containsPoint(double px, double py) {
    const double halfSize = 50;

    return px >= x - halfSize &&
        px <= x + halfSize &&
        py >= y - halfSize &&
        py <= y + halfSize;
  }

  // ===== ADD THESE FIELDS =====
  int costumeIndex = 0;
  int currentAnimationFrame = 0;
  // ================= SOUND =================
  List<Map<String, dynamic>> sounds = [];
  SoundBank? soundBank;
  double volume = 100.0;
  Map<String, double> soundEffects = {
    'pitch': 0.0,
    'pan': 0.0,
  };
  final String id;
  RotationStyle rotationStyle = RotationStyle.allAround;
  // -------------------- CONTROL BLOCKS --------------------
  Map<String, int> _loopCounters = {};
  Map<String, int> _forEachIndex = {};
  Map<String, dynamic> variables = {};
  Map<String, List<dynamic>> lists = {};
  // ===== WATCHER VISIBILITY =====
  Map<String, bool> variableWatchers = {};

  Map<String, dynamic> operatorResults = {};
  List<Block> runningScripts = [];
  String assetPath;
  Sprite({
    String? id,
    this.x = 0,
    this.y = 0,
    this.direction = 90,
    this.visible = true,
    this.bubbleText,
    this.name = '',
    this.rotationStyle = RotationStyle.allAround,
    required this.assetPath,
    this.isSelected = false,
    this.costumeIndex = 0,
    this.currentAnimationFrame = 0,
    Map<String, dynamic>? variables,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        variables = variables ?? {} {
    // DEFAULT SOUNDS FOR THIS SPRITE
    sounds = [
      {'soundId': 'meow', 'name': 'Meow'},
      {'soundId': 'click', 'name': 'Click'},
      {'soundId': 'delete', 'name': 'Delete'},
    ];

    // ===== AUTO CREATE DEFAULT VARIABLE =====
    if (this.variables.isEmpty) {
      this.variables['my variable'] = 0;
      this.lists['my list'] = [];
      variableWatchers['my variable'] = false;
      variableWatchers['my list'] = false;
    }
  }
  bool isTouchingEdge({
    double stageWidth = 480,
    double stageHeight = 360,
  }) {
    return x <= -stageWidth / 2 ||
        x >= stageWidth / 2 ||
        y <= -stageHeight / 2 ||
        y >= stageHeight / 2;
  }

  // ===== ADD THIS METHOD =====
  double distanceTo(double x2, double y2) {
    final dx = x - x2;
    final dy = y - y2;
    return sqrt(dx * dx + dy * dy);
  }

  // -------------------- CLONE CONSTRUCTOR --------------------
  Sprite.from(Sprite other)
      : x = other.x,
        y = other.y,
        direction = other.direction,
        visible = other.visible,
        name = other.name,
        assetPath = other.assetPath,
        rotationStyle = other.rotationStyle,
        isSelected = false,
        variables = Map.from(other.variables),
        lists = Map.from(other.lists),
        variableWatchers = Map.from(other.variableWatchers),
        operatorResults = Map.from(other.operatorResults),
        _loopCounters = {},
        _forEachIndex = {},
        isOriginal = false,
        id = DateTime.now().microsecondsSinceEpoch.toString();

  //JSON factory inside class
  factory Sprite.fromJson(Map<String, dynamic> json) {
    final sprite = Sprite(
      id: json['id'],
      name: json['name'] ?? '',
      assetPath: json['assetPath'] ?? '',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      direction: (json['direction'] ?? 90).toDouble(),
      visible: json['visible'] ?? true,
      variables: Map<String, dynamic>.from(json['variables'] ?? {}),
      costumeIndex: json['costumeIndex'] ?? 0,
      currentAnimationFrame: json['currentAnimationFrame'] ?? 0,
    );

    sprite.lists = Map<String, List<dynamic>>.from(json['lists'] ?? {});
    sprite.variableWatchers = Map<String, bool>.from(json['watchers'] ?? {});

    return sprite;
  }

  //toJson method inside class
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'assetPath': assetPath,
      'x': x,
      'y': y,
      'direction': direction,
      'visible': visible,
      'variables': variables,
      'lists': lists,
      'watchers': variableWatchers,
      'costumeIndex': costumeIndex, // 🔹
      'currentAnimationFrame': currentAnimationFrame, // 🔹
    };
  }

  void showBubble(String text, {int durationMs = 1000}) {
    bubbleText = text;
    bubbleTimer?.cancel();
    bubbleTimer = Timer(Duration(milliseconds: durationMs), () {
      bubbleText = null;
    });
  }

  void hideBubble() {
    bubbleText = null;
    bubbleTimer?.cancel();
  }

  void clear() {
    x = 0;
    y = 0;
    direction = 90;
    visible = true;
    bubbleText = null;
    bubbleTimer?.cancel();

    variables.clear();
    lists.clear();
    variableWatchers.clear();
    operatorResults.clear();

    // Recreate defaults
    variables['my variable'] = 0;
    lists['my list'] = [];
    variableWatchers['my variable'] = false;
    variableWatchers['my list'] = false;
  }
}

class Stage {
  int selectedBackdropIndex;
  ValueNotifier<String> backdropPath;
  Map<String, dynamic> variables;
  List<Block> blocks;
  List<BlockModel> uiBlocks = [];
  Stage({
    this.selectedBackdropIndex = 0,
    String? initialBackdropPath,
    Map<String, dynamic>? variables,
    List<Block>? blocks,
  })  : backdropPath = ValueNotifier(initialBackdropPath ?? ''),
        variables = variables ?? {},
        blocks = blocks ?? [];

  void updateBackdrop(String newBackdropPath, int index) {
    backdropPath.value = newBackdropPath;
    selectedBackdropIndex = index;
  }
}

class _ColorInput extends StatelessWidget {
  final Color color;

  const _ColorInput({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _BooleanSensingBlock extends StatelessWidget {
  final String label;
  final Widget input;
  final String? suffix;
  final String Function() valueBuilder;

  const _BooleanSensingBlock({
    Key? key,
    required this.label,
    required this.input,
    this.suffix,
    required this.valueBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5CB1D6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          input,
          if (suffix != null) ...[
            const SizedBox(width: 6),
            Text(
              suffix!,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            )
          ],
          const SizedBox(width: 6),
          Text(
            valueBuilder(),
            style: const TextStyle(
                color: Colors.yellowAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SensingBlock extends StatelessWidget {
  final String label;
  final String? suffix;
  final String Function() valueBuilder;

  const _SensingBlock({
    Key? key,
    required this.label,
    this.suffix,
    required this.valueBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5CB1D6), // Scratch sensing color
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 6),
            Text(
              suffix!,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            )
          ],
          const SizedBox(width: 6),
          Text(
            valueBuilder(),
            style: const TextStyle(
                color: Colors.yellowAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ===== WORKSPACE ENGINE =====
class WorkspaceEngine extends ChangeNotifier {
  Thread? currentThread;
  late final Scratch3DataBlocks _dataBlocks;
  // Add this at the top of your class
  final Map<String, ValueNotifier<Color?>> _colorMap = {};

  late final seq.Sequencer sequencer;
  final ValueNotifier<void> _repaintNotifier = ValueNotifier(null);
  Listenable get repaint => _repaintNotifier;
  void requestRepaint() {
    _repaintNotifier.value = null;
  }

  late DraggableLogicBlock ifBlock;
  // For runtime/engine blocks
  List<Block> workspaceBlocks = [];

// For editor UI blocks
  List<BlockModel> workspaceUIBlocks = [];
  // ================= WORKSPACE SERIALIZATION =================
  List<Map<String, dynamic>> serializeWorkspaceBlocks(List<BlockModel> blocks) {
    return blocks.map((b) {
      return {
        'id': b.id,
        'type': b.type,
        'opcode': b.opcode,
        'label': b.label,
        'value': b.value,
        'x': b.x,
        'y': b.y,
        'isHat': b.isHat,
        'isNote': b.isNote,
        'noteText': b.noteText,
        'category': b.category,
        'nextId': b.next?.id,
      };
    }).toList();
  }
  // ================= COLOR PICKING ENGINE STATE =================

  final ValueNotifier<Color?> previewColor = ValueNotifier<Color?>(null);

  Offset? previewPixelPosition;

  ui.Image? _cachedStageImage;

  static const int magnifierRadius = 6;

  Future<void> cacheStageImage(GlobalKey stageKey) async {
    final boundary =
        stageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    _cachedStageImage = await boundary.toImage(pixelRatio: 1.0);
  }

  Future<Color?> sampleStagePixelColor(Offset stageLocalPosition) async {
    if (_cachedStageImage == null) return null;

    final image = _cachedStageImage!;
    final x = stageLocalPosition.dx.round();
    final y = stageLocalPosition.dy.round();

    if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
      return null;
    }

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) return null;

    final index = (y * image.width + x) * 4;
    return Color.fromARGB(
      byteData.getUint8(index + 3),
      byteData.getUint8(index),
      byteData.getUint8(index + 1),
      byteData.getUint8(index + 2),
    );
  }

  dynamic getVariable(String name, Sprite sprite) {
    // 1️⃣ Sprite local
    if (sprite.variables.containsKey(name)) {
      return sprite.variables[name]!.notifier.value;
    }

    // 2️⃣ Stage global
    if (stage.variables.containsKey(name)) {
      return stage.variables[name]!.notifier.value;
    }

    return null;
  }

  void setVariable(String name, dynamic value, Sprite sprite) {
    // If sprite already has it → update local
    if (sprite.variables.containsKey(name)) {
      sprite.variables[name] = value;
      return;
    }

    // If stage has it → update global
    if (stage.variables.containsKey(name)) {
      stage.variables[name] = value;
      return;
    }

    // If not found → create as local variable
    sprite.variables[name] = value;
  }

  LogicBlock blockModelToLogicBlock(BlockModel model) {
    return LogicBlock(
      id: model.id ?? UniqueKey().toString(),
      type: model.opcode ?? 'unknown', // ensure type is never null
      value: model.value ?? '',
      subStack: model.innerBlocks.map(blockModelToLogicBlock).toList(),
      elseSubStack: model.elseBlocks.map(blockModelToLogicBlock).toList(),
    );
  }

  void runLogicBlocks() {
    final runtimeBlocks =
        workspaceUIBlocks.map((b) => blockModelToLogicBlock(b)).toList();
    //Use the correct method name from the updated VM
    runtime.logicVM.runLogicBlocks(runtimeBlocks);
  }

  // Store colors for each key
  final Map<String, ValueNotifier<Color?>> _colors = {};

// Get the ValueNotifier for a given color key
  ValueNotifier<Color?> colorListenable(String key) {
    if (!_colors.containsKey(key)) _colors[key] = ValueNotifier(Colors.red);
    return _colors[key]!;
  }

// Start color picking
  void beginColorPick(String key) {
    colorPickingActive.value = true;

    // Use existing color or default red
    Color initialColor = _colors[key]?.value ?? Colors.red;
    previewColor.value = initialColor;

    // Local variable to track the selected color in dialog
    Color selectedColor = initialColor;

    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a Color'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live preview container
              ValueListenableBuilder<Color?>(
                valueListenable: previewColor,
                builder: (context, color, _) {
                  return Container(
                    height: 50,
                    width: double.infinity,
                    color: color ?? Colors.red,
                    margin: const EdgeInsets.only(bottom: 16),
                  );
                },
              ),
              SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) {
                    selectedColor = color;
                    previewColor.value = color; // live update
                  },
                  showLabel: true,
                  pickerAreaHeightPercent: 0.8,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Save selected color
                if (_colors.containsKey(key)) {
                  _colors[key]!.value = selectedColor;
                } else {
                  _colors[key] = ValueNotifier(selectedColor);
                }

                // Reset preview and deactivate
                previewColor.value = null;
                colorPickingActive.value = false;

                Navigator.of(navigatorKey.currentContext!).pop();
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                // Cancel without saving
                previewColor.value = null;
                colorPickingActive.value = false;
                Navigator.of(navigatorKey.currentContext!).pop();
              },
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }

// ================= WORKSPACE EXPORT =================
  Map<String, dynamic> exportWorkspaceState() {
    return {
      'sprites': sprites.map((s) {
        return {
          'id': s.id,
          'blocks': serializeWorkspaceBlocks(s.uiBlocks),
        };
      }).toList(),
      'stage': {
        'blocks': serializeWorkspaceBlocks(stage.uiBlocks),
      }
    };
  }

  EditorBlock blockFromModel(BlockModel model) {
    return EditorBlock(
      id: model.id ?? 'unknown_id',
      opcode: model.opcode ?? 'unknown_opcode',
      type: model.type ?? 'unknown_type',
      label: model.label ?? 'unknown_label',
      value: model.value,
      x: model.position?.dx ?? 0,
      y: model.position?.dy ?? 0,
      isHat: model.shape == ScratchBlockShape.hat,
      isNote: false,
      noteText: null,
      category: 'default',
    );
  }

  bool _eventsRegistered = false;

  final StreamController<String> _broadcastStream =
      StreamController<String>.broadcast();

  Stage stage = Stage();
  final CentralDispatch central = CentralDispatch();
  final rt.Runtime runtime = rt.Runtime();
  // ===== Scratch VM Sensing =====
  late Scratch3SensingBlocks sensingVM;
  late Map<String, Function> _sensingPrimitives;
  final GlobalKey stageKey = GlobalKey();
  final SensingState sensing = SensingState();
  final SoundBank soundBank = SoundBank();

  bool _dragMode = false; // Tracks whether drag mode is on/off
  final String projectId;
  bool _running = false;
  final Map<String, bool> _spriteRunning = {};
  final List<Block> activeBlocks = [];
  bool _touchingColor = false;
  bool _touchingEdge = false;
  double _mouseX = 0.0;
  double _mouseY = 0.0;

  double _timer = 0.0;
  double _loudness = 0.0;

  String _lastAnswer = '';
  late String _currentProjectName;
  Sprite? _activeSprite;
  late final Scratch3SensingBlocks _sensingBlocks;
  late Scratch3SoundBlocks soundBlocks;
  bool get running => _running;

  String get currentProjectName => _currentProjectName;
  List<BlockModel> _blocks = [];
  int _counter = 0; // global counter for control blocks
  double get stageWidth => rt.Runtime.STAGE_WIDTH.toDouble();
  double get stageHeight => rt.Runtime.STAGE_HEIGHT.toDouble();

  Map<String, dynamic> getStageSnapshot() {
    return {
      'width': stageWidth,
      'height': stageHeight,
      'background': stageBackground,
      'selectedBackdropIndex': selectedBackdropIndex,
    };
  }

  String get stageBackground {
    if (currentBackdrop != null) return currentBackdrop!;
    if (backdrops.isNotEmpty && selectedBackdropIndex < backdrops.length) {
      return backdrops[selectedBackdropIndex].assetPath;
    }
    return 'assets/backdrops/default.png'; // fallback
  }

  List<BlockModel> getBlocks() {
    return _blocks;
  }

  set currentProjectName(String value) {
    _currentProjectName = value;
    notifyListeners(); // rebuild UI when project name changes
  }

  /// Create a clone of a sprite
  void createClone(Sprite source) {
    final clone = Sprite.from(source); // use the clone constructor
    sprites.add(clone);
    notifyListeners(); // update UI if needed
  }

  // Clear all blocks from all sprite workspaces
  void clearBlocks() {
    for (var sprite in _sprites) {
      _spriteWorkspaces[sprite.id]?.clear();
    }
    notifyListeners(); // update UI
  }

// Load blocks per sprite
  void loadBlocks(List<BlockModel> blocks) {
    clearBlocks(); // optional: start fresh

    for (var block in blocks) {
      final spriteId = block.variable?['spriteId'] ?? currentSprite.id;
      _spriteWorkspaces.putIfAbsent(spriteId, () => []);

      final engineBlock = _convertBlockModelToBlock(block, spriteId);
      _spriteWorkspaces[spriteId]!.add(engineBlock);
    }

    notifyListeners(); // update UI
  }

  // Optional: getter to see blocks
  List<BlockModel> get currentBlocks => _blocks;

  Map<String, dynamic> getRuntimeState() {
    return {
      // Stage state
      'stage': {
        'selectedBackdropIndex': stage.selectedBackdropIndex,
        'backdropPath': stage.backdropPath,
        'variables': stage.variables,
      },
      // Sprites state
      'sprites': sprites
          .map((s) => {
                'id': s.id,
                'x': s.x,
                'y': s.y,
                'direction': s.direction,
                'visible': s.visible,
                'variables': s.variables,
                'blocks': s.blocks.map((b) => b.toJson()).toList(),
                'costumeIndex': s.costumeIndex,
                'currentAnimationFrame': s.currentAnimationFrame,
              })
          .toList(),
    };
  }

  // Stop all sprites (all scripts)
  void stopAllSprites() {
    for (var sprite in _sprites) {
      stopOtherScripts(sprite);
    }
    notifyListeners();
  }

// Stop all scripts of a given sprite
  void stopOtherScripts(Sprite sprite) {
    // Assuming each sprite has running scripts stored somewhere
    sprite.runningScripts?.forEach((b) => b.stop());
  }

// Stop only the current script of a sprite
  void stopThisScript(Sprite sprite) {
    _spriteRunning[sprite.id] = false;
  }

  List<BlockModel> getAllBlocksForSave() {
    List<BlockModel> allBlocks = [];
    for (var sprite in _sprites) {
      final workspace = _spriteWorkspaces[sprite.id] ?? [];
      for (var b in workspace) {
        allBlocks.add(BlockModel.fromBlock(b, sprite.id));
      }
    }
    return allBlocks;
  }

  // =================== Convert BlockModel to Engine Block ===================
  Block _convertBlockModelToBlock(BlockModel model, String spriteId) {
    return Block(
      id: model.id ?? UniqueKey().toString(),
      type: model.type ?? 'unknown',
      targetId: spriteId,
      uiLabel: model.uiLabel ?? '',
      value: model.value ?? '',
      defaultInputs: model.inputs != null
          ? Map<String, String>.fromEntries(
              model.inputs!.entries.map(
                (e) => MapEntry(e.key, e.value.toString()),
              ),
            )
          : {},
      subStack: [],
      elseSubStack: [],
      dropdownOptions: model.dropdownOptions ?? [],
    );
  }

  final Map<String, Map<String, List<Block>>> _hatBlocks = {};

  final Map<String, List<Block>> _spriteWorkspaces = {};
  final Map<String, Map<String, TextEditingController>> _inputControllers = {};
  // Notify UI when sprites move
  final StreamController<void> _spriteController = StreamController.broadcast();
  Stream<void> get spriteStream => _spriteController.stream;

  Sprite get _sprite => currentSprite;
  // ===== ADD THIS SETTER =====
  set sprite(Sprite sprite) {
    // If the sprite exists in _sprites, select it
    int index = _sprites.indexOf(sprite);
    if (index != -1) {
      selectedIndex = index;
      notifyListeners();
    } else {
      // Otherwise, add it
      addSprite(sprite);
    }
  }

  Map<String, dynamic> get initialData => getCurrentProjectData();

// Used for getBlocksJson / blocks per sprite
  List<Map<String, dynamic>> getBlocksJson() {
    return sprites.expand((s) => s.blocks.map((b) => b.toJson())).toList();
  }

// Used for thumbnail if needed
  String get projectThumbnail => 'assets/project_thumbnail.png';

  Map<String, dynamic> getCurrentProjectData() {
    return {
      'projectId': projectId,
      'projectName': currentProjectName,

      // ===== STAGE =====
      'stage': {
        'currentBackdrop': currentBackdrop,
        'selectedBackdropIndex': selectedBackdropIndex,
      },

      // ===== SPRITES =====
      'sprites': sprites.map((s) => s.toJson()).toList(),

      // ===== BLOCKS (PER SPRITE) =====
      'workspaces': _spriteWorkspaces.map(
        (spriteId, blocks) => MapEntry(
          spriteId,
          blocks.map((b) => b.toJson()).toList(),
        ),
      ),
    };
  }

  List<Block> get currentWorkspace =>
      _spriteWorkspaces[currentSprite.id] ??= [];

  final Map<String, List<String>> _spriteVariables = {};
  String? currentCostume;
  String? currentBackdrop;

  bool get isTouchingColor => _touchingColor;
  bool get isTouchingEdge => _touchingEdge;

  double get mouseX => _mouseX;
  double get mouseY => _mouseY;

  double get timerValue => _timer;
  double get loudness => _loudness;

  String get lastAnswer => _lastAnswer;
  // List of all sprites
  final List<Sprite> _sprites = [];
  // ===== ADD THESE =====
  List<Sprite> backdrops = [];
  int selectedBackdropIndex = 0;

  // ===== METHOD TO CHANGE BACKDROP =====
  void setBackdrop(int index) {
    selectedBackdropIndex = index;
    notifyListeners();
  }

  // Currently selected sprite index
  int selectedIndex = 0;

  // Get all sprites
  List<Sprite> get sprites => _sprites;

  // Get current selected sprite
  Sprite get currentSprite => _sprites[selectedIndex];

  Future<void> addSprite(Sprite sprite) async {
    // Load default sounds for this sprite
    await loadDefaultSounds(sprite);

    // Add sprite to engine
    _sprites.add(sprite);
    _spriteWorkspaces[sprite.id] = [];
    _spriteRunning[sprite.id] = false;
    selectedIndex = _sprites.length - 1;

    notifyListeners();
  }

  // Select a sprite by index
  void selectSprite(int index) {
    if (index >= 0 && index < _sprites.length) {
      selectedIndex = index;
      notifyListeners();
    }
  }

  /// Returns true if the sprite is touching any edge of the stage
  bool _isTouchingEdge() {
    // Scratch stage dimensions
    final double STAGE_WIDTH = rt.Runtime.STAGE_WIDTH.toDouble();
    final double STAGE_HEIGHT = rt.Runtime.STAGE_HEIGHT.toDouble();

    // Sprite dimensions
    const double SPRITE_WIDTH = 80;
    const double SPRITE_HEIGHT = 80;

    // Calculate sprite edges
    double left = _sprite.x - SPRITE_WIDTH / 2;
    double right = _sprite.x + SPRITE_WIDTH / 2;
    double top = _sprite.y + SPRITE_HEIGHT / 2;
    double bottom = _sprite.y - SPRITE_HEIGHT / 2;

    // Check if touching any edge
    if (left <= -STAGE_WIDTH / 2 ||
        right >= STAGE_WIDTH / 2 ||
        top >= STAGE_HEIGHT / 2 ||
        bottom <= -STAGE_HEIGHT / 2) {
      return true;
    }
    return false;
  }

  void resumeExecution() {
    _running = true;
  }

  void resetTimer() {
    sensing.timerStart = DateTime.now().millisecondsSinceEpoch.toDouble();
  }

  void applyDragMode() {
    // Toggle drag mode (you can customize this logic later)
    _dragMode = !_dragMode;
    print('Drag mode is now $_dragMode');

    // If you have a list of sprites and want to apply this to them:
    // for (final sprite in _sprites) {
    //   sprite.variables['draggable'] = _dragMode;
    // }
  }

  // ================= COLOR SENSING =================
  Color _color1 = Colors.red;
  Color _color2 = Colors.blue;

  Color get color1 => _color1;
  Color get color2 => _color2;

  /// Used by sensing blocks
  void setColor(String key, Color color) {
    if (key == 'color1') {
      _color1 = color;
    } else if (key == 'color2') {
      _color2 = color;
    }
  }

  Widget buildSprite(Sprite sprite) {
    Widget child = SvgPicture.asset(sprite.assetPath);

    // LEFT-RIGHT rotation (Scratch style)
    if (sprite.rotationStyle == RotationStyle.leftRight) {
      final flip = sprite.direction.abs() > 90;
      child = Transform(
        transform: Matrix4.identity()..scale(flip ? -1.0 : 1.0, 1.0),
        alignment: Alignment.center,
        child: child,
      );
    }

    // ALL AROUND rotation
    if (sprite.rotationStyle == RotationStyle.allAround) {
      child = Transform.rotate(
        angle: sprite.direction * pi / 180,
        child: child,
      );
    }

    return child;
  }

  // --------------------------------------------------
// SCRATCH COLOR SENSING STATE
// --------------------------------------------------

  final Map<String, ValueNotifier<Color?>> _colorNotifiers = {};

  final ValueNotifier<Color?> previewBackgroundColor =
      ValueNotifier<Color?>(null);

  final ValueNotifier<bool> colorPickingActive = ValueNotifier<bool>(false);

  String? _activeColorKey;

  ValueNotifier<Color?> getColorNotifier(String key) {
    if (!_colors.containsKey(key)) {
      _colors[key] = ValueNotifier<Color?>(Colors.red);
    }
    return _colors[key]!;
  }

  void showColorPickerDialog(String key) {
    colorPickingActive.value = true;

    // Use existing color or default red
    Color initialColor = _colors[key]?.value ?? Colors.red;
    previewColor.value = initialColor;

    // Local variable to track the selected color in dialog
    Color selectedColor = initialColor;

    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a Color'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live preview container
              ValueListenableBuilder<Color?>(
                valueListenable: previewColor,
                builder: (context, color, _) {
                  return Container(
                    height: 50,
                    width: double.infinity,
                    color: color ?? Colors.red,
                    margin: const EdgeInsets.only(bottom: 16),
                  );
                },
              ),
              SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) {
                    selectedColor = color;
                    previewColor.value = color; // live update
                  },
                  showLabel: true,
                  pickerAreaHeightPercent: 0.8,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Save selected color
                _colors[key]?.value = selectedColor;

                // Reset preview and deactivate
                previewColor.value = null;
                colorPickingActive.value = false;

                Navigator.of(navigatorKey.currentContext!).pop();
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                // Cancel without saving
                previewColor.value = null;
                colorPickingActive.value = false;
                Navigator.of(navigatorKey.currentContext!).pop();
              },
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }

  /// Registers or retrieves a color ValueNotifier
  /// Registers or retrieves a color ValueNotifier for inline Scratch blocks
  ValueNotifier<Color?> inlineColorListenable(String key) {
    if (!_colorMap.containsKey(key)) {
      _colorMap[key] = ValueNotifier<Color?>(Colors.red);
    }
    return _colorMap[key]!;
  }

  void beginInlineColorPick(String key) {
    _activeColorKey = key;
    colorPickingActive.value = true;
    previewBackgroundColor.value = _colorMap[key]?.value ?? Colors.red;
  }

  /// Call this when the stage is tapped to pick a color
  void pickColorFromStage(
      String key, Offset stagePosition, GlobalKey stageKey) {
    final RenderBox? box =
        stageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(stagePosition);

    _getColorFromRenderBox(box, local).then((color) {
      _colorMap[key]?.value = color;
      previewColor.value = color;
      colorPickingActive.value = false;
    });
  }

  /// Reads the pixel color from a RenderBox at a given position
  Future<Color> _getColorFromRenderBox(RenderBox box, Offset local) async {
    final boundary = box as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) return Colors.red;

    final x = local.dx.clamp(0, image.width - 1).toInt();
    final y = local.dy.clamp(0, image.height - 1).toInt();
    final index = (y * image.width + x) * 4;

    final r = byteData.getUint8(index);
    final g = byteData.getUint8(index + 1);
    final b = byteData.getUint8(index + 2);
    final a = byteData.getUint8(index + 3);

    return Color.fromARGB(a, r, g, b);
  }

  // ================= Load Project From Firebase =================
  Future<void> loadProjectFromFirebase(List<BlockModel> projectBlocks) async {
    // Clear previous workspaces
    _spriteWorkspaces.clear();
    _hatBlocks.clear();

    // Group blocks by sprite
    for (final blockModel in projectBlocks) {
      final spriteId = blockModel.variable?['spriteId'] ?? 'defaultSprite';

      _spriteWorkspaces.putIfAbsent(spriteId, () => []);

      final block = _convertBlockModelToBlock(blockModel, spriteId);
      _spriteWorkspaces[spriteId]!.add(block);

      // Handle hat blocks (event blocks)
      if (block.type.startsWith('event_')) {
        _hatBlocks.putIfAbsent(block.type, () => {});
        _hatBlocks[block.type]!.putIfAbsent(spriteId, () => []).add(block);
      }
    }
  }

  void updateColorTouching(Color pixelColorUnderSprite) {
    const tolerance = 20;

    int r1 = (pixelColorUnderSprite.r * 255).round();
    int g1 = (pixelColorUnderSprite.g * 255).round();
    int b1 = (pixelColorUnderSprite.b * 255).round();

    int r2 = (_color1.r * 255).round();
    int g2 = (_color1.g * 255).round();
    int b2 = (_color1.b * 255).round();

    final match = (r1 - r2).abs() < tolerance &&
        (g1 - g2).abs() < tolerance &&
        (b1 - b2).abs() < tolerance;

    _touchingColor = match;
  }

  Future<Color> sampleColorAt(Offset position) async {
    final boundary =
        stageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    final x = position.dx.toInt().clamp(0, image.width - 1);
    final y = position.dy.toInt().clamp(0, image.height - 1);

    final index = (y * image.width + x) * 4;

    return Color.fromARGB(
      byteData!.getUint8(index + 3),
      byteData.getUint8(index),
      byteData.getUint8(index + 1),
      byteData.getUint8(index + 2),
    );
  }

  dynamic getSensingValue(String sensorName) {
    final sprite = _activeSprite ?? currentSprite;

    switch (sensorName) {
      // 🖱 Mouse
      case 'mouseX':
        return sensing.mouseX;

      case 'mouseY':
        return sensing.mouseY;

      case 'mouseDown':
        return sensing.mouseDown;

      // Timer
      case 'timer':
        return (DateTime.now().millisecondsSinceEpoch - sensing.timerStart) /
            1000.0;

      // Touching edge
      case 'touchingEdge':
        return _isTouchingEdge();

      // Touching another sprite
      case 'touchingSprite':
        final target = runtime.getSpriteUnder(sprite.x, sprite.y);
        return target != null;

      // Touching color
      case 'touchingColor':
        return isTouchingColor;

      //  Loudness
      case 'loudness':
        return sensing.loudness;

      // Ask / Answer
      case 'currentAnswer':
        return sensing.answer;

      // Distance
      case 'distanceToMouse':
        return sprite.distanceTo(
          sensing.mouseX,
          sensing.mouseY,
        );

      // Key pressed
      case 'isKeyPressed':
        final key = sensing.answer;
        return sensing.pressedKeys.contains(
          LogicalKeyboardKey.keyA,
        );
    }
  }

  void initSensingBlocks() {
    _sensingBlocks = Scratch3SensingBlocks(runtime);
  }

  // ===== Event block helpers (class level) =====
  final Set<String> _pressedKeys = {};

  void keyPressed(String key) {
    _pressedKeys.add(key);
    // trigger event if you want
    triggerEvent('event_whenkeypressed', {'KEY_OPTION': key});
  }

  void keyReleased(String key) {
    _pressedKeys.remove(key);
  }

  bool _keyPressed(String key) {
    return _pressedKeys.contains(key) || key == 'any';
  }

  // Optional: similar for broadcast
  final Set<String> _receivedBroadcasts = {};

  void broadcastReceived(String message) {
    _receivedBroadcasts.add(message);
    triggerEvent('event_whenbroadcastreceived', {'BROADCAST_OPTION': message});
  }

  bool _broadcastReceived(String message) {
    return _receivedBroadcasts.contains(message);
  }

  WorkspaceEngine({
    required this.projectId,
    List<Map<String, dynamic>>? spriteData,
    Map<String, dynamic>? initialData,
  }) {
    sequencer = seq.Sequencer(runtime);
    // Initialize sensing blocks **once**
    _sensingBlocks = Scratch3SensingBlocks(runtime);
    // Initialize blocks
    soundBlocks = Scratch3SoundBlocks(runtime);
    // Register sound primitives
    runtime.registerPrimitives(soundBlocks.getPrimitives());
    // Init Scratch VM
    sensingVM = Scratch3SensingBlocks(runtime);
    _sensingPrimitives = sensingVM.getPrimitives();

    Sprite? getSpriteUnder(double x, double y, {Sprite? exclude}) {
      for (final sprite in sprites) {
        if (exclude != null && sprite.id == exclude.id) continue;

        if (sprite.containsPoint(x, y)) {
          return sprite;
        }
      }
      return null;
    }

    List<BlockModel> exportAllBlocks() {
      List<BlockModel> allBlocks = [];
      for (var sprite in sprites) {
        final blocks = _spriteWorkspaces[sprite.id] ?? [];
        for (var b in blocks) {
          allBlocks.add(BlockModel.fromBlock(b, sprite.id));
        }
      }
      return allBlocks;
    }

    _currentProjectName = 'Untitled Project';

    // ===== Initialize sprite list =====
    _sprites.clear();

    // Use user sprites if provided
    if (spriteData != null && spriteData.isNotEmpty) {
      for (final s in spriteData) {
        _sprites.add(Sprite(
          id: s['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
          name: s['name'] ?? '',
          x: (s['x'] ?? 0).toDouble(),
          y: (s['y'] ?? 0).toDouble(),
          direction: (s['direction'] ?? 90).toDouble(),
          assetPath: s['assetPath'] ?? 'assets/sprites/default.png',
          visible: s['visible'] ?? true,
          variables: Map<String, dynamic>.from(s['variables'] ?? {}),
        ));
      }
    } else {
      // fallback default sprite
      _sprites.add(Sprite(
        id: 'cat',
        name: 'Cat',
        assetPath: 'assets/sprites/cat.svg',
        x: 0,
        y: 0,
        direction: 90,
      ));
    }

    selectedIndex = 0;

    // ===== Initialize running state & targets =====
    for (final sprite in _sprites) {
      _spriteRunning[sprite.id] = false;

      runtime.createTarget(
        id: sprite.id,
        name: sprite.name,
      );

      final tg.Target? target = runtime.getTarget(sprite.id);
      if (target != null && !central.targets.containsKey(sprite.id)) {
        central.registerTarget(target);
      }
    }

    // ===== Initialize Scratch3EventBlocks =====
    final eventBlocks = Scratch3EventBlocks(runtime);

    // ===== Initialize sensing variables =====
    _initSensingVariables();
  }

  List<String> get spriteNames => _sprites.map((s) => s.name).toList();

  List<String> get availableKeys => [
        'up',
        'down',
        'left',
        'right',
        'space',
        'enter',
        'a',
        'b',
        'c',
        'd',
      ];

  void addBlock(Block block) {
    currentWorkspace.add(block);

    print(
        'Sprite ${currentSprite.id} workspace size: ${currentWorkspace.length}');

    if (block.type.startsWith('event_')) {
      _hatBlocks.putIfAbsent(block.type, () => {});
      _hatBlocks[block.type]!
          .putIfAbsent(currentSprite.id, () => [])
          .add(block);
    }
    // ================= SOUND PREVIEW =================
    Future<void> previewSound(String soundName) async {
      final sprite = _activeSprite;
      if (sprite == null) return;
      if (sprite.soundBank == null) return;

      final index = sprite.sounds.indexWhere((s) => s['name'] == soundName);
      if (index == -1) return;

      final soundId = sprite.sounds[index]['soundId'];
      sprite.soundBank!.playSound(sprite, soundId);
    }

    notifyListeners();
  }

  // ================= LOAD DEFAULT SOUNDS =================
  Future<void> loadDefaultSounds(Sprite sprite) async {
    sprite.soundBank ??= SoundBank();

    final meowBytes =
        (await rootBundle.load('assets/sounds/meow.wav')).buffer.asUint8List();
    final clickBytes =
        (await rootBundle.load('assets/sounds/click.mp3')).buffer.asUint8List();
    final deleteBytes = (await rootBundle.load('assets/sounds/delete.mp3'))
        .buffer
        .asUint8List();

    sprite.soundBank!.addSoundPlayer(Sound()
      ..soundId = 'meow'
      ..asset = SoundAsset(
        assetId: 'meow',
        dataFormat: 'wav',
        data: meowBytes,
      ));

    sprite.soundBank!.addSoundPlayer(Sound()
      ..soundId = 'click'
      ..asset = SoundAsset(
        assetId: 'click',
        dataFormat: 'mp3',
        data: clickBytes,
      ));

    sprite.soundBank!.addSoundPlayer(Sound()
      ..soundId = 'delete'
      ..asset = SoundAsset(
        assetId: 'delete',
        dataFormat: 'mp3',
        data: deleteBytes,
      ));
  }

  Sprite get activeSprite => _activeSprite ?? currentSprite;

  Future<void> previewSound(String soundId) async {
    final sprite = activeSprite;
    final soundBank = sprite.soundBank;

    if (soundBank == null) {
      debugPrint('SoundBank not loaded');
      return;
    }

    await soundBank.playSound(sprite, soundId);
  }

  void stop() {
    _running = false;

    for (final block in activeBlocks) {
      block.stop?.call(); // if block has a stop method
    }

    activeBlocks.clear();
    print('WorkspaceEngine: All blocks stopped.');
  }

  void _initSensingVariables() {
    for (final sprite in sprites) {
      sprite.variables['mouseX'] = 0.0;
      sprite.variables['mouseY'] = 0.0;
      sprite.variables['mouseDown'] = false;
      sprite.variables['timer'] = 0.0;

      sprite.variables['touchingEdge'] = false;
      sprite.variables['touchingSprite'] = false;
      sprite.variables['touchingColor'] = false;
      sprite.variables['loudness'] = 0.0;
      sprite.variables['currentAnswer'] = '';

      sprite.variables['distanceToMouse'] = 0.0;
      sprite.variables['isKeyPressed'] = false;
    }
  }

  // ================= PROJECT NAME =================

  void setProjectName(String name) {
    _currentProjectName = name;
    notifyListeners();
  }
  // ================= CREATOR NAME =================

  String _creatorName = 'Unknown';

  String get creatorName => _creatorName;

  void setCreatorName(String name) {
    _creatorName = name;
    notifyListeners();
  }

// ================= WORKSPACE =================

  void clearWorkspace() {
    currentWorkspace.clear();
    _hatBlocks.clear();
    notifyListeners();
  }

  // ================= LOAD PROJECT FROM JSON =================
  void loadFromJson(Map<String, dynamic> json) {
    _sprites.clear();
    _spriteWorkspaces.clear();
    _hatBlocks.clear();
    _spriteRunning.clear();

    _currentProjectName = json['projectName'] ?? 'Untitled Project';

    final stage = json['stage'] ?? {};
    currentBackdrop = stage['currentBackdrop'];
    selectedBackdropIndex = stage['selectedBackdropIndex'] ?? 0;

    final List spritesJson = json['sprites'] ?? [];
    for (final s in spritesJson) {
      final sprite = Sprite.fromJson(Map<String, dynamic>.from(s));
      _sprites.add(sprite);

      _spriteWorkspaces[sprite.id] = [];
      _spriteRunning[sprite.id] = false;

      runtime.createTarget(id: sprite.id, name: sprite.name);
      final target = runtime.getTarget(sprite.id);
      if (target != null && !central.targets.containsKey(sprite.id)) {
        central.registerTarget(target);
      }

      final Map<String, dynamic> blocksJson =
          Map<String, dynamic>.from(json['blocks'] ?? {});

      blocksJson.forEach((spriteId, blockList) {
        final List<Block> blocks = [];

        for (final b in blockList) {
          final block = Block.fromJson(Map<String, dynamic>.from(b));
          blocks.add(block);

          if (block.type.startsWith('event_')) {
            _hatBlocks.putIfAbsent(block.type, () => {});
            _hatBlocks[block.type]!.putIfAbsent(spriteId, () => []).add(block);
          }
        }

        _spriteWorkspaces[spriteId] = blocks;
      });

      for (final workspace in _spriteWorkspaces.values) {
        for (final block in workspace) {
          if (block.next != null) {
            final nextBlock = workspace.firstWhere(
              (b) => b.id == block.next!.id,
              orElse: () => block.next!,
            );
            block.next = nextBlock;
          }
        }
      }
    }

    if (_sprites.isEmpty) {
      addSprite(Sprite(
        id: 'cat',
        name: 'Cat',
        assetPath: 'assets/sprites/cat.svg',
      ));
    }

    selectedIndex = 0;

    //  Restore blocks per sprite
    final workspaces = json['workspaces'] ?? {};
    workspaces.forEach((spriteId, blocksJson) {
      _spriteWorkspaces.putIfAbsent(spriteId, () => []);

      for (final b in blocksJson) {
        final block = Block.fromJson(Map<String, dynamic>.from(b));
        _spriteWorkspaces[spriteId]!.add(block);

        // Register event (hat) blocks
        if (block.type.startsWith('event_')) {
          _hatBlocks.putIfAbsent(block.type, () => {});
          _hatBlocks[block.type]!.putIfAbsent(spriteId, () => []).add(block);
        }
      }
    });

    notifyListeners();
  }

  bool _isTouchingEdgeFor(Sprite sprite) {
    const double SPRITE_WIDTH = 80;
    const double SPRITE_HEIGHT = 80;

    final double halfStageWidth = rt.Runtime.STAGE_WIDTH / 2;
    final double halfStageHeight = rt.Runtime.STAGE_HEIGHT / 2;

    return sprite.x - SPRITE_WIDTH / 2 <= -halfStageWidth ||
        sprite.x + SPRITE_WIDTH / 2 >= halfStageWidth ||
        sprite.y - SPRITE_HEIGHT / 2 <= -halfStageHeight ||
        sprite.y + SPRITE_HEIGHT / 2 >= halfStageHeight;
  }

  /// =======================================================
  /// Call this function only when GREEN FLAG is clicked
  /// =======================================================
  void startSensingUpdates() {
    Timer.periodic(const Duration(milliseconds: 50), (_) {
      for (final sprite in sprites) {
        sprite.variables['timer'] = (sprite.variables['timer'] ?? 0.0) + 0.05;

        sprite.variables['touchingEdge'] = _isTouchingEdgeFor(sprite);

        sprite.variables['distanceToMouse'] = sqrt(
          pow((sprite.variables['mouseX'] ?? 0) - sprite.x, 2) +
              pow((sprite.variables['mouseY'] ?? 0) - sprite.y, 2),
        );
      }
      notifyListeners();
    });
  }

  // ===== SPRITE MOVEMENT WITH COLOR SENSING =====
  Future<void> moveSprite(Sprite sprite, double dx, double dy) async {
    sprite.x += dx;
    sprite.y += dy;

    final position = Offset(sprite.x, sprite.y);

    final pixelColor = await sampleColorAt(position);

    updateColorTouching(pixelColor);

    notifyListeners();
  }

  void removeBlock(Block block) {
    // Find previous
    Block? previous;
    for (final b in currentWorkspace) {
      if (b.next == block) {
        previous = b;
        break;
      }
    }

    // Reconnect
    if (previous != null) previous.next = block.next;

    // Remove
    currentWorkspace.remove(block);

    // Clear links
    block.next = null;

    notifyListeners();
  }

  Future<void> triggerEvent(String eventType,
      [Map<String, dynamic>? args]) async {
    if (!_hatBlocks.containsKey(eventType)) return;

    // 🟢 GREEN FLAG RESET
    if (eventType == 'event_whenflagclicked') {
      _running = true;
      _spriteRunning.clear();

      for (final sprite in sprites) {
        _spriteRunning[sprite.id] = true;
      }
    }

    for (final sprite in sprites) {
      if (_spriteRunning[sprite.id] != true) continue;

      final spriteHats = _hatBlocks[eventType]?[sprite.id];
      if (spriteHats == null) continue;

      for (final hat in spriteHats) {
        final firstBlock = hat.next;
        if (firstBlock == null) continue;

        unawaited(
          _executeStack(firstBlock, sprite.id, args),
        );
      }
    }
  }

  Future<void> _executeStack(Block block, String spriteId,
      [Map<String, dynamic>? args]) async {
    Block? current = block;
    while (current != null && _spriteRunning[spriteId] == true) {
      await _executeBlock(current, spriteId);
      current = current.next;
    }
  }

  Widget buildFieldsForBlock(Block block) {
    _inputControllers.putIfAbsent(block.id, () => {});

    _inputControllers[block.id]!.putIfAbsent('value', () {
      if (block.type == 'motion_movesteps')
        return TextEditingController(text: '10');
      if (block.type == 'motion_turnright' || block.type == 'motion_turnleft')
        return TextEditingController(text: '15');
      return TextEditingController(text: '0');
    });

    _inputControllers[block.id]!
        .putIfAbsent('x', () => TextEditingController(text: '0'));
    _inputControllers[block.id]!
        .putIfAbsent('y', () => TextEditingController(text: '0'));
    _inputControllers[block.id]!
        .putIfAbsent('t', () => TextEditingController(text: '1'));
    _inputControllers[block.id]!
        .putIfAbsent('secs', () => TextEditingController(text: '1'));

    TextEditingController mainController =
        _inputControllers[block.id]!['value']!;

    if (block.type.startsWith('motion_')) {
      return FutureBuilder<Widget>(
        future: buildMotionBlock(
          block,
          projectId: projectId,
          onChanged: (field, val) {
            _inputControllers[block.id]?[field]?.text = val;
            notifyListeners();
          },
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 48);
          }
          return snapshot.data ?? const SizedBox.shrink();
        },
      );
    }

    if (block.type == 'looks_sayforsecs' ||
        block.type == 'looks_thinkforsecs') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TEXT INPUT
          SizedBox(
            width: 100,
            child: TextField(
              controller: _inputControllers[block.id]!['value'],
              decoration: const InputDecoration(
                hintText: 'Text',
                isDense: true,
                contentPadding: EdgeInsets.all(6),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                block.value = v;
                notifyListeners();
              },
            ),
          ),
          const SizedBox(width: 6),

          // SECONDS INPUT
          SizedBox(
            width: 50,
            child: TextField(
              controller: _inputControllers[block.id]!['secs'],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Secs',
                isDense: true,
                contentPadding: EdgeInsets.all(6),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => notifyListeners(),
            ),
          ),
        ],
      );
    }

    // Default TextField for other blocks
    return SizedBox(
      width: block.type.contains('say') || block.type.contains('think')
          ? 120
          : 60, // use a fixed small width for numbers
      child: TextField(
        controller: mainController,
        decoration: InputDecoration(
          hintText: block.isNote ? block.noteText : 'Value/Text',
          isDense: true,
          contentPadding: const EdgeInsets.all(6),
          border: OutlineInputBorder(),
        ),
        keyboardType: block.type.contains('say') || block.type.contains('think')
            ? TextInputType.text
            : TextInputType.number,
        onChanged: (val) async {
          // Update controller
          _inputControllers[block.id]!['value']!.text = val;

          block.value = val;

          notifyListeners();
        },
      ),
    );
  }

  dynamic getInput(Block block, {String field = 'value'}) {
    final ctrl = _inputControllers[block.id]?[field];
    if (ctrl != null && ctrl.text.trim().isNotEmpty) {
      // Only return text if field is 'value', not 'secs'
      if (field == 'value') return ctrl.text.trim();
    }

    if ((block.type == 'looks_sayforsecs' ||
        block.type == 'looks_thinkforsecs')) {
      if (field == 'value') {
        final ctrl = _inputControllers[block.id]?['value'];
        if (ctrl != null && ctrl.text.isNotEmpty) return ctrl.text.trim();
        return block.value.isNotEmpty ? block.value : 'Hello!';
      }
      if (field == 'secs') {
        final ctrl = _inputControllers[block.id]?['secs'];
        if (ctrl != null && ctrl.text.isNotEmpty) {
          return double.tryParse(ctrl.text.trim()) ?? 2;
        }
        return 2;
      }
    }

    if (field == 'value' && block.value.isNotEmpty) return block.value;

    if (block.type == 'motion_movesteps') return '10';
    if (block.type == 'motion_turnright' || block.type == 'motion_turnleft')
      return '15';
    if (field == 'x' || field == 'y') return '0';
    if (field == 't') return '1';
    if (field == 'secs') return 1;

    return '';
  }

  Future<void> runBlocks(List<Block> blocks, {String? spriteId}) async {
    final String id = spriteId ?? currentSprite.id;

    if (_spriteRunning[id] == true) return;

    _spriteRunning[id] = true;

    for (var block in blocks) {
      if (_spriteRunning[id] != true) break;

      await _executeBlock(block, id);
    }

    _spriteRunning[id] = false;
  }

  Future<void> _executeMotionBlock(Block block, Sprite sprite) async {
    if (block.isNote && block.noteText.isNotEmpty) {
      sprite.showBubble(block.noteText, durationMs: 1000);
    } else {
      sprite.hideBubble();
    }

    switch (block.type) {
      // ================= MOVE STEPS =================
      case 'motion_movesteps':
        final steps =
            double.tryParse(getInput(block, field: 'value').toString()) ?? 10;
        final radians = (sprite.direction - 90) * pi / 180;
        final targetX = sprite.x + steps * cos(radians);
        final targetY = sprite.y + steps * sin(radians);

        await _animateMove(sprite, sprite.x, sprite.y, targetX, targetY,
            duration: const Duration(milliseconds: 400));
        break;

      // ================= TURN RIGHT =================
      case 'motion_turnright':
        final deg =
            double.tryParse(getInput(block, field: 'value').toString()) ?? 15;
        sprite.direction = (sprite.direction + deg) % 360;
        notifyListeners();
        break;

      // ================= TURN LEFT =================
      case 'motion_turnleft':
        final deg =
            double.tryParse(getInput(block, field: 'value').toString()) ?? 15;
        sprite.direction = (sprite.direction - deg) % 360;
        if (sprite.direction < 0) sprite.direction += 360;
        notifyListeners();
        break;

      // ================= GO TO X Y =================
      case 'motion_gotoxy':
        final x = double.tryParse(getInput(block, field: 'x').toString()) ?? 0;
        final y = double.tryParse(getInput(block, field: 'y').toString()) ?? 0;

        await _animateMove(sprite, sprite.x, sprite.y, x, y,
            duration: const Duration(milliseconds: 300));
        break;

      // ================= GO TO RANDOM =================
      case 'motion_gotorandom':
        final rand = Random();
        final x = rand.nextDouble() * rt.Runtime.STAGE_WIDTH -
            rt.Runtime.STAGE_WIDTH / 2;
        final y = rand.nextDouble() * rt.Runtime.STAGE_HEIGHT -
            rt.Runtime.STAGE_HEIGHT / 2;

        await _animateMove(sprite, sprite.x, sprite.y, x, y,
            duration: const Duration(milliseconds: 300));
        break;

      // ================= GLIDE SECS TO X Y =================
      case 'motion_glidesecstoxy':
        double secs =
            double.tryParse(getInput(block, field: 't').toString()) ?? 1;
        secs = secs.clamp(0.1, 60);
        final x = double.tryParse(getInput(block, field: 'x').toString()) ?? 0;
        final y = double.tryParse(getInput(block, field: 'y').toString()) ?? 0;

        await _animateMove(sprite, sprite.x, sprite.y, x, y,
            duration: Duration(milliseconds: (secs * 1000).toInt()));
        break;

      // ================= GLIDE SECS TO RANDOM =================
      case 'motion_glidesecstorandom':
        double secs =
            double.tryParse(getInput(block, field: 't').toString()) ?? 1;
        secs = secs.clamp(0.1, 60);

        final rand2 = Random();
        final x2 = rand2.nextDouble() * rt.Runtime.STAGE_WIDTH -
            rt.Runtime.STAGE_WIDTH / 2;
        final y2 = rand2.nextDouble() * rt.Runtime.STAGE_HEIGHT -
            rt.Runtime.STAGE_HEIGHT / 2;

        await _animateMove(sprite, sprite.x, sprite.y, x2, y2,
            duration: Duration(milliseconds: (secs * 1000).toInt()));
        break;

      // ================= POINT IN DIRECTION =================
      case 'motion_pointindirection':
        final deg =
            double.tryParse(getInput(block, field: 'value').toString()) ?? 90;
        sprite.direction = deg % 360;
        notifyListeners();
        break;

      // ================= POINT TOWARDS =================
      case 'motion_pointtowards':
        final target = getInput(block, field: 'target').toString();

        if (target == 'mouse') {
          final mouseX = (sprite.variables['mouseX'] ?? 0).toDouble();
          final mouseY = (sprite.variables['mouseY'] ?? 0).toDouble();
          final dx = mouseX - sprite.x;
          final dy = mouseY - sprite.y;
          final angle = atan2(dy, dx) * 180 / pi + 90;
          sprite.direction = angle % 360;
        } else {
          Sprite? other = sprites.cast<Sprite?>().firstWhere(
                (s) => s!.name == target,
                orElse: () => null,
              );
          if (other != null) {
            final dx = other.x - sprite.x;
            final dy = other.y - sprite.y;
            final angle = atan2(dy, dx) * 180 / pi + 90;
            sprite.direction = angle % 360;
          }
        }
        notifyListeners();
        break;

      // ================= SPIN 360 =================
      case 'motion_spin360':
        for (int i = 0; i < 360; i += 15) {
          sprite.direction = (sprite.direction + 15) % 360;
          notifyListeners();
          await Future.delayed(Duration(milliseconds: 10));
        }
        break;

      // ================= CHANGE X =================
      case 'motion_changexby':
        sprite.x +=
            double.tryParse(getInput(block, field: 'value').toString()) ?? 10;
        notifyListeners();
        break;

      // ================= SET X =================
      case 'motion_setx':
        {
          // Get the raw input from the block
          final rawValue = getInput(block, field: 'value');

          // Convert to double safely
          final newX = double.tryParse(rawValue?.toString() ?? '') ?? 0;

          // Apply to sprite
          sprite.x = newX;

          // Notify listeners / UI
          notifyListeners();
        }
        break;

      // ================= CHANGE Y =================
      case 'motion_changeyby':
        sprite.y +=
            double.tryParse(getInput(block, field: 'value').toString()) ?? 10;
        notifyListeners();
        break;

      // ================= SET Y =================
      case 'motion_sety':
        sprite.y =
            double.tryParse(getInput(block, field: 'value').toString()) ?? 0;
        notifyListeners();
        break;

      // ================= IF ON EDGE, BOUNCE =================
      case 'motion_ifonedgebounce':
        final halfW = rt.Runtime.STAGE_WIDTH / 2;
        final halfH = rt.Runtime.STAGE_HEIGHT / 2;
        bool bounced = false;

        if (sprite.x >= halfW) {
          sprite.x = halfW;
          sprite.direction = 180 - sprite.direction;
          bounced = true;
        } else if (sprite.x <= -halfW) {
          sprite.x = -halfW;
          sprite.direction = 180 - sprite.direction;
          bounced = true;
        }

        if (sprite.y >= halfH) {
          sprite.y = halfH;
          sprite.direction = -sprite.direction;
          bounced = true;
        } else if (sprite.y <= -halfH) {
          sprite.y = -halfH;
          sprite.direction = -sprite.direction;
          bounced = true;
        }

        if (bounced) {
          sprite.direction = (sprite.direction % 360 + 360) % 360;
        }
        notifyListeners();
        break;

      // ================= SET ROTATION STYLE =================
      case 'motion_setrotationstyle':
        final raw = block.arguments['value'] as String? ?? 'all around';
        final style =
            raw.toLowerCase().replaceAll(RegExp(r"[ '\-–]"), "").trim();

        switch (style) {
          case 'leftright':
            sprite.rotationStyle = RotationStyle.leftRight;
            break;
          case 'dontrotate':
            sprite.rotationStyle = RotationStyle.dontRotate;
            break;
          case 'allaround':
          default:
            sprite.rotationStyle = RotationStyle.allAround;
            break;
        }
        notifyListeners();
        break;
    }
  }

  void deleteClone(Sprite sprite) {
    // Do not delete original sprite
    if (sprite.isOriginal) return;

    // Stop this sprite
    _spriteRunning[sprite.id] = false;

    // Remove from sprite list
    _sprites.removeWhere((s) => s.id == sprite.id);

    // Remove workspace blocks belonging to this sprite
    workspaceUIBlocks.removeWhere(
      (b) => b.variable?['spriteId'] == sprite.id,
    );

    workspaceUIBlocks.removeWhere(
      (b) => b.variable?['spriteId'] == sprite.id,
    );

    notifyListeners();
  }

  // ---------------- CONTROL BLOCK EXECUTION ----------------
  Future<void> _executeControlBlock(Block block, Sprite sprite) async {
    sprite._loopCounters ??= {};
    sprite._forEachIndex ??= {};

    switch (block.type) {
      // ================= REPEAT <times> =================
      case 'control_repeat':
        final times = block.arguments['TIMES'] as int? ?? 1;
        sprite._loopCounters[block.id] ??= times;

        while (sprite._loopCounters[block.id]! > 0) {
          sprite._loopCounters[block.id] = sprite._loopCounters[block.id]! - 1;
          await _executeSubStack(block, sprite);

          // Yield for UI
          await Future.delayed(const Duration(milliseconds: 1));
          if (_spriteRunning[sprite.id] != true) break;
        }
        sprite._loopCounters.remove(block.id);
        break;

      // ================= REPEAT UNTIL <condition> =================
      case 'control_repeat_until':
        while (!Cast.toBoolean(getInput(block, field: 'CONDITION'))) {
          await _executeSubStack(block, sprite);
          await Future.delayed(const Duration(milliseconds: 1));
          if (_spriteRunning[sprite.id] != true) break;
        }
        break;

      // ================= REPEAT WHILE <condition> =================
      case 'control_while':
        while (Cast.toBoolean(getInput(block, field: 'CONDITION'))) {
          await _executeSubStack(block, sprite);
          await Future.delayed(const Duration(milliseconds: 1));
          if (_spriteRunning[sprite.id] != true) break;
        }
        break;

      // ================= FOREVER =================
      case 'control_forever':
        _runForever(block, sprite);
        break;

      // ================= WAIT <seconds> =================
      case 'control_wait':
        double duration =
            double.tryParse(getInput(block, field: 'DURATION').toString()) ?? 1;
        duration = duration.clamp(0.1, 60);
        await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
        break;

      // ================= WAIT UNTIL <condition> =================
      case 'control_wait_until':
        while (!Cast.toBoolean(getInput(block, field: 'CONDITION'))) {
          await Future.delayed(const Duration(milliseconds: 20));
          if (_spriteRunning[sprite.id] != true) break;
        }
        break;

      // ================= IF <condition> =================
      case 'control_if':
        if (Cast.toBoolean(getInput(block, field: 'CONDITION'))) {
          await _executeSubStack(block, sprite);
        }
        break;

      // ================= IF ELSE <condition> =================
      case 'control_if_else':
        if (Cast.toBoolean(getInput(block, field: 'CONDITION'))) {
          await _executeSubStack(block, sprite, branch: 1);
        } else {
          await _executeSubStack(block, sprite, branch: 2);
        }
        break;

      // ================= STOP =================
      case 'control_stop':
        final option = getInput(block, field: 'STOP_OPTION').toString();
        if (option == 'all') {
          stopAllSprites();
        } else if (option == 'other scripts in sprite' ||
            option == 'other scripts in stage') {
          stopOtherScripts(sprite);
        } else if (option == 'this script') {
          stopThisScript(sprite);
        }
        break;

      // ================= CREATE CLONE =================
      case 'control_create_clone_of':
        final cloneOption = getInput(block, field: 'CLONE_OPTION').toString();
        Sprite? source;
        if (cloneOption == '_myself_') {
          source = sprite;
        } else {
          source = sprites.firstWhereOrNull((s) => s.name == cloneOption);
        }
        if (source != null) createClone(source);
        break;

      // ================= DELETE THIS CLONE =================
      case 'control_delete_this_clone':
        if (!sprite.isOriginal) deleteClone(sprite);
        break;

      // ================= COUNTER BLOCKS =================
      case 'control_get_counter':
        block.reporterValue = _counter;
        break;

      case 'control_incr_counter':
        _counter++;
        break;

      case 'control_clear_counter':
        _counter = 0;
        break;

      // ================= ALL AT ONCE =================
      case 'control_all_at_once':
        await _executeSubStack(block, sprite);
        break;

      // ================= FOR EACH =================
      case 'control_for_each':
        final varName = getInput(block, field: 'VARIABLE').toString();
        final endValue =
            int.tryParse(getInput(block, field: 'VALUE').toString()) ?? 1;

        sprite._forEachIndex[block.id] ??= 1;

        while (sprite._forEachIndex[block.id]! <= endValue) {
          sprite.variables[varName] = sprite._forEachIndex[block.id]!;

          await _executeSubStack(block, sprite);

          sprite._forEachIndex[block.id] = sprite._forEachIndex[block.id]! + 1;

          await Future.delayed(const Duration(milliseconds: 1));
          if (_spriteRunning[sprite.id] != true) break;
        }
        sprite._forEachIndex.remove(block.id);
        break;
    }

    // Notify UI after control block executes
    notifyListeners();
  }

  Future<void> _runForever(Block block, Sprite sprite) async {
    if (_spriteRunning[sprite.id] != true) return;

    await _executeSubStack(block, sprite);
    await Future.delayed(const Duration(milliseconds: 16)); // frame delay

    _runForever(block, sprite);
  }

// ---------------- SUB-STACK EXECUTION WITH VISUAL HIGHLIGHT ----------------
  Future<void> _executeSubStack(Block parentBlock, Sprite sprite,
      {int branch = 1}) async {
    // branch = 1 (default) or 2 for if-else
    List<Block> subStackToRun = [];
    if (branch == 1) {
      subStackToRun = parentBlock.subStack; // main stack
    } else if (branch == 2) {
      subStackToRun = parentBlock.elseSubStack; // else stack
    }

    for (final block in subStackToRun) {
      if (_spriteRunning[sprite.id] != true) break;

      block.isRunning = true;
      notifyListeners();

      if (block.type.startsWith('motion_')) {
        await _executeMotionBlock(block, sprite);
      } else if (block.type.startsWith('control_')) {
        await _executeControlBlock(block, sprite);
      } else if (block.type.startsWith('logic_')) {
        block.reporterValue = _evaluateLogicBlock(block, sprite);
      } else if (block.type.startsWith('sensing_')) {
        block.reporterValue = _executeSensingBlock(block, sprite);
      } else if (block.type.startsWith('sound_')) {
        await _executeSoundBlock(block, sprite);
      } else {
        await _evaluateBlock(block, sprite);
      }

      block.isRunning = false;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 1));

      // execute next block in sequence (line by line)
      if (block.next != null) {
        await _executeBlock(block.next!, sprite.id);
      }
    }
  }

  /// Execute a sensing block
  dynamic _executeSensingBlock(Block block, Sprite sprite) {
    final util = {'target': sprite, 'ioQuery': runtime.ioQuery};
    final primitives = _sensingBlocks.getPrimitives();

    if (!primitives.containsKey(block.type)) {
      throw Exception('Unknown sensing block: ${block.type}');
    }

    return primitives[block.type]!(block.arguments, util);
  }

  void executeBlock(String opcode, Map<String, dynamic> args, dynamic target) {
    runtime.executeOpcode(opcode, args, {'target': target});
  }

  Future<void> runAllEventBlocks() async {
    if (_eventsRegistered) return;
    _eventsRegistered = true;

    for (var sprite in sprites) {
      final eventBlocks = workspaceUIBlocks.where((b) =>
          b.type?.startsWith('event_') == true &&
          b.variable?['spriteId'] == sprite.id);

      for (var block in eventBlocks) {
        _executeEventBlock(block.toEngineBlock(), sprite);
      }
    }
  }

  Future<void> _executeBlock(Block block, String? spriteId) async {
    if (spriteId == null || _spriteRunning[spriteId] != true) return;

    // Find the sprite by ID, fallback to currentSprite
    final Sprite sprite = sprites.firstWhere(
      (s) => s.id == spriteId,
      orElse: () => currentSprite,
    );

    _activeSprite = sprite;

    // ❌ Skip event blocks here
    if (block.type.startsWith('event_when')) return;

    try {
      // 🟦 MOTION
      if (block.type.startsWith('motion_')) {
        await _executeMotionBlock(block, sprite);
      }

      // 🟥 CONTROL
      else if (block.type.startsWith('control_')) {
        await _executeControlBlock(block, sprite);
      }

      // 🟩 LOGIC (reporter)
      if (block.type.startsWith('logic_')) {
        block.reporterValue = _evaluateLogicBlock(block, sprite);
      }

      // 🟨 SENSING
      else if (block.type.startsWith('sensing_')) {
        block.reporterValue = _executeSensingBlock(block, sprite);
      }

      // 🟪 SOUND
      else if (block.type.startsWith('sound_')) {
        await _executeSoundBlock(block, sprite);
      }
      // 🔊 BROADCAST
      else if (block.type == 'event_broadcast') {
        final msg = block.arguments['BROADCAST_OPTION']?.toString() ?? '';
        _sendBroadcast(msg);
      }

// 🔊 BROADCAST AND WAIT (same behavior for now)
      else if (block.type == 'event_broadcastandwait') {
        final msg = block.arguments['BROADCAST_OPTION']?.toString() ?? '';
        _sendBroadcast(msg);
      }

      // 🟨 DATA / VARIABLES
      else if (block.type.startsWith('data_')) {
        await _executeDataBlock(block, sprite, this);
      }

      // 🟩 OTHER BLOCKS (looks, etc.)
      else {
        await _evaluateBlock(block, sprite);
      }
    } catch (e, st) {
      print('Error executing block ${block.type}: $e\n$st');
    }

    // ✅ EXECUTE NEXT BLOCK
    if (block.next != null) {
      await _executeBlock(block.next!, sprite.id);
    }
  }

  // -------------------- Execute Data Block --------------------
  Future<void> _executeDataBlock(
    Block block,
    Sprite sprite,
    WorkspaceEngine engine,
  ) async {
    try {
      // Helper to safely get argument as String and log if missing
      String? getArg(String key) {
        final value = block.arguments[key];
        if (value is! String) {
          print(
              '⚠️ Missing or invalid argument "$key" in block type "${block.type}"');
          return null;
        }
        return value;
      }

      switch (block.type) {
        // ================= VARIABLES =================

        case 'data_variable':
          {
            final name = getArg('VARIABLE');
            if (name == null) return;
            block.reporterValue = engine.getVariable(name, sprite) ?? 0;
            print('🔹 Variable "$name" value: ${block.reporterValue}');
            break;
          }

        case 'data_setvariableto':
          {
            final name = getArg('VARIABLE');
            if (name == null) return;

            final value = await evaluateInput(block, 'VALUE', sprite, engine);
            engine.setVariable(name, value, sprite);
            print('🔹 Set variable "$name" to $value');
            break;
          }

        case 'data_changevariableby':
          {
            final name = getArg('VARIABLE');
            if (name == null) return;

            final delta = Cast.toNumber(
                    await evaluateInput(block, 'VALUE', sprite, engine)) ??
                0;
            final current =
                Cast.toNumber(engine.getVariable(name, sprite)) ?? 0;
            engine.setVariable(name, current + delta, sprite);
            print(
                '🔹 Changed variable "$name" by $delta (was $current, now ${current + delta})');
            break;
          }

        case 'data_showvariable':
          {
            final name = getArg('VARIABLE');
            if (name == null) return;

            sprite.variableWatchers[name] = true;
            print('👁 Show watcher for "$name"');
            break;
          }

        case 'data_hidevariable':
          {
            final name = getArg('VARIABLE');
            if (name == null) return;

            sprite.variableWatchers[name] = false;
            print('🙈 Hide watcher for "$name"');
            break;
          }

        // ================= LISTS =================

        case 'data_listcontents':
          {
            final name = getArg('LIST');
            if (name == null) return;
            final list = (engine.getVariable(name, sprite) as List?) ?? [];
            block.reporterValue = list;
            print('🔹 List "$name" contents: $list');
            break;
          }

        case 'data_addtolist':
          {
            final name = getArg('LIST');
            if (name == null) return;

            final item = await evaluateInput(block, 'ITEM', sprite, engine);

            final original = engine.getVariable(name, sprite);
            final list = original is List ? List.from(original) : <dynamic>[];

            list.add(item);

            engine.setVariable(name, list, sprite);

            print('🔹 Added item "$item" to list "$name". New list: $list');
            break;
          }

        case 'data_deleteoflist':
          {
            final name = getArg('LIST');
            if (name == null) return;

            final list = (engine.getVariable(name, sprite) as List?) ?? [];
            final index = ((Cast.toNumber(await evaluateInput(
                            block, 'INDEX', sprite, engine)) ??
                        1)
                    .toInt()) -
                1;

            if (index < 0 || index >= list.length) {
              print(
                  '⚠️ Invalid index $index for list "$name" with length ${list.length}');
            } else {
              final removed = list.removeAt(index);
              print(
                  '🔹 Removed item "$removed" from list "$name" at index $index. New list: $list');
            }

            engine.setVariable(name, list, sprite);
            break;
          }

        case 'data_deletealloflist':
          {
            final name = getArg('LIST');
            if (name == null) return;
            engine.setVariable(name, <dynamic>[], sprite);
            print('🔹 Cleared all items from list "$name"');
            break;
          }

        case 'data_insertatlist':
          {
            final name = getArg('LIST');
            if (name == null) return;

            final list = (engine.getVariable(name, sprite) as List?) ?? [];
            final index = ((Cast.toNumber(await evaluateInput(
                            block, 'INDEX', sprite, engine)) ??
                        1)
                    .toInt()) -
                1;
            final item = await evaluateInput(block, 'ITEM', sprite, engine);

            if (index < 0 || index > list.length) {
              print(
                  '⚠️ Invalid index $index for inserting into list "$name" with length ${list.length}');
            } else {
              list.insert(index, item);
              print(
                  '🔹 Inserted item "$item" at index $index into list "$name". New list: $list');
            }

            engine.setVariable(name, list, sprite);
            break;
          }

        case 'data_replaceitemoflist':
          {
            final name = getArg('LIST');
            if (name == null) return;

            final list = (engine.getVariable(name, sprite) as List?) ?? [];
            final index = ((Cast.toNumber(await evaluateInput(
                            block, 'INDEX', sprite, engine)) ??
                        1)
                    .toInt()) -
                1;
            final item = await evaluateInput(block, 'ITEM', sprite, engine);

            if (index < 0 || index >= list.length) {
              print(
                  '⚠️ Invalid index $index for replacing item in list "$name" with length ${list.length}');
            } else {
              final old = list[index];
              list[index] = item;
              print(
                  '🔹 Replaced item "$old" with "$item" at index $index in list "$name". New list: $list');
            }

            engine.setVariable(name, list, sprite);
            break;
          }

        case 'data_itemoflist':
          {
            final name = getArg('LIST');
            if (name == null) return;

            final list = (engine.getVariable(name, sprite) as List?) ?? [];
            final index = ((Cast.toNumber(await evaluateInput(
                            block, 'INDEX', sprite, engine)) ??
                        1)
                    .toInt()) -
                1;

            if (index < 0 || index >= list.length) {
              print(
                  '⚠️ Invalid index $index for list "$name" with length ${list.length}');
              block.reporterValue = '';
            } else {
              block.reporterValue = list[index];
              print(
                  '🔹 Retrieved item "${block.reporterValue}" from list "$name" at index $index');
            }
            break;
          }

        case 'data_itemnumoflist':
          {
            final name = getArg('LIST');
            if (name == null) return;

            final list = (engine.getVariable(name, sprite) as List?) ?? [];
            final item = await evaluateInput(block, 'ITEM', sprite, engine);

            final index = list.indexOf(item);
            block.reporterValue = index >= 0 ? index + 1 : 0;
            print(
                '🔹 Item "$item" index in list "$name": ${block.reporterValue}');
            break;
          }

        case 'data_lengthoflist':
          {
            final name = getArg('LIST');
            if (name == null) return;

            final list = (engine.getVariable(name, sprite) as List?) ?? [];
            block.reporterValue = list.length;
            print('🔹 List "$name" length: ${block.reporterValue}');
            break;
          }

        case 'data_listcontainsitem':
          {
            final name = getArg('LIST');
            if (name == null) return;

            final list = (engine.getVariable(name, sprite) as List?) ?? [];
            final item = await evaluateInput(block, 'ITEM', sprite, engine);
            block.reporterValue = list.contains(item);
            print(
                '🔹 List "$name" contains item "$item": ${block.reporterValue}');
            break;
          }
      }
    } catch (e, st) {
      print('❌ Error executing data block "${block.type}": $e\n$st');
    }

    notifyListeners();
    engine.requestRepaint();
  }

  Future<dynamic> evaluateInput(
    Block block,
    String name,
    Sprite sprite,
    WorkspaceEngine engine,
  ) async {
    final nested = block.inputBlocks[name];

    if (nested != null) {
      await _executeBlock(nested, sprite.id);
      return nested.reporterValue;
    }

    return block.arguments[name];
  }

  Future<void> _executeEventBlock(Block block, Sprite sprite) async {
    switch (block.type) {
      /// -----------------------------------
      /// GREEN FLAG
      /// -----------------------------------
      case 'event_whenflagclicked':
        Future.microtask(() => _executeSubStack(block, sprite));
        break;

      /// -----------------------------------
      /// KEY PRESSED
      /// -----------------------------------
      case 'event_whenkeypressed':
        final keyName = (block.arguments['KEY_OPTION'] ??
                block.arguments['keyOption'] ??
                '')
            .toString()
            .toLowerCase();

        final specialKey = _mapScratchKey(keyName);

        void keyboardListener(RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            // ANY key
            if (keyName == 'any') {
              Future.microtask(() => _executeSubStack(block, sprite));
              return;
            }

            // Space / arrow keys
            if (specialKey != null && event.logicalKey == specialKey) {
              Future.microtask(() => _executeSubStack(block, sprite));
              return;
            }

            // Letter keys
            if (event.character != null &&
                event.character!.toLowerCase() == keyName) {
              Future.microtask(() => _executeSubStack(block, sprite));
            }
          }
        }

        RawKeyboard.instance.addListener(keyboardListener);
        break;

      /// -----------------------------------
      /// BROADCAST RECEIVED
      /// -----------------------------------
      case 'event_whenbroadcastreceived':
        final message = block.arguments['BROADCAST_OPTION']?.toString() ?? '';

        _broadcastStream.stream.where((m) => m == message).listen((_) {
          Future.microtask(() => _executeSubStack(block, sprite));
        });
        break;
    }
  }

  void _sendBroadcast(String message) {
    _broadcastStream.add(message);
  }

  LogicalKeyboardKey? _mapScratchKey(String key) {
    switch (key) {
      case 'space':
        return LogicalKeyboardKey.space;
      case 'up arrow':
        return LogicalKeyboardKey.arrowUp;
      case 'down arrow':
        return LogicalKeyboardKey.arrowDown;
      case 'left arrow':
        return LogicalKeyboardKey.arrowLeft;
      case 'right arrow':
        return LogicalKeyboardKey.arrowRight;
      default:
        return null; // letters handled separately
    }
  }

  Future<void> _executeSoundBlock(Block block, Sprite _sprite) async {
    final soundBank = _sprite.soundBank;
    if (soundBank == null) return;

    final soundName = block.arguments['SOUND_MENU']?.toString();
    String? soundId;

    if (soundName != null && soundName.isNotEmpty && soundName != 'No sounds') {
      final sound = _sprite.sounds.firstWhere(
        (s) => s['name'] == soundName,
        orElse: () => {},
      );

      if (sound.isNotEmpty) {
        soundId = sound['soundId'] as String?;
      }
    }

    switch (block.type) {
      case 'sound_play':
        if (soundId == null || soundId.isEmpty) {
          _sprite.showBubble('No sound selected!');
          return;
        }
        _sprite.showBubble('🔊 Playing $soundName');
        soundBank.playSound(_sprite, soundId);
        break;

      case 'sound_playuntildone':
        if (soundId == null || soundId.isEmpty) {
          _sprite.showBubble('No sound selected!');
          return;
        }
        _sprite.showBubble('🔊 Playing $soundName until done');
        await soundBank.playSoundAndWait(_sprite, soundId);
        break;

      case 'sound_stopallsounds':
        soundBank.stopAllSounds(_sprite);
        _sprite.showBubble('🛑 Stopped all sounds');
        break;

      case 'sound_seteffectto':
        {
          final effect = block.arguments['EFFECT']?.toString().toLowerCase();
          final value =
              double.tryParse(block.arguments['VALUE']?.toString() ?? '0') ?? 0;
          if (effect != null && _sprite.soundEffects.containsKey(effect)) {
            _sprite.soundEffects[effect] = value;
            soundBank.setEffects(_sprite);
          }
        }
        break;

      case 'sound_changeeffectby':
        {
          final effect = block.arguments['EFFECT']?.toString().toLowerCase();
          final value =
              double.tryParse(block.arguments['VALUE']?.toString() ?? '0') ?? 0;
          if (effect != null && _sprite.soundEffects.containsKey(effect)) {
            _sprite.soundEffects[effect] =
                (_sprite.soundEffects[effect] ?? 0) + value;
            soundBank.setEffects(_sprite);
          }
        }
        break;

      case 'sound_cleareffects':
        _sprite.soundEffects.updateAll((key, value) => 0.0);
        soundBank.setEffects(_sprite);
        break;

      case 'sound_setvolumeto':
        {
          final vol =
              double.tryParse(block.arguments['VOLUME']?.toString() ?? '100') ??
                  100;
          _sprite.volume = vol.clamp(0, 100);
          soundBank.setEffects(_sprite);
        }
        break;

      case 'sound_changevolumeby':
        {
          final vol =
              double.tryParse(block.arguments['VOLUME']?.toString() ?? '0') ??
                  0;
          _sprite.volume = (_sprite.volume + vol).clamp(0, 100);
          soundBank.setEffects(_sprite);
        }
        break;

      case 'sound_volume':
        _sprite.showBubble('Volume: ${_sprite.volume.toStringAsFixed(0)}%');
        break;

      default:
        break;
    }
  }

  /// Convert values to boolean for conditions
  bool _isTruthy(dynamic val) {
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) return val.isNotEmpty;
    return val != null;
  }

  /// Execute control blocks like if, if-else, repeat, wait, etc.
  Future<void> executeLogicBlock(BlockModel blockModel, Sprite sprite) async {
    // Convert UI block → engine block
    final block = blockModel.toEngineBlock();

    if (block.type == 'control_if') {
      final condBlock = block.getInput('condition');
      if (condBlock == null) return;

      final condValue = await _evaluateLogicBlock(condBlock, sprite);
      if (_isTruthy(condValue)) {
        for (final b in block.subStack) {
          await _executeBlock(
              b, sprite.id); // ensure _executeBlock accepts Block
        }
      }
    } else if (block.type == 'control_if_else') {
      final condBlock = block.getInput('condition');
      if (condBlock == null) return;

      final condValue = await _evaluateLogicBlock(condBlock, sprite);
      if (_isTruthy(condValue)) {
        for (final b in block.subStack) {
          await _executeBlock(b, sprite.id);
        }
      } else {
        for (final b in block.elseSubStack) {
          await _executeBlock(b, sprite.id);
        }
      }
    } else if (block.type.startsWith('logic_')) {
      // simple logic evaluation
      await _evaluateLogicBlock(block, sprite);
    }
  }

  Future<dynamic> _evaluateLogicBlock(Block block, Sprite sprite) async {
    switch (block.type) {
      case 'logic_true':
        return true;

      case 'logic_false':
        return false;

      case 'logic_negate':
        final aBlock = block.getInput('A');
        if (aBlock == null) return null;
        final value = await _evaluateLogicBlock(aBlock, sprite);
        return !(value as bool? ?? false);

      case 'logic_operation':
        final aBlock = block.getInput('A');
        final bBlock = block.getInput('B');
        if (aBlock == null || bBlock == null) return null;
        final a = await _evaluateLogicBlock(aBlock, sprite);
        final b = await _evaluateLogicBlock(bBlock, sprite);
        final op = block.value ?? 'AND';
        if (op == 'AND') return (a as bool? ?? false) && (b as bool? ?? false);
        return (a as bool? ?? false) || (b as bool? ?? false);

      case 'logic_ternary':
        final condBlock = block.getInput('IF');
        final thenBlock = block.getInput('THEN');
        final elseBlock = block.getInput('ELSE');
        if (condBlock == null) return null;
        final condValue = await _evaluateLogicBlock(condBlock, sprite);
        if (_isTruthy(condValue)) {
          if (thenBlock == null) return null;
          return await _evaluateLogicBlock(thenBlock, sprite);
        } else {
          if (elseBlock == null) return null;
          return await _evaluateLogicBlock(elseBlock, sprite);
        }

      default:
        return null;
    }
  }

  Future<void> _evaluateBlock(Block block, Sprite sprite) async {
    final _sprite = sprite; // use the passed sprite
    final inputValue = getInput(block);

    switch (block.type) {
      // ===== LOOKS =====
      case 'looks_say':
        {
          final text =
              getInput(block, field: 'value')?.toString().trim().isNotEmpty ==
                      true
                  ? getInput(block, field: 'value').toString()
                  : 'Hello!';

          _sprite.showBubble(text, durationMs: 2000);
          break;
        }

      case 'looks_sayforsecs':
        {
          final textCtrl = _inputControllers[block.id]?['value'];
          final String text =
              (textCtrl != null && textCtrl.text.trim().isNotEmpty)
                  ? textCtrl.text.trim()
                  : (block.value.isNotEmpty ? block.value : 'Hello!');

          final secsCtrl = _inputControllers[block.id]?['secs'];
          double secs = 2.0;
          if (secsCtrl != null && secsCtrl.text.trim().isNotEmpty) {
            secs = double.tryParse(secsCtrl.text.trim()) ?? 2.0;
          }
          secs = secs.clamp(0.1, 60.0);

          _sprite.showBubble(text, durationMs: (secs * 1000).toInt());

          break;
        }

      case 'looks_thinkforsecs':
        {
          final textCtrl = _inputControllers[block.id]?['value'];
          final text = textCtrl != null && textCtrl.text.trim().isNotEmpty
              ? textCtrl.text.trim()
              : block.value.isNotEmpty
                  ? block.value
                  : 'Hmm...';

          final secsCtrl = _inputControllers[block.id]?['secs'];
          double secs = 2.0;
          if (secsCtrl != null && secsCtrl.text.trim().isNotEmpty) {
            secs = double.tryParse(secsCtrl.text.trim()) ?? 2.0;
          }
          secs = secs.clamp(0.1, 60.0);

          _sprite.showBubble(' $text', durationMs: (secs * 1000).toInt());
          notifyListeners();

          await Future.delayed(Duration(milliseconds: (secs * 1000).toInt()));

          _sprite.hideBubble();
          notifyListeners();
          break;
        }

      case 'looks_think':
        {
          final text =
              getInput(block, field: 'value')?.toString().trim().isNotEmpty ==
                      true
                  ? getInput(block, field: 'value').toString()
                  : '...';

          _sprite.showBubble('$text', durationMs: 2000);
          break;
        }

      case 'looks_show':
        _sprite.visible = true;
        break;

      case 'looks_hide':
        _sprite.visible = false;
        break;

      case 'looks_nextcostume':
        {
          final costumes = _spriteVariables['costumes'] ?? ['Default'];
          int index = costumes.indexOf(currentCostume ?? costumes.first);
          index = (index + 1) % costumes.length;
          currentCostume = costumes[index];
          break;
        }

      case 'looks_switchcostumeto':
        {
          final costumes = _spriteVariables['costumes'] ?? ['Default'];

          final name =
              getInput(block, field: 'value')?.toString().trim().isNotEmpty ==
                      true
                  ? getInput(block, field: 'value').toString()
                  : costumes.first;

          currentCostume = costumes.contains(name) ? name : costumes.first;
          break;
        }

      case 'looks_switchbackdropto':
        {
          final backdrops = _spriteVariables['backdrops'] ?? ['Default'];

          final name =
              getInput(block, field: 'value')?.toString().trim().isNotEmpty ==
                      true
                  ? getInput(block, field: 'value').toString()
                  : backdrops.first;

          currentBackdrop = backdrops.contains(name) ? name : backdrops.first;
          break;
        }

      case 'looks_changeeffectby':
        {
          final effect = getInput(block, field: 'effect') ?? 'color';
          final change = double.tryParse(
                  getInput(block, field: 'value')?.toString() ?? '') ??
              0;

          _sprite.variables['effect_$effect'] =
              (_sprite.variables['effect_$effect'] ?? 0) + change;
          break;
        }

      case 'looks_seteffectto':
        {
          final effect = getInput(block, field: 'effect') ?? 'color';
          final value = double.tryParse(
                  getInput(block, field: 'value')?.toString() ?? '') ??
              0;

          _sprite.variables['effect_$effect'] = value;
          break;
        }

      case 'looks_cleargraphiceffects':
        _sprite.variables.removeWhere((k, _) => k.startsWith('effect_'));
        break;

      case 'looks_changesizeby':
        {
          final change = double.tryParse(
                  getInput(block, field: 'value')?.toString() ?? '') ??
              0;

          _sprite.variables['size'] =
              (_sprite.variables['size'] ?? 100) + change;
          break;
        }

      case 'looks_setsizeto':
        {
          final size = double.tryParse(
                  getInput(block, field: 'value')?.toString() ?? '') ??
              100;

          _sprite.variables['size'] = size;
          break;
        }

      case 'looks_gotofrontback':
        _sprite.variables['layer'] =
            getInput(block, field: 'value')?.toString() ?? 'front';
        break;

      case 'looks_goforwardbackwardlayers':
        {
          final move =
              int.tryParse(getInput(block, field: 'value')?.toString() ?? '') ??
                  0;

          _sprite.variables['layer'] = (_sprite.variables['layer'] ?? 0) + move;
          break;
        }

      case 'looks_costumename':
        _sprite.showBubble(
          'Costume: ${currentCostume ?? 'Default'}',
          durationMs: 1000,
        );
        break;

      case 'looks_backdropname':
        _sprite.showBubble(
          'Backdrop: ${currentBackdrop ?? 'Default'}',
          durationMs: 1000,
        );
        break;

      // ===== DATA =====
      case 'data_setvariableto':
        if (block.arguments.length > 1)
          _sprite.variables[block.arguments[0]] = block.arguments[1];
        _sprite.showBubble('${block.arguments[0]} = ${block.arguments[1]}');
        break;

      case 'data_changevariableby':
        if (block.arguments.length > 1) {
          _sprite.variables[block.arguments[0]] =
              ((_sprite.variables[block.arguments[0]] ?? 0) +
                  double.tryParse(block.arguments[1].toString())!);
        }
        _sprite.showBubble(
            '${block.arguments[0]} = ${_sprite.variables[block.arguments[0]]}');
        break;

      case 'data_addtolist':
        if (block.arguments.length > 1)
          _sprite.lists
              .putIfAbsent(block.arguments[0], () => [])
              .add(block.arguments[1]);
        _sprite
            .showBubble('Add to ${block.arguments[0]}: ${block.arguments[1]}');
        break;

      case 'data_deleteoflist':
        if (block.arguments.length > 1 &&
            _sprite.lists.containsKey(block.arguments[0])) {
          int index = int.tryParse(block.arguments[1].toString()) ?? 0;
          if (index >= 0 && index < _sprite.lists[block.arguments[0]]!.length)
            _sprite.lists[block.arguments[0]]!.removeAt(index);
          _sprite.showBubble('Delete index $index from ${block.arguments[0]}');
        }
        break;
    }

    notifyListeners();
  }

  dynamic _evaluateOperatorBlock(Block block) {
    dynamic a =
        block.arguments.isNotEmpty ? evaluateValue(block.arguments[0]) : 0;

    dynamic b =
        block.arguments.length > 1 ? evaluateValue(block.arguments[1]) : 0;

    dynamic result;

    switch (block.type) {
      // ===== BASIC ARITHMETIC =====
      case 'operator_add':
        result = a + b;
        break;
      case 'operator_subtract':
        result = a - b;
        break;
      case 'operator_multiply':
        result = a * b;
        break;
      case 'operator_divide':
        result = b == 0 ? 0 : a / b;
        break;

      // ===== RANDOM =====
      case 'operator_random':
        int min = a.toInt();
        int max = b.toInt();
        if (max < min) {
          int temp = min;
          min = max;
          max = temp;
        }
        result = (Random().nextInt(max - min + 1) + min).toDouble();
        break;

      // ===== COMPARISON =====
      case 'operator_gt':
        result = a > b;
        break;
      case 'operator_lt':
        result = a < b;
        break;
      case 'operator_equals':
        result = a == b;
        break;

      // ===== LOGICAL =====
      case 'operator_and':
        result = (a != 0 && b != 0);
        break;
      case 'operator_or':
        result = (a != 0 || b != 0);
        break;
      case 'operator_not':
        result = (a == 0);
        break;

      // ===== MISC / NUMERIC =====
      case 'operator_mod':
        result = b == 0 ? 0 : a % b;
        break;
      case 'operator_floor':
        result = a.floorToDouble();
        break;
      case 'operator_ceiling':
        result = a.ceilToDouble();
        break;
      case 'operator_round':
        result = a.roundToDouble();
        break;

      // ===== STRING OPERATORS =====
      case 'operator_length':
        result = (block.arguments.isNotEmpty
            ? block.arguments[0].toString().length
            : 0);
        break;
      case 'operator_letter_of':
        int index = int.tryParse(block.arguments.length > 1
                ? block.arguments[1].toString()
                : '1') ??
            1;
        String str =
            block.arguments.isNotEmpty ? block.arguments[0].toString() : '';
        if (index < 1 || index > str.length)
          result = '';
        else
          result = str[index - 1];
        break;
      case 'operator_join':
        String str1 =
            block.arguments.isNotEmpty ? block.arguments[0].toString() : '';
        String str2 =
            block.arguments.length > 1 ? block.arguments[1].toString() : '';
        result = str1 + str2;
        break;
      case 'operator_contains':
        String str1 =
            block.arguments.isNotEmpty ? block.arguments[0].toString() : '';
        String str2 =
            block.arguments.length > 1 ? block.arguments[1].toString() : '';
        result = str1.contains(str2);
        break;

      default:
        result = 0;
    }

    return result;
  }

  void _reflowWorkspaceBlocks() {
    double currentY = 12; // starting Y
    for (final block in workspaceUIBlocks) {
      // use UI blocks
      if (block is BlockModel) {
        block.y = currentY; // BlockModel has y
        currentY += EditorScreen.blockHeight + EditorScreen.blockGap;
      }
    }
  }

  void applyRuntimeState(Map<String, dynamic> runtime) {
    workspaceUIBlocks.clear();
    workspaceBlocks.clear();

    // ---------------- Helper: safely parse blocks ----------------
    List<BlockModel> parseBlocks(dynamic blocksData) {
      if (blocksData == null) return [];
      if (blocksData is List) {
        return blocksData
            .map((b) => BlockModel.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      } else if (blocksData is Map) {
        return blocksData.values
            .map((b) => BlockModel.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      } else {
        return [];
      }
    }

    // ---------------- Convert top-level sprites to list ----------------
    final spriteList = <dynamic>[];
    final spritesData = runtime['sprites'];
    if (spritesData != null) {
      if (spritesData is List) {
        spriteList.addAll(spritesData);
      } else if (spritesData is Map) {
        spriteList.addAll(spritesData.values);
      }
    }

    // ---------------- Load sprites ----------------
    for (final s in spriteList) {
      Sprite? sprite;
      try {
        sprite = sprites.firstWhere((sp) => sp.id == s['id']);
      } catch (_) {
        sprite = null;
      }
      if (sprite == null) continue;

      sprite.x = s['x'] ?? sprite.x;
      sprite.y = s['y'] ?? sprite.y;
      sprite.direction = s['direction'] ?? sprite.direction;
      sprite.visible = s['visible'] ?? sprite.visible;
      sprite.costumeIndex = s['costumeIndex'] ?? sprite.costumeIndex;
      sprite.variables = Map<String, dynamic>.from(s['variables'] ?? {});
      sprite.currentAnimationFrame =
          s['currentAnimationFrame'] ?? sprite.currentAnimationFrame;

      sprite.uiBlocks = parseBlocks(s['blocks']);
      workspaceUIBlocks.addAll(sprite.uiBlocks);

      sprite.blocks = sprite.uiBlocks.map((b) => b.toEngineBlock()).toList();
      workspaceBlocks.addAll(sprite.blocks);
    }

    // ---------------- Stage ----------------
    stage.uiBlocks = parseBlocks(runtime['stage']?['blocks']);
    workspaceUIBlocks.addAll(stage.uiBlocks);

    stage.blocks = stage.uiBlocks.map((b) => b.toEngineBlock()).toList();
    workspaceBlocks.addAll(stage.blocks);
  }

  dynamic evaluateValue(dynamic input) {
    // If it's a Block (operator)
    if (input is Block && input.type.startsWith('operator_')) {
      return _evaluateOperatorBlock(input);
    }

    // If it's a number
    if (input is num) return input;

    // If it's a string number
    if (input is String) {
      return num.tryParse(input) ?? input;
    }

    return input;
  }

  Future<void> _animateMove(
    Sprite sprite,
    double startX,
    double startY,
    double endX,
    double endY, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    final int fps = 60;
    final int steps = (duration.inMilliseconds / (1000 / fps)).ceil();
    final dx = (endX - startX) / steps;
    final dy = (endY - startY) / steps;

    for (int i = 0; i < steps; i++) {
      sprite.x += dx;
      sprite.y += dy;

      // Clamp inside stage bounds (no bouncing)
      sprite.x = sprite.x
          .clamp(-rt.Runtime.STAGE_WIDTH / 2, rt.Runtime.STAGE_WIDTH / 2);
      sprite.y = sprite.y
          .clamp(-rt.Runtime.STAGE_HEIGHT / 2, rt.Runtime.STAGE_HEIGHT / 2);

      notifyListeners();
      await Future.delayed(
        Duration(milliseconds: (duration.inMilliseconds / steps).ceil()),
      );
    }

    // Ensure final position is exactly at target
    sprite.x =
        endX.clamp(-rt.Runtime.STAGE_WIDTH / 2, rt.Runtime.STAGE_WIDTH / 2);
    sprite.y =
        endY.clamp(-rt.Runtime.STAGE_HEIGHT / 2, rt.Runtime.STAGE_HEIGHT / 2);
    notifyListeners();
  }

  void stopSprite(String spriteId) {
    _spriteRunning[spriteId] = false;

    // Safely find the sprite
    Sprite? sprite;
    for (var s in _sprites) {
      if (s.id == spriteId) {
        sprite = s;
        break;
      }
    }
    if (sprite == null) return;

    // Stop bubble
    sprite.bubbleTimer?.cancel();
    sprite.bubbleText = null;

    notifyListeners();
  }

  Future<void> startAllScripts() async {
    _running = true;

    for (final sprite in _sprites) {
      _spriteRunning[sprite.id] = true;
    }

    await triggerEvent('event_whenflagclicked');
  }

// Stop all scripts
  void stopAllScripts() {
    _running = false;

    //Stop all sprites from running
    for (var sprite in _sprites) {
      _spriteRunning[sprite.id] = false;

      // Stop bubbles
      sprite.bubbleTimer?.cancel();
      sprite.bubbleText = null;

      // Reset sprite to default state
      sprite.x = 0;
      sprite.y = 0;
      sprite.direction = 90;
      sprite.rotationStyle = RotationStyle.allAround;
      sprite.visible = true;
    }

    // Notify UI listeners to redraw
    notifyListeners();
  }
}

// ===== STAGE WIDGET WITH SCRATCH-LIKE SCALE =====
class StageWidget extends StatefulWidget {
  final WorkspaceEngine engine;
  const StageWidget({super.key, required this.engine});

  @override
  State<StageWidget> createState() => _StageWidgetState();
}

/* ---------------- BUBBLE TAIL ---------------- */
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* ================= STATE ================= */
class _StageWidgetState extends State<StageWidget>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final List<int> _selectedIndices = [];

  /// Each sprite has its own animation controller
  final Map<int, AnimationController> _bubbleControllers = {};

  /// Smooth bubble offsets per sprite
  final Map<int, Offset> _bubbleOffsets = {};

  @override
  void initState() {
    super.initState();

    // Show all sprites (none hidden)
    for (final sprite in widget.engine.sprites) {
      sprite.visible = true;
    }

    _focusNode.requestFocus();
    RawKeyboard.instance.addListener(_handleKey);
  }

  @override
  void dispose() {
    for (final c in _bubbleControllers.values) {
      c.dispose();
    }
    RawKeyboard.instance.removeListener(_handleKey);
    _focusNode.dispose();
    super.dispose();
  }

  /* ---------------- KEYBOARD ---------------- */
  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.delete) {
      _deleteSelectedSprites();
    }
  }

  void _deleteSelectedSprites() {
    if (_selectedIndices.isEmpty) return;

    setState(() {
      _selectedIndices.sort((a, b) => b.compareTo(a));
      for (final index in _selectedIndices) {
        _bubbleControllers[index]?.dispose();
        _bubbleControllers.remove(index);
        _bubbleOffsets.remove(index);
        widget.engine.sprites.removeAt(index);
      }
      _selectedIndices.clear();
    });
  }

  /* ---------------- SPRITE LOADER ---------------- */
  Widget _loadSprite(String path) {
    if (path.toLowerCase().endsWith('.svg')) {
      // Use flutter_svg for SVG files
      return SvgPicture.asset(
        path,
        fit: BoxFit.contain,
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.contain,
      );
    }
  }

  /* ---------------- BUBBLE ---------------- */
  Widget bubbleWithTail({
    required String text,
    double maxWidth = 220,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            softWrap: true,
          ),
        ),
        Positioned(
          bottom: -6,
          left: 30,
          child: CustomPaint(
            size: const Size(12, 6),
            painter: _BubbleTailPainter(),
          ),
        ),
      ],
    );
  }

  /* ---------------- SELECTION ---------------- */
  void _handleSpriteTap(int index, {bool multi = false}) {
    setState(() {
      if (multi) {
        _selectedIndices.contains(index)
            ? _selectedIndices.remove(index)
            : _selectedIndices.add(index);
      } else {
        _selectedIndices
          ..clear()
          ..add(index);
      }
    });
  }

  /* ================= BUILD ================= */
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: LayoutBuilder(
        builder: (context, c) {
          final sx = c.maxWidth / 480;
          final sy = c.maxHeight / 360;

          return AnimatedBuilder(
            animation: widget.engine,
            builder: (_, __) {
              return Stack(
                children: [
                  for (int i = 0; i < widget.engine.sprites.length; i++)
                    if (widget.engine.sprites[i].visible)
                      _buildSprite(
                        widget.engine.sprites[i],
                        i,
                        c.maxWidth,
                        c.maxHeight,
                        sx,
                        sy,
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /* ---------------- SPRITE + BUBBLE ---------------- */
  Widget _buildSprite(
    dynamic t,
    int index,
    double w,
    double h,
    double sx,
    double sy,
  ) {
    const size = 80.0;

    final x = w / 2 + t.x * sx - size / 2;
    final y = h / 2 - t.y * sy - size / 2;

    final controller = _bubbleControllers.putIfAbsent(
      index,
      () => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      ),
    );

    if (t.bubbleText != null && t.bubbleText!.isNotEmpty) {
      controller.forward();
    } else {
      controller.reverse();
    }

    // Initialize smooth bubble offset
    _bubbleOffsets.putIfAbsent(index, () => Offset(x, y - 55));

    // Interpolate bubble position for smooth follow
    final targetOffset = Offset(x, y - 55);
    _bubbleOffsets[index] =
        Offset.lerp(_bubbleOffsets[index], targetOffset, 0.2)!;

    double rot = 0;
    double flipX = 1;

    if (t.rotationStyle == RotationStyle.allAround) {
      rot = (t.direction - 90) * pi / 180;
    } else if (t.rotationStyle == RotationStyle.leftRight &&
        t.direction > 90 &&
        t.direction < 270) {
      flipX = -1;
    }

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => _handleSpriteTap(
          index,
          multi: RawKeyboard.instance.keysPressed
              .contains(LogicalKeyboardKey.control),
        ),
        onPanUpdate: (d) {
          setState(() {
            t.x += d.delta.dx / sx;
            t.y -= d.delta.dy / sy;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bubble with smooth follow, multiple bubbles visible simultaneously
            if (t.bubbleText != null && t.bubbleText!.isNotEmpty)
              Positioned(
                left: _bubbleOffsets[index]!.dx - x,
                top: _bubbleOffsets[index]!.dy - y,
                child: ScaleTransition(
                  scale: controller,
                  child: bubbleWithTail(
                    text: t.bubbleText!,
                  ),
                ),
              ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateZ(rot)
                ..scale(flipX, 1),
              child: SizedBox(
                width: size,
                height: size,
                child: _loadSprite(t.assetPath),
              ),
            ),
            if (_selectedIndices.contains(index))
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
