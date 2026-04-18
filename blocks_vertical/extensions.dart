// lib/blocks_vertical/extensions.dart
import '../models/block_model.dart';

final List<BlockModel> extensionsBlocks = [
  BlockModel(
    type: 'extension_pen_down',
    message: '%1 %2 pen down',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/extensions/pen-block-icon.svg',
        'width': 40,
        'height': 40
      },
      {'type': 'field_vertical_separator'}
    ],
    category: 'more',
    extensions: ['colours_more', 'shape_statement', 'scratch_extension'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'extension_music_drum',
    message: '%1 %2 play drum %3',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/extensions/music-block-icon.svg',
        'width': 40,
        'height': 40
      },
      {'type': 'field_vertical_separator'},
      {'type': 'input_value', 'name': 'NUMBER'}
    ],
    category: 'more',
    extensions: ['colours_more', 'shape_statement', 'scratch_extension'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'extension_wedo_motor',
    message: '%1 %2 turn a motor %3',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/extensions/wedo2-block-icon.svg',
        'width': 40,
        'height': 40
      },
      {'type': 'field_vertical_separator'},
      {
        'type': 'field_image',
        'src': 'assets/rotate-right.svg',
        'width': 24,
        'height': 24
      }
    ],
    category: 'more',
    extensions: ['colours_more', 'shape_statement', 'scratch_extension'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'extension_wedo_hat',
    message: '%1 %2 when I am wearing a hat',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/extensions/wedo2-block-icon.svg',
        'width': 40,
        'height': 40
      },
      {'type': 'field_vertical_separator'}
    ],
    category: 'more',
    extensions: ['colours_more', 'shape_hat', 'scratch_extension'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'extension_wedo_boolean',
    message: '%1 %2 O RLY?',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/extensions/wedo2-block-icon.svg',
        'width': 40,
        'height': 40
      },
      {'type': 'field_vertical_separator'}
    ],
    category: 'more',
    extensions: ['colours_more', 'output_boolean', 'scratch_extension'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'extension_wedo_tilt_reporter',
    message: '%1 %2 tilt angle %3',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/extensions/wedo2-block-icon.svg',
        'width': 40,
        'height': 40
      },
      {'type': 'field_vertical_separator'},
      {'type': 'input_value', 'name': 'TILT'}
    ],
    category: 'more',
    extensions: ['colours_more', 'output_number', 'scratch_extension'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'extension_wedo_tilt_menu',
    message: '%1',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'TILT',
        'options': [
          ['Any', 'Any'],
          ['Whirl', 'Whirl'],
          ['South', 'South'],
          ['Back in time', 'Back in time']
        ]
      }
    ],
    category: 'more', // <- added this
    extensions: ['colours_more', 'output_string'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'extension_music_reporter',
    message: '%1 %2 hey now, you\'re an all-star',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/extensions/music-block-icon.svg',
        'width': 40,
        'height': 40
      },
      {'type': 'field_vertical_separator'}
    ],
    category: 'more',
    extensions: ['colours_more', 'output_number', 'scratch_extension'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'extension_microbit_display',
    message: '%1 %2 display %3',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/extensions/microbit-block-icon.svg',
        'width': 40,
        'height': 40
      },
      {'type': 'field_vertical_separator'},
      {'type': 'input_value', 'name': 'MATRIX'}
    ],
    category: 'pen',
    extensions: ['colours_pen', 'shape_statement', 'scratch_extension'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'extension_music_play_note',
    message: '%1 %2 play note %3 for %4 beats',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/extensions/music-block-icon.svg',
        'width': 40,
        'height': 40
      },
      {'type': 'field_vertical_separator'},
      {'type': 'input_value', 'name': 'NOTE'},
      {'type': 'input_value', 'name': 'BEATS'}
    ],
    category: 'pen',
    extensions: ['colours_pen', 'shape_statement', 'scratch_extension'],
    shape: ScratchBlockShape.stack,
  ),
];
