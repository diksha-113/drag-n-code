import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' show ImageByteFormat;
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/block_model.dart';
import '../vm/engine/runtime.dart';
import '../core/workspace.dart';
import '../inputfields/operator_blocks.dart';
import '../inputfields/motion_blocks.dart';
import '../inputfields/look_blocks.dart';
import '../inputfields/sensing_blocks.dart';
import '../inputfields/control_blocks.dart';
import '../inputfields/sound_blocks.dart';
import '../screens/sprite_panel.dart';
import 'package:flutter/services.dart';
import '../core/blocks/logic/logicui.dart';
import '../screens/backdrop_panel.dart';
import '../inputfields/event_blocks.dart';
import '../inputfields/data_blocks.dart';
import '../vm/engine/variable.dart';
import 'package:flutter/services.dart';

enum CodeLanguage {
  dart,
  python,
  javascript,
  php,
  lua,
  xml,
  json,
}

// ===== BLOCK MODEL =====
class BlockInfo {
  final String type;
  final String label;
  final bool isHat;
  final bool isNote;
  final String? noteText;
  String? defaultValue;

  BlockInfo({
    required this.type,
    this.label = '',
    this.isHat = false,
    this.isNote = false,
    this.noteText,
    this.defaultValue,
  });
}

class EditorScreen extends StatefulWidget {
  final Stage stage;
  final String projectId;
  final String uid;
  final Map<String, dynamic>? initialProjectData;

  final String? currentProjectTitle;
  final Map<String, dynamic>? initialData;
  final Map<String, dynamic>? runtimeState;
  final List<dynamic>? projectData;

  const EditorScreen({
    Key? key,
    required this.stage,
    required this.projectId,
    required this.uid,
    this.projectData,
    this.currentProjectTitle,
    this.initialData,
    this.runtimeState,
    this.initialProjectData,
  }) : super(key: key);

  static const double blockHeight = 44;
  static const double blockGap = 2;

  @override
  State<EditorScreen> createState() => _EditorScreenState();

  // ===== HELPER: Flatten all sprite blocks into workspaceBlocks =====
  List<EditorBlock> convertAllSpriteBlocks(Map<String, dynamic> data) {
    final List<EditorBlock> blocks = [];

    if (data['sprites'] is Map) {
      final spritesMap = Map<String, dynamic>.from(data['sprites']);
      spritesMap.forEach((spriteId, spriteData) {
        if (spriteData['blocks'] is Map) {
          final blocksData = Map<String, dynamic>.from(spriteData['blocks']);
          blocksData.forEach((id, b) {
            blocks.add(EditorBlock(
              id: id,
              type: b['type'] ?? 'default',
              opcode: b['opcode'] ?? '',
              x: (b['x'] ?? 0).toDouble(),
              y: (b['y'] ?? 0).toDouble(),
              isHat: b['isHat'] ?? false,
              isNote: b['isNote'] ?? false,
              noteText: b['noteText'],
              category: b['category'] ?? 'default',
              label: b['label'] ?? '',
              value: b['value'],
            ));
          });
        }
      });
    }

    return blocks;
  }
}

class _EditorScreenState extends State<EditorScreen> {
  final GlobalKey _stageKey = GlobalKey();
  CodeLanguage _selectedLanguage = CodeLanguage.dart;
  String selectedLanguage = 'JavaScript';
  String generatedCode = '';

  String? _currentProjectId;
  String? _currentProjectTitle;
  final Map<String, List<EditorBlock>> _spriteWorkspaces = {};
  List<EditorBlock> workspaceBlocks = [];
  String? selectedSpriteId;

  final List<BlockModel> workspaceUIBlocks = [];

  late Map<String, dynamic> blocks = {}; // initialize as empty
  late Map<String, dynamic> sprites = {};
  late Map<String, dynamic> backdrops = {};
  late Map<String, dynamic> sounds = {};

  bool _loading = true;

  Sprite? currentSprite; // selected sprite

  final FirestoreService _fs = FirestoreService();
  final FocusNode _focusNode = FocusNode();

  Future<Widget>? _soundBlockFuture;
  Sprite? _lastSprite;

  // ===== PANEL VISIBILITY =====
  bool _showBackdropPanel = false;
  int? _selectedBackdropIndex;

  // ===== ASSETS =====
  final List<String> spriteAssets = [
    'assets/sprites/cat.svg',
    'assets/sprites/dog.png',
    'assets/sprites/alien.png',
    'assets/sprites/ball.png',
    'assets/sprites/star.png',
  ];
  // ===== ZOOM STATE (ADD THIS) =====
  double _zoom = 1.0;
  static const double _zoomStep = 0.2;
  final TransformationController _controller = TransformationController();
  final List<String> backdropAssets = [
    'assets/backdrops/stage_snow.png',
    'assets/backdrops/stage_snowforest.png',
    'assets/backdrops/stage_underwater.png',
    'assets/backdrops/stage_ground.png',
    'assets/backdrops/stage_basketball.png',
    'assets/backdrops/stage_neontunnel.png',
    'assets/backdrops/stage_room.png',
    'assets/backdrops/stage_classroom.png',
    'assets/backdrops/stage_dance.png',
    'assets/backdrops/stage_night.png',
    'assets/backdrops/stage_space.png',
    'assets/backdrops/stage_road.png',
  ];

  final Runtime runtime = Runtime();
  late final WorkspaceEngine engine;

  Rect? workspaceRect;
  @override
  void initState() {
    super.initState();
    // Create engine instance
    engine = WorkspaceEngine(projectId: widget.projectId);
    _currentProjectId = widget.projectId;
    _currentProjectTitle = widget.currentProjectTitle;
    //Load initial data (if provided)
    final savedData = widget.initialData ?? {};
    // ---------- Stage blocks ----------
    final rawStageBlocks = savedData['stage']?['blocks'];
    final stageBlocksData = rawStageBlocks is Map
        ? rawStageBlocks.values.toList()
        : (rawStageBlocks ?? []);
    final stageBlocks = deserializeWorkspaceBlocks(stageBlocksData);
    _spriteWorkspaces['stage'] = stageBlocks;
    engine.stage.uiBlocks.addAll(_convertWorkspaceToEngineBlocks(stageBlocks));
    // ---------- Sprite blocks ----------
    final spritesMap = savedData['sprites'];
    if (spritesMap is Map) {
      for (final spriteData in spritesMap.values) {
        final spriteId = spriteData['id'];
        final rawSpriteBlocks = spriteData['blocks'];

        final spriteBlocksData = rawSpriteBlocks is Map
            ? rawSpriteBlocks.values.toList()
            : (rawSpriteBlocks ?? []);
        final spriteBlocks = deserializeWorkspaceBlocks(spriteBlocksData);
        _spriteWorkspaces[spriteId] = spriteBlocks;
        final sprite = engine.sprites
            .where((s) => s.id == spriteId)
            .cast<Sprite?>()
            .firstWhere((s) => s != null, orElse: () => null);
        if (sprite != null) {
          sprite.uiBlocks.addAll(_convertWorkspaceToEngineBlocks(spriteBlocks));
        }
      }
    }
    //Apply runtime state
    engine.applyRuntimeState(widget.runtimeState ?? {});
    //Select stage by default & load workspace
    selectedSpriteId = 'stage';
    workspaceBlocks = List.from(_spriteWorkspaces['stage'] ?? []);
    //Layout blocks (IMPORTANT)
    _reflowWorkspaceBlocks();
    _loading = false;
    //Rebuild UI
    setState(() {});
    //Load from Firestore only if opening via pencil
    if (widget.initialData == null || widget.initialData!.isEmpty) {
      _initEditor();
    }
  }

  /// Converts deserialized _Block to engine BlockModel
  List<BlockModel> _convertWorkspaceToEngineBlocks(
      List<EditorBlock> workspaceBlocks) {
    final List<BlockModel> engineBlocks = [];

    for (var block in workspaceBlocks) {
      final model = BlockModel(
        id: block.id,
        opcode: block.opcode,
        type: block.type,
        label: block.label,
        value: block.value,
        shape: block.isHat ? ScratchBlockShape.hat : ScratchBlockShape.stack,
        x: block.x,
        y: block.y,
      );
      // Set position using Offset instead of x/y
      model.position = Offset(block.x ?? 12, block.y ?? 12);

      engineBlocks.add(model);
    }

    // Link blocks vertically
    for (int i = 0; i < engineBlocks.length - 1; i++) {
      engineBlocks[i].next = engineBlocks[i + 1];
    }

    return engineBlocks;
  }

  String generateCodePreview(CodeLanguage lang) {
    if (workspaceBlocks.isEmpty) {
      return '// No blocks yet';
    }

    final buffer = StringBuffer();

    for (final block in workspaceBlocks) {
      buffer.writeln(_blockToCodeString(block, lang, indent: 0));
    }

    return buffer.toString();
  }

