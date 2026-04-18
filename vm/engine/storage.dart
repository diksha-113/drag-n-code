// lib/vm/engine/storage.dart

/// Minimal Asset representation for sounds
class Asset {
  final String assetId;
  final String? dataFormat;
  final List<int>? data; // Raw bytes of the sound

  Asset({required this.assetId, this.dataFormat, this.data});
}

class Storage {
  /// Default sound asset id
  String defaultAssetIdSound = 'default_sound';

  /// Internal store of assets
  final Map<String, Asset> _assets = {};

  /// Add asset manually
  void add(Asset asset) {
    _assets[asset.assetId] = asset;
  }

  /// Get an asset by id
  Asset? get(String assetId) {
    return _assets[assetId];
  }

  /// Simulate loading an asset (Sound only)
  Future<Asset?> load(String type, String md5, String ext) async {
    // Only handle type == 'Sound'
    if (_assets.containsKey(md5)) return _assets[md5];

    // Return a stub asset if missing
    return Asset(assetId: md5, dataFormat: ext, data: []);
  }
}
