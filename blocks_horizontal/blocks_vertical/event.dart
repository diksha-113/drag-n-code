// lib/blocks_vertical/event.dart
import '../models/block_model.dart';

final List<BlockModel> eventBlocks = [
  BlockModel(
    id: 'event_whentouchingobject',
    type: 'event_whentouchingobject',
    message: 'when touching %1',
    args: [
      {'type': 'input_value', 'name': 'TOUCHINGOBJECTMENU'}
    ],
    category: 'event',
    extensions: ['colours_event', 'shape_hat'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_touchingobjectmenu',
    type: 'event_touchingobjectmenu',
    message: '%1',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'TOUCHINGOBJECTMENU',
        'options': [
          ['_mouse_', 'Mouse'],
          ['_edge_', 'Edge']
        ]
      }
    ],
    category: 'event',
    extensions: ['colours_event', 'output_string'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_whenflagclicked',
    type: 'event_whenflagclicked',
    message: 'when flag clicked',
    args: [
      {
        'type': 'field_image',
        'src': 'assets/green-flag.svg',
        'width': 24,
        'height': 24,
        'alt': 'flag',
      }
    ],
    category: 'event',
    extensions: ['colours_event', 'shape_hat'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_whenthisspriteclicked',
    type: 'event_whenthisspriteclicked',
    message: 'when this sprite clicked',
    category: 'event',
    extensions: ['colours_event', 'shape_hat'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_whenstageclicked',
    type: 'event_whenstageclicked',
    message: 'when stage clicked',
    category: 'event',
    extensions: ['colours_event', 'shape_hat'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_whenbroadcastreceived',
    type: 'event_whenbroadcastreceived',
    message: 'when I receive %1',
    args: [
      {
        'type': 'field_variable',
        'name': 'BROADCAST_OPTION',
        'variableTypes': ['broadcast_message'],
        'variable': 'message1'
      }
    ],
    category: 'event',
    extensions: ['colours_event', 'shape_hat'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_whenbackdropswitchesto',
    type: 'event_whenbackdropswitchesto',
    message: 'when backdrop switches to %1',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'BACKDROP',
        'options': [
          ['backdrop1', 'BACKDROP1']
        ]
      }
    ],
    category: 'event',
    extensions: ['colours_event', 'shape_hat'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_whengreaterthan',
    type: 'event_whengreaterthan',
    message: 'when %1 > %2',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'WHENGREATERTHANMENU',
        'options': [
          ['loudness', 'LOUDNESS'],
          ['timer', 'TIMER']
        ]
      },
      {'type': 'input_value', 'name': 'VALUE'}
    ],
    category: 'event',
    extensions: ['colours_event', 'shape_hat'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_broadcast_menu',
    type: 'event_broadcast_menu',
    message: '%1',
    args: [
      {
        'type': 'field_variable',
        'name': 'BROADCAST_OPTION',
        'variableTypes': ['broadcast_message'],
        'variable': 'message1'
      }
    ],
    category: 'event',
    extensions: ['output_string'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_broadcast',
    type: 'event_broadcast',
    message: 'broadcast %1',
    args: [
      {'type': 'input_value', 'name': 'BROADCAST_INPUT'}
    ],
    category: 'event',
    extensions: ['colours_event', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_broadcastandwait',
    type: 'event_broadcastandwait',
    message: 'broadcast %1 and wait',
    args: [
      {'type': 'input_value', 'name': 'BROADCAST_INPUT'}
    ],
    category: 'event',
    extensions: ['colours_event', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    id: 'event_whenkeypressed',
    type: 'event_whenkeypressed',
    message: 'when %1 key pressed',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'KEY_OPTION',
        'options': [
          ['space', 'space'],
          ['up arrow', 'up arrow'],
          ['down arrow', 'down arrow'],
          ['right arrow', 'right arrow'],
          ['left arrow', 'left arrow'],
          ['any', 'any'],
          ['a', 'a'],
          ['b', 'b'],
          ['c', 'c'],
          ['d', 'd'],
          ['e', 'e'],
          ['f', 'f'],
          ['g', 'g'],
          ['h', 'h'],
          ['i', 'i'],
          ['j', 'j'],
          ['k', 'k'],
          ['l', 'l'],
          ['m', 'm'],
          ['n', 'n'],
          ['o', 'o'],
          ['p', 'p'],
          ['q', 'q'],
          ['r', 'r'],
          ['s', 's'],
          ['t', 't'],
          ['u', 'u'],
          ['v', 'v'],
          ['w', 'w'],
          ['x', 'x'],
          ['y', 'y'],
          ['z', 'z'],
          ['0', '0'],
          ['1', '1'],
          ['2', '2'],
          ['3', '3'],
          ['4', '4'],
          ['5', '5'],
          ['6', '6'],
          ['7', '7'],
          ['8', '8'],
          ['9', '9']
        ]
      }
    ],
    shape: ScratchBlockShape.stack,
    category: 'event',
    extensions: ['colours_event', 'shape_hat'],
  ),
];
