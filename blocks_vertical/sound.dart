// lib/blocks_vertical/sound.dart
import 'package:flutter/material.dart';
import '../models/block_model.dart';

class SoundBlocks {
  static List<BlockModel> allBlocks() {
    return [
      // Sounds Menu
      BlockModel(
        name: 'soundsMenu',
        displayName: 'Sound %1',
        blockType: BlockType.reporter,
        customInputs: [
          BlockInput.dropdown(
            name: 'SOUND_MENU',
            options: [
              '0',
              '1',
              '2',
              '3',
              '4',
              '5',
              '6',
              '7',
              '8',
              '9',
              'call a function'
            ],
          ),
        ],
        category: 'Sound',
        color: Colors.orangeAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Play sound
      BlockModel(
        name: 'playSound',
        displayName: 'Play %1',
        blockType: BlockType.statement,
        customInputs: [
          BlockInput.text(name: 'SOUND_MENU'),
        ],
        category: 'Sound',
        color: Colors.orangeAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Play sound until done
      BlockModel(
        name: 'playSoundUntilDone',
        displayName: 'Play %1 until done',
        blockType: BlockType.statement,
        customInputs: [
          BlockInput.text(name: 'SOUND_MENU'),
        ],
        category: 'Sound',
        color: Colors.orangeAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Stop all sounds
      BlockModel(
        name: 'stopAllSounds',
        displayName: 'Stop all sounds',
        blockType: BlockType.statement,
        customInputs: [],
        category: 'Sound',
        color: Colors.orangeAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Set effect to
      BlockModel(
        name: 'setEffectTo',
        displayName: 'Set %1 effect to %2',
        blockType: BlockType.statement,
        customInputs: [
          BlockInput.dropdown(name: 'EFFECT', options: ['PITCH', 'PAN']),
          BlockInput.text(name: 'VALUE'),
        ],
        category: 'Sound',
        color: Colors.orangeAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Change effect by
      BlockModel(
        name: 'changeEffectBy',
        displayName: 'Change %1 effect by %2',
        blockType: BlockType.statement,
        customInputs: [
          BlockInput.dropdown(name: 'EFFECT', options: ['PITCH', 'PAN']),
          BlockInput.text(name: 'VALUE'),
        ],
        category: 'Sound',
        color: Colors.orangeAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Clear effects
      BlockModel(
        name: 'clearEffects',
        displayName: 'Clear sound effects',
        blockType: BlockType.statement,
        customInputs: [],
        category: 'Sound',
        color: Colors.orangeAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Change volume by
      BlockModel(
        name: 'changeVolumeBy',
        displayName: 'Change volume by %1',
        blockType: BlockType.statement,
        customInputs: [
          BlockInput.text(name: 'VOLUME'),
        ],
        category: 'Sound',
        color: Colors.orangeAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Set volume to
      BlockModel(
        name: 'setVolumeTo',
        displayName: 'Set volume to %1',
        blockType: BlockType.statement,
        customInputs: [
          BlockInput.text(name: 'VOLUME'),
        ],
        category: 'Sound',
        color: Colors.orangeAccent,
        shape: ScratchBlockShape.stack,
      ),
      // Report volume
      BlockModel(
        name: 'volume',
        displayName: 'Volume',
        blockType: BlockType.number,
        customInputs: [],
        category: 'Sound',
        color: Colors.orangeAccent,
        shape: ScratchBlockShape.stack,
      ),
    ];
  }
}
