// lib/blocks_vertical/looks.dart
import 'package:flutter/material.dart';
import '../models/block_model.dart';

final List<BlockModel> looksBlocks = [
  BlockModel(
    type: 'looks_sayforsecs',
    message: 'LOOKS_SAYFORSECS',
    args: [
      {'type': 'input_value', 'name': 'MESSAGE'},
      {'type': 'input_value', 'name': 'SECS'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_say',
    message: 'LOOKS_SAY',
    args: [
      {'type': 'input_value', 'name': 'MESSAGE'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_thinkforsecs',
    message: 'LOOKS_THINKFORSECS',
    args: [
      {'type': 'input_value', 'name': 'MESSAGE'},
      {'type': 'input_value', 'name': 'SECS'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_think',
    message: 'LOOKS_THINK',
    args: [
      {'type': 'input_value', 'name': 'MESSAGE'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_show',
    message: 'LOOKS_SHOW',
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_hide',
    message: 'LOOKS_HIDE',
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_hideallsprites',
    message: 'LOOKS_HIDEALLSPRITES',
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_changeeffectby',
    message: 'LOOKS_CHANGEEFFECTBY',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'EFFECT',
        'options': [
          ['COLOR', 'COLOR'],
          ['FISHEYE', 'FISHEYE'],
          ['WHIRL', 'WHIRL'],
          ['PIXELATE', 'PIXELATE'],
          ['MOSAIC', 'MOSAIC'],
          ['BRIGHTNESS', 'BRIGHTNESS'],
          ['GHOST', 'GHOST']
        ]
      },
      {'type': 'input_value', 'name': 'CHANGE'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_seteffectto',
    message: 'LOOKS_SETEFFECTTO',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'EFFECT',
        'options': [
          ['COLOR', 'COLOR'],
          ['FISHEYE', 'FISHEYE'],
          ['WHIRL', 'WHIRL'],
          ['PIXELATE', 'PIXELATE'],
          ['MOSAIC', 'MOSAIC'],
          ['BRIGHTNESS', 'BRIGHTNESS'],
          ['GHOST', 'GHOST']
        ]
      },
      {'type': 'input_value', 'name': 'VALUE'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_cleargraphiceffects',
    message: 'LOOKS_CLEARGRAPHICEFFECTS',
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_changesizeby',
    message: 'LOOKS_CHANGESIZEBY',
    args: [
      {'type': 'input_value', 'name': 'CHANGE'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_setsizeto',
    message: 'LOOKS_SETSIZETO',
    args: [
      {'type': 'input_value', 'name': 'SIZE'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_size',
    message: 'LOOKS_SIZE',
    category: 'looks',
    checkboxInFlyout: true,
    extensions: ['colours_looks', 'output_number'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_changestretchby',
    message: 'LOOKS_CHANGESTRETCHBY',
    args: [
      {'type': 'input_value', 'name': 'CHANGE'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_setstretchto',
    message: 'LOOKS_SETSTRETCHTO',
    args: [
      {'type': 'input_value', 'name': 'STRETCH'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_costume',
    message: '%1',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'COSTUME',
        'options': [
          ['costume1', 'COSTUME1'],
          ['costume2', 'COSTUME2']
        ]
      }
    ],
    category: 'looks', // added
    color: Colors.blue,
    secondaryColor: Colors.blueAccent,
    tertiaryColor: Colors.lightBlue,
    quaternaryColor: Colors.blueGrey,
    extensions: ['output_string'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_switchcostumeto',
    message: 'LOOKS_SWITCHCOSTUMETO',
    args: [
      {'type': 'input_value', 'name': 'COSTUME'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_nextcostume',
    message: 'LOOKS_NEXTCOSTUME',
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_switchbackdropto',
    message: 'LOOKS_SWITCHBACKDROPTO',
    args: [
      {'type': 'input_value', 'name': 'BACKDROP'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_backdrops',
    message: '%1',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'BACKDROP',
        'options': [
          ['backdrop1', 'BACKDROP1']
        ]
      }
    ],
    category: 'looks', // added
    color: Colors.blue,
    secondaryColor: Colors.blueAccent,
    tertiaryColor: Colors.lightBlue,
    quaternaryColor: Colors.blueGrey,
    extensions: ['output_string'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_gotofrontback',
    message: 'LOOKS_GOTOFRONTBACK',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'FRONT_BACK',
        'options': [
          ['front', 'front'],
          ['back', 'back']
        ]
      }
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_goforwardbackwardlayers',
    message: 'LOOKS_GOFORWARDBACKWARDLAYERS',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'FORWARD_BACKWARD',
        'options': [
          ['forward', 'forward'],
          ['backward', 'backward']
        ]
      },
      {'type': 'input_value', 'name': 'NUM'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_backdropnumbername',
    message: 'LOOKS_BACKDROPNUMBERNAME',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'NUMBER_NAME',
        'options': [
          ['number', 'number'],
          ['name', 'name']
        ]
      }
    ],
    category: 'looks',
    checkboxInFlyout: true,
    extensions: ['colours_looks', 'output_number'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_costumenumbername',
    message: 'LOOKS_COSTUMENUMBERNAME',
    args: [
      {
        'type': 'field_dropdown',
        'name': 'NUMBER_NAME',
        'options': [
          ['number', 'number'],
          ['name', 'name']
        ]
      }
    ],
    category: 'looks',
    checkboxInFlyout: true,
    extensions: ['colours_looks', 'output_number'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_switchbackdroptoandwait',
    message: 'LOOKS_SWITCHBACKDROPTOANDWAIT',
    args: [
      {'type': 'input_value', 'name': 'BACKDROP'},
    ],
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
  BlockModel(
    type: 'looks_nextbackdrop',
    message: 'LOOKS_NEXTBACKDROP_BLOCK',
    category: 'looks',
    extensions: ['colours_looks', 'shape_statement'],
    shape: ScratchBlockShape.stack,
  ),
];