  String _blockToCodeString(
    EditorBlock block,
    CodeLanguage lang, {
    required int indent,
  }) {
    final spacing = '  ' * indent;
    final label = block.isNote ? '// ${block.noteText ?? ""}' : block.label;

    String line;

    switch (lang) {
      case CodeLanguage.dart:
        line = '$spacing$label();';
        break;
      case CodeLanguage.python:
        line = '$spacing$label()';
        break;
      case CodeLanguage.javascript:
      case CodeLanguage.php:
        line = '$spacing$label();';
        break;
      case CodeLanguage.lua:
        line = '$spacing$label()';
        break;
      case CodeLanguage.xml:
        line = '$spacing<$label />';
        break;
      case CodeLanguage.json:
        line = '$spacing{"block": "$label"}';
        break;
    }
    for (final child in block.children) {
      line += '\n' + _blockToCodeString(child, lang, indent: indent + 1);
    }

    // Next block
    if (block.next != null) {
      line += '\n' + _blockToCodeString(block.next!, lang, indent: indent);
    }

    return line;
  }

  Future<void> _pickColorFromStage(Offset position) async {
    final boundary =
        _stageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) return;

    // Capture stage image
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ImageByteFormat.rawRgba);

    if (byteData == null) return;

    final width = image.width;
    final height = image.height;

    final dx = position.dx.clamp(0, width - 1).toInt();
    final dy = position.dy.clamp(0, height - 1).toInt();

    final index = (dy * width + dx) * 4;

    final r = byteData.getUint8(index);
    final g = byteData.getUint8(index + 1);
    final b = byteData.getUint8(index + 2);
    final a = byteData.getUint8(index + 3);

    final pickedColor = Color.fromARGB(a, r, g, b);

    // ✅ Send color to engine (Scratch-style shared sensing color)
    engine.setColor('pickedColor', pickedColor);
  }

  Future<void> _initEditor() async {
    setState(() => _loading = true);

    try {
      // Fetch project from Firestore
      final project = await _fs.getProject(
        uid: widget.uid,
        projectId: widget.projectId,
      );

      if (project == null) {
        debugPrint("Project not found");
        setState(() => _loading = false);
        return;
      }

      //Extract project data
      final Map<String, dynamic> projectData =
          Map<String, dynamic>.from(project['data'] ?? {});

      // ================= Restore Stage Backdrop =================
      final stageBackdrop = projectData['stage']?['backdrop'];
      if (stageBackdrop != null && stageBackdrop.toString().isNotEmpty) {
        engine.stage.backdropPath.value = stageBackdrop;
        debugPrint('Backdrop restored: $stageBackdrop');
      }

      // Helper: convert EditorBlock → Block (engine)
      Block _blockFromEditorBlock(EditorBlock uiBlock,
          {required String targetId}) {
        return Block(
          id: uiBlock.id,
          type: uiBlock.type,
          value: uiBlock.value ?? '',
          targetId: targetId,
        );
      }

      // ================= Restore Stage Blocks =================
      final stageBlocksDataRaw = projectData['stage']?['blocks'] ?? [];
      List<Map<String, dynamic>> stageBlocksData;

      if (stageBlocksDataRaw is Map) {
        stageBlocksData = stageBlocksDataRaw.values
            .map((b) => Map<String, dynamic>.from(b))
            .toList();
      } else if (stageBlocksDataRaw is List) {
        stageBlocksData = stageBlocksDataRaw
            .map((b) => Map<String, dynamic>.from(b))
            .toList();
      } else {
        stageBlocksData = [];
      }

      final List<EditorBlock> stageEditorBlocks =
          deserializeWorkspaceBlocks(stageBlocksData);

      // Assign to engine.stage.blocks
      engine.stage.blocks = stageEditorBlocks
          .map((b) => _blockFromEditorBlock(b, targetId: 'stage'))
          .toList();

      // ================= Restore Sprites =================
      final spritesData = projectData['sprites'] ?? {};
      for (final spriteId in spritesData.keys) {
        final spriteJson = spritesData[spriteId];

        // Check if sprite exists in engine, else create
        Sprite sprite;
        try {
          sprite = engine.sprites.firstWhere((s) => s.id == spriteId);
        } catch (e) {
          sprite = Sprite(
            id: spriteId,
            assetPath: spriteJson['assetPath'],
          );

          engine.sprites.add(sprite);
        }

        final List<EditorBlock> spriteEditorBlocks =
            deserializeWorkspaceBlocks(spriteJson['blocks'] ?? []);

        sprite.blocks = spriteEditorBlocks
            .map((b) => _blockFromEditorBlock(b, targetId: sprite.id))
            .toList();
      }
      // ================= Update UI =================
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          // Update workspaceBlocks for UI
          workspaceBlocks.clear();
          workspaceBlocks.addAll(stageEditorBlocks);

          // Reflow positions so blocks are visible
          _reflowWorkspaceBlocks();

          // Select stage by default
          selectedSpriteId = 'stage';
          debugPrint('Project loaded: ${workspaceBlocks.length} stage blocks');
        });
      });

      // Select first sprite if any
      if (engine.sprites.isNotEmpty) {
        engine.selectSprite(0);
      } else {
        final defaultSprite = Sprite(assetPath: 'default.png');
        engine.sprites.add(defaultSprite);
        engine.selectSprite(0);
      }

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Failed to init editor: $e');
      setState(() => _loading = false);
    }
  }

  /// Helper: Convert EditorBlock → _Block for engine
  EditorBlock _blockFromEditorBlock(EditorBlock b) {
    return EditorBlock(
      id: b.id,
      type: b.type,
      opcode: b.opcode,
      label: b.label,
      x: b.x,
      y: b.y,
      isHat: b.isHat,
      isNote: b.isNote,
      noteText: b.noteText,
      category: b.category,
      value: b.value,
      fromPalette: false,
    );
  }

  void _selectBackdrop(int index) {
    setState(() {
      _selectedBackdropIndex = index;
      widget.stage.updateBackdrop(backdropAssets[index], index);
    });
  }

  void _reflowWorkspaceBlocks() {
    double currentY = 12; // top offset
    setState(() {
      for (final block in workspaceBlocks) {
        block.y = currentY;
        currentY += EditorScreen.blockHeight + EditorScreen.blockGap;
      }
    });
  }

  void _loadProjectData(Map<String, dynamic> data, WorkspaceEngine engine) {
    if (data.isEmpty) return;

    // Load stage blocks into a temporary list
    final List<EditorBlock> loadedBlocks = [];

    if (data['stage'] is Map && data['stage']['blocks'] is List) {
      final stageBlocks =
          List<Map<String, dynamic>>.from(data['stage']['blocks']);
      for (final blockData in stageBlocks) {
        loadedBlocks.add(EditorBlock(
          id: blockData['id'],
          type: blockData['type'],
          opcode: blockData['opcode'] ?? blockData['type'],
          x: (blockData['x'] ?? 12).toDouble(),
          y: (blockData['y'] ?? 12).toDouble(),
          isHat: blockData['isHat'] ?? false,
          isNote: blockData['isNote'] ?? false,
          noteText: blockData['noteText'] ?? '',
          category: blockData['category'] ?? 'default',
          label: blockData['label'] ?? '',
          value: blockData['value'] ?? '',
          fromPalette: false,
        ));
        blocks[blockData['id']] = blockData;
      }
      engine.stage.backdropPath.value = data['stage']['backdrop'] ?? '';
    }

    // Sprites, backdrops, sounds
    sprites = Map<String, dynamic>.from(data['sprites'] ?? {});
    backdrops = Map<String, dynamic>.from(data['backdrops'] ?? {});
    sounds = Map<String, dynamic>.from(data['sounds'] ?? {});

    _reflowWorkspaceBlocks();

    // Update UI after first frame to ensure rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        workspaceBlocks.clear();
        workspaceBlocks.addAll(loadedBlocks);
        selectedSpriteId = 'stage';
      });
      debugPrint('Project loaded: ${workspaceBlocks.length} stage blocks');
    });
  }

  Color _getBlockColor(String type) {
    if (type.startsWith('event')) return const Color(0xFFFFBF00);
    if (type.startsWith('motion')) return const Color(0xFF4C97FF);
    if (type.startsWith('looks')) return const Color(0xFF9966FF);
    if (type.startsWith('sound')) return const Color(0xFFD65CD6);
    if (type.startsWith('control')) return const Color(0xFFFFAB19);
    if (type.startsWith('sensing')) return const Color(0xFF5CB1D6);
    if (type.startsWith('operator')) return const Color(0xFF59C059);
    if (type.startsWith('data')) return const Color(0xFFFF8C1A);
    if (type.startsWith('logic')) return const Color(0xFF5C81A6);
    return const Color(0xFF9E9E9E);
  }

  final List<String> categories = [
    'Events',
    'Motion',
    'Looks',
    'Sound',
    'Control',
    'Logic',
    'Sensing',
    'Operators',
    'Data',
    'Notes'
  ];
  Future<void> saveBlocksPlatformSafe(String fileName, String content) async {
    if (kIsWeb) {
      // Web: trigger browser download
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile/Desktop: use FilePicker saveFile
      String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save $fileName',
        fileName: fileName,
      );

      if (path != null) {
        final file = io.File(path);
        await file.writeAsString(content);
      }
    }
  }

  final Map<String, List<BlockInfo>> blocksByCategory = {
    'Events': [
      // Hat blocks
      BlockInfo(
          type: 'event_whenflagclicked',
          label: 'When Flag Clicked',
          isHat: true),
      BlockInfo(
          type: 'event_whenkeypressed', label: 'When Key Pressed', isHat: true),
      BlockInfo(
          type: 'event_whenthisspriteclicked',
          label: 'When This Sprite Clicked',
          isHat: true),
      BlockInfo(
          type: 'event_whenstageclicked',
          label: 'When Stage Clicked',
          isHat: true),
      BlockInfo(
          type: 'event_whentouchingobject',
          label: 'When Touching Object',
          isHat: true),
      BlockInfo(
          type: 'event_whenbackdropswitchesto',
          label: 'When Backdrop Switches To',
          isHat: true),
      BlockInfo(
          type: 'event_whengreaterthan',
          label: 'When Greater Than',
          isHat: true),
      BlockInfo(
          type: 'event_whenbroadcastreceived',
          label: 'When I Receive',
          isHat: true),
    ],
    'Motion': [
      BlockInfo(type: 'motion_movesteps', label: 'Move Steps'),
      BlockInfo(type: 'motion_turnright', label: 'Turn Right'),
      BlockInfo(type: 'motion_turnleft', label: 'Turn Left'),
      BlockInfo(type: 'motion_gotoxy', label: 'Go to X,Y'),
      BlockInfo(type: 'motion_glidesecstoxy', label: 'Glide to X,Y'),
      BlockInfo(type: 'motion_glidesecstorandom', label: 'Glide to Random'),
      BlockInfo(type: 'motion_xposition', label: 'X Position'),
      BlockInfo(type: 'motion_yposition', label: 'Y Position'),
      BlockInfo(type: 'motion_ifonedgebounce', label: 'If on Edge, Bounce'),
      BlockInfo(type: 'motion_setrotationstyle', label: 'Set Rotation Style'),
    ],
    'Looks': [
      BlockInfo(type: 'looks_sayforsecs', label: 'Say for Seconds'),
      BlockInfo(type: 'looks_say', label: 'Say'),
      BlockInfo(type: 'looks_thinkforsecs', label: 'Think for Seconds'),
      BlockInfo(type: 'looks_think', label: 'Think'),
      BlockInfo(type: 'looks_show', label: 'Show'),
      BlockInfo(type: 'looks_hide', label: 'Hide'),
      BlockInfo(type: 'looks_switchcostumeto', label: 'Switch Costume To'),
      BlockInfo(type: 'looks_nextcostume', label: 'Next Costume'),
      BlockInfo(type: 'looks_changeeffectby', label: 'Change Effect By'),
      BlockInfo(type: 'looks_seteffectto', label: 'Set Effect To'),
      BlockInfo(
          type: 'looks_cleargraphiceffects', label: 'Clear Graphic Effects'),
      BlockInfo(type: 'looks_changesizeby', label: 'Change Size By'),
      BlockInfo(type: 'looks_setsizeto', label: 'Set Size To'),
      BlockInfo(type: 'looks_gotofrontback', label: 'Go to Front/Back'),
    ],
    'Sound': [
      BlockInfo(type: 'sound_play', label: 'Play Sound'),
      BlockInfo(type: 'sound_playuntildone', label: 'Play Sound Until Done'),
      BlockInfo(type: 'sound_stopallsounds', label: 'Stop All Sounds'),
      BlockInfo(type: 'sound_changeeffectby', label: 'Change Effect By'),
      BlockInfo(type: 'sound_seteffectto', label: 'Set Effect To'),
      BlockInfo(type: 'sound_cleareffects', label: 'Clear Effects'),
      BlockInfo(type: 'sound_setvolumeto', label: 'Set Volume To'),
      BlockInfo(type: 'sound_changevolumeby', label: 'Change Volume By'),
      BlockInfo(type: 'sound_volume', label: 'Volume'),
    ],
    'Control': [
      BlockInfo(type: 'control_wait', label: 'Wait'),
      BlockInfo(type: 'control_repeat', label: 'Repeat'),
      BlockInfo(type: 'control_forever', label: 'Forever'),
      BlockInfo(type: 'control_if', label: 'If'),
      BlockInfo(type: 'control_if_else', label: 'If Else'),
      BlockInfo(type: 'control_wait_until', label: 'Wait Until'),
      BlockInfo(type: 'control_repeat_until', label: 'Repeat Until'),
      BlockInfo(type: 'control_stop', label: 'Stop'),
      BlockInfo(type: 'control_create_cloneof', label: 'Create Clone Of'),
      BlockInfo(type: 'control_delete_this_clone', label: 'Delete This Clone'),
    ],
    'Sensing': [
      BlockInfo(type: 'sensing_touchingobject', label: 'Touching Object?'),
      BlockInfo(type: 'sensing_touchingcolor', label: 'Touching Color?'),
      BlockInfo(
          type: 'sensing_coloristouchingcolor',
          label: 'Color is Touching Color?'),
      BlockInfo(type: 'sensing_askandwait', label: 'Ask and Wait'),
      BlockInfo(type: 'sensing_answer', label: 'Answer'),
      BlockInfo(type: 'sensing_keypressed', label: 'Key Pressed?'),
      BlockInfo(type: 'sensing_mousedown', label: 'Mouse Down?'),
      BlockInfo(type: 'sensing_mousex', label: 'Mouse X Position'),
      BlockInfo(type: 'sensing_mousey', label: 'Mouse Y Position'),
      BlockInfo(type: 'sensing_timer', label: 'Timer'),
      BlockInfo(type: 'sensing_resettimer', label: 'Reset Timer'),
      BlockInfo(type: 'sensing_of', label: 'Of'),
      BlockInfo(type: 'sensing_distance', label: 'Distance To'),
      BlockInfo(type: 'sensing_loudness', label: 'Loudness'),
      BlockInfo(type: 'sensing_videoon', label: 'Video On'),
    ],
    'Operators': [
      BlockInfo(type: 'operator_add', label: 'Add'),
      BlockInfo(type: 'operator_subtract', label: 'Subtract'),
      BlockInfo(type: 'operator_multiply', label: 'Multiply'),
      BlockInfo(type: 'operator_divide', label: 'Divide'),
      BlockInfo(type: 'operator_mod', label: 'Modulo'),
      BlockInfo(type: 'operator_random', label: 'Random'),
      BlockInfo(type: 'operator_gt', label: 'Greater Than'),
      BlockInfo(type: 'operator_lt', label: 'Less Than'),
      BlockInfo(type: 'operator_equals', label: 'Equals'),
      BlockInfo(type: 'operator_and', label: 'And'),
      BlockInfo(type: 'operator_or', label: 'Or'),
      BlockInfo(type: 'operator_not', label: 'Not'),
      BlockInfo(type: 'operator_join', label: 'Join Text'),
      BlockInfo(type: 'operator_letter_of', label: 'Letter Of'),
      BlockInfo(type: 'operator_length', label: 'Length Of'),
      BlockInfo(type: 'operator_contains', label: 'Contains'),
      BlockInfo(type: 'operator_round', label: 'Round'),
      BlockInfo(type: 'operator_mathop', label: 'Math Operation'),
    ],
    'Data': [
      BlockInfo(type: 'data_variable', label: 'Variable'),
      BlockInfo(type: 'data_setvariableto', label: 'Set Variable To'),
      BlockInfo(type: 'data_changevariableby', label: 'Change Variable By'),
      BlockInfo(type: 'data_showvariable', label: 'Show Variable'),
      BlockInfo(type: 'data_hidevariable', label: 'Hide Variable'),
      BlockInfo(type: 'data_list', label: 'List'),
      BlockInfo(type: 'data_addtolist', label: 'Add To List'),
      BlockInfo(type: 'data_deleteoflist', label: 'Delete From List'),
      BlockInfo(type: 'data_insertatlist', label: 'Insert At List'),
      BlockInfo(type: 'data_replaceitemoflist', label: 'Replace Item In List'),
      BlockInfo(type: 'data_itemoflist', label: 'Item Of List'),
      BlockInfo(type: 'data_lengthoflist', label: 'Length Of List'),
    ],
    'Logic': [
      BlockInfo(type: 'logic_and', label: 'And'),
      BlockInfo(type: 'logic_or', label: 'Or'),
      BlockInfo(type: 'logic_not', label: 'Not'),
      BlockInfo(type: 'logic_true', label: 'True'),
      BlockInfo(type: 'logic_false', label: 'False'),
    ],
    'Notes': [
      BlockInfo(
          type: 'Note Block',
          label: 'Note',
          isNote: true,
          noteText: 'New note...')
    ],
  };
  void _reflowBlocksVertically() {
    double currentY = 12; // start offset at top
    for (final block in workspaceBlocks) {
      block.y = currentY;
      currentY += EditorScreen.blockHeight + EditorScreen.blockGap;
    }
  }

  String selectedCategory = 'Events';

  void _addBlock(BlockInfo blockInfo, [int? index]) {
    final bool isEventHat =
        blockInfo.isHat && blockInfo.type.startsWith('event_');

    double y;

    // -------------------------------
// EVENT (HAT) BLOCKS → STACK AT TOP
// -------------------------------
    if (isEventHat) {
      final hatBlocks = workspaceBlocks.where((b) => b.isHat).toList();
      y = hatBlocks.isEmpty
          ? 12
          : hatBlocks.last.y + EditorScreen.blockHeight + EditorScreen.blockGap;
    } else {
      // -------------------------------
      // NORMAL BLOCKS → BELOW LAST BLOCK
      // -------------------------------
      if (workspaceBlocks.isEmpty) {
        y = EditorScreen.blockHeight + EditorScreen.blockGap;
      } else {
        // Stack below the last block in workspace
        final lastBlock = workspaceBlocks.last;
        y = lastBlock.y + EditorScreen.blockHeight + EditorScreen.blockGap;
      }
    }

    // -------------------------------
    // CREATE BLOCK
    // -------------------------------
    final newBlock = EditorBlock(
      opcode: blockInfo.type,
      id: UniqueKey().toString(),
      type: blockInfo.type,
      x: 50,
      y: y,
      isHat: isEventHat,
      isNote: blockInfo.isNote,
      noteText: blockInfo.noteText,
      category: selectedCategory ?? 'default',
      value: blockInfo.defaultValue,
      label: blockInfo.label,
      fromPalette: true,
    );

    // -------------------------------
    // ADD TO WORKSPACE
    // -------------------------------
    setState(() {
      if (index != null) {
        workspaceBlocks.insert(index + 1, newBlock);
      } else {
        workspaceBlocks.add(newBlock);
      }
    });
  }

  Future<void> _saveWorkspaceToFirestore({String? projectTitle}) async {
    // If no project exists yet, ask for name
    if (_currentProjectId == null &&
        (projectTitle == null || projectTitle.isEmpty)) {
      _showUploadProjectDialog(
        context,
        engine,
        workspaceBlocks,
        currentProjectId: null,
        currentProjectTitle: projectTitle,
        onProjectSaved: (savedId, savedTitle) {
          setState(() {
            _currentProjectId = savedId;
            _currentProjectTitle = savedTitle;
          });
        },
      );
      return;
    }

    try {
      final projectData = engine.exportWorkspaceState();
      final runtimeState = engine.getRuntimeState();

      await _fs.saveOrUpdateProject(
        uid: widget.uid,
        projectId: _currentProjectId, // use state variable
        projectTitle: projectTitle ?? _currentProjectTitle ?? 'Untitled',
        projectData: projectData,
        runtimeState: runtimeState,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workspace saved!')),
      );
    } catch (e) {
      debugPrint('Save failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Widget _buildBlockWithField(EditorBlock block, {bool dragging = false}) {
    final sprite = engine.activeSprite;
    final bool isControl = block.type.startsWith('control_');
    Widget content = const SizedBox();
    if (block.isNote) {
      content = Text(
        block.noteText ?? '',
        style:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      );
    } else {
      final controller = TextEditingController(text: block.value ?? '');
      void onChanged(String val) => block.value = val;
      // ---------- SENSING BLOCKS ----------
      if (block.type.startsWith('sensing_')) {
        Widget sensingBlock =
            getSensingBlock(block.type, engine); // use 'engine' here

        return Material(
          elevation: dragging ? 6 : 2,
          borderRadius: BorderRadius.circular(14),
          child: sensingBlock,
        );
      }
      // ================= SOUND BLOCKS =================
      if (block.type.startsWith('sound_')) {
        // Set engine sprite ONLY when sprite actually changes
        if (_lastSprite != sprite) {
          _lastSprite = sprite;

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            engine.sprite = sprite;

            // LOAD DEFAULT SOUNDS ONCE PER SPRITE
            await engine.loadDefaultSounds(sprite);

            // Set default SOUND_MENU if empty
            if ((block.modelBlock.values?['SOUND_MENU']?.toString() ?? '')
                    .isEmpty &&
                sprite.sounds.isNotEmpty) {
              block.modelBlock.values ??= {};
              block.modelBlock.values!['SOUND_MENU'] =
                  sprite.sounds.first['name'];
            }

            // Trigger rebuild after loading sounds
            if (mounted) setState(() {});
          });
        }

        // Always create a fresh Future per build
        _soundBlockFuture = buildSoundBlocks(
          block.modelBlock.toEngineBlock(),
          sprite: sprite,
          projectId: engine.projectId,

          // SAFE: event-based state update
          onChanged: (field, value) {
            if (!mounted) return;
            setState(() {
              block.modelBlock.values ??= {};
              block.modelBlock.values![field] = value;
            });
          },

          // SAFE: event-based sound preview
          onPreviewSound: (soundName) {
            engine.previewSound(soundName);
          },
        );

        return FutureBuilder<Widget>(
          future: _soundBlockFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Material(
                elevation: dragging ? 6 : 2,
                borderRadius: BorderRadius.circular(14),
                child: const SizedBox(
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Material(
                elevation: dragging ? 6 : 2,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            return Material(
              elevation: dragging ? 6 : 2,
              borderRadius: BorderRadius.circular(14),
              child: snapshot.data!,
            );
          },
        );
      }

      // ================= LOOKS BLOCKS =================
      if (block.type.startsWith('looks_')) {
        block.controllers.putIfAbsent(
          'value',
          () => TextEditingController(text: block.value ?? ''),
        );

        // ======== ADD THIS ========
        if (block.type == 'looks_sayforsecs' ||
            block.type == 'looks_thinkforsecs') {
          block.controllers.putIfAbsent(
            'text',
            () => TextEditingController(text: block.value ?? 'Hello!'),
          );
          block.controllers.putIfAbsent(
            'secs',
            () => TextEditingController(text: '2'), // default 2 seconds
          );
        }

        final modelBlock = block.modelBlock;

        return buildLooksBlock(
          modelBlock,
          onChanged: (field, value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  block.value = value;
                });
              }
            });
          },
        );
      }
      // ================= LOGIC BLOCKS =================
      if (block.type.startsWith('logic_')) {
        final modelBlock = block.modelBlock;

        return Material(
          elevation: dragging ? 6 : 2,
          borderRadius: BorderRadius.circular(14),
          child: LogicBlocks.buildWidget(modelBlock),
        );
      }

