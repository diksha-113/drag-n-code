// lib/vm/engine/sound_bank.dart
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../util/log.dart';
import 'sound_assets.dart';

class Sound {
  String? soundId;
  SoundAsset? asset;
  num rate = 44100;
  int sampleCount = 0;
}

class SoundBank {
  final Map<String, Sound> _sounds = {};

  /// Keeps track of playing audio for each target+sound
  final Map<String, AudioPlayer> _players = {};

  void addSoundPlayer(Sound sound) {
    if (sound.soundId != null) {
      _sounds[sound.soundId!] = sound;
    }
  }

  Future<void> playSound(dynamic target, String soundId) async {
    final sound = _sounds[soundId];
    if (sound == null || sound.asset == null) {
      Log.warn('Sound not found or asset missing: $soundId');
      return;
    }

    final key = '${target.id}_$soundId';

    // Reuse existing player or create new
    final player = _players[key] ?? AudioPlayer();
    _players[key] = player;

    try {
      // Stop any current playing
      await player.stop();

      // Play from bytes
      await player.play(BytesSource(Uint8List.fromList(sound.asset!.data)));

      Log.info('Playing sound $soundId for target ${target.id}');
    } catch (e) {
      Log.error('Error playing sound $soundId: $e');
    }
  }

  Future<void> playSoundAndWait(dynamic target, String soundName) async {
    final playFuture = playSound(target, soundName);
    if (playFuture != null) {
      await playFuture; // wait until sound finishes
    }
  }

  Future<void> loadAssetSound({
    required String soundId,
    required String assetPath,
  }) async {
    try {
      final byteData = await rootBundle.load(assetPath);

      final sound = Sound()
        ..soundId = soundId
        ..asset = SoundAsset(
          assetId: soundId,
          dataFormat: assetPath.split('.').last,
          data: byteData.buffer.asUint8List(),
        )
        ..sampleCount = byteData.lengthInBytes;

      _sounds[soundId] = sound;

      Log.info('Loaded sound $soundId from $assetPath');
    } catch (e) {
      Log.error('Failed to load sound $soundId: $e');
    }
  }

  void stop(dynamic target, String soundId) {
    final key = '${target.id}_$soundId';
    final player = _players[key];
    if (player != null) {
      player.stop();
      _players.remove(key);
      Log.info('Stopped sound $soundId for target ${target.id}');
    }
  }

  void stopAllSounds(dynamic target) {
    final keysToRemove =
        _players.keys.where((k) => k.startsWith('${target.id}_')).toList();

    for (final key in keysToRemove) {
      _players[key]?.stop();
      _players.remove(key);
    }

    Log.info('Stopped all sounds for target ${target.id}');
  }

  void setEffects(dynamic target) {
    // Optional: implement pitch/pan/effects
    Log.info('Setting sound effects for target ${target.id}');
  }
}
