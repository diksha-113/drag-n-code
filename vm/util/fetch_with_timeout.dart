import 'dart:async';

/// Type definition for a custom fetch function
typedef FetchFunction<T> = Future<T> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  String method,
});

/// Internal variable to hold the fetch function
late FetchFunction _myFetch;

/// Set a custom fetch function
void setFetch<T>(FetchFunction<T> fetch) {
  _myFetch = fetch;
}

/// Controller to allow aborting requests
class FetchController {
  bool _aborted = false;

  bool get aborted => _aborted;

  void abort() {
    _aborted = true;
  }
}

/// Fetch a URL with timeout and optional abort
Future<T> fetchWithTimeout<T>(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  String method = 'GET',
  required Duration timeout,
  FetchController? controller,
}) async {
  final completer = Completer<T>();

  // Timeout timer
  late final Timer timer;
  timer = Timer(timeout, () {
    if (!completer.isCompleted) {
      controller?.abort();
      completer.completeError(
        TimeoutException('Fetch timed out after ${timeout.inMilliseconds} ms'),
      );
    }
  });

  try {
    final result = await _myFetch(
      url,
      headers: headers,
      body: body,
      method: method,
    );

    if (controller != null && controller.aborted) {
      completer.completeError(StateError('Fetch aborted'));
    } else {
      completer.complete(result);
    }
  } catch (e) {
    if (!completer.isCompleted) completer.completeError(e);
  } finally {
    timer.cancel();
  }

  return completer.future;
}
