// lib/vm/engine/sound_asset.dart

class SoundAsset {
  final String assetId;
  final String dataFormat; // e.g., 'wav', 'mp3'
  final List<int> data; // raw bytes of the sound file

  SoundAsset({
    required this.assetId,
    required this.dataFormat,
    required this.data,
  });
}