// ================= CONTROL BLOCKS =================
      if (block.type.startsWith('control_')) {
        // Convert engine Block to BlockModel for UI
        final modelBlock = block.toBlockModel();

        return Material(
          elevation: dragging ? 6 : 2,
          borderRadius: BorderRadius.circular(14),
          child: ControlBlock(
            block: modelBlock,
            onChanged: (String name, dynamic value) {
              // Your logic here
              print('Input $name changed to $value');

              // If you want, you can call the original onChanged:
              onChanged(value.toString());
            },
          ),
        );
      }
      // ================= VARIABLE BLOCKS =================
      Block? _engineBlock;
      Widget? _dataBlockWidget;

      if (block.type.startsWith('data_')) {
        _engineBlock ??= block.modelBlock.toEngineBlock();

        _dataBlockWidget ??= buildDataBlocks(
          _engineBlock!,
          sprite: sprite,
          context: context,
          onChanged: (field, value) {
            if (dragging || !mounted) return;

            setState(() {
              _engineBlock!.arguments[field] = value;
              block.value = value.toString();
            });
          },
        );

        return _dataBlockWidget!;
      }

      // ================= OPERATOR BLOCKS =================
      if (block.type.startsWith('operator_')) {
        final modelBlock = block.modelBlock;

        return buildOperatorBlock(
          modelBlock,
          onChanged: (field, value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  modelBlock.values ??= <String, String>{};
                  modelBlock.values![field] = value;
                });
              }
            });
          },
        );
      }
      // ================= EVENT BLOCKS =================
      if (block.type.startsWith('event_')) {
        final engineBlock = block.modelBlock.toEngineBlock();
        content = FutureBuilder<Widget>(
          future: buildEventBlock(
            engineBlock,
            projectId: engine.projectId,
            onChanged: (field, val) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    block.value = val;
                    block.modelBlock.values?[field] = val;
                    engineBlock.arguments[field] = val;
                  });
                }
              });
            },
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 48);
            return snapshot.data!;
          },
        );

        return Material(
          elevation: dragging ? 6 : 2,
          borderRadius: BorderRadius.circular(14),
          child: content,
        );
      }
      // ============== MOTION====================
      if (block.type.startsWith('motion')) {
        final engineBlock = block.modelBlock.toEngineBlock();
        content = FutureBuilder<Widget>(
          future: buildMotionBlock(
            engineBlock,
            projectId: engine.projectId,
            onChanged: (field, val) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    block.value = val;
                    block.modelBlock.values?[field] = val;
                    engineBlock.arguments[field] = val;
                  });
                }
              });
            },
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(height: 48);
            }
            return snapshot.data!;
          },
        );
      }
    }

    return Material(
      elevation: dragging ? 6 : 2,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _getBlockColor(block.type),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: content,
      ),
    );
  }

  // Converts a single block to JSON, including nested children
  String _blockToJson(EditorBlock block) {
    // If it's a note block, just return its note text
    if (block.isNote) {
      return '{"note": "${block.noteText}"}';
    }

    // If block has no children, just output type + label
    if (block.children.isEmpty) {
      return '{"type": "${block.type}", "label": "${block.label}"}';
    }

    // If block has children, recursively serialize them
    final childrenJson = block.children.map(_blockToJson).join(', ');

    return '''
{
  "type": "${block.type}",
  "label": "${block.label}",
  "children": [$childrenJson]
}
''';
  }

