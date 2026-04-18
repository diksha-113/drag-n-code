import 'dart:async';

/// JSON-RPC 2.0 client/server base class
abstract class JSONRPC {
  int _requestID = 0;
  final Map<int, Completer> _openRequests = {};

  /// Send an RPC request and return a Future for the result.
  Future<dynamic> sendRemoteRequest(
      String method, Map<String, dynamic>? params) {
    final requestID = _requestID++;
    final completer = Completer<dynamic>();
    _openRequests[requestID] = completer;

    _sendRequest(method, params, requestID);

    return completer.future;
  }

  /// Send an RPC notification (no response expected)
  void sendRemoteNotification(String method, Map<String, dynamic>? params) {
    _sendRequest(method, params, null);
  }

  /// Override this to handle incoming RPC calls
  dynamic didReceiveCall(String method, Map<String, dynamic>? params);

  /// Override this to actually send a JSON message
  void sendMessage(Map<String, dynamic> message);

  void _sendRequest(String method, Map<String, dynamic>? params, int? id) {
    final request = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    };

    if (id != null) {
      request['id'] = id;
    }

    sendMessage(request);
  }

  /// Handle an incoming message (request or response)
  void handleMessage(Map<String, dynamic> json) {
    if (json['jsonrpc'] != '2.0') {
      throw Exception('Bad or missing JSON-RPC version in message: $json');
    }

    if (json.containsKey('method')) {
      _handleRequest(json);
    } else {
      _handleResponse(json);
    }
  }

  void _sendResponse(int id, dynamic result, [dynamic error]) {
    final response = {
      'jsonrpc': '2.0',
      'id': id,
    };
    if (error != null) {
      response['error'] = error;
    } else {
      response['result'] = result; // Removed redundant ?? null
    }
    sendMessage(response);
  }

  void _handleResponse(Map<String, dynamic> json) {
    final result = json['result'];
    final error = json['error'];
    final id = json['id'];

    final completer = _openRequests[id];
    _openRequests.remove(id);

    if (completer != null) {
      if (error != null) {
        completer.completeError(error);
      } else {
        completer.complete(result);
      }
    }
  }

  void _handleRequest(Map<String, dynamic> json) {
    final method = json['method'] as String;
    final params = json['params'] as Map<String, dynamic>?;
    final id = json['id'];

    final rawResult = didReceiveCall(method, params);

    if (id != null) {
      Future.value(rawResult).then(
        (result) => _sendResponse(id, result),
        onError: (error) => _sendResponse(id, null, error),
      );
    }
  }
}
