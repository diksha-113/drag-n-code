// lib/vm/dispatch/central_dispatch.dart
// Central dispatch for Drag N Code — Scratch 3.0-like skeleton
//
// Fully integrated with SharedDispatch and WorkerDispatch
// Handles services, opcodes, broadcast, targets, threads, and workers.

import 'dart:async';
import 'dart:isolate';

import '../util/log.dart';
import 'shared_dispatch.dart';
import 'worker_dispatch.dart';
import '../engine/target.dart' as engine_target;

class CentralDispatch with SharedDispatch {
  // -----------------------
  // Core state
  // -----------------------
  final Map<String, _ProviderRecord> _services = {};
  final List<_WorkerRecord> _workers = [];
  final Map<String, Function> opcodes = {};
  final Map<String,
          List<FutureOr<void> Function(engine_target.Target?, String)>>
      _broadcastListeners = {};
  final List<ScriptThread> _threads = [];
  Timer? _tickTimer;
  int tickMs = 40;
  final Map<String, engine_target.Target> targets = {};
  // -----------------------
// Workspace execution event listeners
// -----------------------
  final Map<String, List<void Function(dynamic)>> _listeners = {};

  // -----------------------
  // Event system for Workspace
  // -----------------------
  final Map<String, List<List<Map<String, dynamic>>>> _eventStacks = {};

  void register(String eventName, List<Map<String, dynamic>> blocks) {
    _eventStacks.putIfAbsent(eventName, () => []).add(blocks);
  }

  // -----------------------
// Hat blocks for "when flag clicked", "when I receive", etc.
// -----------------------
  final Map<String, List<List<Map<String, dynamic>>>> _hatBlocks = {};

  void emit(String eventName, dynamic workspace) {
    final stacks = _eventStacks[eventName];
    if (stacks == null) return;
    for (final blocks in stacks) {
      final blockIds = blocks.map((b) => b['id'] as String).toList();
      workspace.runStack(blockIds);
    }
  }

  CentralDispatch() {
    _registerBaseOpcodes();
  }

  // -----------------------
  // Hat blocks methods
  // -----------------------
  /// Register a hat event (e.g., whenFlagClicked, whenIReceive)
  void registerHat(
      String eventName, List<Map<String, dynamic>> blocks, dynamic target) {
    _hatBlocks.putIfAbsent(eventName, () => []).add(blocks);
  }

  /// Get all blocks registered for a hat event
  List<Map<String, dynamic>>? getHatBlocks(String eventName) {
    final stacks = _hatBlocks[eventName];
    if (stacks == null || stacks.isEmpty) return null;
    return stacks.expand((stack) => stack).toList();
  }

  // -----------------------
  // Services - local + remote
  // -----------------------
  void setServiceSync(String service, dynamic provider) {
    _services[service] = _ProviderRecord(provider: provider, isRemote: false);
  }

  dynamic callSync(String service, String method, [List<dynamic>? args]) {
    final rec = _services[service];
    if (rec == null) {
      throw Exception('Provider not found: $service');
    }
    if (rec.isRemote) {
      throw Exception("Cannot callSync remote provider: $service");
    }
    final provider = rec.provider;
    final fn = provider[method];
    if (fn is Function) {
      return Function.apply(fn, args);
    }
    throw Exception("Method not found: $method on $service");
  }

  Future<dynamic> transferCall(String service, String method,
      List<dynamic>? transfer, List<dynamic> args) {
    final rec = _services[service];
    if (rec == null) return Future.error('Service not found: $service');

    if (!rec.isRemote) {
      try {
        final result = Function.apply(rec.provider[method], args);
        return Future.value(result);
      } catch (e) {
        return Future.error(e);
      }
    }

    final worker = rec.provider as _WorkerRecord;
    final completer = Completer<dynamic>();
    final responseId = storeCallbacks(
      (v) => completer.complete(v),
      (err) => completer.completeError(err),
    );

    final msg = <String, dynamic>{
      'service': service,
      'method': method,
      'args': args,
      'responseId': responseId,
    };

    try {
      worker.sendPort.send(msg);
    } catch (e) {
      return Future.error(e);
    }

    return completer.future;
  }

