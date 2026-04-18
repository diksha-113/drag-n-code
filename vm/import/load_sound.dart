// lib/vm/engine/load_sound.dart

import '../engine/runtime.dart';
import '../util/log.dart';
import '../engine/storage.dart';

/// Represents a Scratch sound object
class Sound {
  String md5;
  dynamic data;
  String? assetId;
  SoundAsset? asset;
  String? dataFormat;
  int? sampleCount;
  double? rate;
  int? soundId;
  Map<String, dynamic>? broken;

  Sound({required this.md5, this.data});
}

/// Minimal SoundAsset stub
class SoundAsset {
  String assetId;
  String dataFormat;
  List<int> data;

  SoundAsset(
      {required this.assetId, required this.dataFormat, required this.data});
}

/// Load a sound from an asset asynchronously
Future<Sound> loadSoundFromAsset(
    Sound sound, SoundAsset soundAsset, Runtime runtime) async {
  sound.assetId = soundAsset.assetId;
  sound.asset = soundAsset;

  // Add to runtime storage
  runtime.storage?.add(Asset(
      assetId: soundAsset.assetId,
      dataFormat: soundAsset.dataFormat,
      data: soundAsset.data));

  if (runtime.audioEngine == null) {
    Log.warn('No audio engine present; cannot load sound asset: ${sound.md5}');
    return sound;
  }

  // Simulate decoding sound via audio engine
  final soundPlayer = {
    'id': sound.md5.hashCode, // fake unique ID
    'buffer': {'sampleRate': 44100, 'length': soundAsset.data.length}
  };

  final soundBuffer = soundPlayer['buffer'] as Map<String, dynamic>;
  sound.soundId = soundPlayer['id'] as int;
  sound.rate = (soundBuffer['sampleRate'] as num?)?.toDouble() ?? 44100.0;
  sound.sampleCount = soundBuffer['length'] as int?;

  return sound;
}

/// Handle sound load errors by replacing with default asset
Future<Sound> handleSoundLoadError(Sound sound, Runtime runtime) async {
  final oldAsset = sound.asset;
  final oldAssetId = sound.assetId;
  final oldSample = sound.sampleCount;
  final oldRate = sound.rate;
  final oldDataFormat = sound.dataFormat;

  // Use default sound asset
  final defaultAssetId =
      runtime.storage?.defaultAssetIdSound ?? 'default_sound';
  final defaultAsset =
      SoundAsset(assetId: defaultAssetId, dataFormat: 'wav', data: []);
  sound.assetId = defaultAsset.assetId;
  sound.asset = defaultAsset;
  sound.md5 = '${sound.assetId}.${defaultAsset.dataFormat}';

  final loadedSound = await loadSoundFromAsset(sound, defaultAsset, runtime);

  loadedSound.broken = {
    'assetId': oldAssetId,
    'md5': '${oldAssetId ?? 'unknown'}.${oldDataFormat ?? 'wav'}',
    'asset': oldAsset,
    'sampleCount': oldSample,
    'rate': oldRate,
    'dataFormat': oldDataFormat
  };

  return loadedSound;
}

/// Load a sound, given the runtime and asset
Future<Sound> loadSound(Sound sound, Runtime runtime) async {
  if (runtime.storage == null) {
    Log.warn(
        'No storage module present; cannot load sound asset: ${sound.md5}');
    return sound;
  }

  final parts = sound.md5.split('.');
  final md5 = parts[0];
  final ext = parts.length > 1 ? parts[1].toLowerCase() : 'wav';
  sound.dataFormat = ext;

  // Attempt to fetch asset from storage
  Asset? storedAsset = runtime.storage?.get(md5);
  SoundAsset soundAsset;
  if (storedAsset != null) {
    soundAsset = SoundAsset(
        assetId: storedAsset.assetId,
        dataFormat: storedAsset.dataFormat ?? ext,
        data: storedAsset.data ?? []);
  } else {
    // fallback stub asset
    soundAsset = SoundAsset(assetId: md5, dataFormat: ext, data: []);
  }

  try {
    return await loadSoundFromAsset(sound, soundAsset, runtime);
  } catch (e) {
    Log.warn('Failed to load sound: ${sound.md5} with error: $e');
    return handleSoundLoadError(sound, runtime);
  }
}