// Generate JSON for the entire workspace
  String _generateJson() {
    final blocksJson = workspaceBlocks.map(_blockToJson).join(',\n');

    return '''
{
  "blocks": [
$blocksJson
  ]
}
''';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          engine.sensing.pressedKeys.add(event.logicalKey);
        } else if (event is KeyUpEvent) {
          engine.sensing.pressedKeys.remove(event.logicalKey);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Column(
          children: [
            _header(context, engine),
            _categoryTabs(),
            Expanded(
              child: Row(
                children: [
                  _toolbox(),
                  _scriptArea(),
                  _stageAndJson(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Color primaryBlue = Color(0xFF4C97FF);

  Widget _header(BuildContext context, dynamic engine) => Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: primaryBlue, // solid blue header
        child: Row(
          children: [
            // ===== BACK ARROW =====
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: SizedBox(
                width: 28,
                height: 28,
                child: SvgPicture.asset(
                  'assets/images/back_arrow.svg',
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Editor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),

            // ===== FILE TEXT (Dropdown) =====
            PopupMenuButton<String>(
              tooltip: 'File',
              offset: const Offset(0, 40),
              color: Colors.white,
              child: Row(
                children: const [
                  Text(
                    'File',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
              onSelected: (value) async {
                if (engine == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Engine not ready!')),
                  );
                  return;
                }

                switch (value) {
                  case 'new':
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('New Editor'),
                        content: const Text(
                            'Are you sure you want to create a new editor? Unsaved changes will be lost.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel')),
                          ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('New')),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      engine.clearWorkspace();
                      engine.currentProjectName = '';
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New editor opened!')),
                      );
                    }
                    break;

                  case 'load':
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['scratchproj', 'json'],
                    );

                    if (result != null && result.files.single.bytes != null) {
                      final jsonString =
                          utf8.decode(result.files.single.bytes!);
                      final data = jsonDecode(jsonString);

                      engine.loadFromJson(data);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('File loaded successfully!')),
                      );
                    }
                    break;

                  case 'save':
                    // 1. Save to Firestore
                    await _saveWorkspaceToFirestore();

                    // 2. Optional: also save locally
                    final jsonData = jsonEncode({
                      'stage': engine.getStageSnapshot(),
                      'blocks': engine.getBlocks(),
                    });

                    if (kIsWeb) {
                      final bytes = utf8.encode(jsonData);
                      final blob = html.Blob([bytes]);
                      final url = html.Url.createObjectUrlFromBlob(blob);
                      final anchor = html.AnchorElement(href: url)
                        ..setAttribute('download', 'project.scratchproj')
                        ..click();
                      html.Url.revokeObjectUrl(url);
                    } else {
                      String? path = await FilePicker.platform.saveFile(
                        dialogTitle: 'Save Project',
                        fileName: 'project.scratchproj',
                      );
                      if (path != null) {
                        final file = io.File(path);
                        await file.writeAsString(jsonData);
                      }
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Project saved successfully!')),
                    );
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'new', child: Text('New')),
                PopupMenuItem(
                    value: 'load', child: Text('Load from your computer')),
                PopupMenuItem(
                    value: 'save', child: Text('Save to your computer')),
              ],
            ),

            const SizedBox(width: 20),

            // ===== QUICK SAVE TEXT =====
            GestureDetector(
              onTap: () async {
                if (engine == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Engine not ready!')),
                  );
                  return;
                }

                final jsonData = jsonEncode({
                  'stage': engine.getStageSnapshot(),
                  'blocks': engine.getBlocks(),
                });

                if (kIsWeb) {
                  final bytes = utf8.encode(jsonData);
                  final blob = html.Blob([bytes]);
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  final anchor = html.AnchorElement(href: url)
                    ..setAttribute('download', 'QuickSave.scratchproj')
                    ..click();
                  html.Url.revokeObjectUrl(url);
                } else {
                  String? path = await FilePicker.platform.saveFile(
                    dialogTitle: 'Quick Save',
                    fileName: 'QuickSave.scratchproj',
                  );
                  if (path != null) {
                    final file = io.File(path);
                    await file.writeAsString(jsonData);
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quick saved successfully!')),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Quick Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget header(BuildContext context, dynamic engine) =>
      _header(context, engine);

// ================= CATEGORY TABS (UNCHANGED) =================
  Widget _categoryTabs() {
    double underlineLeft = 0;
    double underlineWidth = 0;

    if (selectedCategory.isNotEmpty) {
      final key = _categoryKeys[selectedCategory];
      if (key != null && key.currentContext != null) {
        final RenderBox box =
            key.currentContext!.findRenderObject() as RenderBox;
        final pos = box.localToGlobal(Offset.zero,
            ancestor: context.findRenderObject());
        underlineLeft = pos.dx - 12;
        underlineWidth = box.size.width;
      }
    }

    return SizedBox(
      height: 50,
      child: Stack(
        children: [
          ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final selected = cat == selectedCategory;

              _categoryKeys.putIfAbsent(cat, () => GlobalKey());

              return GestureDetector(
                onTap: () => setState(() => selectedCategory = cat),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    height: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          key: _categoryKeys[cat],
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF00C6FF),
                                      Color(0xFF0072FF)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: selected ? null : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: underlineLeft,
            bottom: 0,
            width: underlineWidth,
            height: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF00C6FF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Add this at class level
  final Map<String, GlobalKey> _categoryKeys = {};

  Widget _toolbox() {
    final blocks = blocksByCategory[selectedCategory]!;
    return Container(
      width: 240,
      color: const Color(0xFFF7F9FC),
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: blocks
            .map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Draggable<BlockInfo>(
                    data: b,
                    feedback: _blockWidget(b, dragging: true),
                    childWhenDragging:
                        Opacity(opacity: 0.4, child: _blockWidget(b)),
                    child: _blockWidget(b),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Offset _getNonOverlappingPosition(
    Offset desired,
    List<EditorBlock> blocks,
  ) {
    const double blockHeight = 56;
    const double spacing = 8;

    double x = desired.dx;
    double y = desired.dy;

    bool overlaps;
    do {
      overlaps = false;
      for (final b in blocks) {
        if ((x - b.x).abs() < 160 && (y - b.y).abs() < blockHeight) {
          y = b.y + blockHeight + spacing;
          overlaps = true;
          break;
        }
      }
    } while (overlaps);

    return Offset(x, y);
  }

  Offset _getNextAutoPosition(List<EditorBlock> blocks) {
    if (blocks.isEmpty) {
      return const Offset(100, 100);
    }

    const double blockHeight = 56;
    const double blockWidth = 180;
    const double spacing = 12;
    const double maxHeight = 900;

    final last = blocks.last;

    double nextX = last.x;
    double nextY = last.y + blockHeight + spacing;

    // Move to next column if vertical space exceeded
    if (nextY > maxHeight) {
      nextX = last.x + blockWidth + 40;
      nextY = 100;
    }

    return Offset(nextX, nextY);
  }

  Widget _scriptArea() {
    Offset _snapToGrid(Offset position) {
      const double gridSize = 20;
      return Offset(
        (position.dx / gridSize).round() * gridSize,
        (position.dy / gridSize).round() * gridSize,
      );
    }

    final ScrollController _verticalController = ScrollController();
    final ScrollController _horizontalController = ScrollController();

    return Expanded(
      child: Stack(
        children: [
          // ================= WORKSPACE WITH SCROLLBARS =================
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Scrollbar(
              controller: _verticalController,
              thumbVisibility: true,
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 2000,
                      height: 2000,
                      child: InteractiveViewer(
                        transformationController: _controller,
                        boundaryMargin: const EdgeInsets.all(2000),
                        minScale: 0.5,
                        maxScale: 3.0,
                        panEnabled: true,
                        scaleEnabled: true,
                        child: DragTarget<BlockInfo>(
                          onWillAccept: (_) => true,
                          onAcceptWithDetails: (details) {
                            final Offset desired =
                                _getNextAutoPosition(workspaceBlocks);

                            final Offset safe = _getNonOverlappingPosition(
                              desired,
                              workspaceBlocks,
                            );

                            final Offset snapped = _snapToGrid(safe);

                            final EditorBlock newBlock = EditorBlock(
                              opcode: details.data.type,
                              id: UniqueKey().toString(),
                              type: details.data.type,
                              label: details.data.label,
                              x: snapped.dx,
                              y: snapped.dy,
                              isHat: false,
                              isNote: details.data.isNote,
                              noteText: details.data.noteText,
                              category: 'default',
                            );

                            setState(() {
                              workspaceBlocks.add(newBlock);
                            });
                          },
                          builder: (_, __, ___) {
                            return Stack(
                              children: [
                                for (int i = 0; i < workspaceBlocks.length; i++)
                                  _WorkspaceBlockWidget(
                                    index: i,
                                    workspaceBlocks: workspaceBlocks,
                                    onAddNote: (_, [__]) {},
                                    buildFields: _buildBlockWithField,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ================= PLACEHOLDER TEXT =================
          if (workspaceBlocks.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Center(
                  child: Text(
                    'Drag blocks here',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),

          // ================= FIXED CONTROLS =================
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_in',
                  onPressed: () {
                    _zoom = (_zoom + _zoomStep).clamp(0.5, 3.0);
                    _controller.value = Matrix4.identity()..scale(_zoom);
                  },
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_out',
                  onPressed: () {
                    _zoom = (_zoom - _zoomStep).clamp(0.5, 3.0);
                    _controller.value = Matrix4.identity()..scale(_zoom);
                  },
                  child: const Icon(Icons.zoom_out),
                ),
                const SizedBox(height: 8),
                DragTarget<EditorBlock>(
                  onAccept: (block) {
                    setState(() {
                      workspaceBlocks.remove(block);
                    });
                  },
                  builder: (_, candidateData, __) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty
                            ? Colors.red.shade700
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageAndJson() => Container(
        width: 440,
        height: 650,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // ===== GREEN FLAG =====
                GestureDetector(
                  onTap: () async {
                    final engineBlocks =
                        convertWorkspaceToEngineBlocks(workspaceBlocks)
                            .map((b) => b.toEngineBlock())
                            .toList();
                    await engine.runBlocks(engineBlocks);
                  },
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: SvgPicture.asset('assets/green-flag.svg'),
                  ),
                ),

                const SizedBox(width: 10),

                // ===== STOP BUTTON =====
                GestureDetector(
                  onTap: () {
                    engine.stop();
                  },
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: SvgPicture.asset('assets/icon--stop-all.svg'),
                  ),
                ),

                const SizedBox(width: 16),

                // ===== SPRITE ICON (YELLOW) =====
                GestureDetector(
                  onTap: () async {
                    final int? selectedIndex = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpritePanel(
                          spriteAssets: spriteAssets,
                          engineSprites: engine.sprites,
                        ),
                      ),
                    );

                    if (selectedIndex != null &&
                        selectedIndex >= 0 &&
                        selectedIndex < engine.sprites.length) {
                      setState(() {
                        engine.selectSprite(selectedIndex);
                      });
                    }
                  },
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: SvgPicture.asset(
                      'assets/icon--sprite.svg',
                      colorFilter:
                          const ColorFilter.mode(Colors.amber, BlendMode.srcIn),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ===== BACKDROP ICON (GREY) =====
                GestureDetector(
                  onTap: () async {
                    final selectedBackdrop = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BackdropPanel(
                          backdropAssets: backdropAssets,
                          currentBackdrop:
                              engine.stage.backdropPath.value, // use .value
                        ),
                      ),
                    );

                    if (selectedBackdrop != null) {
                      engine.stage.backdropPath.value =
                          selectedBackdrop; // update ValueNotifier
                    }
                  },
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: SvgPicture.asset(
                      'assets/icon--backdrop.svg',
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

                // ===== FILE UPLOAD ICON (PURPLE) =====
                GestureDetector(
                  onTap: () {
                    _showUploadProjectDialog(
                      context,
                      engine,
                      workspaceBlocks,
                      currentProjectId: _currentProjectId,
                      currentProjectTitle: _currentProjectTitle,
                      onProjectSaved: (projectId, projectTitle) {
                        setState(() {
                          _currentProjectId = projectId;
                          _currentProjectTitle = projectTitle;
                        });
                      },
                    );
                  },
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: SvgPicture.asset(
                      'assets/icon--file-upload.svg',
                      colorFilter: const ColorFilter.mode(
                        Colors.purple,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 9,
              child: Focus(
                autofocus: true,
                onKeyEvent: (FocusNode node, KeyEvent event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.delete) {
                    engine.stage.backdropPath.value = '';
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: ValueListenableBuilder<String?>(
                  valueListenable: engine.stage.backdropPath,
                  builder: (context, backdropPath, _) {
                    return Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                            image:
                                backdropPath != null && backdropPath.isNotEmpty
                                    ? DecorationImage(
                                        image: AssetImage(backdropPath),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: RepaintBoundary(
                            key: _stageKey,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (details) {
                                _pickColorFromStage(details.localPosition);
                              },
                              child: StageWidget(engine: engine),
                            ),
                          ),
                        ),

                        // ✅ Scratch-style overlay — updated to include editable stage/global variables
                        Positioned.fill(
                          child: StageVariableWatchers(
                            engine: engine,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Code Preview',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        DropdownButton<CodeLanguage>(
                          value: _selectedLanguage,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: CodeLanguage.dart,
                              child: Text('Dart'),
                            ),
                            DropdownMenuItem(
                              value: CodeLanguage.python,
                              child: Text('Python'),
                            ),
                            DropdownMenuItem(
                              value: CodeLanguage.javascript,
                              child: Text('JavaScript'),
                            ),
                            DropdownMenuItem(
                              value: CodeLanguage.php,
                              child: Text('PHP'),
                            ),
                            DropdownMenuItem(
                              value: CodeLanguage.lua,
                              child: Text('Lua'),
                            ),
                            DropdownMenuItem(
                              value: CodeLanguage.xml,
                              child: Text('XML'),
                            ),
                            DropdownMenuItem(
                              value: CodeLanguage.json,
                              child: Text('JSON'),
                            ),
                          ],
                          onChanged: (lang) {
                            setState(() {
                              _selectedLanguage = lang!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: Text(
                          generateCodePreview(_selectedLanguage),
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );

  Widget _blockWidget(BlockInfo block, {bool dragging = false}) {
    final bool isHat = block.isHat;

    return Material(
      elevation: dragging ? 6 : 2,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 160,
        height: EditorScreen.blockHeight,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _getBlockColor(block.type),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            if (isHat)
              Container(
                width: 20,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
              ),
            if (isHat) const SizedBox(width: 4),
            Expanded(
              child: Text(
                block.isNote ? block.noteText ?? '' : block.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StageVariableWatchers extends StatefulWidget {
  final WorkspaceEngine engine;

  const StageVariableWatchers({
    super.key,
    required this.engine,
  });

  @override
  State<StageVariableWatchers> createState() => _StageVariableWatchersState();
}

class _StageVariableWatchersState extends State<StageVariableWatchers> {
  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;

    // Separate global + sprite variables
    final stageVars = engine.stage.variables.values
        .whereType<Variable>()
        .where((v) => v.visibleOnStage)
        .toList();

    if (stageVars.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: stageVars.map((v) {
        return Positioned(
          left: v.monitorPosition.dx,
          top: v.monitorPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                v.monitorPosition += details.delta;
              });
            },
            onLongPress: () {
              _showMonitorOptions(context, v);
            },
            child: ValueListenableBuilder(
              valueListenable: v.notifier,
              builder: (context, value, _) {
                return _buildMonitor(v);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonitor(Variable v) {
    switch (v.monitorMode) {
      case MonitorMode.large:
        return _largeMonitor(v);
      case MonitorMode.slider:
        return _sliderMonitor(v);
      case MonitorMode.normal:
      default:
        return _normalMonitor(v);
    }
  }

  Widget _normalMonitor(Variable v) {
    return _monitorContainer(
      child: Text(
        '${v.name}: ${v.value}',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _largeMonitor(Variable v) {
    return _monitorContainer(
      child: Column(
        children: [
          Text(
            v.name,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '${v.value}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderMonitor(Variable v) {
    final numValue = (v.value is num) ? v.value.toDouble() : 0.0;

    return _monitorContainer(
      child: Column(
        children: [
          Text('${v.name}: ${v.value}'),
          Slider(
            min: v.sliderMin,
            max: v.sliderMax,
            value: numValue.clamp(v.sliderMin, v.sliderMax),
            onChanged: (newVal) {
              setState(() {
                v.value = newVal;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _monitorContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  void _showMonitorOptions(BuildContext context, Variable v) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Normal"),
              onTap: () {
                setState(() {
                  v.monitorMode = MonitorMode.normal;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Large"),
              onTap: () {
                setState(() {
                  v.monitorMode = MonitorMode.large;
                });
                Navigator.pop(context);
              },
            ),
            if (v.value is num)
              ListTile(
                title: const Text("Slider"),
                onTap: () {
                  setState(() {
                    v.monitorMode = MonitorMode.slider;
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        );
      },
    );
  }
}

// ---------------- CONVERT ENGINE BLOCK TO EDITOR BLOCK ----------------
EditorBlock convertEngineBlockToEditor(Block b) {
  return EditorBlock(
    id: b.id,
    type: b.type,
    opcode: b.uiLabel,
    label: b.uiLabel,
    value: b.value,
    x: b.x,
    y: b.y,
    isHat: b.isHat,
    isNote: b.isNote,
    noteText: b.noteText,
    category: 'default',
  );
}

// ================= UPLOAD / SAVE PROJECT DIALOG =================
void _showUploadProjectDialog(
  BuildContext context,
  WorkspaceEngine engine,
  List<EditorBlock> workspaceBlocks, {
  String? currentProjectId,
  String? currentProjectTitle,
  required Function(String projectId, String projectTitle) onProjectSaved,
}) {
  final TextEditingController projectNameController = TextEditingController(
    text: currentProjectTitle?.trim().isNotEmpty == true
        ? currentProjectTitle
        : '',
  );

  showDialog(
    context: context,
    builder: (context) {
      String? errorText;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              currentProjectId != null ? 'Save Project' : 'Upload Project',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: projectNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter project name',
                    errorText: errorText,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = projectNameController.text.trim();

                  if (name.isEmpty) {
                    setState(() {
                      errorText = 'Project name cannot be empty';
                    });
                    return;
                  }

                  final uid =
                      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

                  // ===== SYNC UI → ENGINE =====
                  final engineBlocks =
                      convertWorkspaceToEngineBlocks(workspaceBlocks);
                  engine.clearBlocks();
                  engine.loadBlocks(engineBlocks);

                  // ===== SAVE TO FIRESTORE =====
                  final savedProjectId = await saveOrUploadProject(
                    uid: uid,
                    engine: engine,
                    workspaceBlocks: workspaceBlocks,
                    projectName: name,
                    projectId: currentProjectId,
                    context: context,
                  );

                  onProjectSaved(savedProjectId, name);

                  Navigator.pop(context);
                },
                child: Text(currentProjectId != null ? 'Save' : 'Upload'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ================= SAVE / UPLOAD PROJECT =================
Future<String> saveOrUploadProject({
  required String uid,
  required WorkspaceEngine engine,
  required List<EditorBlock> workspaceBlocks,
  required String projectName,
  String? projectId,
  required BuildContext context,
}) async {
  try {
    final isNewProject = projectId == null;

    final docRef = isNewProject
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('projects')
            .doc()
        : FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('projects')
            .doc(projectId);

    // ================= STAGE DATA =================
    List<Map<String, dynamic>> serializeBlocks(List<EditorBlock> blocks) {
      return blocks.map((b) {
        return {
          'id': b.id,
          'type': b.type,
          'value': b.controllers['value']?.text ?? b.value,
          'next': b.next != null ? serializeBlocks([b.next!])[0] : null,
        };
      }).toList();
    }

    final stageData = {
      'blocks': serializeBlocks(workspaceBlocks),
      'backdrop': engine.stage.backdropPath.value,
    };

    // ================= SPRITES DATA =================
    final spritesData = {
      for (final sprite in engine.sprites)
        sprite.id: {
          'assetPath': sprite.assetPath,
          'blocks': serializeBlocks(
            sprite.blocks.map((b) => convertEngineBlockToEditor(b)).toList(),
          ),
        }
    };

    // ================= FINAL PROJECT DATA =================
    final projectData = {
      'stage': stageData,
      'sprites': spritesData,
    };

    // ================= FIRESTORE SAVE =================
    await docRef.set(
      {
        'title': projectName.trim().isEmpty ? 'My Project' : projectName,
        'data': projectData,
        'updatedAt': FieldValue.serverTimestamp(),
        if (isNewProject) 'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // ================= FEEDBACK =================
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isNewProject
              ? 'Project uploaded successfully'
              : 'Project saved successfully',
        ),
      ),
    );

    return docRef.id;
  } catch (e) {
    debugPrint('❌ Save/upload error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to save project')),
    );
    rethrow;
  }
}

// ===== WORKSPACE BLOCK WIDGET (UPDATED) =====
class _WorkspaceBlockWidget extends StatefulWidget {
  final int index;
  final List<EditorBlock> workspaceBlocks;
  final Function(BlockInfo, [int?]) onAddNote;
  final Widget Function(EditorBlock block, {bool dragging}) buildFields;

  const _WorkspaceBlockWidget({
    Key? key, // Use Key to preserve state
    required this.index,
    required this.workspaceBlocks,
    required this.onAddNote,
    required this.buildFields,
  }) : super(key: key);

  @override
  State<_WorkspaceBlockWidget> createState() => _WorkspaceBlockWidgetState();
}

class _WorkspaceBlockWidgetState extends State<_WorkspaceBlockWidget> {
  double? _startX;
  double? _startY;

  /// Snap position to grid
  Offset _snapToGrid(Offset position) {
    const double gridSize = 20;
    return Offset(
      (position.dx / gridSize).round() * gridSize,
      (position.dy / gridSize).round() * gridSize,
    );
  }

  /// Get all blocks connected below this block
  List<EditorBlock> _getStackedBlocks(EditorBlock block) {
    List<EditorBlock> stack = [block];
    EditorBlock? current = block;
    while (current?.next != null) {
      stack.add(current!.next!);
      current = current.next;
    }
    return stack;
  }

  @override
  Widget build(BuildContext context) {
    // Safety check
    if (widget.index >= widget.workspaceBlocks.length) {
      return const SizedBox.shrink();
    }

    final block = widget.workspaceBlocks[widget.index];

    return Positioned(
      key: ValueKey(block.id),
      top: block.y,
      left: block.x,
      child: Draggable<EditorBlock>(
        data: block,
        onDragStarted: () {
          _startX = block.x;
          _startY = block.y;
        },
        feedback: Material(
          color: Colors.transparent,
          child: widget.buildFields(block, dragging: true),
        ),
        childWhenDragging: Opacity(
          opacity: 0.4,
          child: widget.buildFields(block),
        ),
        onDragEnd: (details) {
          setState(() {
            if (!widget.workspaceBlocks.contains(block)) return;

            final renderBox = context.findRenderObject() as RenderBox;
            Offset localOffset = renderBox.globalToLocal(details.offset);

            // Snap to grid
            localOffset = _snapToGrid(localOffset);

            // Move hat block with all stacked blocks
            if (block.isHat) {
              final dx = localOffset.dx - _startX!;
              final dy = localOffset.dy - _startY!;

              final stackedBlocks = _getStackedBlocks(block);
              for (final b in stackedBlocks) {
                b.x += dx;
                b.y += dy;
              }
              return;
            }

            // Normal blocks: stay below hats
            final double minY =
                widget.workspaceBlocks.where((b) => b.isHat).fold<double>(
                      EditorScreen.blockHeight,
                      (maxY, b) => b.y + EditorScreen.blockHeight > maxY
                          ? b.y + EditorScreen.blockHeight
                          : maxY,
                    );

            block.y = localOffset.dy.clamp(minY, double.infinity);
            block.x = localOffset.dx;
          });
        },
        child: widget.buildFields(block),
      ),
    );
  }
}

// ===== EDITOR BLOCK CLASS =====
class EditorBlock {
  final String id;
  final String type;
  final String opcode;

  String label;
  String? value;

  double x;
  double y;

  final bool isHat;
  final bool isNote;
  final String? noteText;
  final String category;
  final bool fromPalette;

  EditorBlock? parent;
  EditorBlock? next;
  List<EditorBlock> children = [];

  late final BlockModel modelBlock;

  Map<String, TextEditingController> controllers = {};

  EditorBlock({
    required this.id,
    required this.type,
    required this.opcode,
    required this.x,
    required this.y,
    required this.isHat,
    required this.isNote,
    required this.noteText,
    required this.category,
    required this.label,
    this.value,
    this.fromPalette = false,
  }) {
    modelBlock = BlockModel(
      id: id,
      type: type,
      opcode: opcode,
      label: label,
      value: value ?? '',
      shape: isHat ? ScratchBlockShape.hat : ScratchBlockShape.stack,
      x: x,
      y: y,
    );
  }

  EditorBlock copyWith({
    double? x,
    double? y,
    String? value,
    String? label,
  }) {
    return EditorBlock(
      id: id,
      type: type,
      opcode: opcode,
      x: x ?? this.x,
      y: y ?? this.y,
      isHat: isHat,
      isNote: isNote,
      noteText: noteText,
      category: category,
      value: value ?? this.value,
      label: label ?? this.label,
    );
  }

  Offset get topConnection => Offset(0, y);
  Offset get bottomConnection => Offset(0, y + EditorScreen.blockHeight);

  bool get canHaveTop => true;
  bool get canHaveBottom => true;
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'opcode': opcode,
      'label': label,
      'value': value,
      'x': x,
      'y': y,
      'isHat': isHat,
      'isNote': isNote,
      'noteText': noteText,
      'category': category,
    };
  }
}

// ===== BLOCK → MODEL EXTENSION =====
extension EditorBlockToModel on EditorBlock {
  BlockModel toBlockModel() {
    return BlockModel(
      id: id,
      opcode: opcode,
      type: type,
      label: label,
      value: value,
      shape: isHat ? ScratchBlockShape.hat : ScratchBlockShape.stack,
      x: x,
      y: y,
    );
  }
}

List<EditorBlock> editorBlocksFromJson(List<dynamic> blocksJson) {
  return blocksJson.map((b) {
    final map = Map<String, dynamic>.from(b);
    return EditorBlock(
      id: map['id'] ?? UniqueKey().toString(),
      type: map['type'] ?? 'unknown',
      opcode: map['opcode'] ?? 'unknown',
      label: map['label'] ?? '',
      value: map['value'] ?? '',
      x: (map['x'] ?? 0).toDouble(),
      y: (map['y'] ?? 0).toDouble(),
      isHat: map['isHat'] ?? false,
      isNote: map['isNote'] ?? false,
      noteText: map['noteText'],
      category: map['category'] ?? 'default',
    );
  }).toList();
}

// ===== EDITOR → ENGINE CONVERTER =====
BlockModel convertToEngineBlock(EditorBlock uiBlock) {
  final model = uiBlock.modelBlock;

  // Sync main value
  if (uiBlock.value != null) {
    model.value = uiBlock.value!;
  }

  // Sync input controllers
  uiBlock.controllers.forEach((key, controller) {
    model.values ??= {};
    model.values![key] = controller.text;
  });

  model.position = Offset(uiBlock.x, uiBlock.y);
  return model;
}

// ===== DROPDOWN OPTIONS HELPER =====
List<String>? getDropdownOptions(EditorBlock block) {
  switch (block.type) {
    case 'looks_switchcostumeto':
      return ['costume1', 'costume2'];
    case 'looks_switchbackdropto':
      return ['backdrop1', 'backdrop2'];
    default:
      return null;
  }
}

// ===== SCRATCH CONTROL BLOCK CLIPPER =====
class ScratchControlClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();

    const notchH = 6.0;
    const radius = 10.0;

    p.moveTo(radius, 0);
    p.lineTo(size.width - radius, 0);
    p.quadraticBezierTo(size.width, 0, size.width, radius);

    p.lineTo(size.width, size.height - radius);
    p.quadraticBezierTo(
        size.width, size.height, size.width - radius, size.height);

    p.lineTo(32, size.height);
    p.lineTo(26, size.height + notchH);
    p.lineTo(20, size.height);
    p.lineTo(radius, size.height);

    p.quadraticBezierTo(0, size.height, 0, size.height - radius);
    p.lineTo(0, radius);
    p.quadraticBezierTo(0, 0, radius, 0);

    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ===== WORKSPACE → ENGINE BLOCKS =====
List<BlockModel> convertWorkspaceToEngineBlocks(
    List<EditorBlock> workspaceBlocks) {
  final List<BlockModel> engineBlocks = [];

  for (final block in workspaceBlocks) {
    engineBlocks.add(convertToEngineBlock(block));
  }

  // Vertical linking
  for (int i = 0; i < engineBlocks.length - 1; i++) {
    engineBlocks[i].next = engineBlocks[i + 1];
  }

  return engineBlocks;
}

List<EditorBlock> convertEngineBlocksToEditor(List<BlockModel> blocks) {
  return blocks.map((b) {
    return EditorBlock(
      id: b.id ?? UniqueKey().toString(),
      type: b.type ?? 'unknown',
      opcode: b.opcode ?? 'unknown',
      label: b.label ?? '',
      value: b.value,
      x: b.position?.dx ?? 0,
      y: b.position?.dy ?? 0,
      isHat: b.shape == ScratchBlockShape.hat,
      isNote: false,
      noteText: null,
      category: 'default',
    );
  }).toList();
}

// ===== WORKSPACE SERIALIZER =====
List<Map<String, dynamic>> serializeWorkspaceBlocks(List<EditorBlock> blocks) {
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

List<EditorBlock> deserializeWorkspaceBlocks(List<dynamic> data) {
  final Map<String, EditorBlock> blockMap = {};

  // ================= CREATE BLOCKS =================
  for (final item in data) {
    final String id = (item['id'] != null && item['id'].toString().isNotEmpty)
        ? item['id'].toString()
        : UniqueKey().toString();

    final String type = item['type'] ?? 'unknown';

    final block = EditorBlock(
      id: id,
      type: type,
      opcode: item['opcode'] ?? type,
      label: item['label'] ?? type,
      value: item['value']?.toString(),
      x: (item['x'] as num?)?.toDouble() ?? 0.0,
      y: (item['y'] as num?)?.toDouble() ?? 0.0,
      isHat: item['isHat'] ?? false,
      isNote: item['isNote'] ?? false,
      noteText: item['noteText'],
      category: item['category'] ?? 'default',
    );

    block.controllers['value'] = TextEditingController(
      text: block.value ?? '',
    );

    blockMap[id] = block;
  }

  // ================= LINK BLOCKS =================
  for (final item in data) {
    final currentId = item['id']?.toString();
    final nextId = item['nextId']?.toString();

    if (currentId != null &&
        nextId != null &&
        blockMap.containsKey(currentId) &&
        blockMap.containsKey(nextId)) {
      blockMap[currentId]!.next = blockMap[nextId];
    }
  }

  return blockMap.values.toList();
}

class VariableWatchers extends StatelessWidget {
  final WorkspaceEngine engine;
  final Sprite sprite;
  final Listenable repaint;

  const VariableWatchers({
    super.key,
    required this.sprite,
    required this.repaint,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: repaint,
      builder: (context, _) {
        final visibleScalars = sprite.variables.values
            .whereType<Variable>()
            .where((v) => v.visible && !v.isList)
            .toList();

        final visibleLists = sprite.variables.values
            .whereType<Variable>()
            .where((v) => v.visible && v.isList)
            .toList();

        if (visibleScalars.isEmpty && visibleLists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 12,
          left: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scalar variable monitors
              ...visibleScalars.map((v) => _buildScalarMonitor(v)),

              // List variable monitors
              ...visibleLists.map((v) => _buildListMonitor(v)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScalarMonitor(Variable v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: variableOrange,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2),
        ],
      ),
      child: Text(
        '${v.name}: ${v.value ?? 0}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildListMonitor(Variable v) {
    final list = (v.value as List?) ?? [];
    final display = list.isEmpty ? 'empty list' : list.join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2),
        ],
      ),
      child: Text(
        '${v.name}: $display',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
