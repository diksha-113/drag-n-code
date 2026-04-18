// lib/vm/engine/load_costume.dart
// Full, corrected implementation adapted for Flutter runtime.
// Purpose: load vector/bitmap costumes from assets or storage and return
// a costume map with skinId, size, rotation centers, etc.

import 'dart:async';
import 'dart:typed_data';

import '../util/log.dart' as log;
import '../util/string_util.dart';

/// ======== STORAGE AND ASSET (stubs) ========
class AssetType {
  final String runtimeFormat;
  final String contentType;

  const AssetType(this.runtimeFormat, this.contentType);

  static const imageVector = AssetType('vector', 'image/svg+xml');
  static const imageBitmap = AssetType('bitmap', 'image/png');
}

class Asset {
  final String assetId;
  final String dataFormat;
  final Uint8List data;
  final AssetType assetType;

  Asset(this.assetId, this.dataFormat, this.data)
      : assetType =
            dataFormat == 'svg' ? AssetType.imageVector : AssetType.imageBitmap;

  String decodeText() => 'SVG_DATA';

  Uint8List encodeBinary() => data;

  void encodeTextData(String svg, String dataFormat, bool generateMD5) {}
}

class Storage {
  final Map<String, String> defaultAssetId = {
    'imageVector': 'default_vector',
    'imageBitmap': 'default_bitmap',
  };

  Asset? get(String? assetId) {
    if (assetId == null || assetId.isEmpty) return null;
    return Asset(assetId, 'png', Uint8List(0));
  }

  Future<Asset?> load(AssetType type, String md5, String ext) async {
    return Asset(md5, ext, Uint8List(0));
  }

  Asset createAsset(AssetType type, String dataFormat, Uint8List data,
      dynamic arg, bool md5) {
    return Asset('generated_id', dataFormat, data);
  }
}

/// ======== RENDERER (stub) ========
class Renderer {
  int createSVGSkin(String svg, [List<double>? rotationCenter]) => 1;

  int createBitmapSkin(dynamic canvas, int bitmapResolution,
          [List<double>? rotationCenter]) =>
      2;

  List<double> getSkinRotationCenter(int skinId) => [0.0, 0.0];

  List<int> getSkinSize(int skinId) => [100, 100];
}

/// ======== V2 BITMAP ADAPTER (stub) ========
class V2BitmapAdapter {
  dynamic resize(dynamic canvas, int width, int height) => canvas;

  List<int> convertDataURIToBinary(String dataUri) => <int>[];
}

/// ======== RUNTIME (stub) ========
class Runtime {
  final Storage storage = Storage();
  final Renderer renderer = Renderer();
  V2BitmapAdapter? v2BitmapAdapter = V2BitmapAdapter();
}

/// ======== CANVAS POOL ========
final canvasPool = CanvasPool();

class CanvasPool {
  final List<dynamic> _pool = [];
  Future<void>? _clearSoon;

  void clear() {
    _clearSoon ??= Future.delayed(const Duration(seconds: 1)).then((_) {
      _pool.clear();
      _clearSoon = null;
    });
  }

  dynamic create() => _pool.isNotEmpty ? _pool.removeLast() : Object();

  void release(dynamic canvas) {
    clear();
    _pool.add(canvas);
  }
}

/// ======== VECTOR COSTUME LOADING ========
Future<Map<String, dynamic>> loadVector_(
    Map<String, dynamic> costume, Runtime runtime,
    [List<double>? rotationCenter, int? optVersion]) async {
  final asset = costume['asset'];
  if (asset == null || asset is! Asset) {
    return Future.error('Missing asset for vector costume.');
  }

  final svgString = asset.decodeText();

  costume['skinId'] = runtime.renderer.createSVGSkin(svgString, rotationCenter);
  costume['size'] = runtime.renderer.getSkinSize(costume['skinId']);

  rotationCenter ??= runtime.renderer.getSkinRotationCenter(costume['skinId']);
  final rc0 = rotationCenter.isNotEmpty ? rotationCenter[0] : 0.0;
  final rc1 = rotationCenter.length > 1 ? rotationCenter[1] : 0.0;

  costume['rotationCenterX'] = rc0;
  costume['rotationCenterY'] = rc1;
  costume['bitmapResolution'] = 1;

  return costume;
}

/// ======== BITMAP COSTUME LOADING ========
Future<Map<String, dynamic>> fetchBitmapCanvas_(
    Map<String, dynamic> costume, Runtime runtime,
    [List<double>? rotationCenter]) async {
  final assetDyn = costume['asset'];
  if (assetDyn == null || assetDyn is! Asset) {
    return Future.error('Costume load failed. Assets were missing or invalid.');
  }

  final mergeCanvas = canvasPool.create();
  final scale = (costume['bitmapResolution'] == 1) ? 2 : 1;

  if (rotationCenter != null && rotationCenter.isNotEmpty) {
    rotationCenter[0] *= scale;
    if (rotationCenter.length > 1) rotationCenter[1] *= scale;
  }

  costume['rotationCenterX'] =
      rotationCenter != null && rotationCenter.isNotEmpty
          ? rotationCenter[0]
          : 0.0;
  costume['rotationCenterY'] =
      rotationCenter != null && rotationCenter.length > 1
          ? rotationCenter[1]
          : 0.0;

  costume['bitmapResolution'] = 2;
  costume.remove('textLayerMD5');
  costume.remove('textLayerAsset');

  return <String, dynamic>{
    'canvas': mergeCanvas,
    'mergeCanvas': mergeCanvas,
    'rotationCenter': rotationCenter,
    'assetMatchesBase': scale == 1,
  };
}

