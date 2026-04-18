// lib/blocks_vertical/sensing.dart
import '../models/block_model.dart';
import 'package:flutter/material.dart';

class SensingBlocks {
  static List<BlockModel> allBlocks() {
    return [
      // Touching Object
      BlockModel(
        name: 'touchingObject',
        displayName: 'Touching %1?',
        blockType: BlockType.boolean,
        customInputs: [
          BlockInput.dropdown(
            name: 'TOUCHINGOBJECTMENU',
            options: ['_mouse_', '_edge_'],
          )
        ],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Touching Color
      BlockModel(
        name: 'touchingColor',
        displayName: 'Touching Color %1?',
        blockType: BlockType.boolean,
        customInputs: [
          BlockInput.colorPicker(name: 'COLOR'),
        ],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),

      // Color is touching color
      BlockModel(
        name: 'colorIsTouchingColor',
        displayName: 'Color %1 is touching %2?',
        blockType: BlockType.boolean,
        customInputs: [
          BlockInput.colorPicker(name: 'COLOR'),
          BlockInput.colorPicker(name: 'COLOR2'),
        ],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Distance to
      BlockModel(
        name: 'distanceTo',
        displayName: 'Distance to %1',
        blockType: BlockType.number,
        customInputs: [
          BlockInput.dropdown(
            name: 'DISTANCETOMENU',
            options: ['_mouse_'],
          )
        ],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Ask and wait
      BlockModel(
        name: 'askAndWait',
        displayName: 'Ask %1 and wait',
        blockType: BlockType.statement,
        customInputs: [
          BlockInput.text(name: 'QUESTION'),
        ],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Answer
      BlockModel(
        name: 'answer',
        displayName: 'Answer',
        blockType: BlockType.number,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Key pressed
      BlockModel(
        name: 'keyPressed',
        displayName: 'Key pressed %1?',
        blockType: BlockType.boolean,
        customInputs: [
          BlockInput.dropdown(
            name: 'KEY_OPTION',
            options: [
              'space',
              'up arrow',
              'down arrow',
              'right arrow',
              'left arrow',
              'any',
              'a',
              'b',
              'c',
              'd',
              'e',
              'f',
              'g',
              'h',
              'i',
              'j',
              'k',
              'l',
              'm',
              'n',
              'o',
              'p',
              'q',
              'r',
              's',
              't',
              'u',
              'v',
              'w',
              'x',
              'y',
              'z',
              '0',
              '1',
              '2',
              '3',
              '4',
              '5',
              '6',
              '7',
              '8',
              '9'
            ],
          )
        ],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Mouse down
      BlockModel(
        name: 'mouseDown',
        displayName: 'Mouse down?',
        blockType: BlockType.boolean,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Mouse X
      BlockModel(
        name: 'mouseX',
        displayName: 'Mouse X',
        blockType: BlockType.number,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Mouse Y
      BlockModel(
        name: 'mouseY',
        displayName: 'Mouse Y',
        blockType: BlockType.number,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Set drag mode
      BlockModel(
        name: 'setDragMode',
        displayName: 'Set drag mode %1',
        blockType: BlockType.statement,
        customInputs: [
          BlockInput.dropdown(
            name: 'DRAG_MODE',
            options: ['draggable', 'not draggable'],
          )
        ],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Loudness
      BlockModel(
        name: 'loudness',
        displayName: 'Loudness',
        blockType: BlockType.number,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Loud
      BlockModel(
        name: 'loud',
        displayName: 'Loud?',
        blockType: BlockType.boolean,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Timer
      BlockModel(
        name: 'timer',
        displayName: 'Timer',
        blockType: BlockType.number,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Reset timer
      BlockModel(
        name: 'resetTimer',
        displayName: 'Reset Timer',
        blockType: BlockType.statement,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Of (properties)
      BlockModel(
        name: 'of',
        displayName: 'of %1 %2',
        blockType: BlockType.dynamic,
        customInputs: [
          BlockInput.dropdown(
            name: 'PROPERTY',
            options: [
              'x position',
              'y position',
              'direction',
              'costume #',
              'costume name',
              'size',
              'volume',
              'backdrop #',
              'backdrop name'
            ],
          ),
          BlockInput.dropdown(
            name: 'OBJECT',
            options: ['Sprite1', 'Stage'],
          ),
        ],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Current
      BlockModel(
        name: 'current',
        displayName: 'Current %1',
        blockType: BlockType.number,
        customInputs: [
          BlockInput.dropdown(
            name: 'CURRENTMENU',
            options: [
              'YEAR',
              'MONTH',
              'DATE',
              'DAYOFWEEK',
              'HOUR',
              'MINUTE',
              'SECOND'
            ],
          ),
        ],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Days since 2000
      BlockModel(
        name: 'daysSince2000',
        displayName: 'Days since 2000',
        blockType: BlockType.number,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Online
      BlockModel(
        name: 'online',
        displayName: 'Online?',
        blockType: BlockType.boolean,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Username
      BlockModel(
        name: 'username',
        displayName: 'Username',
        blockType: BlockType.number,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
      // User ID
      BlockModel(
        name: 'userId',
        displayName: 'User ID',
        blockType: BlockType.number,
        customInputs: [],
        category: 'Sensing',
        color: Colors.blueAccent,
        shape: ScratchBlockShape.stack,
      ),
    ];
  }
}
