// lib/vm/engine/mouse_wheel.dart

import '../engine/runtime.dart';

class MouseWheel {
  final Runtime runtime;

  MouseWheel(this.runtime);

  /// Mouse wheel event handler
  void postData(Map<String, dynamic> data) {
    final matchFields = <String, String>{};

    if (data['deltaY'] < 0) {
      matchFields['KEY_OPTION'] = 'up arrow';
    } else if (data['deltaY'] > 0) {
      matchFields['KEY_OPTION'] = 'down arrow';
    } else {
      return; // No action if deltaY is 0
    }

    runtime.startHats('event_whenkeypressed', matchFields);
  }
}