  // -----------------------
  // Workers (Isolates)
  // -----------------------
  Future<dynamic> spawnWorker({String? serviceName, List<String>? args}) async {
    final receive = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();

    final isolate = await Isolate.spawn(
      workerEntry,
      receive.sendPort,
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );

    final completer = Completer<dynamic>();
    late StreamSubscription sub;
    sub = receive.listen((dynamic msg) {
      if (msg is SendPort) {
        final workerRec = _WorkerRecord(
          isolate: isolate,
          sendPort: msg,
          receivePort: receive,
          serviceName: serviceName,
        );

        _workers.add(workerRec);

        if (serviceName != null) {
          _services[serviceName] =
              _ProviderRecord(provider: workerRec, isRemote: true);
        }

        completer.complete(workerRec);
        sub.cancel();
      } else if (msg is Map<String, dynamic>) {
        handleWorkerMessage(msg);
      }
    });

    errorPort.listen((e) {
      log('Worker error: $e');
    });
    exitPort.listen((_) {
      log('Worker exited');
      _workers.removeWhere((w) => w.isolate == isolate);
      _services.removeWhere((k, v) {
        return v.provider is _WorkerRecord &&
            (v.provider as _WorkerRecord).isolate == isolate;
      });
    });

    return completer.future;
  }

  /// Central handler for messages from workers
  void handleWorkerMessage(dynamic raw) {
    if (raw is! Map<String, dynamic>) return;

    if (raw.containsKey('responseId') &&
        (raw.containsKey('result') || raw.containsKey('error'))) {
      final idRaw = raw['responseId'];
      final id = (idRaw is int) ? idRaw : int.tryParse(idRaw.toString()) ?? 0;
      if (id != 0) {
        deliverResponse(id, raw);
        return;
      }
    }

    final service = raw['service'];
    final method = raw['method'];
    final args = (raw['args'] as List?)?.cast<dynamic>() ?? <dynamic>[];
    final responseId = raw['responseId'];
    final replyTo = raw['replyTo'] as SendPort?;

    if (service == 'dispatch' && method == 'handshake') return;

    Future.sync(() {
      final rec = _services[service];
      if (rec == null) {
        throw Exception('Service not found: $service');
      }
      if (rec.isRemote) {
        throw Exception('Remote->remote not supported here');
      }
      final fn = rec.provider[method];
      if (fn is Function) {
        return Function.apply(fn, args);
      }
      throw Exception('Method not found: $method on $service');
    }).then((res) {
      if (responseId != null && replyTo != null) {
        replyTo.send({'responseId': responseId, 'result': res});
      }
    }).catchError((err) {
      if (responseId != null && replyTo != null) {
        replyTo.send({'responseId': responseId, 'error': err.toString()});
      }
    });
  }

  // -----------------------
  // Opcode registry
  // -----------------------
  void registerOpcode(String name, Function handler) => opcodes[name] = handler;

  void _registerBaseOpcodes() {
    registerOpcode('motion_move',
        (engine_target.Target t, List<dynamic> args, ScriptThread thread) {
      final dx = (args.isNotEmpty && args[0] is num)
          ? (args[0] as num).toDouble()
          : 0.0;
      final dy = (args.length > 1 && args[1] is num)
          ? (args[1] as num).toDouble()
          : 0.0;
      t.x += dx;
      t.y += dy;
      return null;
    });

    registerOpcode('looks_say',
        (engine_target.Target t, List<dynamic> args, ScriptThread thread) {
      final msg = args.isNotEmpty ? args[0].toString() : '';
      t.say = msg;
      return null;
    });

    registerOpcode('control_wait', (engine_target.Target t, List<dynamic> args,
        ScriptThread thread) async {
      final seconds = (args.isNotEmpty && args[0] is num)
          ? (args[0] as num).toDouble()
          : 0.0;
      await thread.sleep((seconds * 1000).toInt());
      return null;
    });

    registerOpcode('event_broadcast',
        (engine_target.Target t, List<dynamic> args, ScriptThread thread) {
      final msg = args.isNotEmpty ? args[0].toString() : '';
      broadcast(msg);
      return null;
    });
  }

  // -----------------------
  // Broadcast / whenIReceive
  // -----------------------
  void onBroadcast(String message,
      FutureOr<void> Function(engine_target.Target?, String) listener) {
    _broadcastListeners.putIfAbsent(message, () => []).add(listener);
  }

  void offBroadcast(String message,
      FutureOr<void> Function(engine_target.Target?, String) listener) {
    final list = _broadcastListeners[message];
    if (list != null) {
      list.remove(listener);
      if (list.isEmpty) {
        _broadcastListeners.remove(message);
      }
    }
  }

