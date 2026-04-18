import 'dart:async';
import '../dispatch/central_dispatch.dart';
import '../util/log.dart' as log;

typedef ExtensionConstructor = dynamic Function(dynamic runtime);

class PendingExtensionWorker {
  final String extensionURL;
  final Completer<int> completer;

  PendingExtensionWorker(this.extensionURL) : completer = Completer<int>();
}

class ExtensionManager {
  int nextExtensionWorker = 0;

  final List<PendingExtensionWorker> pendingExtensions = [];
  final Map<int, PendingExtensionWorker> pendingWorkers = {};
  final Map<String, String> _loadedExtensions = {};

  final CentralDispatch runtime;

  ExtensionManager(this.runtime) {
    // Register this manager as a service in runtime
    runtime.setServiceSync('extensions', this);
  }

  bool isExtensionLoaded(String extensionID) {
    return _loadedExtensions.containsKey(extensionID);
  }

  // Example built-in extensions
  static final Map<String, ExtensionConstructor> builtinExtensions = {
    'coreExample': (runtime) => throw UnimplementedError(),
    'pen': (runtime) => throw UnimplementedError(),
    'wedo2': (runtime) => throw UnimplementedError(),
    'music': (runtime) => throw UnimplementedError(),
    'microbit': (runtime) => throw UnimplementedError(),
    'text2speech': (runtime) => throw UnimplementedError(),
    'translate': (runtime) => throw UnimplementedError(),
    'videoSensing': (runtime) => throw UnimplementedError(),
    'ev3': (runtime) => throw UnimplementedError(),
    'makeymakey': (runtime) => throw UnimplementedError(),
    'boost': (runtime) => throw UnimplementedError(),
    'gdxfor': (runtime) => throw UnimplementedError(),
  };

  void loadExtensionIdSync(String extensionId) {
    if (!builtinExtensions.containsKey(extensionId)) {
      log.warn('Could not find extension $extensionId in built-in extensions.');
      return;
    }

    if (isExtensionLoaded(extensionId)) {
      log.warn(
          'Rejecting attempt to load a second extension with ID $extensionId');
      return;
    }

    final extension = builtinExtensions[extensionId]!(runtime);
    final serviceName = _registerInternalExtension(extension);
    _loadedExtensions[extensionId] = serviceName;
  }

  Future<void> loadExtensionURL(String extensionURL) async {
    if (builtinExtensions.containsKey(extensionURL)) {
      if (isExtensionLoaded(extensionURL)) {
        log.warn(
            'Rejecting attempt to load a second extension with ID $extensionURL');
        return;
      }

      final extension = builtinExtensions[extensionURL]!(runtime);
      final serviceName = _registerInternalExtension(extension);
      _loadedExtensions[extensionURL] = serviceName;
      return;
    }

    // Non-built-in: simulate worker-based loading
    final workerInfo = PendingExtensionWorker(extensionURL);
    pendingExtensions.add(workerInfo);

    // NOTE: Worker handling not implemented yet
    await workerInfo.completer.future;
  }

  String _registerInternalExtension(dynamic extensionObject) {
    final extensionInfo = extensionObject.getInfo();
    final fakeWorkerId = nextExtensionWorker++;
    final serviceName = 'extension_${fakeWorkerId}_${extensionInfo.id}';

    runtime.setServiceSync(serviceName, extensionObject);
    runtime
        .callSync('extensions', 'registerExtensionServiceSync', [serviceName]);

    return serviceName;
  }

  void onWorkerInit(int id, [dynamic e]) {
    final workerInfo = pendingWorkers[id];
    pendingWorkers.remove(id);
    if (workerInfo == null) return;

    if (e != null) {
      workerInfo.completer.completeError(e);
    } else {
      workerInfo.completer.complete(id);
    }
  }
}
