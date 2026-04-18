// lib/blocks/sound.dart
import '../util/math_util.dart';
import '../util/cast.dart';
import '../util/clone.dart';

const bool storeWaiting = true;

class Scratch3SoundBlocks {
  final dynamic runtime;
  final Map<String, Set<String>> waitingSounds = {};

  Scratch3SoundBlocks(this.runtime) {
    if (runtime != null) {
      runtime.on('PROJECT_STOP_ALL', stopAllSounds);
      runtime.on('PROJECT_STOP_ALL', _clearEffectsForAllTargets);
      runtime.on('STOP_FOR_TARGET', _stopWaitingSoundsForTarget);
      runtime.on('PROJECT_START', _clearEffectsForAllTargets);
      runtime.on('targetWasCreated', _onTargetCreated);
      runtime.on('PREVIEW_SOUND', _previewSound);
    }
  }

  // ----------------- CONSTANTS -----------------

  static String get stateKey => 'Scratch.sound';

  static Map<String, dynamic> get defaultSoundState => {
        'effects': {'pitch': 0.0, 'pan': 0.0}
      };

  static Map<String, int> get midiNoteRange => {'min': 36, 'max': 96};
  static Map<String, int> get beatRange => {'min': 0, 'max': 100};
  static Map<String, int> get tempoRange => {'min': 20, 'max': 500};

  static Map<String, Map<String, int>> get effectRange => {
        'pitch': {'min': -360, 'max': 360},
        'pan': {'min': -100, 'max': 100}
      };

  // ----------------- BLOCK TYPES -----------------

  Map<String, Map<String, String>> get blockTypes => {
        'sound_play': {},
        'sound_playuntildone': {},
        'sound_stopallsounds': {},
        'sound_seteffectto': {'EFFECT': 'string', 'VALUE': 'number'},
        'sound_changeeffectby': {'EFFECT': 'string', 'VALUE': 'number'},
        'sound_cleareffects': {},
        'sound_sounds_menu': {'SOUND_MENU': 'string'},
        'sound_beats_menu': {'BEATS': 'number'},
        'sound_effects_menu': {'EFFECT': 'string'},
        'sound_setvolumeto': {'VOLUME': 'number'},
        'sound_changevolumeby': {'VOLUME': 'number'},
        'sound_volume': {},
      };

  // ----------------- STATE MGMT -----------------

  Map<String, dynamic> _getSoundState(dynamic target) {
    var soundState = target.getCustomState(stateKey);
    if (soundState == null) {
      soundState = Clone.simple(defaultSoundState);
      target.setCustomState(stateKey, soundState);
      target.soundEffects = soundState['effects'];
    }
    return soundState;
  }

  void _onTargetCreated(dynamic newTarget, dynamic sourceTarget) {
    if (sourceTarget != null) {
      final soundState = sourceTarget.getCustomState(stateKey);
      if (soundState != null) {
        newTarget.setCustomState(stateKey, Clone.simple(soundState));
        _syncEffectsForTarget(newTarget);
      }
    }
  }

  // ----------------- PRIMITIVES -----------------

  Map<String, Function> getPrimitives() {
    return {
      'sound_play': playSound,
      'sound_playuntildone': playSoundAndWait,
      'sound_stopallsounds': stopAllSounds,
      'sound_seteffectto': setEffect,
      'sound_changeeffectby': changeEffect,
      'sound_cleareffects': clearEffects,
      'sound_sounds_menu': soundsMenu,
      'sound_beats_menu': beatsMenu,
      'sound_effects_menu': effectsMenu,
      'sound_setvolumeto': setVolume,
      'sound_changevolumeby': changeVolume,
      'sound_volume': getVolume,
    };
  }

  // ----------------- MONITORS -----------------

  Map<String, dynamic> getMonitored() {
    return {
      'sound_volume': {
        'isSpriteSpecific': true,
        'getId': (targetId) => '${targetId}_volume'
      }
    };
  }

  void _previewSound(dynamic data) {
    final target = runtime.getEditingTarget();
    if (target == null) return;

    final sprite = target.sprite;
    if (sprite.soundBank == null) return;

    final soundName = data['soundName'];
    final index = sprite.sounds.indexWhere(
      (s) => s['name'] == soundName,
    );

    if (index == -1) return;

    final soundId = sprite.sounds[index]['soundId'];

    // Stop previous preview (Scratch-like behavior)
    sprite.soundBank.stop(target, soundId);

    // Play preview
    sprite.soundBank.playSound(target, soundId);
  }

  // ----------------- SOUND PLAY -----------------

  dynamic playSound(dynamic args, dynamic util) {
    _validateArgs('sound_play', args);
    _playSound(args, util, false);
    return null;
  }

  dynamic playSoundAndWait(dynamic args, dynamic util) {
    _validateArgs('sound_playuntildone', args);
    return _playSound(args, util, storeWaiting);
  }

  Future<dynamic> _playSound(
      dynamic args, dynamic util, bool storeWaiting) async {
    final index = _getSoundIndex(args['SOUND_MENU'], util);
    if (index >= 0) {
      final target = util.target;
      final sprite = target.sprite;
      final soundId = sprite.sounds[index]['soundId'];

      if (sprite.soundBank != null) {
        if (storeWaiting) {
          _addWaitingSound(target.id, soundId);
        } else {
          _removeWaitingSound(target.id, soundId);
        }
        return sprite.soundBank.playSound(target, soundId);
      }
    }
    return null;
  }

  void _addWaitingSound(String targetId, String soundId) {
    waitingSounds.putIfAbsent(targetId, () => {});
    waitingSounds[targetId]!.add(soundId);
  }

