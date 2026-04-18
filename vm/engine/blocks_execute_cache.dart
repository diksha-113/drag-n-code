// lib/engine/blocks_execute_cache.dart

typedef GetCachedFunction = dynamic Function(
  dynamic blockContainer,
  String blockId,
);

class BlocksExecuteCache {
  static GetCachedFunction? _getCached;

  static void setGetCached(GetCachedFunction fn) {
    _getCached = fn;
  }

  static dynamic getCached(dynamic blockContainer, String blockId) {
    if (_getCached == null) {
      throw StateError('BlocksExecuteCache.getCached not initialized');
    }
    return _getCached!(blockContainer, blockId);
  }
}

class BlockCached {
  final dynamic runtime;
  final Map<String, dynamic> _data;

  BlockCached(this.runtime, this._data);

  String get id => _data['id'];
  String get opcode => _data['opcode'];
  Map<String, dynamic> get inputs => _data['inputs'] ?? {};
  Map<String, dynamic> get fields => _data['fields'] ?? {};
  Map<String, dynamic> get mutation => _data['mutation'] ?? {};

  Map<String, dynamic> get argValues {
    final args = <String, dynamic>{};
    inputs.forEach((k, v) => args[k] = v);
    fields.forEach((k, v) => args[k] = v);
    return args;
  }
}