Future<Map<String, dynamic>> loadBitmap_(
    Map<String, dynamic> costume, Runtime runtime,
    [List<double>? rotationCenter]) async {
  final fetched = await fetchBitmapCanvas_(costume, runtime, rotationCenter);

  List<double>? fetchedRc;
  final rawRc = fetched['rotationCenter'];
  if (rawRc is List && rawRc.isNotEmpty) {
    final a = rawRc.isNotEmpty ? (rawRc[0] as num).toDouble() : 0.0;
    final b = rawRc.length > 1 ? (rawRc[1] as num).toDouble() : 0.0;
    fetchedRc = [a, b];
  }

  final center =
      fetchedRc != null ? [fetchedRc[0] / 2, fetchedRc[1] / 2] : null;

  costume['skinId'] = runtime.renderer.createBitmapSkin(
      fetched['canvas'], costume['bitmapResolution'] ?? 2, center);

  final mergeCanvas = fetched['mergeCanvas'];
  if (mergeCanvas != null) canvasPool.release(mergeCanvas);

  final renderSize = runtime.renderer.getSkinSize(costume['skinId']);
  costume['size'] = [renderSize[0] * 2, renderSize[1] * 2];

  if (fetchedRc == null) {
    final rc = runtime.renderer.getSkinRotationCenter(costume['skinId']);
    costume['rotationCenterX'] = rc[0] * 2;
    costume['rotationCenterY'] = rc[1] * 2;
    costume['bitmapResolution'] = 2;
  }

  return costume;
}

/// ======== ERROR HANDLING ========
Future<Map<String, dynamic>> handleCostumeLoadError(
    Map<String, dynamic> costume, Runtime runtime) async {
  final oldAsset = costume['asset'];
  final oldAssetId = costume['assetId'];
  final oldRotationX = costume['rotationCenterX'];
  final oldRotationY = costume['rotationCenterY'];
  final oldBitmapResolution = costume['bitmapResolution'];
  final oldDataFormat = costume['dataFormat'];

  final isVector = (oldDataFormat as String?) == 'svg';

  final fallbackId = isVector
      ? (runtime.storage.defaultAssetId['imageVector'] ?? '')
      : (runtime.storage.defaultAssetId['imageBitmap'] ?? '');

  final assetId = (costume['assetId'] as String?) ?? fallbackId;
  costume['asset'] = runtime.storage.get(assetId);
  final asset = costume['asset'] as Asset?;
  costume['md5'] = '${costume['assetId']}.${asset?.dataFormat ?? 'png'}';

  final loadedCostume = isVector
      ? await loadVector_(costume, runtime)
      : await loadBitmap_(costume, runtime);

  loadedCostume['broken'] = {
    'assetId': oldAssetId,
    'md5': '$oldAssetId.$oldDataFormat',
    'asset': oldAsset,
    'dataFormat': oldDataFormat,
    'rotationCenterX': oldRotationX,
    'rotationCenterY': oldRotationY,
    'bitmapResolution': oldBitmapResolution,
  };

  return loadedCostume;
}

/// ======== MAIN LOAD FUNCTIONS ========
Future<Map<String, dynamic>> loadCostumeFromAsset(
    Map<String, dynamic> costume, Runtime runtime,
    [int? optVersion]) async {
  List<double>? rotationCenter;
  if (costume['rotationCenterX'] != null &&
      costume['rotationCenterY'] != null) {
    rotationCenter = [
      (costume['rotationCenterX'] as num).toDouble(),
      (costume['rotationCenterY'] as num).toDouble()
    ];
  }

  final assetDyn = costume['asset'];
  if (assetDyn == null || assetDyn is! Asset) {
    return Future.error('Costume asset missing or invalid.');
  }

  if (assetDyn.assetType.runtimeFormat == AssetType.imageVector.runtimeFormat) {
    try {
      return await loadVector_(costume, runtime, rotationCenter, optVersion);
    } catch (e) {
      log.warn('Error loading vector image: $e');
      return handleCostumeLoadError(costume, runtime);
    }
  }

  try {
    return await loadBitmap_(costume, runtime, rotationCenter);
  } catch (e) {
    log.warn('Error loading bitmap image: $e');
    return handleCostumeLoadError(costume, runtime);
  }
}

Future<Map<String, dynamic>> loadCostume(
    String md5ext, Map<String, dynamic> costume, Runtime runtime,
    [int? optVersion]) async {
  final parts = StringUtil.splitFirst(md5ext, '.');
  final md5 = parts.isNotEmpty ? (parts[0] ?? '') : '';
  final extRaw = (parts.length > 1) ? parts[1] : null;
  final ext =
      (extRaw is String && extRaw.isNotEmpty) ? extRaw.toLowerCase() : 'png';

  costume['dataFormat'] = ext;

  if (costume['asset'] != null) {
    return loadCostumeFromAsset(costume, runtime, optVersion);
  }

  final assetType =
      (ext == 'svg') ? AssetType.imageVector : AssetType.imageBitmap;
  final costumeAsset = await runtime.storage.load(assetType, md5, ext);

  if (costumeAsset != null) {
    costume['asset'] = costumeAsset;
  } else {
    return handleCostumeLoadError(costume, runtime);
  }

  return loadCostumeFromAsset(costume, runtime, optVersion);
}
