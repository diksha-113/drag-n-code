// lib/blocks_vertical/motion.dart
import '../models/block_model.dart';

final List<BlockModel> motionBlocks = [
  BlockModel(
    id: 'motion_movesteps',
    type: 'motion_movesteps',
    message: 'move %1 steps',
    args: [
      {'type': 'input_value', 'name': 'STEPS'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_turnright',
    type: 'motion_turnright',
    message: 'turn %1 %2 degrees',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/media/rotate-right.svg',
        'width': 24,
        'height': 24
      },
      {'type': 'input_value', 'name': 'DEGREES'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_turnleft',
    type: 'motion_turnleft',
    message: 'turn %1 %2 degrees',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/media/rotate-left.svg',
        'width': 24,
        'height': 24
      },
      {'type': 'input_value', 'name': 'DEGREES'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_pointindirection',
    type: 'motion_pointindirection',
    message: 'point in direction %1',
    args: [
      {'type': 'input_value', 'name': 'DIRECTION'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_pointtowards_menu',
    type: 'motion_pointtowards_menu',
    message: '%1',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'TOWARDS',
        'options': [
          ['mouse-pointer', '_mouse_'],
          ['random', '_random_'],
        ],
      },
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_pointtowards',
    type: 'motion_pointtowards',
    message: 'point towards %1',
    args: [
      {'type': 'input_value', 'name': 'TOWARDS'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_goto_menu',
    type: 'motion_goto_menu',
    message: '%1',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'TO',
        'options': [
          ['mouse-pointer', '_mouse_'],
          ['random', '_random_'],
        ],
      },
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_gotoxy',
    type: 'motion_gotoxy',
    message: 'go to x: %1 y: %2',
    args: [
      {'type': 'input_value', 'name': 'X'},
      {'type': 'input_value', 'name': 'Y'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_goto',
    type: 'motion_goto',
    message: 'go to %1',
    args: [
      {'type': 'input_value', 'name': 'TO'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_glidesecstoxy',
    type: 'motion_glidesecstoxy',
    message: 'glide %1 secs to x: %2 y: %3',
    args: [
      {'type': 'input_value', 'name': 'SECS'},
      {'type': 'input_value', 'name': 'X'},
      {'type': 'input_value', 'name': 'Y'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_glideto_menu',
    type: 'motion_glideto_menu',
    message: '%1',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'TO',
        'options': [
          ['mouse-pointer', '_mouse_'],
          ['random', '_random_'],
        ],
      },
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_glideto',
    type: 'motion_glideto',
    message: 'glide %1 secs to %2',
    args: [
      {'type': 'input_value', 'name': 'SECS'},
      {'type': 'input_value', 'name': 'TO'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_changexby',
    type: 'motion_changexby',
    message: 'change x by %1',
    args: [
      {'type': 'input_value', 'name': 'DX'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_setx',
    type: 'motion_setx',
    message: 'set x to %1',
    args: [
      {'type': 'input_value', 'name': 'X'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_changeyby',
    type: 'motion_changeyby',
    message: 'change y by %1',
    args: [
      {'type': 'input_value', 'name': 'DY'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_sety',
    type: 'motion_sety',
    message: 'set y to %1',
    args: [
      {'type': 'input_value', 'name': 'Y'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_ifonedgebounce',
    type: 'motion_ifonedgebounce',
    message: 'if on edge, bounce',
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_setrotationstyle',
    type: 'motion_setrotationstyle',
    message: 'set rotation style %1',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'STYLE',
        'options': [
          ['left-right', 'left-right'],
          ['don\'t rotate', 'don\'t rotate'],
          ['all around', 'all around'],
        ],
      },
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_xposition',
    type: 'motion_xposition',
    message: 'x position',
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_yposition',
    type: 'motion_yposition',
    message: 'y position',
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_direction',
    type: 'motion_direction',
    message: 'direction',
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_scroll_right',
    type: 'motion_scroll_right',
    message: 'scroll right %1',
    args: [
      {'type': 'input_value', 'name': 'DISTANCE'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_scroll_up',
    type: 'motion_scroll_up',
    message: 'scroll up %1',
    args: [
      {'type': 'input_value', 'name': 'DISTANCE'},
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_align_scene',
    type: 'motion_align_scene',
    message: 'set stage alignment %1',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'ALIGNMENT',
        'options': [
          ['bottom-left', 'bottom-left'],
          ['bottom-right', 'bottom-right'],
          ['middle', 'middle'],
          ['top-left', 'top-left'],
          ['top-right', 'top-right'],
        ],
      },
    ],
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_xscroll',
    type: 'motion_xscroll',
    message: 'x scroll',
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'motion_yscroll',
    type: 'motion_yscroll',
    message: 'y scroll',
    category: 'motion',
    shape: ScratchBlockShape.stack,
  ),
];