  void broadcast(String message) {
    final listeners =
        List<FutureOr<void> Function(engine_target.Target?, String)>.from(
            _broadcastListeners[message] ?? []);
    for (final l in listeners) {
      final thread = createThread((thread) async {
        try {
          await Future.sync(() => l(null, message));
        } catch (e) {
          log('broadcast listener error: $e');
        }
      });
      thread.start();
    }
  }

  /// Register a listener for a custom event
  void onEvent(String eventName, void Function(dynamic event) callback) {
    _listeners.putIfAbsent(eventName, () => []).add(callback);
  }

  /// Emit an event to all registered listeners
  void emitEvent(String eventName, {dynamic message}) {
    final listeners = _listeners[eventName];
    if (listeners == null) return;
    for (final cb in listeners) {
      try {
        cb({'message': message});
      } catch (e) {
        log('Event listener error: $e');
      }
    }
  }

  // -----------------------
  // Targets (sprites/stage)
  // -----------------------
  void registerTarget(engine_target.Target t) => targets[t.id] = t;
  engine_target.Target? getTarget(String id) => targets[id];
  void unregisterTarget(String id) => targets.remove(id);

  // -----------------------
  // Threads / scheduler
  // -----------------------
  ScriptThread createThread(FutureOr<void> Function(ScriptThread) runner) {
    final t = ScriptThread(runner, this);
    _threads.add(t);
    return t;
  }

  void removeThread(ScriptThread t) => _threads.remove(t);

  void startTicks({int ms = 40}) {
    if (_tickTimer != null) return;
    tickMs = ms;
    _tickTimer = Timer.periodic(Duration(milliseconds: tickMs), (_) => _tick());
    log('ticks started at $tickMs ms');
  }

  void stopTicks() {
    _tickTimer?.cancel();
    _tickTimer = null;
    log('ticks stopped');
  }

  void _tick() {
    final snapshot = List<ScriptThread>.from(_threads);
    for (final t in snapshot) {
      if (!t.isRunning || t.isSleeping) continue;
      t._step();
    }
  }

  // -----------------------
  // Cleanup
  // -----------------------
  void stopAllWorkers() {
    for (final w in List<_WorkerRecord>.from(_workers)) {
      try {
        w.receivePort.close();
        w.isolate.kill(priority: Isolate.immediate);
      } catch (_) {}
    }
    _workers.clear();
    _services.clear();
    log('All workers stopped and services cleared');
  }

  void dispose() {
    stopTicks();
    stopAllWorkers();
    _threads.clear();
    targets.clear();
    _broadcastListeners.clear();
    _eventStacks.clear();
  }
}

// -----------------------
// ScriptThread - cooperative runner
// -----------------------
class ScriptThread {
  final FutureOr<void> Function(ScriptThread) _runner;
  final CentralDispatch _central;
  bool isRunning = false;
  bool isSleeping = false;
  Completer<void>? _sleepCompleter;

  ScriptThread(this._runner, this._central);

  void start() {
    if (isRunning) return;
    isRunning = true;
    Future<void>(() async {
      try {
        await _runner(this);
      } catch (e) {
        Log.error('Thread runner error: $e');
      } finally {
        isRunning = false;
        _central.removeThread(this);
      }
    });
  }

  void _step() {}

  Future<void> sleep(int ms) {
    isSleeping = true;
    _sleepCompleter = Completer<void>();
    Timer(Duration(milliseconds: ms), () {
      isSleeping = false;
      if (!(_sleepCompleter?.isCompleted ?? true)) {
        _sleepCompleter?.complete();
      }
    });
    return _sleepCompleter!.future;
  }

  void stop() {
    isRunning = false;
    isSleeping = false;
    if (!(_sleepCompleter?.isCompleted ?? true)) {
      _sleepCompleter?.complete();
    }
    _central.removeThread(this);
  }
}

// -----------------------
// Internal records
// -----------------------
class _ProviderRecord {
  final dynamic provider;
  final bool isRemote;
  _ProviderRecord({required this.provider, required this.isRemote});
}

class _WorkerRecord {
  final Isolate isolate;
  final SendPort sendPort;
  final ReceivePort receivePort;
  final String? serviceName;
  _WorkerRecord({
    required this.isolate,
    required this.sendPort,
    required this.receivePort,
    this.serviceName,
  });
}
