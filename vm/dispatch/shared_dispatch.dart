// lib/vm/dispatch/shared_dispatch.dart
// SharedDispatch: common utilities for central + worker dispatches
// Provides logging helpers and callback handling.

import '../util/log.dart';

mixin SharedDispatch {
  int _nextCallbackId = 1;
  final Map<int, void Function(dynamic)> _onSuccess = {};
  final Map<int, void Function(dynamic)> _onError = {};

  /// Store success and error callbacks, returns a unique callback ID
  int storeCallbacks(
      void Function(dynamic) onSuccess, void Function(dynamic) onError) {
    final id = _nextCallbackId++;
    _onSuccess[id] = onSuccess;
    _onError[id] = onError;
    return id;
  }

  /// Deliver response to the registered callback
  void deliverResponse(int id, Map<String, dynamic> raw) {
    if (raw.containsKey('result')) {
      _onSuccess[id]?.call(raw['result']);
    } else if (raw.containsKey('error')) {
      _onError[id]?.call(raw['error']);
    } else {
      _onSuccess[id]?.call(null);
    }
    _onSuccess.remove(id);
    _onError.remove(id);
  }

  /// Logging utility
  void log(String msg) {
    Log.info(msg);
  }
}
