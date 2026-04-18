// lib/vm/dispatch/worker_dispatch.dart
// WorkerDispatch: run inside a worker isolate
// Handles incoming messages and can call central via SendPort

import 'dart:async';
import 'dart:isolate';
import '../util/log.dart';

class WorkerDispatch {
  final SendPort mainSendPort;
  final Map<String, Function> _services = {};

  WorkerDispatch(this.mainSendPort) {
    log('WorkerDispatch initialized');
  }

  void registerService(String name, Function handler) {
    _services[name] = handler;
  }

  void handleMessage(dynamic msg) async {
    if (msg is Map<String, dynamic>) {
      final responseId = msg['responseId'] as int?;
      final service = msg['service'] as String?;
      final method = msg['method'] as String?;
      final args = (msg['args'] as List?) ?? [];

      if (service != null && method != null) {
        final handler = _services[method];
        if (handler is Function) {
          try {
            final result =
                await Future.sync(() => Function.apply(handler, args));
            if (responseId != null) {
              mainSendPort.send({'responseId': responseId, 'result': result});
            }
          } catch (e) {
            if (responseId != null) {
              mainSendPort
                  .send({'responseId': responseId, 'error': e.toString()});
            }
          }
        } else {
          if (responseId != null) {
            mainSendPort
                .send({'responseId': responseId, 'error': 'Method not found'});
          }
        }
      }
    }
  }

  void log(String msg) {
    Log.info(msg);
  }
}

// Helper entrypoint for Isolate.spawn
Future<void> workerEntry(SendPort mainSendPort) async {
  final port = ReceivePort();
  mainSendPort.send(port.sendPort); // handshake

  final worker = WorkerDispatch(mainSendPort);

  await for (final dynamic msg in port) {
    worker.handleMessage(msg);
  }
}