  void _removeWaitingSound(String targetId, String soundId) {
    waitingSounds[targetId]?.remove(soundId);
  }

  int _getSoundIndex(dynamic soundName, dynamic util) {
    final sounds = util.target.sprite.sounds;
    if (sounds.isEmpty) return -1;

    final index = getSoundIndexByName(soundName, util);
    if (index != -1) return index;

    final numIndex = int.tryParse(soundName.toString());
    if (numIndex != null) {
      return MathUtil.wrapClamp(numIndex - 1, 0, sounds.length - 1);
    }

    return -1;
  }

  int getSoundIndexByName(dynamic soundName, dynamic util) {
    final sounds = util.target.sprite.sounds;
    for (int i = 0; i < sounds.length; i++) {
      if (sounds[i]['name'] == soundName.toString()) return i;
    }
    return -1;
  }

  // ----------------- STOP SOUNDS -----------------

  void stopAllSounds() {
    if (runtime.targets == null) return;
    for (var t in runtime.targets) {
      _stopAllSoundsForTarget(t);
    }
  }

  void _stopAllSoundsForTarget(dynamic target) {
    if (target.sprite.soundBank != null) {
      target.sprite.soundBank.stopAllSounds(target);
      waitingSounds[target.id]?.clear();
    }
  }

  void _stopWaitingSoundsForTarget(dynamic target) {
    final soundIds = waitingSounds[target.id];
    if (soundIds != null) {
      for (var id in soundIds) {
        target.sprite.soundBank.stop(target, id);
      }
      soundIds.clear();
    }
  }

  // ----------------- EFFECTS -----------------

  dynamic setEffect(dynamic args, dynamic util) {
    _validateArgs('sound_seteffectto', args);
    return _updateEffect(args, util, false);
  }

  dynamic changeEffect(dynamic args, dynamic util) {
    _validateArgs('sound_changeeffectby', args);
    return _updateEffect(args, util, true);
  }

  Future<void> _updateEffect(dynamic args, dynamic util, bool change) async {
    final effect = args['EFFECT'].toString().toLowerCase();
    final value = Cast.toNumber(args['VALUE']).toDouble();
    final soundState = _getSoundState(util.target);

    if (!soundState['effects'].containsKey(effect)) return;

    if (change) {
      soundState['effects'][effect] += value;
    } else {
      soundState['effects'][effect] = value;
    }

    final range = effectRange[effect];
    if (range != null) {
      final minVal = (range['min'] ?? 0).toDouble();
      final maxVal = (range['max'] ?? 0).toDouble();
      soundState['effects'][effect] = MathUtil.clamp(
          soundState['effects'][effect].toDouble(), minVal, maxVal);
    }

    _syncEffectsForTarget(util.target);
  }

  void _syncEffectsForTarget(dynamic target) {
    if (target.sprite.soundBank == null) return;
    target.soundEffects = _getSoundState(target)['effects'];
    target.sprite.soundBank.setEffects(target);
  }

  void clearEffects(dynamic args, dynamic util) {
    _validateArgs('sound_cleareffects', args);
    _clearEffectsForTarget(util.target);
  }

  void _clearEffectsForTarget(dynamic target) {
    final state = _getSoundState(target);
    state['effects'].updateAll((key, value) => 0.0);
    _syncEffectsForTarget(target);
  }

  void _clearEffectsForAllTargets() {
    if (runtime.targets == null) return;
    for (var t in runtime.targets) {
      _clearEffectsForTarget(t);
    }
  }

  // ----------------- VOLUME -----------------

  Future<void> setVolume(dynamic args, dynamic util) {
    _validateArgs('sound_setvolumeto', args);
    final volume = Cast.toNumber(args['VOLUME']).toDouble();
    return _updateVolume(volume, util);
  }

  Future<void> changeVolume(dynamic args, dynamic util) {
    _validateArgs('sound_changevolumeby', args);
    final volume =
        Cast.toNumber(args['VOLUME']).toDouble() + util.target.volume;
    return _updateVolume(volume, util);
  }

  Future<void> _updateVolume(double volume, dynamic util) async {
    final clampedVolume = MathUtil.clamp(volume, 0.0, 100.0);
    util.target.volume = clampedVolume;
    _syncEffectsForTarget(util.target);
  }

  double getVolume(dynamic args, dynamic util) {
    _validateArgs('sound_volume', args);
    return util.target.volume;
  }

  // ----------------- MENUS -----------------

  dynamic soundsMenu(dynamic args) {
    _validateArgs('sound_sounds_menu', args);
    return args['SOUND_MENU'];
  }

  dynamic beatsMenu(dynamic args) {
    _validateArgs('sound_beats_menu', args);
    return args['BEATS'];
  }

  dynamic effectsMenu(dynamic args) {
    _validateArgs('sound_effects_menu', args);
    return args['EFFECT'];
  }

  // ----------------- ARG VALIDATION -----------------

  void _validateArgs(String opcode, Map<String, dynamic> args) {
    final expected = blockTypes[opcode];
    if (expected == null) return;
    expected.forEach((key, type) {
      if (!args.containsKey(key)) {
        throw ArgumentError('Missing argument "$key" for block "$opcode"');
      }
      final value = args[key];
      if (type == 'number' && value is! num) {
        throw ArgumentError(
            'Argument "$key" must be a number for block "$opcode"');
      }
      if (type == 'string' && value is! String) {
        throw ArgumentError(
            'Argument "$key" must be a string for block "$opcode"');
      }
    });
  }
}
