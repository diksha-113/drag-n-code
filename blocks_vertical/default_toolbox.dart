// lib/blocks_vertical/default_toolbox.dart

import '../models/block_model.dart';

final List<BlockModel> defaultBlocks = [
  // Motion Blocks
  BlockModel(
    id: 'motion_movesteps',
    type: 'motion_movesteps',
    category: 'Motion',
    inputs: {'STEPS': 10},
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_turnright',
    type: 'motion_turnright',
    category: 'Motion',
    inputs: {'DEGREES': 15},
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_turnleft',
    type: 'motion_turnleft',
    category: 'Motion',
    inputs: {'DEGREES': 15},
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_pointindirection',
    type: 'motion_pointindirection',
    category: 'Motion',
    inputs: {'DIRECTION': 90},
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_pointtowards',
    type: 'motion_pointtowards',
    category: 'Motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_gotoxy',
    type: 'motion_gotoxy',
    category: 'Motion',
    inputs: {'X': 0, 'Y': 0},
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_changexby',
    type: 'motion_changexby',
    category: 'Motion',
    inputs: {'DX': 10},
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_changeyby',
    type: 'motion_changeyby',
    category: 'Motion',
    inputs: {'DY': 10},
    shape: ScratchBlockShape.stack,
  ),

  // Looks Blocks
  BlockModel(
    id: 'looks_show',
    type: 'looks_show',
    category: 'Looks',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'looks_hide',
    type: 'looks_hide',
    category: 'Looks',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'looks_switchcostumeto',
    type: 'looks_switchcostumeto',
    category: 'Looks',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'looks_nextcostume',
    type: 'looks_nextcostume',
    category: 'Looks',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'looks_nextbackdrop',
    type: 'looks_nextbackdrop',
    category: 'Looks',
    shape: ScratchBlockShape.stack,
  ),

  // Sound Blocks
  BlockModel(
    id: 'sound_play',
    type: 'sound_play',
    category: 'Sound',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'sound_playuntildone',
    type: 'sound_play,untildone',
    category: 'Sound',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'sound_stopallsounds',
    type: 'sound_stopallsounds',
    category: 'Sound',
    shape: ScratchBlockShape.stack,
  ),

  // Events Blocks
  BlockModel(
    id: 'event_whenflagclicked',
    type: 'event_whenflagclicked',
    category: 'Events',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_whenkeypressed',
    type: 'event_whenkeypressed',
    category: 'Events',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_whenthisspriteclicked',
    type: 'event_whenthisspriteclicked',
    category: 'Events',
    shape: ScratchBlockShape.stack,
  ),

  // Control Blocks
  BlockModel(
    id: 'control_wait',
    type: 'control_wait',
    category: 'Control',
    inputs: {'DURATION': 1},
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'control_repeat',
    type: 'control_repeat',
    category: 'Control',
    inputs: {'TIMES': 10},
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'control_forever',
    type: 'control_forever',
    category: 'Control',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'control_if',
    type: 'control_if',
    category: 'Control',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'control_if_else',
    type: 'control_if_else',
    category: 'Control',
    shape: ScratchBlockShape.stack,
  ),

  // Operators Blocks
  BlockModel(
    id: 'operator_add',
    type: 'operator_add',
    category: 'Operators',
    inputs: {'NUM1': 0, 'NUM2': 0},
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'operator_subtract',
    type: 'operator_subtract',
    category: 'Operators',
    inputs: {'NUM1': 0, 'NUM2': 0},
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'operator_multiply',
    type: 'operator_multiply',
    category: 'Operators',
    inputs: {'NUM1': 0, 'NUM2': 0},
    shape: ScratchBlockShape.stack,
  ),

  // Variables (dynamic)
  BlockModel(
    id: 'variable',
    type: 'variable',
    category: 'Variables',
    shape: ScratchBlockShape.stack,
  ),

  // My Blocks (Procedures)
  BlockModel(
    id: 'procedure',
    type: 'procedure',
    category: 'MyBlocks',
    shape: ScratchBlockShape.stack,
  ),

  // Extensions
  BlockModel(
    id: 'extension_pen_down',
    type: 'extension_pen_down',
    category: 'Extensions',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'extension_music_drum',
    type: 'extension_music_drum',
    category: 'Extensions',
    inputs: {'NUMBER': 1},
    shape: ScratchBlockShape.stack,
  ),
];
